%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "general.h"

extern int yylex(void);

/* Declaracion de variables */
GenericNode* variable = NULL;
t_variable* data_variable = NULL;
t_function* data_function = NULL;
GenericNode* function = NULL;
t_parameter data_parameter;
GenericNode* error_list = NULL;
GenericNode* sentencias = NULL;
t_sent* data_sent = NULL;

%}

%define parse.error verbose
%locations

%union {
    char* string_type;
    int int_type;
    double double_type;
    char char_type;
    void* void_type;
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

%type expresion expAsignacion expCondicional expOr expAnd expIgualdad expRelacional expAditiva expMultiplicativa expUnaria expPostfijo
%type operAsignacion operUnario nombreTipo listaArgumentos expPrimaria
%type sentExpresion sentSalto sentSeleccion sentIteracion sentEtiquetadas sentCompuesta sentencia
%type unidadTraduccion declaracionExterna definicionFuncion declaracion especificadorDeclaracion listaDeclaradores listaDeclaracionOp declarador declaradorDirecto

%start programa

%nonassoc THEN
%nonassoc ELSE 

%nonassoc VACIO
%nonassoc ','
%nonassoc '='
%nonassoc ';'

%%

programa
    : unidadTraduccion
    ;

unidadTraduccion
    : declaracionExterna {reset_token_buffer();}
    | unidadTraduccion declaracionExterna{reset_token_buffer();}
    ;

sentencia
    : sentCompuesta {reset_token_buffer();} 
    | sentExpresion {reset_token_buffer();} 
    | sentSeleccion {reset_token_buffer();} 
    | sentIteracion {reset_token_buffer();} 
    | sentEtiquetadas {reset_token_buffer();}  
    | sentSalto {reset_token_buffer();} 
    ;

sentCompuesta
    : '{' listaDeclaracionOp listaSentencias '}' 
    ;

listaDeclaraciones
    : declaracion listaDeclaracionOp
    | error
    ;

listaDeclaracionOp
    : listaDeclaraciones
    | %empty
    ;

listaSentencias
    : sentencia
    | %empty
    ;   

sentExpresion
    : ';'
    | expresion opcionExpresion
    ; 

opcionExpresion
    : ';'
    | error {yerror(@0); yyerrok;}
    ;

sentSeleccion
    : IF '(' expresion ')' sentencia %prec THEN {add_sent("if", @1.first_line, @1.first_column);}
    | IF '(' expresion ')' sentencia ELSE sentencia {add_sent("if/else", @1.first_line, @1.first_column);}
    | SWITCH '(' expresion ')' {reset_token_buffer(); } sentencia {add_sent($<string_type>1, @1.first_line, @1.first_column); }
    ;

sentIteracion
    : WHILE '(' expresion ')' sentencia {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    | DO sentencia WHILE '(' expresion ')' ';' {add_sent("do/while", @1.first_line, @1.first_column);} 
    | FOR '(' expresionOp ';' expresionOp ';' expresionOp ')' sentencia {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    ;

expresionOp
    : expresion
    | %empty
    ;

sentEtiquetadas
    : IDENTIFICADOR ':' sentencia 
    | CASE expresion ':' sentencia {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    | CASE expresion ':' error sentencia {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    | DEFAULT ':' sentencia {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    ;

sentSalto
    : RETURN sentExpresion {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    | CONTINUE ';' {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    | BREAK ';' {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    | GOTO IDENTIFICADOR ';'{add_sent($<string_type>1, @1.first_line, @1.first_column);}
    ;

expresion
    : expAsignacion %prec VACIO
    | expAsignacion ',' expresion
    ;
    
expAsignacion
    : expCondicional
    | expUnaria operAsignacion expAsignacion 
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
    | expOr '?' expresion ':' expCondicional
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
    : '<' expAditiva
    | '>' expAditiva
    | LE expAditiva
    | GE expAditiva
    ;

expAditiva
    : expMultiplicativa
    | expAditiva opcionAditiva
    ;

opcionAditiva
    : '+' expMultiplicativa
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
    | opcionIncDec expPostfijo 
    | expPostfijo opcionIncDec
    | operUnario expUnaria
    | SIZEOF '(' nombreTipo ')' 
    ;  

opcionIncDec
    : INC_OP 
    | DEC_OP
    ;

operUnario
    : '&' 
    | '*' 
    | '-' 
    | '!' 
    ;

expPostfijo
    : expPrimariaAdaptada 
    | expPostfijo opcionPostfijo
    ;
    
expPrimariaAdaptada
    : IDENTIFICADOR 
    | ENTERO        
    | NUM        
    | CONSTANTE 
    | LITERAL_CADENA 
    | PALABRA_RESERVADA
    ;

listaArgumentosOp
    : listaArgumentos ')'
    | ')'
    | expresion ')'
    ;

opcionPostfijo
    : '[' expresion ']'
    | '(' listaArgumentosOp 
    ;

listaArgumentos
    : expAsignacion masListaArgumentos
    ;

masListaArgumentos
    : masListaArgumentos ',' expAsignacion
    ;

expPrimaria
    : IDENTIFICADOR 
    | ENTERO        
    | NUM        
    | CONSTANTE 
    | LITERAL_CADENA 
    | '(' expresion ')'
    | PALABRA_RESERVADA
    ;

nombreTipo
    : TIPO_DATO 
    ;

declaracionExterna
    : definicionFuncion    
    | declaracion
    ; 

definicionFuncion
    : especificadorDeclaracion decla listaDeclaracionOp sentCompuesta {
        data_function->return_type = strdup($<string_type>1);
        data_function->name = strdup($<string_type>2); 
        data_function->type = "definicion"; 
        insert_node((GenericNode**)&function, data_function, sizeof(t_function));
        data_function->parameters = NULL;
    }
    ;

declaracion
    : especificadorDeclaracion listaDeclaradores ';'
    | especificadorDeclaracion decla ';' {
        data_function->return_type = strdup($<string_type>1);
        data_function->name = strdup($<string_type>2);
        data_function->type = "declaracion"; 
        insert_node((GenericNode**)&function, data_function, sizeof(t_function));
        data_function->parameters = NULL;
    }
    | especificadorDeclaracion error {yerror(@2);}
    ;

especificadorDeclaracionOp
    : especificadorDeclaracion
    | %empty
    ;
    
especificadorDeclaracion 
    : TIPO_ALMACENAMIENTO especificadorDeclaracionOp
    | especificadorTipo especificadorDeclaracionOp
    | TIPO_CALIFICADOR especificadorDeclaracionOp 
    ;

listaDeclaradores
    : declarador { 
            insert_node((GenericNode**)&variable, data_variable, sizeof(t_variable));
    }
    ;
    | listaDeclaradores ',' declarador {
            insert_node((GenericNode**)&variable, data_variable, sizeof(t_variable));
    }
    ;

declarador
    : decla opcionPostDeclarador
    ;

opcionPostDeclarador
    : %prec VACIO %empty
    | '=' inicializador
    ;

opcionComa
    : ','
    | %empty
    ;

listaInicializadores
    : inicializador
    | listaInicializadores ',' inicializador
    ;

inicializador
    : expAsignacion 
    | '{' listaInicializadores opcionComa '}' 
    ;

especificadorTipo
    : TIPO_DATO { data_variable->type = strdup($<string_type>1); }
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
    : '{' listaDeclaracionesStruct '}'
    | %empty
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
    : listaCalificadores
    | %empty
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
    : ':' expresion
    | %empty
    ;

decla
    : puntero declaradorDirecto { $<string_type>$ = strdup($<string_type>2);}
    | declaradorDirecto { $<string_type>$ = strdup($<string_type>1);}
    ;

punteroOp
    : puntero
    | %empty
    ;

puntero
    : '*' listaCalificadoresTipoOp punteroOp
    ;

listaCalificadoresTipoOp
    : listaCalificadoresTipo
    | %empty
    ;
    
listaCalificadoresTipo
    : TIPO_CALIFICADOR
    | listaCalificadoresTipo TIPO_CALIFICADOR
    ;

declaradorDirecto
    : IDENTIFICADOR {
        $<string_type>$ = strdup($<string_type>1);
        data_variable->variable = strdup($<string_type>1);
        data_variable->line = yylloc.first_line;
    }
    | '(' decla ')'
    | declaradorDirecto continuacionDeclaradorDirecto { data_function->line = yylloc.first_line;}
    ;

continuacionDeclaradorDirecto
    : '[' expConstanteOp ']'
    | '(' opcional 
    ;

opcional
    : ')' 
    | listaTiposParametros  ')' 
    | listaIdentificadores ')' 
    | TIPO_DATO ')' { 
        data_parameter.type = strdup($<string_type>1);
        data_parameter.name = NULL;
        insert_node((GenericNode**)&(data_function->parameters), &data_parameter, sizeof(t_parameter));
        }
    ;

listaTiposParametrosOp 
    : listaTiposParametros 
    | %empty 
    ;
    
listaTiposParametros
    : listaParametros opcionalListaParametros
    ;
    
opcionalListaParametros
    : ',' ELIPSIS
    | %empty
    ;

listaParametros
    : declaracionParametro  {
        insert_node((GenericNode**)&(data_function->parameters), &data_parameter, sizeof(t_parameter));
    }
    | listaParametros ',' declaracionParametro {
        insert_node((GenericNode**)&(data_function->parameters), &data_parameter, sizeof(t_parameter));
    }
    ;

declaracionParametro
    : especificadorDeclaracion decla { 
        data_parameter.name = strdup($<string_type>2); 
        data_parameter.type = strdup($<string_type>1);
        }
    ;


listaIdentificadoresOp
    : listaIdentificadores
    | %empty
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
    : '{' listaEnumeradores '}'
    | %empty
    ;

listaEnumeradores
    : enumerador
    | listaEnumeradores ',' enumerador
    ;
  
enumerador
    : IDENTIFICADOR opcionalEnumerador
    ;

opcionalEnumerador
    : '=' expresion
    | %empty
    ;
    
%%


int main(int argc, char *argv[]) {
    if (argc > 1) {
        FILE *file = fopen(argv[1], "r");
        if (!file) {
            printf("Error abriendo el archivo de entrada");
            return 1;
        }
        yyin = file;
    }
    
    init_structures();
    
    yyparse();

    print_lists();

    if (yyin && yyin != stdin) {
        fclose(yyin);
    }
    
    free_all_lists(); 

    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error de sintaxis: %s\n", s);
}
