%option noyywrap
%option case-insensitive
%s COMMENT_a COMMENT_b NORMAL

comstart_a "--"
comstop_a "\n"

comstart_b "/*!"
comstop_b "*/"
%%
    BEGIN NORMAL;
<NORMAL>{comstart_a}  { BEGIN COMMENT_a; }
<NORMAL>{comstart_b}  { BEGIN COMMENT_b; }
<COMMENT_a>{comstop_a}  { BEGIN 0; BEGIN NORMAL; }
<COMMENT_b>{comstop_b}  { BEGIN 0; BEGIN NORMAL; }
<COMMENT_a>[ [:graph:]\t] ;
<COMMENT_b>[ [:graph:]\t\n] ;
<NORMAL>`[[_a-zA-Z]+[-_a-zA-Z0-9]*]*`   {
    memset(yylval.str, 0, sizeof(yylval.str)); 
    strncpy(yylval.str, yytext, strlen(yytext)) ; 
    return entity_name; 
    }
<NORMAL>"CREATE"    { return CREATE; }
<NORMAL>"TABLE"    { return TABLE; }
<NORMAL>"TEMPORARY"    { return TEMPORARY; }
<NORMAL>"IF NOT EXIST"    { return IF_NOT_EXIST; }
<NORMAL>"NULL"    { return SQLNULL; }
<NORMAL>"DEFAULT"    { return DEFAULT; }
<NORMAL>"NOT"    { return NOT; }
<NORMAL>"COMMENT"    { return COMMENT; }
<NORMAL>"FULLTEXT"    { return FULLTEXT; }
<NORMAL>"SPATIAL"    { return SPATIAL; }
<NORMAL>"CONSTRAINT"    { return CONSTRAINT; }
<NORMAL>"INDEX"    { return INDEX; }
<NORMAL>"KEY"    { return KEY; }
<NORMAL>"PRIMARY"    { return PRIMARY; }
<NORMAL>"UNIQUE"    { return UNIQUE; }
<NORMAL>"FOREIGN KEY"    { return FOREIGN_KEY; }
<NORMAL>"BIT"    { return BIT; }
<NORMAL>"TINYINT"    { return TINYINT; }
<NORMAL>"SMALLINT"    { return SMALLINT; }
<NORMAL>"MEDIUMINT"    { return MEDIUMINT; }
<NORMAL>"INT"    { return INT; }
<NORMAL>"INTEGER"    { return INTEGER; }
<NORMAL>"BIGINT"    { return BIGINT; }
<NORMAL>"REAL"    { return REAL; }
<NORMAL>"DOUBLE"    { return DOUBLE; }
<NORMAL>"FLOAT"    { return FLOAT; }
<NORMAL>"DECIMAL"    { return DECIMAL; }
<NORMAL>"NUMERIC"    { return NUMERIC; }
<NORMAL>"DATE"    { return DATE; }
<NORMAL>"TIME"    { return TIME; }
<NORMAL>"TIMESTAMP"    { return TIMESTAMP; }
<NORMAL>"DATETIME"    { return DATETIME; }
<NORMAL>"YEAR"    { return YEAR; }
<NORMAL>"CHAR"    { return CHAR; }
<NORMAL>"VARCHAR"    { return VARCHAR; }
<NORMAL>"TINYTEXT"    { return TINYTEXT; }
<NORMAL>"TEXT"    { return TEXT; }
<NORMAL>"MEDIUMTEXT"    { return MEDIUMTEXT; }
<NORMAL>"LONGTEXT"    { return LONGTEXT; }
<NORMAL>"BINARY"    { return BINARY; }
<NORMAL>"VARBINARY"    { return VARBINARY; }
<NORMAL>"TINYBLOB"    { return TINYBLOB; }
<NORMAL>"BLOB"    { return BLOB; }
<NORMAL>"MEDIUMBLOB"    { return MEDIUMBLOB; }
<NORMAL>"LONGBLOB"    { return LONGBLOB; }
<NORMAL>"ENUM"    { return ENUM; }
<NORMAL>"SET"    { return SET; }
<NORMAL>"GEOMETRY"    { return GEOMETRY; }
<NORMAL>"POINT"    { return POINT; }
<NORMAL>"LINESTRING"    { return LINESTRING; }
<NORMAL>"POLYGON"    { return POLYGON; }
<NORMAL>"MULTIPOINT"    { return MULTIPOINT; }
<NORMAL>"MULTILINESTRING"    { return MULTILINESTRING; }
<NORMAL>"MULTIPOLYGON"    { return MULTIPOLYGON; }
<NORMAL>"GEOMETRYCOLLECTION"    { return GEOMETRYCOLLECTION; }
<NORMAL>"UNSIGNED"    { return UNSIGNED; }
<NORMAL>"ZEROFILL"    { return ZEROFILL; }
<NORMAL>"ASC"    { return ASC; }
<NORMAL>"DESC"    { return DESC; }
<NORMAL>"USING"    { return USING; }
<NORMAL>"BTREE"    { return BTREE; }
<NORMAL>"HASH"    { return HASH; }
<NORMAL>"RTREE"    { return RTREE; }
<NORMAL>"MATCH"    { return MATCH; }
<NORMAL>"FULL"    { return FULL; }
<NORMAL>"PARTIAL"    { return PARTIAL; }
<NORMAL>"SIMPLE"    { return SIMPLE; }
<NORMAL>"ON DELETE"    { return ON_DELETE; }
<NORMAL>"ON UPDATE"    { return ON_UPDATE; }
<NORMAL>"RESTRICT"    { return RESTRICT; }
<NORMAL>"CASCADE"    { return CASCADE; }
<NORMAL>"NO"    { return NO; }
<NORMAL>"ACTION"    { return ACTION; }
<NORMAL>"ENGINE"    { return ENGINE; }
<NORMAL>"TYPE"    { return TYPE; }
<NORMAL>"AUTO_INCREMENT"    { return AUTO_INCREMENT; }
<NORMAL>"AVG_ROW_LENGTH"    { return AVG_ROW_LENGTH; }
<NORMAL>"CHECKSUM"    { return CHECKSUM; }
<NORMAL>"CHARACTER"    { return CHARACTER; }
<NORMAL>"CHARSET"    { return CHARSET; }
<NORMAL>"COLLATE"    { return COLLATE; }
<NORMAL>"CONNECTION"    { return CONNECTION; }
<NORMAL>"DATA"    { return DATA; }
<NORMAL>"DIRECTORY"    { return DIRECTORY; }
<NORMAL>"DELAY_KEY_WRITE"    { return DELAY_KEY_WRITE; }
<NORMAL>"INSERT_METHOD"    { return INSERT_METHOD; }
<NORMAL>"MAX_ROWS"    { return MAX_ROWS; }
<NORMAL>"MIN_ROWS"    { return MIN_ROWS; }
<NORMAL>"PACK_KEYS"    { return PACK_KEYS; }
<NORMAL>"PASSWORD"    { return PASSWORD; }
<NORMAL>"ROW_FORMAT"    { return ROW_FORMAT; }
<NORMAL>"UNION"    { return UNION; }
<NORMAL>"FIRST"    { return FIRST; }
<NORMAL>"LAST"    { return LAST; }
<NORMAL>"DYNAMIC"    { return DYNAMIC; }
<NORMAL>"FIXED"    { return FIXED; }
<NORMAL>"COMPRESSED"    { return COMPRESSED; }
<NORMAL>"REDUNDANT"    { return REDUNDANT; }
<NORMAL>"COMPACT"    { return COMPACT; }
<NORMAL>"CURRENT_TIMESTAMP"    { return CURRENT_TIMESTAMP; }
<NORMAL>"REFERENCES"    { return REFERENCES; }
<NORMAL>[[_a-zA-Z]+[-_a-zA-Z0-9]*]*    { 
    memset(yylval.str, 0, sizeof(yylval.str)); 
    strncpy(yylval.str, yytext, strlen(yytext)) ; 
    return entity_name; 
    }
<NORMAL>'[^']*'    { 
    memset(yylval.str, 0, sizeof(yylval.str)); 
    strncpy(yylval.str, yytext, strlen(yytext)) ; 
    return string_value; 
    }
<NORMAL>[0-9]+    { yylval.si = atoi(yytext); return int_value; }
<NORMAL>[ \n\t]   ;
<NORMAL>.   { return yytext[0]; }
