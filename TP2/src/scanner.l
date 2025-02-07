%{

#include <stdio.h>
#include "utils.h"

#define LINEA_INICIAL 1
#define COLUMNA_INICIAL 1

//-------------------------------IDENTIFICADORES------------------------------//

Identifier *identificadores = NULL;
int conteo_identificadores = 0;
int capacidad_identificadores = 0; 

//-------------------------------LITERAL CADENA-------------------------------//

StringLiteral *literales = NULL;
int conteo_literales = 0;
int capacidad_literales = 0;

//-----------------------------PALABRAS RESERVADAS----------------------------//

t_key_word *keyWords = NULL;
int linea = LINEA_INICIAL;
int columna = COLUMNA_INICIAL;
int cantidad_keywords = 0;

//--------------------------OPERADORES Y PUNTUACION---------------------------//

Operator *operadores = NULL;
int conteo_operadores = 0;
int capacidad_operadores = 0;

//--------------------------CONSTANTES (DECIMALES)---------------------------//

Constantes *constantes = NULL;
int conteo_constantes = 0;
int capacidad_constantes = 0;

//---------------------------CONSTANTES (OCTALES)----------------------------//

Octal *constOctal = NULL;
int conteo_octal = 0;
int capacidad_octal = 0;

//----------------- --------CONSTANTES (HEXADECIMAL)-------------------------//

Hexadecimal *constHexa = NULL;
int conteo_hexa = 0;
int capacidad_hexa = 0;

//---------------------------CONSTANTES (REALES)----------------------------//

float* const_real = NULL;
int conteo_const_real = 0;
int capacidad_const_real = 0;

//---------------------------CONSTANTES (CARACTER)--------------------------//

Caracter *caracteres = NULL;
int conteo_caracter = 0;
int capacidad_caracter = 0; 
int contador_orden = 0; 

//----------------------------NO RECONOCIDAS--------------------------------//

No_Reconocidas *no_reconocidas = NULL;
int cantidad_no_rec = 0;

//--------------------------------------------------------------------------//

%}

SUFIJO_ENTERO ([uU]?[lL]{0,2}|[lL]{0,2}[uU]?)?
SUFIJO_REAL ([eE][+-]?[0-9]+)?[fFlL]?
DIGITO_DECIMAL [0-9]
DIGITO_OCTAL [0-7]
DIGITO_HEXA [0-9a-fA-F]
ESCAPE_SIMPLE [abfnrtv\\\'\"\?]
OPERADORES \[|\]|\{|\}|\(|\)|\*|,|:|;|=|\.|#|&|\+|-|~|!|\/|%|<|>|\^|\?|(\.\.\.)|(->)|(\+\+)|(--)|(<<)|(>>)|(<=)|(>=)|(==)|(!=)|(&&)|(\|\|)|(\*=)|(\/=)|(%=)|(\+=)|(-=)|(<<=)|(>>=)|(&=)|(\^=)|(\|=)|(##)


%pointer
%option noyywrap
%x tokenNoReconocido

%%

[1-9]{DIGITO_DECIMAL}*{SUFIJO_ENTERO} { int valor = atoi(yytext); agregar_constante(valor); columna += yyleng;}
0{DIGITO_OCTAL}*{SUFIJO_ENTERO} { int valor_decimal = strtol(yytext, NULL, 8); agregar_octal(yytext, valor_decimal); columna += yyleng;}
0[xX]{DIGITO_HEXA}+{SUFIJO_ENTERO} { int valor_decimal = strtol(yytext, NULL, 16); agregar_hexa(yytext, valor_decimal); columna += yyleng;}


[0-9]+\.[0-9]*{SUFIJO_REAL} { float valor = atof(yytext); agregar_constante_real(valor); columna += yyleng; }
\.[0-9]+{SUFIJO_REAL} { float valor = atof(yytext); agregar_constante_real(valor); columna += yyleng; }
[0-9]+{SUFIJO_REAL} { float valor = atof(yytext); agregar_constante_real(valor); columna += yyleng; }


int|float|double|char|void|short|long|unsigned|signed { agregar_keyword(yytext, TIPO_DATO); columna += yyleng;}
if|else|while|for|do|switch|case|default|break|continue|return|goto { agregar_keyword(yytext, TIPO_CONTROL); columna += yyleng;}
sizeof|typedef|static|extern|auto|register|volatile|const|enum|struct|union { agregar_keyword(yytext, OTROS); columna += yyleng;}


'[^\\\']' { agregar_caracter(yytext); columna += yyleng;}
'\\{ESCAPE_SIMPLE}' { agregar_caracter(yytext); columna += yyleng;}
'\\{DIGITO_OCTAL}{1,3}' { agregar_caracter(yytext); columna += yyleng;}
'\\x{DIGITO_HEXA}+' { agregar_caracter(yytext); columna += yyleng;}


\"([^\\\"\n]|\\{ESCAPE_SIMPLE}|\\{DIGITO_OCTAL}{1,3}|\\x{DIGITO_HEXA}+)*\" { agregar_literal(yytext); columna += yyleng;}   


[_a-zA-Z][_a-zA-Z0-9]* { agregar_identificador(yytext); columna += yyleng;}


{OPERADORES} { agregar_operador(yytext); columna += yyleng;}


[ \t]+ { columna += yyleng; }


\n { linea++; columna = 1;}


[^ \t\n] { yyless(0); columna += yyleng; BEGIN(tokenNoReconocido); }
<tokenNoReconocido>{
    <<EOF>> {
        BEGIN(INITIAL);
    }
    " "|\t|\n {
        yyless(0);
        BEGIN(INITIAL);
    }
    [^ \t\n]+ {
        agregar_no_reconocida(yytext);
        columna += yyleng;
        BEGIN(INITIAL);
    }
}

%%

int main(int argc, char *argv[]) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            printf("Error abriendo el archivo de entrada");
            return EXIT_FAILURE;
        }
    } else {
        yyin = stdin;
    }

    yylex();

    if (yyin != stdin) 
        fclose(yyin);

    imprimir_identificadores();
    liberar_identificadores();

    imprimir_literales();  
    liberar_literales(); 

    imprimir_keywords();
    liberar_keywords();

    imprimir_constante();
    sumatoriaConstantes();
    liberar_constante();

    imprimir_hexa(); 
    liberar_hexa(); 

    imprimir_octal(); 
    liberar_octal(); 

    imprimir_real();
    liberar_real(); 
    
    imprimir_caracter();
    liberar_caracter(); 

    imprimir_operadores();
    liberar_operadores();

    imprimir_no_reconocidas();
    liberar_no_reconocidas();

    return EXIT_SUCCESS;
}