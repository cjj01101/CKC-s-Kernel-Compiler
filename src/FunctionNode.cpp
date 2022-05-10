#include <assert.h>
#include <stdio.h>
#include "FunctionNode.h"
#include "DeclarationNode.h"
#include "StatementNode.h"
#include "ExpressionNode.h"
#include "TypeNode.h"
#include "Utility.h"

/*      (DE)CONSTRUCT FUNCTION      */

FunctionNode::FunctionNode(IdentifierNode *name, TypeNode *returnType, ParameterListNode *parameters, CompoundStatementNode *body)
	: ASTNode(), returnType(returnType), name(name), parameters(parameters), body(body)
{
	assert(NOT_NULL(returnType));
	assert(NOT_NULL(name));
	assert(NOT_NULL(parameters));
	assert(NOT_NULL(body));
}

FunctionNode::~FunctionNode() {
	delete returnType;
	delete name;
	delete parameters;
	delete body;
}

ParameterListNode::~ParameterListNode() {
	for(auto param : parameters) delete param;
}

FunctionCallNode::FunctionCallNode(IdentifierNode *name, ArgumentListNode *arguments)
	: ExpressionNode(), name(name), arguments(arguments)
{
	assert(NOT_NULL(name));
	assert(NOT_NULL(arguments));
}

FunctionCallNode::~FunctionCallNode() {
	delete name;
	delete arguments;
}

ArgumentListNode::~ArgumentListNode() {
	for(auto arg : arguments) delete arg;
}

/*    (DE)CONSTRUCT FUNCTION END    */

/*         SEMANTIC ANALYZE         */

void FunctionNode::AnalyzeSemantic(SymbolTable *intab) {

	std::string sym(name->GetName());
	if(intab->HasSymbol(sym)) {
		throw ASTException("Redeclaration of symbol '" + sym + "'.");
	}

	/* Create Symbol Table in Function Scope */
	SymbolTable symtab;
	symtab.prev = intab;
	parameters->AnalyzeSemantic(&symtab);

	/* Add Function Definition */
	std::vector<Type> paramTypes;
	for(auto param : parameters->parameters) {
        paramTypes.push_back(param->GetType());
    }
	intab->AddEntry(
		sym,
		SymbolTableEntry(
			SymbolKind::FUNCTION,
			SymbolType(returnType->GetType(), paramTypes)
		)
	);

	/* Move into Function Body */
	body->AnalyzeSemantic(&symtab);

}

void ParameterListNode::AnalyzeSemantic(SymbolTable *intab) {

	for(auto param : parameters) param->AnalyzeSemantic(intab);
	for(auto &it : intab->entry) it.second.kind = SymbolKind::ARGUMENT;
}

void FunctionCallNode::AnalyzeSemantic(SymbolTable *intab) {

	name->AnalyzeSemantic(intab);
	arguments->AnalyzeSemantic(intab);

	/* Start Type Checking */
	char message[128];

	/* Check Symbol Kind */
	char *fname = name->GetName();
	std::string sym(fname);
	const auto &symbolContent = intab->FindSymbolOccurrence(sym)->entry.at(sym);
	if(symbolContent.kind != SymbolKind::FUNCTION) {
		sprintf(message, "'%s' is not a function.", fname);
		throw ASTException(message);
	}
	
	/* Get Parameter Types */
	const auto &paramTypes = symbolContent.type.argTypes;
	int paramNum = paramTypes.size();

	/* Get Argument Types*/
	std::vector<Type> argTypes;
	for(auto arg : arguments->arguments) {
		argTypes.push_back(arg->GetValueType());
	}
	int argNum = argTypes.size();

	/* Validate Argument Types */
	if(argNum != paramNum) {
		sprintf(message, "function %s expects %d arguments, %d provided.", fname, paramNum, argNum);
		throw ASTException(message);
	}

	for(int i = 0; i < paramNum; i++) {
		if(!TypeUtils::CanConvert(argTypes[i], paramTypes[i])) {
			sprintf(message, "cannot convert '%s' to '%s' in call to function %s.",
				TypeUtils::GetTypeName(argTypes[i]), TypeUtils::GetTypeName(paramTypes[i]), fname);
			throw ASTException(message);
		}
	}

	/* Determine Value Type */
	valueType = name->GetValueType();
}

void ArgumentListNode::AnalyzeSemantic(SymbolTable *intab) {

	for(auto arg : arguments) arg->AnalyzeSemantic(intab);
}

/*       SEMANTIC ANALYZE END       */

/*          PRINT FUNCTION          */

void FunctionNode::PrintContentInLevel(int level) const {
	printf("Function Definition\n");

	PRINT_CHILD_WITH_HINT(returnType, "RETURN TYPE");
	PRINT_CHILD_WITH_HINT(name, "NAME");
	PRINT_CHILD_WITH_HINT(parameters, "PARAMS");
	PRINT_CHILD_WITH_HINT(body, "BODY");
}

void ParameterListNode::PrintContentInLevel(int level) const {
	printf("Parameter List\n");

	for(auto param : parameters) {
		PRINT_CHILD_WITH_HINT(param, "PARAM");
	}
}

void FunctionCallNode::PrintContentInLevel(int level) const {
	printf("Function Call\n");

	PRINT_CHILD_WITH_HINT(name, "NAME");
	PRINT_CHILD_WITH_HINT(arguments, "ARGS");
}

void ArgumentListNode::PrintContentInLevel(int level) const {
	printf("Argument List\n");

	for(auto arg : arguments) {
		PRINT_CHILD_WITH_HINT(arg, "ARG");
	}
}

/*        PRINT FUNCTION END        */

/*        AUXILIARY FUNCTION        */

void ParameterListNode::AppendParameter(DeclarationNode *param) {
	assert(NOT_NULL(param));
	parameters.push_back(param);
}

void ArgumentListNode::AppendArgument(ExpressionNode *arg) {
	assert(NOT_NULL(arg));
	arguments.push_back(arg);
}

/*      AUXILIARY FUNCTION END      */