%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <math.h>
  #include <stdbool.h>
  #include "./lib/record.h"

  int yylex(void);
  int yyerror(char *s);
  int yyerrorTk(char *s, char *t);
  extern int yylineno;
  extern char * yytext;

  char * cat(char *, char *, char *, char *, char *);

  int countIntDigits(int number);

  struct Stack stack;
%}

%union {
  char * sValue;
  struct record * rec;
};

%token <sValue> TYPE ID STR_LIT BOOL_LIT INT_LIT FLOAT_LIT CHAR_LIT

%token GLOBAL CONST ASSIGN
%token FOR WHILE DO IF CONTINUE
%token ELIF ELSE SWITCH CASE DEFAULT BREAK
%token FUNC RETURN PRINT PARSEINT PARSEFLOAT PARSECHAR PARSESTRING
%token OR AND NOT EQUAL DIFFERENCE GREATER_THAN GREATER_THAN_OR_EQUAL LESS_THAN LESS_THAN_OR_EQUAL
%token SUM INCREMENT SUBTRACTION DECREMENT MULTIPLICATION POWER DIVISION REST

%type <sValue> stmt stmts
%type <rec> assign
%type <rec> expr expr_eq expr_comp oper term factor

%start program

%%

program : stmts { 
                  FILE * out_file = fopen("output.c", "w");
                  fprintf(out_file, "#include <math.h>\n#include <stdio.h>\n%s", $1);
                }
        ;

stmts :            { $$ = ""; }
      | stmt stmts { $$ = cat($1, "\n", $2, "", ""); }
      ;
      
stmt : assign {
        char * code;
        code = cat($1->type, " ", $1->name, " = ", $1->sValue);
        code = cat(code, ";", "", "", "");
        $$ = code;
       }
     ;

assign : TYPE ID ASSIGN expr {
          if ((strcmp($1, "int") == 0)) {
            if ((strcmp($4->type, "int") == 0)) {
              $$ = createRecord(&stack, $2, "int", $4->sValue);
            } else { yyerrorTk("Int required", "="); }
          }
          else if ((strcmp($1, "bool") == 0)) {
            if ((strcmp($4->type, "bool") == 0)) {
              $$ = createRecord(&stack, $2, "int", $4->sValue);
            } else { yyerrorTk("Bool required", "="); }
          }
          else if ((strcmp($1, "float") == 0)) {
            if ((strcmp($4->type, "float") == 0)) {
              $$ = createRecord(&stack, $2, "float", $4->sValue);
            } else { yyerrorTk("Float required", "="); }
          }
          else if ((strcmp($1, "char") == 0)) {
            if ((strcmp($4->type, "char") == 0)) {
              char * newChar = (char *) malloc(3 * sizeof(char));
              sprintf(newChar, "\'%s\'", $4->sValue);
              $$ = createRecord(&stack, $2, "char", newChar);
            } else { yyerrorTk("Char required", "="); }
          }
          else if ((strcmp($1, "string") == 0)) {
            if ((strcmp($4->type, "string") == 0)) {
              char * newString = (char *) malloc((strlen($4->sValue) + 2) * sizeof(char));
              sprintf(newString, "\"%s\"", $4->sValue);
              char * newName = (char *) malloc((strlen($4->sValue) + 2) * sizeof(char));
              sprintf(newName, "%s[%d]", $2, (int) strlen($4->sValue));
              $$ = createRecord(&stack, newName, "char", newString);
            } else { yyerrorTk("String required", "="); }
          }
          else { yyerrorTk("Wrong assign", "="); }
         }
       ;
         
expr : NOT expr_eq { 
                    printf("a%sa\n", expr->type);
                    if ((expr != NULL) && strcmp(expr->type, "bool") == 0) {
                      if(strcmp(expr->sValue, "0") == 0){
                        setValue(expr, "bool", "1"); 
                      }else if(strcmp(expr->sValue, "1") == 0){
                        setValue(expr, "bool", "0");
                      }
                    } else { yyerrorTk("Not a boolean", $2->name); }
      }
     | expr_eq OR expr { }
     | expr_eq AND expr { }
     | expr_eq { $$ = $1; }
     ;

expr_eq : expr_comp EQUAL expr_eq { }
        | expr_comp DIFFERENCE expr_eq { }
        | expr_comp { $$ = $1; }
        ;

expr_comp : oper GREATER_THAN expr_comp { }
          | oper GREATER_THAN_OR_EQUAL expr_comp { }
          | oper LESS_THAN expr_comp { }
          | oper LESS_THAN_OR_EQUAL expr_comp { }
          | oper { $$ = $1; }
          ;

oper : term SUM oper { 
                          if (strcmp($1->type, "int") == 0) {
                            if ((strcmp($3->type, "int") == 0)) {
                              int sum = atoi($1->sValue) + atoi($3->sValue);
                              char * sumString = (char *) malloc(countIntDigits(sum) * sizeof(char));
                              sprintf(sumString, "%d", sum);
                              $$ = createRecord(&stack, NULL, "int", sumString);
                              // freeRecord($1); freeRecord($3);
                            }else { yyerrorTk("Different types", "+"); }
                          }
                          else if(strcmp($1->type, "float") == 0){
                            if((strcmp($3->type, "float") == 0)){
                              float sum = atof($1->sValue) + atof($3->sValue);
                              char * sumString = (char *) malloc(countIntDigits(sum) * sizeof(char));
                              sprintf(sumString, "%f", sum);
                              $$ = createRecord(&stack, NULL, "float", sumString);
                              // freeRecord($1); freeRecord($3);
                            }else { yyerrorTk("Different types", "+"); }
                          }
    }
     | term SUBTRACTION oper { 
                              if (strcmp($1->type, "int") == 0) {
                                if ((strcmp($3->type, "int") == 0)) {
                                  int sub = atoi($1->sValue) - atoi($3->sValue);
                                  char * subString = (char *) malloc(countIntDigits(sub) * sizeof(char));
                                  sprintf(subString, "%d", sub);
                                  $$ = createRecord(&stack, NULL, "int", subString);
                                  // freeRecord($1); freeRecord($3);
                                }else { yyerrorTk("Different types", "+"); }
                              }
                              else if(strcmp($1->type, "float") == 0){
                                if((strcmp($3->type, "float") == 0)){
                                  float sub = atof($1->sValue) - atof($3->sValue);
                                  char * subString = (char *) malloc(countIntDigits(sub) * sizeof(char));
                                  sprintf(subString, "%f", sub);
                                  $$ = createRecord(&stack, NULL, "float", subString);
                                  // freeRecord($1); freeRecord($3);
                                }else { yyerrorTk("Different types", "+"); }
                              }
     }
     | term { $$ = $1; }
     ;

term : factor MULTIPLICATION term { 
                                    if (strcmp($1->type, "int") == 0) {
                                      if ((strcmp($3->type, "int") == 0)) {
                                        int mult = atoi($1->sValue) * atoi($3->sValue);
                                        char * multString = (char *) malloc(countIntDigits(mult) * sizeof(char));
                                        sprintf(multString, "%d", mult);
                                        $$ = createRecord(&stack, NULL, "int", multString);
                                        // freeRecord($1); freeRecord($3);
                                      }else { yyerrorTk("Different types", "*"); }
                                    }
                                    else if(strcmp($1->type, "float") == 0){
                                      if((strcmp($3->type, "float") == 0)){
                                        float mult = atof($1->sValue) * atof($3->sValue);
                                        char * multString = (char *) malloc(countIntDigits(mult) * sizeof(char));
                                        sprintf(multString, "%f", mult);
                                        $$ = createRecord(&stack, NULL, "float", multString);
                                        // freeRecord($1); freeRecord($3);
                                      }else { yyerrorTk("Different types", "*"); }
                                    }
      }
     | factor DIVISION term       {
                                    if (strcmp($1->type, "int") == 0) {
                                      if ((strcmp($3->type, "int") == 0)) {
                                        int division = atoi($1->sValue) / atoi($3->sValue);
                                        char * divisionString = (char *) malloc(countIntDigits(division) * sizeof(char));
                                        sprintf(divisionString, "%d", division);
                                        $$ = createRecord(&stack, NULL, "int", divisionString);
                                        // freeRecord($1); freeRecord($3);
                                      }else { yyerrorTk("Different types", "/"); }
                                    }
                                    else if((strcmp($1->type, "float") == 0)){
                                      if((strcmp($3->type, "float") == 0)){
                                        float division = atof($1->sValue) / atof($3->sValue);
                                        char * divisionString = (char *) malloc(countIntDigits(division) * sizeof(char));
                                        sprintf(divisionString, "%f", division);
                                        $$ = createRecord(&stack, NULL, "float", divisionString);
                                        // freeRecord($1); freeRecord($3);
                                      }else{ yyerrorTk("Different types", "/"); }
                                    }
                                  }
     | factor                     { $$ = $1; }
     ;

factor : ID         {
                      struct record * id = search(&stack, $1);
                      if (id != NULL) $$ = id;
                      else yyerrorTk("Identifier not found", $1);
                    }
        | BOOL_LIT  {
                      char * boolString = (char *) malloc(1 * sizeof(char));
                      if ((strcmp($1, "true") == 0)) sprintf(boolString, "1");
                      else sprintf(boolString, "0");
                      $$ = createRecord(&stack, NULL, "bool", boolString);
                    }
       | INT_LIT    { $$ = createRecord(&stack, NULL, "int", $1); }
       | FLOAT_LIT  { $$ = createRecord(&stack, NULL, "float", $1); }
       | STR_LIT    { $$ = createRecord(&stack, NULL, "string", $1); }
       | CHAR_LIT   { $$ = createRecord(&stack, NULL, "char", $1); }
       ;

%%

int main(void) {
  initialize(&stack);
	return yyparse();
}

int yyerror(char *msg) {
	fprintf(stderr, "%d: %s at '%s'\n", yylineno, msg, yytext);
	return 0;
}

int yyerrorTk(char *msg, char* tkn) {
	fprintf(stderr, "%d: %s at '%s'\n", yylineno, msg, tkn);
	exit(0);
}

char * cat(char * s1, char * s2, char * s3, char * s4, char * s5){
  int tam;
  char * output;

  tam = strlen(s1) + strlen(s2) + strlen(s3) + strlen(s4) + strlen(s5) + 1;
  output = (char *) malloc(sizeof(char) * tam);
  
  if (!output){
    printf("Allocation problem. Closing application...\n");
    exit(0);
  }
  
  sprintf(output, "%s%s%s%s%s", s1, s2, s3, s4, s5);
  
  return output;
}

int countIntDigits(int number) {
  int count = 0;
  do {
    number /= 10;
    ++count;
  } while (number != 0);
}