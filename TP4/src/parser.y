%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "general.h"

extern int yylex(void);
void yyerror(const char *s);

/* Declaracion de variables */
GenericNode* variable = NULL;
GenericNode* function = NULL;
GenericNode* error_list = NULL;
GenericNode* sentencias = NULL;
GenericNode* semantic_errors = NULL;
GenericNode* symbol_table = NULL;

//int* invocated_arguments = NULL;
t_variable* data_variable = NULL;

t_variable* data_variable_aux = NULL;
t_variable* data_variable_aux_2 = NULL;

t_function* data_function = NULL;
t_parameter data_parameter;
t_sent* data_sent = NULL;
t_semantic_error* data_sem_error = NULL; 
t_symbol_table* data_symbol = NULL;

int declaration_flag = 0; // Si está en declaracion
int parameter_flag = 0; // Si está dentro de los parametros de X funcion
int quantity_parameters = 0; // Cantidad de parametros
int assign_void_flag = 0; // Si se asigna una variable a una funcion void

int sem_multi = 0;
char* tipo_auxiliar = "";

%}

%error-verbose
%locations

%union {
    char* string_type;
    int int_type;
    double double_type;
    char char_type;
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
%token PTR_OP INC_OP DEC_OP
%token ELIPSIS

/* TO DO: agregamos los tipos para que corra */
%type <void*> expAsignacion expCondicional expOr expAnd expIgualdad expRelacional expAditiva expUnaria expMultiplicativa expPostfijo
%type <void*> operAsignacion operUnario nombreTipo listaArgumentos expPrimaria
%type <void*> sentExpresion sentSalto sentSeleccion sentIteracion sentEtiquetadas sentCompuesta sentencia
%type <void*> unidadTraduccion declaracionExterna definicionFuncion declaracion especificadorDeclaracion listaDeclaradores listaDeclaracionOp declarador declaradorDirecto


%start programa

%%

programa
    : input
    ;

input
    : 
    | input expresion {reset_token_buffer();}
    | input sentencia {reset_token_buffer();}
    | input unidadTraduccion {reset_token_buffer();}
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
    : '{' {parameter_flag = 0;} opcionDeclaracion opcionSentencia '}' 
    ;

opcionDeclaracion
    : 
    | listaDeclaraciones
    ;

opcionSentencia
    : 
    | listaSentencias
    ;

listaDeclaraciones
    : listaDeclaraciones declaracion
    | declaracion 
    | error
    ;

listaSentencias
    : listaSentencias sentencia 
    | sentencia
    | error
    ;

sentExpresion
    : ';'
    | expresion ';' 
    | expresion error { yerror(@1);}
    ;

sentSeleccion
    : IF '(' expresion ')' sentencia {add_sent($<string_type>1, @1.first_line, @1.first_column);} 
    | IF '(' expresion ')' sentencia ELSE sentencia  {add_sent("if/else", @1.first_line, @1.first_column);} 
    | SWITCH '(' expresion ')' {reset_token_buffer(); } sentencia {add_sent($<string_type>1, @1.first_line, @1.first_column); }
    ;


sentIteracion
    : WHILE '(' expresion ')' sentencia {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    | DO sentencia WHILE '(' expresion ')' ';' {add_sent("do/while", @1.first_line, @1.first_column);} 
    | FOR '(' expresionOp ';' expresionOp ';' expresionOp ')' sentencia {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    ;

expresionOp
    : 
    | expresion
    ;

sentEtiquetadas
    : IDENTIFICADOR ':' sentencia 
    | CASE expresion ':' listaSentencias {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    | DEFAULT ':' listaSentencias {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    ;

sentSalto
    : RETURN sentExpresion {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    | CONTINUE ';' {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    | BREAK ';' {add_sent($<string_type>1, @1.first_line, @1.first_column);}
    | GOTO IDENTIFICADOR ';'{add_sent($<string_type>1, @1.first_line, @1.first_column);}
    ;

expresion 
    : expAsignacion
    | expresion ',' expAsignacion
    ;

expAsignacion
    : expCondicional
    | expUnaria operAsignacion expAsignacion {
        if(assign_void_flag) {
            _asprintf(&data_sem_error->msg, "%i:%i: No se ignora el valor de retorno void como deberia ser", @1.first_line, @1.first_column);
            insert_node(&semantic_errors, data_sem_error, sizeof(t_semantic_error));
            assign_void_flag = 0;
        }
    }
    | expUnaria operAsignacion error 
    ;

operAsignacion
    : '='
    | ADD_ASSIGN 
    | SUB_ASSIGN 
    | MUL_ASSIGN 
    | DIV_ASSIGN
    | MOD_ASSIGN
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
    | expMultiplicativa '*' {sem_multi = 1;} expUnaria /* { 
        if(data_variable_aux = getId($1)) {
            printf("El tipo del primer operando () es: %s \n", data_variable_aux->type);F
            printf("El tipo del segundo operando () es: %s \n", tipo_auxiliar);
        } else { 
            printf("No esta \n"); 
        }
    } */
    | expMultiplicativa '/' expUnaria
    | expMultiplicativa '%' expUnaria 
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
    | IDENTIFICADOR opcionPostfijo {
        insert_sem_error_invocate_function(@1.first_line, @1.first_column, $<string_type>1, quantity_parameters);

        // t_symbol_table* existing_symbol = (t_symbol_table*)get_element(FUNCTION, $<string_type>1, compare_char_and_ID_function);
        // if(existing_symbol)
        //     compare_arguments(existing_symbol);
        
        if(fetch_element(FUNCTION, $<string_type>1, compare_void_function)) {
            assign_void_flag = 1;
        }
        quantity_parameters = 0;
    }
    ;

opcionPostfijo
    : '[' expresion ']'
    | '(' {parameter_flag = 1;} listaArgumentosOp ')' {parameter_flag = 0;}
    ;

listaArgumentosOp
    : 
    | listaArgumentos 
    ;

listaArgumentos
    : expAsignacion { quantity_parameters ++;}
    | listaArgumentos ',' expAsignacion { quantity_parameters ++;}
    ;

expPrimaria
    : IDENTIFICADOR {
        if(!declaration_flag) {
            if(!fetch_element(VARIABLE, $<string_type>1, compare_ID_parameter) && !fetch_parameter($<string_type>1) && !fetch_element(FUNCTION, $<string_type>1, compare_char_and_ID_function)) {
               _asprintf(&data_sem_error -> msg, "%i:%i: '%s' sin declarar", @1.first_line, @1.first_column, $<string_type>1);
               insert_node(&semantic_errors, data_sem_error, sizeof(semantic_errors));
            }
            
        }
        declaration_flag = 0;

    }
    | ENTERO            { 
        // if(parameter_flag) {  
        //     add_parameter(NUMBER);
        // }
    } 
    | NUM               { 
        // if(parameter_flag){
        //     add_parameter(NUMBER);
        // }
       
    }
    | CONSTANTE         {
        // if(parameter_flag) {
        //     add_parameter(NUMBER);
        // }
    }
    | LITERAL_CADENA    { 
        // if(parameter_flag) {
        //     add_parameter(STRING);
        // }
        printf("El valor del sem es %d \n", sem_multi);
        if(sem_multi == 1){
            tipo_auxiliar = "char*";
            sem_multi = 0;
        }
        
    }
    | '(' expresion ')' 
    | PALABRA_RESERVADA
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
    : especificadorDeclaracion decla listaDeclaracionOp sentCompuesta { // ToDo: Reducir codigo && Tratar de arreglar el +1 del @1.first_column
        save_function("definicion", $<string_type>1, $<string_type>2);
        if(!fetch_element(FUNCTION, data_function, compare_ID_in_declaration_or_definition) && !fetch_element(FUNCTION, data_function, compare_ID_and_different_type_functions)) {
            insert_node(&function, data_function, sizeof(t_function));
            data_symbol -> line = @2.first_line;
            data_symbol -> column = @2.first_column + 1;
            insert_symbol(FUNCTION);
            data_function->parameters = NULL;
        }
        else {
            insert_sem_error_different_symbol(@2.first_column + 1);
            data_function->parameters = NULL;
        }              
    }
    ;

declaracion
    : especificadorDeclaracion listaDeclaradores ';'
    | especificadorDeclaracion decla ';' { // ToDo: Reducir codigo && Tratar de arreglar el +1 del @1.first_column
        if (parameter_flag) {
            save_function("declaracion", $<string_type>1, $<string_type>2);
            if(!fetch_element(FUNCTION, data_function, compare_ID_in_declaration_or_definition) && !fetch_element(FUNCTION, data_function, compare_ID_and_different_type_functions)) {
                insert_node(&function, data_function, sizeof(t_function));
                data_symbol -> line = @2.first_line;
                data_symbol -> column = @2.first_column + 1;
                insert_symbol(FUNCTION);
                data_function->parameters = NULL;
            } else {
                insert_sem_error_different_symbol(@2.first_column + 1);
            }
        } else {
            insert_node(&variable, data_variable, sizeof(t_variable));
            insert_symbol(VARIABLE);
        }
    }
    ;

especificadorDeclaracion 
    : TIPO_ALMACENAMIENTO especificadorDeclaracionOp
    | especificadorTipo especificadorDeclaracionOp 
    | TIPO_CALIFICADOR especificadorDeclaracionOp 
    ;
    
especificadorDeclaracionOp
    : 
    | especificadorDeclaracion
    ;

listaDeclaradores
    : declarador { 
        int redeclaration_line = data_variable->line;
        int redeclaration_column = data_variable->column;
        handle_redeclaration(redeclaration_line, redeclaration_column, data_variable->variable);
        insert_if_not_exists();
    }
    | listaDeclaradores ',' declarador {
        int redeclaration_line = data_variable->line;
        int redeclaration_column = data_variable->column;
        handle_redeclaration(redeclaration_line, redeclaration_column, data_variable->variable);
        insert_if_not_exists();
    }
    ;

listaDeclaracionOp
    : 
    | listaDeclaraciones
    ;
    
declarador
    : decla
    | decla '=' inicializador
    ;

opcionComa
    : 
    | ','
    ;

listaInicializadores
    : inicializador
    | listaInicializadores ',' inicializador
    ;

inicializador
    : expAsignacion {declaration_flag = 1;}
    | '{' listaInicializadores opcionComa '}' 
    ;

especificadorTipo
    : TIPO_DATO { data_variable->type = strdup($<string_type>1);}
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
    : 
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
    : 
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
    : 
    | ':' expresion
    ;

decla
    : punteroOp declaradorDirecto { $<string_type>$ = strdup($<string_type>2);}
    ;

punteroOp
    : 
    | puntero
    ;

puntero
    : '*' listaCalificadoresTipoOp punteroOp
    ;

listaCalificadoresTipoOp
    : 
    | listaCalificadoresTipo
    ;
    
listaCalificadoresTipo
    : TIPO_CALIFICADOR
    | listaCalificadoresTipo TIPO_CALIFICADOR
    ;

declaradorDirecto
    : IDENTIFICADOR {
        $<string_type>$ = strdup($<string_type>1);
        data_variable->variable = strdup($<string_type>1);
        data_variable->line = data_symbol->line = yylloc.first_line;
        data_variable->column =  data_symbol->column = yylloc.first_column;
    }
    | '(' decla ')'
    | declaradorDirecto continuacionDeclaradorDirecto { data_function->line = yylloc.first_line; parameter_flag = 1;}
    ;

continuacionDeclaradorDirecto
    : '[' expConstanteOp ']'
    | '(' listaTiposParametrosOp ')'
    | '(' listaIdentificadoresOp ')'
    | '(' TIPO_DATO ')' {  
            data_parameter.type = strdup($<string_type>2);
            data_parameter.name = NULL;
            insert_node(&data_function->parameters, &data_parameter, sizeof(t_parameter));
        }
    ;

listaTiposParametrosOp 
    : 
    | listaTiposParametros 
    ;
    
listaTiposParametros
    : listaParametros opcionalListaParametros
    ;
    
opcionalListaParametros
    : 
    | ',' ELIPSIS
    ;

listaParametros
    : declaracionParametro  {
        insert_node(&(data_function->parameters), &data_parameter, sizeof(t_parameter));
    }
    | listaParametros ',' declaracionParametro {
        insert_node(&(data_function->parameters), &data_parameter, sizeof(t_parameter));
    }
    ;
    
declaracionParametro
    : especificadorDeclaracion opcionesDecla {
        data_parameter.type = strdup($<string_type>1);
        data_parameter.validation_type = NUMBER;
    }
    ;

opcionesDecla
    :  {data_parameter.name = (char*)malloc(1); data_parameter.name = '\0';}
    | decla { 
        data_parameter.name = strdup($<string_type>1); 
        }
    | declaradorAbstracto
    ;

listaIdentificadoresOp
    : listaIdentificadores
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
    : 
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
    : 
    | '=' expresion
    ;

declaradorAbstracto
    : puntero declaradorAbstractoDirectoOp
    | declaradorAbstractoDirecto
    ;

declaradorAbstractoDirectoOp
    : 
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
    //fprintf(stderr, "Error sintactico");
}