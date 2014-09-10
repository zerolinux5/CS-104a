%{
// Dummy parser for scanner project.

#include <assert.h>

#include "lyutils.h"
#include "astree.h"

%}

%debug
%defines
%error-verbose
%token-table
%verbose

%token TOK_VOID TOK_BOOL TOK_CHAR TOK_INT TOK_STRING
%token TOK_IF TOK_ELSE TOK_WHILE TOK_RETURN TOK_STRUCT
%token TOK_FALSE TOK_TRUE TOK_NULL TOK_NEW TOK_ARRAY
%token TOK_EQ TOK_NE TOK_LT TOK_LE TOK_GT TOK_GE
%token TOK_IDENT TOK_INTCON TOK_CHARCON TOK_STRINGCON

%token TOK_BLOCK TOK_CALL TOK_IFELSE TOK_INITDECL
%token TOK_POS TOK_NEG TOK_NEWARRAY TOK_TYPEID TOK_FIELD
%token TOK_ORD TOK_CHR TOK_ROOT

%right TOK_IF TOK_ELSE
%right '='
%left TOK_EQ TOK_NE TOK_LT TOK_GT TOK_LE TOK_GE
%left '+' '-'
%left '*' '/' '%'
%right TOK_POS TOK_NEG '!' TOK_ORD TOK_CHR
%left '[' '.'

%start program

%%

program		: program structdef {$$ = adopt1($1, $2);}
		| program function {$$ = adopt1($1, $2);}
		| program statement {$$ = adopt1($1, $2)}
		| {$$ = new_parseroot();}
		;

structdef	: TOK_STRUCT TOK_IDENT '{' '}' {$$ = 
			adopt2(new_astree(0,0,0,0,"structdef"), $1, $2);}
		| TOK_STRUCT TOK_IDENT '{'structsubset '}'  {$$ = 
			adopt3(new_astree(0,0,0,0,"structdef"),$1, $2, $4);}
		;
structsubset	: structsubset decl ';' {$$ = 
			adopt2(new_astree(0,0,0,0,"structsubset"), $1, $2);}
			| decl ';' {$$ = adopt1(new_astree(0,0,0,0,"structsubset"), $1);}
		;

decl		: type TOK_IDENT  {$$ = adopt2(new_astree(0,0,0,0, "decl"),
				$1, $2);}
		;

type		: basetype {$$ = adopt1(new_astree(0,0,0,0, "basetype"), $1);}
		| basetype '[]' {$$ = adopt1(new_astree(0,0,0,0, "basetype"), $1);}
		;

basetype	: TOK_VOID {$$ = new_astree(TOK_VOID, 0, 0, 0, yytext);}
		| TOK_BOOL {$$ = new_astree(TOK_BOOL, 0, 0, 0, yytext);}
		| TOK_CHAR {$$ = new_astree(TOK_CHAR, 0, 0, 0, yytext);}
		| TOK_INT {$$ = new_astree(TOK_INT, 0, 0, 0, yytext);}
		| TOK_STRING {$$ = new_astree(TOK_STRING, 0, 0, 0, yytext);}
		| TOK_IDENT {$$ = new_astree(TOK_IDENT, 0, 0, 0, yytext);}
		;
function	: type TOK_IDENT '(' functionlist ')' block  {$$ = adopt4(
				new_astree(0,0,0,0,"function"),$1, $2, $4, $6);}
		;

functionlist	: functionlist ',' decl {$$ = adopt2(
				new_astree(0,0,0,0,"functionlist"),$1, $2);}
		| decl {$$ = adopt1(new_astree(0,0,0,0, "functionlist"),$1);}
		| 
		;

block		: '{' '}' {$$ = new_astree(0,0,0,0,"block");}
		| '{' blocklist '}' {$$ = adopt1(new_astree(0,0,0,0,"block"), $2);} 
		| ';' {$$ = new_astree(0, 0, 0, 0, "block");}
		;

blocklist	: blocklist statement {$$ = 
			adopt1(new_astree(0,0,0,0,"blocklist"), $2);} 
			| statement {$$ = $1;}
		;

statement	: block {$$ = $1;} 
		| vardecl {$$ = $1;}
		| while {$$ = $1;}
		| ifelse {$$ = $1;}
		| return {$$ = $1;}
		| expr ';' {$$ = $1;}
		;

vardecl		: type TOK_IDENT '=' expr ';' {$$ = adopt3(new_astree(0,0,0,0,"vardecl"),
				$1, $2, $4);}
		;
while		: TOK_WHILE '(' expr ')' statement {$$ = adopt2(new_astree(TOK_WHILE,0,0,0,""),
				$3, $5);}
		;

ifelse		: TOK_IF '(' expr ')' statement %prec TOK_ELSE {$$ = 
				adopt3(new_astree(0,0,0,0,"ifelse"),$1, $3, $5);}
		| TOK_IF '(' expr ')' statement TOK_ELSE statement {$$ = adopt5(
				new_astree(0,0,0,0,"ifelse"),$1, $3,$5,$6, $7);}
		;

return		: TOK_RETURN expr ';' {$$ = adopt2(new_astree(TOK_RETURN,0,0,0,""),
				$1, $2);}
		| TOK_RETURN ';' {$$ = adopt1(new_astree(TOK_RETURN, 0,0,0, ""), $1);}
		;

expr		: binop {$$ = $1;}
		| unop {$$ = $1;}
		| allocator {$$ = $1;}
		| call {$$ = $1;}
		| '(' expr ')' {$$ = $2;}
		| variable {$$ = $1;}
		| constant {$$ = $1;}
		;

binop		: expr operator expr {$$ = adopt3(
				new_astree(0,0,0,0,"binop"), $1,$2,$3);}
		;

unop		: '-' expr %prec TOK_NEG {$$ = adopt1(new_astree(0,0,0,0,"unop"),
				$2);}
		| '+' expr %prec TOK_POS {$$ = adopt1(new_astree(0,0,0,0,"unop"),
				$2);}
		| '!' expr {$$ = adopt1(new_astree(0,0,0,0,"unop"),
				$2);} 
		| TOK_ORD expr {$$ = adopt1(new_astree(0,0,0,0,"unop"), $2);}
		| TOK_CHR expr {$$ = adopt1(new_astree(0,0,0,0,"unop"), $2);}
		;

allocator	: TOK_NEW basetype '(' ')' {$$ = adopt1(new_astree(0,0,0,0,"allocator"), 
				$2);}
		| TOK_NEW basetype '(' expr ')' {$$ = adopt2(new_astree(0,0,0,0,"allocator"),
				$2, $4)}
		| TOK_NEW basetype '[' expr ']' {$$ = adopt1(new_astree(0,0,0,0,"allocator"),
				$2);}
		;

call		: TOK_IDENT '(' ')' {$$ = adopt1(new_astree(0,0,0,0,"call"), $1);}
		| TOK_IDENT '(' callist ')' {$$ = adopt2(new_astree(0,0,0,0,"call"),$1, $3);}
		;

callist		: callist ',' expr {$$ = adopt1($1, $3);}
		| expr {$$ = adopt1(new_astree(0,0,0,0,"callist"),$1);}

variable	: TOK_IDENT {$$ = adopt1(new_astree(0,0,0,0,"variable"),$1);}
		| expr '[' expr ']' {$$ = adopt2(new_astree(0,0,0,0,"variable"),$1, $3);}
		| expr '.' TOK_IDENT {$$ = adopt2(new_astree(0,0,0,0,"variable"),
					$1, $3);}
		;

constant	: TOK_INTCON {$$ = new_astree(TOK_INTCON, 0, 0, 0, "");}
		| TOK_CHARCON {$$ = new_astree(TOK_CHARCON, 0, 0, 0, "");}
		| TOK_STRINGCON {$$ = new_astree(TOK_STRINGCON, 0, 0, 0, "");}
		| TOK_FALSE {$$ = new_astree(TOK_FALSE, 0, 0, 0, "");}
		| TOK_TRUE {$$ = new_astree(TOK_TRUE, 0, 0, 0, "");}
		| TOK_NULL {$$ = new_astree(TOK_NULL, 0, 0, 0, "");}
		;

operator	: '+' {$$ = $1;}
		| '-' {$$ = $1;}
		| '=' {$$ = $1;}
		| '*' {$$ = $1;}
		| '/' {$$ = $1;}
		| '%' {$$ = $1;}
		| TOK_LT {$$ = $1;}
		| TOK_LE {$$ = $1;}
		| TOK_GT {$$ = $1;}
		| TOK_GE {$$ = $1;}
		| TOK_NE {$$ = $1;}
		| TOK_EQ {$$ = $1;}
		;
%%

const char *get_yytname (int symbol) {
   return yytname [YYTRANSLATE (symbol)];
}


bool is_defined_token (int symbol) {
   return YYTRANSLATE (symbol) > YYUNDEFTOK;
}
