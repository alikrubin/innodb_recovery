OBJECTS = stream_parser.o c_parser.o
TARGETS = stream_parser c_parser
SRCS = stream_parser.c include/mysql_def.h c_parser.c
INC_PATH = -I./include
LIBS = -pthread -lm

CC=gcc
YACC=bison
LEX=flex

all: $(TARGETS)
	

stream_parser.o: stream_parser.c include/mysql_def.h
	$(CC) -g -O3 $(CFLAGS) $(INC_PATH) -c $<

stream_parser: stream_parser.o
	$(CC) -g -O3 $(CFLAGS) $(INC_PATH) $(LIB_PATH) $(LIBS) $< -o $@

sql_parser.o: sql_parser.c
	$(CC) -g -O3 $(CFLAGS) $(INC_PATH) -c $< 

sql_parser.c: sql_parser.y lex.yy.c
	#$(YACC) -r all -o $@ $<
	$(YACC) -o $@ $<

lex.yy.c: sql_parser.l
	#$(LEX) -d $<
	$(LEX) $<

c_parser.o: c_parser.c
	$(CC) -g -O3 $(CFLAGS) $(INC_PATH) -c $<

tables_dict.o: tables_dict.c
	$(CC) -g -O3 $(CFLAGS) $(INC_PATH) -c $<

print_data.o: print_data.c
	$(CC) -g -O3 $(CFLAGS) $(INC_PATH) -c $<

check_data.o: check_data.c
	$(CC) -g -O3 $(CFLAGS) $(INC_PATH) -c $<

c_parser: sql_parser.o c_parser.o tables_dict.o print_data.o check_data.o
	$(CC) -g -O3 $(CFLAGS) $(INC_PATH) $(LIB_PATH) $(LIBS) $^ -o $@

install: $(TARGETS)
	$(INSTALL) $(INSTALLFLAGS) $(TARGETS) $(BINDIR)/$(TARGETS)

clean:
	rm -f $(OBJECTS) $(TARGETS) lex.yy.c sql_parser.c sql_parser.output
	rm -f *.o *.core
