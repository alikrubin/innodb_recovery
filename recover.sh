#!/bin/bash

#set -ex
#mysql_user="`whoami`"
#mysql_password=""
#mysql_host="localhost"
MYSQL="mysql "
mysql_db=""
work_dir="/tmp/recovery_$RANDOM"
top_dir="`pwd`"
tables=""
mysql_tmp_socket="/tmp/mysqldr-$RANDOM.sock" 
VERBOSE=0

### Functions

function usage() {
printf "Valid options are \n";
printf " \t -d database name to extract \n"
printf " \t -t table_name(s), list table with 'table1 table2 tableN' \n"
printf " \t -v verbose mode  \n"
printf " \t -D recover deleted rows  \n"
printf "recover.sh -v 1 -d sakila -t 'film payment' -D" 
printf "\n"
}

function start_mysql {
        mysql_datadir="`mktemp -d`"
        mysql_start_timeout="300"
        mysql_user="nobody"

        mkdir -p "$mysql_datadir"
        #mysql_install_db --no-defaults --datadir="$mysql_datadir"
        chown -R $mysql_user "$mysql_datadir"
        mysqld --no-defaults --sql-mode=''  --default-storage-engine=MyISAM  --default-tmp-storage-engine=MyISAM --skip-innodb --datadir="$mysql_datadir" --socket="$mysql_tmp_socket" --user=$mysql_user --skip-networking --skip-grant-tables 1>/dev/null 2>/dev/null &

        while [ "`mysql -NB --socket=\"$mysql_tmp_socket\" -e 'select 1'`" != "1" ]
        do
                echo "Waiting till aux instance of MySQL starts"
                sleep 1
                mysql_start_timeout=$(($mysql_start_timeout - 1))
                if [ $mysql_start_timeout -eq 0 ]; then echo "Can't start aux instance of MySQL. Exiting..."; exit ; fi
        done
}

### Main

if [ $# -lt 2 ] ; then
        echo 'Too few arguments supplied'
        usage
        exit 1
fi

while getopts ":v:d:t:D" opt; do
  case $opt in
    v)
       VERBOSE=1
       ;;
    d)
       mysql_db=$OPTARG
       if [ $VERBOSE -eq 1  ] ; then
           echo "Database: $mysql_db"
       fi
       ;;
    t)
       tables=$OPTARG
       if [ $VERBOSE -eq 1  ] ; then
           echo "TABLES: $tables"
       fi
       ;;
    D)
       UNDEL=" -D "
       if [ $VERBOSE -eq 1  ] ; then
           echo "UNDEL flag is set"
       fi
       ;;
  esac
done

start_mysql
echo $mysql_tmp_socket
MYSQL_TMP="mysql --no-defaults -S $mysql_tmp_socket "
if [ $VERBOSE -eq 1  ] ; then
   mydebug=" -vvv "
fi

# Check that the script is run from source directory
if ! test -f "$top_dir/stream_parser.c"
then
	echo "Script $0 must be run from a directory with TwinDB InnoDB Recovery Tool source code"
	exit 1
fi

echo -n "Initializing working directory... "
if test -d "$work_dir"
then
	echo "Directory $work_dir must not exist. Remove it and restart $0"
	exit 1
fi

mkdir "$work_dir"
cd "$work_dir"
trap "if [ $? -ne 0 ] ; then rm -r \"$work_dir\"; fi" EXIT
echo "OK"


echo -n "Testing MySQL connection... "
#if test -z "$mysql_password"
#then
#	MYSQL="mysql -u$mysql_user -h $mysql_host"
#else
#	MYSQL="mysql -u$mysql_user -p$mysql_password -h $mysql_host"
#fi

$MYSQL -e "SELECT COUNT(*) FROM user" mysql >/dev/null
has_innodb=`$MYSQL -e "SHOW ENGINES"| grep InnoDB| grep -e "YES" -e "DEFAULT"`
if test -z "$has_innodb"
then
	echo "InnoDB is not enabled on this MySQL server"
	exit 1
fi
echo "OK"

echo -n "Creating recovery database... "
$MYSQL -e "CREATE DATABASE IF NOT EXISTS ${mysql_db}_recovered"
$MYSQL_TMP -e "CREATE DATABASE IF NOT EXISTS ${mysql_db}_recovered"

echo -n "Building InnoDB parsers... "
cd "$top_dir"
make  > "$work_dir/make.log" 2>&1
cd "$work_dir"
echo "OK"

# Get datadir
datadir="`$MYSQL  -e "SHOW VARIABLES LIKE 'datadir'" -NB | awk '{ $1 = ""; print $0}'| sed 's/^ //'`"
innodb_file_per_table=`$MYSQL  -e "SHOW VARIABLES LIKE 'innodb_file_per_table'" -NB | awk '{ print $2}'`
innodb_data_file_path=`$MYSQL  -e "SHOW VARIABLES LIKE 'innodb_data_file_path'" -NB | awk '{ $1 = ""; print $0}'| sed 's/^ //'`

echo "Splitting InnoDB tablespace into pages... "
old_IFS="$IFS"
IFS=";"
for ibdata in $innodb_data_file_path
do
	ibdata_file=`echo $ibdata| awk -F: '{print $1}'`
	"$top_dir"/stream_parser -f "$datadir/$ibdata_file"
done
IFS=$old_IFS
if [ $innodb_file_per_table == "ON" ]
then
	for t in $tables
	do
		"$top_dir"/stream_parser -f "$datadir/$mysql_db/$t.ibd"
	done
fi
echo "OK"

echo -n "Recovering InnoDB dictionary... "
old_IFS="$IFS"
IFS=";"
for ibdata in $innodb_data_file_path
do
	ibdata_file=`echo $ibdata| awk -F: '{print $1}'`
	dir="pages-$ibdata_file"/FIL_PAGE_INDEX/`printf "%016d" 1`.page
	mkdir -p "dumps/${mysql_db}_recovered"
	if test -f "$dir"
	then
		"$top_dir"/c_parser -4Uf "$dir" -p "${mysql_db}_recovered" \
            -t "$top_dir"/dictionary/SYS_TABLES.sql \
            >> "dumps/${mysql_db}_recovered/SYS_TABLES" \
            2>SYS_TABLES.sql
	fi
	dir="pages-$ibdata_file"/FIL_PAGE_INDEX/`printf "%016d" 3`.page
	if test -f "$dir"
	then
		"$top_dir"/c_parser -4Uf "$dir" -p "${mysql_db}_recovered" \
        -t "$top_dir"/dictionary/SYS_INDEXES.sql \
        >> "dumps/${mysql_db}_recovered/SYS_INDEXES" \
        2>SYS_INDEXES.sql
	fi
done
IFS=$old_IFS

$MYSQL_TMP $mydebug -e "DROP TABLE IF EXISTS SYS_TABLES" ${mysql_db}_recovered 
$MYSQL_TMP $mydebug -e "DROP TABLE IF EXISTS SYS_INDEXES" ${mysql_db}_recovered 
# load structure
$MYSQL_TMP $mydebug ${mysql_db}_recovered < "$top_dir"/dictionary/SYS_TABLES.sql
$MYSQL_TMP $mydebug ${mysql_db}_recovered < "$top_dir"/dictionary/SYS_INDEXES.sql
# load data
$MYSQL_TMP $mydebug ${mysql_db}_recovered < SYS_INDEXES.sql
$MYSQL_TMP $mydebug ${mysql_db}_recovered < SYS_TABLES.sql
echo "OK"
echo -n "Recovering tables... "
for t in $tables
do
	# Create table structure
	pwd
	echo "pages-$t.ibd/$t.sql"
	#$MYSQL -NB -e "show create table ${mysql_db}.$t\G" |grep -v "* 1. row *"|egrep -v "^$t$" > pages-$t.ibd/$t.sql	
	mysqldump --skip-triggers --skip-add-drop-table --no-data ${mysql_db} $t > pages-$t.ibd/$t.sql
	#echo ";" >> pages-$t.ibd/$t.sql
	# Get index id
	index_id=`$MYSQL_TMP -NB -e "SELECT SYS_INDEXES.ID FROM SYS_INDEXES JOIN SYS_TABLES ON SYS_INDEXES.TABLE_ID = SYS_TABLES.ID WHERE SYS_TABLES.NAME= '${mysql_db}/$t' ORDER BY ID LIMIT 1" ${mysql_db}_recovered`
	# get row format
	Row_format=`$MYSQL -NB -e "SHOW TABLE STATUS LIKE '$t'" ${mysql_db}| awk '{print $4}'`
	is_56=`$MYSQL -NB -e "select @@version"| grep 5\.6`
	if [ "$Row_format" == "Compact" ]
	then
		Row_format_arg="-5"
        if ! test -z "$is_56"; then Row_format_arg="-6"; fi
	else
		Row_format_arg="-4"
	fi
	if [ $innodb_file_per_table == "ON" ]
	then
#                -p "${mysql_db}_recovered" \
#                -b "pages-$t.ibd/FIL_PAGE_TYPE_BLOB" \
		#"$top_dir"/c_parser $Row_format_arg -Uf "pages-$t.ibd/FIL_PAGE_INDEX/`printf '%016u' $index_id`.page" \
		"$top_dir"/c_parser $Row_format_arg -Uf "$datadir/$mysql_db/$t.ibd" \
		-p "${mysql_db}_recovered" \
                -t "pages-$t.ibd/$t.sql" $UNDEL \
                > "dumps/${mysql_db}_recovered/$t" 2> $t.sql
	else
		old_IFS="$IFS"
		IFS=";"
		for ibdata in $innodb_data_file_path
		do
			ibdata_file=`echo $ibdata| awk -F: '{print $1}'`
			dir="pages-$ibdata_file"/FIL_PAGE_INDEX/0-$index_id
			if test -d "$dir"
			then
				"$top_dir"/c_parser $Row_format_arg -Uf "$dir" -p "${mysql_db}_recovered" -b "pages-$ibdata_file/FIL_PAGE_TYPE_BLOB" -t "pages-$t.ibd/$t.sql" $UNDEL >> "dumps/${mysql_db}_recovered/$t" 2> $t.sql
			fi

		done
		IFS="$old_IFS"
	fi
done
echo "OK"

echo -n "Loading recovered data into MySQL... "
for t in $tables
do
	$MYSQL $mydebug -e "DROP TABLE IF EXISTS \`$t\`;CREATE TABLE $t like ${mysql_db}.$t" ${mysql_db}_recovered
	$MYSQL $mydebug ${mysql_db}_recovered < $t.sql
done

echo "OK"

cd "$top_dir"
echo "Shutting down temp MySQL..."
mysqladmin --no-defaults -S $mysql_tmp_socket shutdown

echo "DONE"

