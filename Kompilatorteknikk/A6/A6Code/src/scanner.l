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

SPACE [\ \t\n]
DIGIT [0-9]
LETTER [A-Za-z_]
COMMENT \/\/[^\n]*\n
ESCAPED \"([^\"\n]|\\\")*\"

%%
{SPACE}+    {}
{COMMENT}   {}
FUNC        { RETURN( FUNC );    }
PRINT       { RETURN( PRINT );   }
RETURN      { RETURN( RETURN );  }
CONTINUE    { RETURN( CONTINUE );}
IF          { RETURN( IF );      }
THEN        { RETURN( THEN );    }
ELSE        { RETURN( ELSE );    }
FI          { RETURN( FI );     }
WHILE       { RETURN( WHILE );       }
FOR         { RETURN( FOR );         }
TO          { RETURN( TO );          }
DO          { RETURN( DO );          }
DONE        { RETURN( DONE );    }
VAR         { RETURN( VAR );     }
:=          { RETURN( ASSIGN );  }
==          { RETURN( EQUAL );   }
"!="        { RETURN( NEQUAL );  }
"<="        { RETURN( LEQUAL );  }
">="        { RETURN( GEQUAL );  }
">"         { RETURN( yytext[0] ); }
"<"         { RETURN( yytext[0] ); }
{DIGIT}+    { RETURN( NUMBER );  }
{ESCAPED}   { RETURN( STRING );  }
{LETTER}({LETTER}|{DIGIT})* { RETURN( IDENTIFIER ); }
.           { RETURN( yytext[0] ); }
%%
