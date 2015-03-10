%{
#include "parser.h"
#ifdef DUMP_TOKENS
    #define RETURN(t) do {                                      \
        fprintf ( stderr, "TOKEN ( %d,\t'%s' )\n", t, yytext );    \
        return t;                                               \
    } while ( 0 )
#else
    #define RETURN(t) return t
#endif
%}

%option array
%option noyywrap
%option yylineno

DIGIT [0-9]
LETTER [A-Za-z_]
ID {LETTER}({LETTER}|{DIGIT})*
STRING \"([^\"\n]|\\\")*\"
WHITESPACE [ \t\n]
COMMENTS \/\/[^\n]*\n


%%
"FUNC"			{ RETURN (FUNC); }
"PRINT"			{ RETURN (PRINT); }
"RETURN"		{ RETURN (RETURN); }
"CONTINUE"		{ RETURN (CONTINUE); }
"IF"			{ RETURN (IF); }
"THEN"			{ RETURN (THEN); }
"ELSE"			{ RETURN (ELSE); }
"FI"			{ RETURN (FI); }
"WHILE"			{ RETURN (WHILE); }
"DO"			{ RETURN (DO); }
"DONE"			{ RETURN (DONE); }
"FOR"			{ RETURN (FOR); }
"TO" 			{ RETURN (TO); }
"VAR"			{ RETURN (VAR); }
{DIGIT}+		{ RETURN(NUMBER); }
{STRING} 		{ RETURN(STRING); }
{ID}			{ RETURN(IDENTIFIER); }
":="			{ RETURN (ASSIGN); }
">="			{ RETURN (GEQUAL); }
"<="			{ RETURN (LEQUAL); }
"=="			{ RETURN (EQUAL); }
"!="			{ RETURN (NEQUAL); }
{WHITESPACE}		{ }
{COMMENTS}		{ }
.    			{ RETURN( yytext[0] ); }

%%
