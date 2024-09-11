%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "general.h"

extern int yylex(void);
void yyerror(const char*);

//-------- Declaracion de variables --------//
GenericNode* variable = NULL;
t_variable* data_variable = NULL;
t_function* data_function;
GenericNode* function;

int in_function_params = 0;

%}

%define parse.error verbose
%locations

%union {
    char* string_type;
    int int_type;
    double double_type;
    char char_type;
    unsigned long unsigned_long_type;
}

%token <string_type> IDENTIFICADOR
%token <string_type> LITERAL_CADENA
%token <string_type> PALABRA_RESERVADA
%token CONSTANTE
%token <string_type> TIPO_DATO
%token <string_type> TIPO_ALMACENAMIENTO TIPO_CALIFICADOR ENUM STRUCT UNION
%token <string_type> RETURN IF ELSE WHILE DO FOR DEFAULT CASE  
%token <string_type> CONTINUE BREAK GOTO SWITCH SIZEOF
%token <int_type> ENTERO
%token <double_type> NUM

%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN
%token EQ NEQ LE GE AND OR
%token LEFT_SHIFT RIGHT_SHIFT
%token PTR_OP INC_OP DEC_OP
%token ELIPSIS

%type <int_type> expresion expAsignacion expCondicional expOr expAnd expIgualdad expRelacional expAditiva expMultiplicativa expUnaria expPostfijo
%type <int_type> operAsignacion operUnario nombreTipo listaArgumentos expPrimaria
%type <int_type> sentExpresion sentSalto sentSeleccion sentIteracion sentEtiquetadas sentCompuesta sentencia
%type <string_type> unidadTraduccion declaracionExterna definicionFuncion declaracion especificadorDeclaracion listaDeclaradores listaDeclaracionOp declarador declaradorDirecto

%start programa

%%

programa
    : input { printf("Programa reconocido\n"); }
    ;

input
    : %empty
    | input expresion
    | input sentencia /* Permitir que el archivo termine con una sentencia */
    | input unidadTraduccion
    /* | input error '\n' { printf("EL ERROR ESTA ACA \n"); yyerrok; } */
    ;

sentencia
    : sentCompuesta 
    | sentExpresion 
    | sentSeleccion 
    | sentIteracion 
    | sentEtiquetadas 
    | sentSalto
    | '\n'
    ;

sentCompuesta
    : '{' opcionDeclaracion '}' 
    ;

opcionDeclaracion
    : %empty
    | listaDeclaraciones
    ;

opcionSentencia
    : %empty
    | listaSentencias
    ;

listaDeclaraciones
    : listaDeclaraciones declaracionExterna
    | declaracionExterna 
    ;

listaSentencias
    : listaSentencias sentencia
    | sentencia
    ;

sentExpresion
    : ';' 
    | expresion ';' 
    ;

sentSeleccion
    : IF '(' expresion ')' sentencia opcionElse
    | SWITCH //{

    //     t_statement* stament = malloc(sizeof(t_statement));
    //     stament->location = malloc(sizeof(location));
    //     stament->location->line = @1.first_line;  
    //     stament->location->column = @1.first_column;  
    //     stament->type = "switch";

    //     add_node(&statements_list, stament, sizeof(t_statement));}
    | '(' expresion ')' sentencia 
    ;

opcionElse
    : %empty
    | ELSE sentencia
    ;

sentIteracion
    : WHILE '(' expresion ')' sentencia

    //     t_statement* stament = malloc(sizeof(t_statement));
    //     stament->location = malloc(sizeof(location));
    //     stament->location->line = @1.first_line;  
    //     stament->location->column = @1.first_column;  
    //     stament->type = "while";

    //     add_node(&statements_list, stament, sizeof(t_statement));
    // } 
    | DO sentencia WHILE '(' expresion ')' ';'

    //     t_statement* stament = malloc(sizeof(t_statement));
    //     stament->location = malloc(sizeof(location));
    //     stament->location->line = @1.first_line;  
    //     stament->location->column = @1.first_column;  
    //     stament->type = "do/while";

    //     add_node(&statements_list, stament, sizeof(t_statement));
    // } 
    | FOR '('opcionExp')' sentencia

        // t_statement* stament = malloc(sizeof(t_statement));
        // stament->location = malloc(sizeof(location));
        // stament->GOlocation->line = @1.first_line;  
        // stament->location->column = @1.first_column;  
        // stament->type = "for";

        // add_node(&statements_list, stament, sizeof(t_statement));

    ;

sentEtiquetadas
    : IDENTIFICADOR ':' sentencia 
    | CASE  expresion ':' listaSentencias

    //     t_statement* stament = malloc(sizeof(t_statement));
    //     stament->location = malloc(sizeof(location));
    //     stament->location->line = @1.first_line;  
    //     stament->location->column = @1.first_column;  
    //     stament->type = "case";

    //     add_node(&statements_list, stament, sizeof(t_statement));
    // } 
    | DEFAULT ':' listaSentencias 

    //     t_statement* stament = malloc(sizeof(t_statement));
    //     stament->location = malloc(sizeof(location));
    //     stament->location->line = @1.first_line;  
    //     stament->location->column = @1.first_column;  
    //     stament->type = "default";

    //     add_node(&statements_list, stament, sizeof(t_statement));
    // }
    ;

sentSalto
    : RETURN ';' 

    //     t_statement* stament = malloc(sizeof(t_statement));
    //     stament->location = malloc(sizeof(location));
    //     stament->location->line = @1.first_line;  
    //     stament->location->column = @1.first_column;  
    //     stament->type = "return";

    //     add_node(&statements_list, stament, sizeof(t_statement));
    // }
    | RETURN expresion ';' 

    //     t_statement* stament = malloc(sizeof(t_statement));
    //     stament->location = malloc(sizeof(location));
    //     stament->location->line = @1.first_line;  
    //     stament->location->column = @1.first_column;  
    //     stament->type = "return";

    //     add_node(&statements_list, stament, sizeof(t_statement));
    // } 
    ;

expresion
    : expAsignacion 
    | expresion ',' expAsignacion
    ;

opcionExp
    : %empty
    | expresion ';' 
    | expresion ';' expresion
    | expresion ';' expresion ';' expresion
    ;

expAsignacion
    : expCondicional 
    | expUnaria operAsignacion expAsignacion {add_node(&variable, data_variable, sizeof(t_variable));}
    ;

operAsignacion
    : '=' 
    | ADD_ASSIGN 
    | SUB_ASSIGN 
    | MUL_ASSIGN 
    | DIV_ASSIGN 
    ;

expCondicional
    : expOr 
    | expOr '?' expresion : expCondicional
    ; 

expOr
    : expAnd
    | expOr OR expAnd
    ;

expAnd
    : expIgualdad 
    | expAnd AND expIgualdad 
    ;

expIgualdad
    : expRelacional 
    | expIgualdad opcionIgualdad
    ;

opcionIgualdad
    : EQ expRelacional
    | NEQ expRelacional 
    ;

expRelacional
    : expAditiva
    | expRelacional opcionRelacional
    ;
    
opcionRelacional
    : %empty
    | '<' expAditiva
    | '>' expAditiva
    | LE expAditiva
    | GE expAditiva
    ;

expAditiva
    : expMultiplicativa
    | expAditiva opcionAditiva
    ;

opcionAditiva
    : %empty
    | '+' expMultiplicativa
    | '-' expMultiplicativa
    ;
    
expMultiplicativa
    : expUnaria
    | expMultiplicativa opcionMultiplicativa
    ;
opcionMultiplicativa
    : '*' expUnaria
    | '/' expUnaria
    | '%' expUnaria
    ;

expUnaria
    : expPostfijo
    | INC_OP expUnaria 
    | DEC_OP expUnaria 
    | expUnaria INC_OP
    | expUnaria DEC_OP
    | operUnario expUnaria 
    | SIZEOF '(' nombreTipo ')' 
    ;

operUnario
    : '&' 
    | '*' 
    | '-' 
    | '!' 
    ;

expPostfijo
    : expPrimaria
    | expPostfijo expPrimaria
    | expPostfijo opcionPostfijo
    ;
    
opcionPostfijo
    : '[' expresion ']'
    | '(' listaArgumentosOp ')' 
    ;

listaArgumentosOp
    : %empty
    | listaArgumentos 
    ;

listaArgumentos
    : expAsignacion
    | listaArgumentos ',' expAsignacion
    ;

expPrimaria
    : IDENTIFICADOR
    | ENTERO
    | NUM
    | CONSTANTE
    | LITERAL_CADENA 
    | '(' expresion ')'
    ;

nombreTipo
    : TIPO_DATO 
    ;

unidadTraduccion
    : declaracionExterna 
    | unidadTraduccion declaracionExterna
    ;

declaracionExterna
    : definicionFuncion    
    | declaracion           
    ;

definicionFuncion
    : especificadorDeclaracion decla especificadorDeclaracionOp sentCompuesta {printf("No entra por aqui\n"); }
    ;

declaracion
    : especificadorDeclaracion listaDeclaradores ';' { printf("Entra por aqui\n");}
    ;
    
especificadorDeclaracionOp
    : %empty
    | especificadorDeclaracion
    ;
    
especificadorDeclaracion 
    : TIPO_ALMACENAMIENTO especificadorDeclaracionOp
    | especificadorTipo especificadorDeclaracionOp
    | TIPO_CALIFICADOR especificadorDeclaracionOp 
    ;

listaDeclaradores
    : declarador { 
        if (in_function_params) {
            add_node(&variable, data_variable, sizeof(t_variable));
        }
    }
    | listaDeclaradores ',' declarador { 
        if (in_function_params) {
            add_node(&variable, data_variable, sizeof(t_variable));
        }
    }
    ;

listaDeclaracionOp
    : %empty
    | listaDeclaradores
    ;
    
declarador
    : decla
    | decla '=' inicializador
    ;

inicializador
    : expresion
    | '{' listaInicializadores opcionComa '}' 
    ;

opcionComa
    : %empty
    | ','
    ;

listaInicializadores
    : inicializador
    | listaInicializadores ',' inicializador
    ;

especificadorTipo
    : TIPO_DATO { data_variable -> type = strdup($<string_type>1);}
    | especificadorStructUnion
    | especificadorEnum
    ;

especificadorStructUnion
    : STRUCT cuerpoEspecificador
    ;

cuerpoEspecificador
    : '{' listaDeclaracionesStruct '}'
    | IDENTIFICADOR cuerpoStructOp
    ;

cuerpoStructOp
    : %empty
    | '{' listaDeclaracionesStruct '}'
    ;

listaDeclaracionesStruct
    : declaracionStruct
    | listaDeclaracionesStruct declaracionStruct
    ;

declaracionStruct
    : listaCalificadores declaradoresStruct ';'
    ;

listaCalificadores
    : especificadorTipo listaCalificadoresOp
    | TIPO_CALIFICADOR listaCalificadoresOp
    ;

listaCalificadoresOp
    : %empty
    | listaCalificadores
    ;

declaradoresStruct
    : declaStruct
    | declaradoresStruct ',' declaStruct
    ;

declaStruct     
    : declaSi
    | ':' expresion
    ;

declaSi
    : decla expConstanteOp
    ;

expConstanteOp
    : %empty
    | ':' expresion
    ;

decla
    : punteroOp declaradorDirecto
    ;

punteroOp
    : %empty
    | puntero
    ;

puntero
    : '*' listaCalificadoresTipoOp punteroOp
    ;

listaCalificadoresTipoOp
    : %empty
    | listaCalificadoresTipo
    ;
    
listaCalificadoresTipo
    : TIPO_CALIFICADOR
    | listaCalificadoresTipo TIPO_CALIFICADOR
    ;

declaradorDirecto
    : IDENTIFICADOR {
        if (!in_function_params) {
            data_variable->variable = strdup($<string_type>1);
            data_variable->line = yylloc.first_line;  // Guardar la línea donde fue declarada
        }
    }
    | '(' decla ')' 
    | declaradorDirecto continuacionDeclaradorDirecto
    ;


continuacionDeclaradorDirecto
    : '[' expConstanteOp ']' 
    | '(' { in_function_params = 1; } listaTiposParametrosOp ')' { in_function_params = 0; }
    | '(' listaIdentificadoresOp ')'
    | '(' TIPO_DATO ')'
    ;

listaTiposParametrosOp 
    : %empty
    | listaTiposParametros
    ;
    
listaTiposParametros
    : listaParametros opcionalListaParametros
    ;
    
opcionalListaParametros
    : %empty
    | ',' ELIPSIS
    ;

listaParametros
    : declaracionParametro
    | listaParametros ',' declaracionParametro
    ;
    
declaracionParametro
    : especificadorDeclaracion opcionesDecla 
    ;

opcionesDecla
    : decla
    | declaradorAbstracto
    ;

listaIdentificadoresOp
    : %empty
    | listaIdentificadores
    ;

listaIdentificadores
    : IDENTIFICADOR
    | listaIdentificadores ',' IDENTIFICADOR 
    ;

especificadorEnum
    : ENUM opcionalEspecificadorEnum
    ;

opcionalEspecificadorEnum
    : IDENTIFICADOR opcionalListaEnumeradores
    | '{' listaEnumeradores '}'
    ;

opcionalListaEnumeradores
    : %empty
    | '{' listaEnumeradores '}'
    ;

listaEnumeradores
    : enumerador
    | listaEnumeradores ',' enumerador
    ;

enumerador
    : IDENTIFICADOR opcionalEnumerador
    ;

opcionalEnumerador
    : %empty
    | '=' expresion
    ;

declaradorAbstracto
    : puntero declaradorAbstractoDirectoOp
    | declaradorAbstractoDirecto
    ;

declaradorAbstractoDirectoOp
    : %empty
    | declaradorAbstractoDirecto
    ;

declaradorAbstractoDirecto
    : '(' declaradorAbstracto ')'
    | declaradorAbstractoDirectoOp postOpcionDeclaradorAbstracto
    ;

postOpcionDeclaradorAbstracto
    : '[' expresion ']'
    | '(' listaTiposParametrosOp ')'
    ;

listaDeclaracionSentencia
    : %empty
    | listaDeclaracionSentencia declaracion
    | listaDeclaracionSentencia sentencia
    ;

%%

int main(int argc, char *argv[]) {
    if (argc > 1) {
        FILE *file = fopen(argv[1], "r");
        if (!file) {
            perror("Error abriendo el archivo de entrada");
            return 1;
        }
        yyin = file;
    }

    init_structures();

    yyparse();

    // print_statements_list();
    print_lists();

    if (yyin && yyin != stdin) {
        fclose(yyin);
    }

    //free_lists();

    return 0;
}