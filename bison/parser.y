%{
    #include <stdio.h>
    #include "AbstractSyntaxTree.h"
    #include "ValueNode.h"
    #include "OperatorNode.h"
    #include "DeclarationNode.h"
    #include "StatementNode.h"

    int yylex(void);
    void yyerror(char *);
    
    enum class type;

    ASTNode *root = nullptr;
%}

%union {
    int intNum;
    char str[MAXVARLEN];
    ASTNode *node;
    CompoundStatementNode *compound;
}

%token <intNum> INT
%token <str> ID
%token TYPE_INT
%token OP_ADD OP_SUB OP_MUL OP_DIV OP_MOD
%token OP_GT OP_LT OP_GTE OP_LTE OP_EQ OP_NEQ
%token OP_AND OP_XOR OP_OR OP_LOGAND OP_LOGOR
%token OP_ASSIGN
%token LP RP LBR RBR SEM COMMA
%token IF ELSE WHILE FOR

%type <node> item declaration type declarators
%type <node> statement compoundstmt exprstmt ctrlstmt initstmt
%type <node> expr logorexpr logandexpr orexpr xorexpr andexpr ecmprexpr cmprexpr arithexpr
%type <node> term factor identifier variable integer

%type <compound> items

%nonassoc IFX
%nonassoc ELSE

%%

        program : item { if($1) $1->PrintInLevel(0); } program
                | /* empty */
                ;

           item : declaration { $$ = $1; }
                | statement { $$ = $1; }
                ;

    declaration : type declarators SEM { $$ = new DeclarationNode($2, $1); }
                ;

           type : TYPE_INT { $$ = new TypeNode(Type::INTEGER); }
                ;

    declarators : identifier { $$ = $1; }
                ;

     identifier : ID { $$ = new VariableNode($1); }
                ;

      statement : compoundstmt { $$ = $1; }
                | exprstmt { $$ = $1; }
                | ctrlstmt { $$ = $1; }
                ;

   compoundstmt : LBR items RBR { $$ = $2; }
                ;

          items : items item { $$ = $1; $$->AppendStatement($2); }
                | item { $$ = new CompoundStatementNode(); $$->AppendStatement($1);; }
                ;

       exprstmt : expr SEM { $$ = new ExpressionStatementNode($1); }
                | SEM  { $$ = new EmptyStatementNode(); }
                ;

           expr : variable OP_ASSIGN expr { $$ = new AssignOpNode($1, $3); }
                | logorexpr { $$ = $1; }
                ;

       variable : identifier { $$ = $1; }
                ;

      logorexpr : logorexpr OP_LOGOR logandexpr { $$ = new BinaryOpNode(Operator::LOGOR, $1, $3); }
                | logandexpr { $$ = $1; }
                ;

     logandexpr : logandexpr OP_LOGAND orexpr { $$ = new BinaryOpNode(Operator::LOGAND, $1, $3); }
                | orexpr { $$ = $1; }
                ;

         orexpr : orexpr OP_OR xorexpr { $$ = new BinaryOpNode(Operator::OR, $1, $3); }
                | xorexpr { $$ = $1; }
                ;

        xorexpr : xorexpr OP_XOR andexpr { $$ = new BinaryOpNode(Operator::XOR, $1, $3); }
                | andexpr { $$ = $1; }
                ;

        andexpr : andexpr OP_AND ecmprexpr { $$ = new BinaryOpNode(Operator::AND, $1, $3); }
                | ecmprexpr { $$ = $1; }
                ;

      ecmprexpr : ecmprexpr OP_EQ cmprexpr { $$ = new BinaryOpNode(Operator::EQ, $1, $3); }
                | ecmprexpr OP_NEQ cmprexpr { $$ = new BinaryOpNode(Operator::NEQ, $1, $3); }
                | cmprexpr { $$ = $1; }
                ;

       cmprexpr : cmprexpr OP_GT arithexpr { $$ = new BinaryOpNode(Operator::GT, $1, $3); }
                | cmprexpr OP_LT arithexpr { $$ = new BinaryOpNode(Operator::LT, $1, $3); }
                | cmprexpr OP_GTE arithexpr { $$ = new BinaryOpNode(Operator::GTE, $1, $3); }
                | cmprexpr OP_LTE arithexpr { $$ = new BinaryOpNode(Operator::LTE, $1, $3); }
                | arithexpr { $$ = $1; }
                ;

      arithexpr : arithexpr OP_ADD term { $$ = new BinaryOpNode(Operator::ADD, $1, $3); }
                | arithexpr OP_SUB term { $$ = new BinaryOpNode(Operator::SUB, $1, $3); }
                | term { $$ = $1; }
                ;

           term : term OP_MUL factor { $$ = new BinaryOpNode(Operator::MUL, $1, $3); }
                | term OP_DIV factor { $$ = new BinaryOpNode(Operator::DIV, $1, $3); }
                | term OP_MOD factor { $$ = new BinaryOpNode(Operator::MOD, $1, $3); }
                | OP_SUB factor { $$ = new BinaryOpNode(Operator::MUL, new IntegerNode(-1), $2); }
                | factor { $$ = $1; }
                ;

         factor : variable { $$ = $1; }
                | integer { $$ = $1; }
                | LP expr RP { $$ = $2; }
                ;
     
        integer : INT { $$ = new IntegerNode($1); }
                ;

       ctrlstmt : IF LP expr RP statement %prec IFX { $$ = new IfStatementNode($3, $5, new EmptyStatementNode()); }
                | IF LP expr RP statement ELSE statement { $$ = new IfStatementNode($3, $5, $7); }
                // | DO statement WHILE LP expr RP {  }
                | WHILE LP expr RP statement { $$ = new WhileStatementNode($3, $5); }
                | FOR LP initstmt exprstmt expr RP statement { $$ = new ForStatementNode($3, $4, $5, $7); }
                | FOR LP initstmt exprstmt RP statement { $$ = new ForStatementNode($3, $4, new EmptyExpressionNode() ,$6); }
                ;

       initstmt : exprstmt { $$ = $1; }
                | declaration { $$ = $1; }
                ;

%%

void yyerror(char *e) {
    fprintf(stderr, "error: %s\n", e);
}

int yywrap(){
    return 1;
}

void GenerateSyntaxTree(FILE *input, AbstractSyntaxTree &tree){
    extern FILE *yyin;
    yyin = input;
    yyparse();
}