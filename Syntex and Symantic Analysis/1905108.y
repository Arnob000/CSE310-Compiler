%{
#include<bits/stdc++.h>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include "1905108_SymbolTable.h"
#define YYSTYPE symbolInfo*


using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

int line_count=1;
int error_count=0;

FILE *logout;
FILE *errorout;
FILE *parseout;

symbolTable st(11);
symbolTable demo(5);
symbolInfo* demi;
vector<symbolInfo*> varList;
vector<pair<string,string> > paraList;
vector<pair<string,string> > argList;


void yyerror(string s)
{
	fprintf(logout,"Error at line no %d : %s\n",line_count, s.c_str()); 
	return ;
}

symbolInfo* createTerminal(string name, string type, int lcount){
    symbolInfo *s= new symbolInfo(name, type);
    s->setTerminal(true);
    s->setStartLine(lcount);
    s->setEndLine(lcount); 
	return s;           
}
				
void checkVoid(symbolInfo* sym, int lc, string stng){
	if(sym->getType()=="VOID"){
		fprintf(errorout,"Line# %d: %s\n", lc, stng.c_str());
		error_count++;
		sym->setType("INT");
	}
}

void checkVoidDouble(symbolInfo* s1, symbolInfo* s2, int lc, string stng){
	if(s1->getType()=="VOID" || s2->getType()=="VOID"){
		fprintf(errorout,"Line# %d: %s\n", lc, stng.c_str());
		error_count++;
		if(s1->getType()=="VOID")
			s1->setType("INT");
		if(s2->getType()=="VOID")
			s2->setType("INT");
	}
}

//return stmt err checking
void checkRSTMT(symbolInfo* s1, symbolInfo* s2){
	if(s1->getType()=="VOID" && s2->isFun()=="RETSTMT"){
		error_count++;
		fprintf(errorout,"Line# %d: return statement with a value, in function returing 'void'\n",s1->getStartLine());
	}
	else if(s1->getType()!="VOID" && s2->isFun()!="RETSTMT"){
		error_count++;
		fprintf(errorout,"Line# %d: Warning: no return statement in function returing non-void\n",s1->getStartLine());
	}
	else if(s1->getType()=="INT" && s2->getType()=="FLOAT"){
		error_count++;
		fprintf(errorout,"Line# %d: Warning: possible loss of data for returning FLOAT type data from INT type function\n",s1->getStartLine());
	}
}

void printParseTree(symbolInfo* node, int space){
	vector<symbolInfo*> lst;
	if(node!=NULL){
		if(node->isTerminal()){
			for(int i=1; i<=space; i++){
				fprintf(parseout," ");
			}
			fprintf(parseout,"%s : %s",node->getType().c_str(), node->getName().c_str());
			
			if(node->getStartLine()==node->getEndLine()){
				fprintf(parseout,"\t<Line: %d>\n",node->getStartLine());
			}
			else{
				fprintf(parseout,"\t<Line: %d-%d>\n",node->getStartLine(), node->getEndLine());
			}
		}
		else{
			for(int i=1; i<=space; i++){
				fprintf(parseout," ");
			}
			fprintf(parseout,"%s ",node->getName().c_str());
			fprintf(parseout,"\t<Line: %d-%d>\n",node->getStartLine(), node->getEndLine());
			
			lst=node->getChildList();
			for(int i=0; i<lst.size(); i++){
				printParseTree(lst[i],space+1);
			}
			node->clearChild();
		}
		
	}
	
}

void initFunDef(string fName, string fType){			
		//setting up function scope
		symbolInfo* sym =st.lookUp(fName);
		if(sym->getName()==""){
			st.Insert(fName,fType);
			symbolInfo* ss=st.lookUp(fName);
			ss->setIdType("defFunc");
		}
		else if(sym->getName()==fName){
			if(sym->isFun()=="decFunc"){
				if(sym->getType() != fType){
					fprintf(errorout,"Line# %d: Conflicting types for '%s'\n",line_count,fName.c_str());
					error_count++;
				}
				else if(sym->getParaCount() != paraList.size()){
					fprintf(errorout,"Line# %d: Conflicting types for '%s'\n",line_count,fName.c_str());
					error_count++;
				}
				else{
					sym->setIdType("defFunc");
				}

			}
			else if(sym->isFun()=="defFun"){
				fprintf(errorout,"Line# %d: Multiple declaration of Function '%s'\n",line_count,fName.c_str());
				error_count++;
			}
			else{
				fprintf(errorout,"Line# %d: '%s' redeclared as different kind of symbol\n",line_count,fName.c_str());
				error_count++;
			}
		}
		st.enterScope();
}


void initializeFunDef(string fName, string fType){	
		//setting up function scope
		bool flag=false;
		symbolInfo* sym =st.lookUp(fName);
		if(sym->getName()==""){
			st.Insert(fName,fType);
			symbolInfo* ss=st.lookUp(fName);

			st.enterScope();
			
			for(int i=0; i<paraList.size(); i++){
				if(paraList[i].first=="type_specifier"){
					fprintf(errorout,"Line# %d: To few arguments for '%s'\n",line_count, ss->getName().c_str());
					error_count++;
					flag=true;
					if(paraList[i].second=="VOID"){
						fprintf(errorout,"Line# %d: Function parameter can not be void\n",line_count);
						error_count++;
						paraList[i].second="INT"; 
					}
				}
				else{
					if(paraList[i].second=="VOID"){
						fprintf(errorout,"Line# %d: Function parameter '%s' can not be void\n",line_count,paraList[i].first.c_str());
						error_count++;
						paraList[i].second="INT"; 
					}		
										
					bool t=st.Insert(paraList[i].first, paraList[i].second);
					if(t){
						ss->insertParam(paraList[i].first, paraList[i].second);
					}
					else{
						fprintf(errorout,"Line# %d: Redefinition of parameter '%s'\n",line_count,paraList[i].first.c_str());
						error_count++;	
						flag=true;					
					}
				}
			}

			if (flag==false)
				ss->setIdType("defFunc");
			else{
				ss->setIdType("errFunc");
			}

		}
		else if(sym->getName()==fName){
			st.enterScope();
			flag=false;
			if(sym->isFun()=="decFunc"){
				vector<pair<string, string> > funPara = sym->getParam();
				
				if(sym->getType()!=fType){
					fprintf(errorout,"Line# %d: Conflicting types for '%s'\n",line_count,fName.c_str());
					error_count++;
					flag=true;
				}
				else if(sym->getParaCount() != paraList.size()){
					fprintf(errorout,"Line# %d: Conflicting types for '%s'\n",line_count,fName.c_str());
					error_count++;
					flag=true;
				}
				else{					
					for(int i=0; i<paraList.size(); i++){
						if(paraList[i].first=="type_specifier"){
							fprintf(errorout,"Line# %d: To few arguments for '%s'\n",line_count, sym->getName().c_str());
							error_count++;
							flag=true;
							if(paraList[i].second=="VOID"){
								fprintf(errorout,"Line# %d: Function parameter can not be void\n",line_count);
								error_count++;
								paraList[i].second=funPara[i+1].second; //recover
							}
						}						
						else {
							if(paraList[i].second=="VOID"){
								fprintf(errorout,"Line# %d: Function parameter '%s' can not be void\n",line_count,paraList[i].first.c_str());
								error_count++;
								paraList[i].second=funPara[i+1].second; //recover
							}

							if(paraList[i].second != funPara[i+1].second){
								fprintf(errorout,"Line# %d: Conflicting types of parameter '%s' for '%s'\n",line_count,paraList[i].first.c_str(), fName.c_str());
								error_count++;
								flag=true;			
							}		
						}									
						
					}
				}

				int len=min(funPara.size()-1, paraList.size());
				//inserting at new name
				for(int i=1; i<=len; i++){
					bool t=st.Insert(paraList[i-1].first, paraList[i-1].second);
					if(t==false){
						fprintf(errorout,"Line# %d: Redefinition of parameter '%s'\n",line_count,paraList[i].first.c_str());
						error_count++;	
						flag=true;					
					}	
					if(flag==false)
						sym->insertParam(paraList[i-1].first, funPara[i].second, i);
				}
				if(paraList.size()>len){
					for(int i=len; i<paraList.size(); i++)
						st.Insert(paraList[i-1].first, paraList[i-1].second);
					//redef or not?
				}

				if(flag==false){
					sym->setIdType("defFunc");
				}
				else{
					sym->setIdType("errFunc");
				}

			}
			else if(sym->isFun()=="defFun"){
				fprintf(errorout,"Line# %d: Multiple declaration of Function '%s'\n",line_count,fName.c_str());
				error_count++;

				for(int i=0; i<paraList.size(); i++)
						bool t=st.Insert(paraList[i].first, paraList[i].second);
					
			}
			else{
				fprintf(errorout,"Line# %d: '%s' redeclared as different kind of symbol\n",line_count,fName.c_str());
				error_count++;
				for(int i=0; i<paraList.size(); i++)
						bool t=st.Insert(paraList[i].first, paraList[i].second);
					
			}
		}

		paraList.clear();
}

%}

%token IF ELSE FOR DO WHILE SWITCH DEFAULT BREAK INT FLOAT VOID CHAR DOUBLE RETURN CASE PRINTLN CONTINUE
%token CONST_INT CONST_FLOAT CONST_CHAR ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP BITOP NOT
%token LPAREN RPAREN LCURL RCURL LSQUARE RSQUARE COMMA SEMICOLON
%token ID SINGLE_LINE_STRING MULTI_LINE_STRING

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		$$=new symbolInfo("start : program","INIT");
		$$->setChild((symbolInfo*)$1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		printParseTree((symbolInfo*)$$, 0);
		fprintf(logout,"start : program \n");
		delete $$;
	}
	;
//out of scope statement error recovered
program : program unit 
	{
		$$=new symbolInfo("program : program unit","COMPONENT");
		$$->setChild((symbolInfo*)$1);
		$$->setChild((symbolInfo*)$2);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());
		fprintf(logout,"program : program unit \n"); 
	}
	| program error setErrUnit unit
	{
		$2=demi;
		$$=new symbolInfo("program : program unit","COMPONENT");
		$$->setChild((symbolInfo*)$1);
		$$->setChild((symbolInfo*)$2);
		
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());
		fprintf(logout,"program : program unit \n"); 

		error_count++;
		fprintf(errorout,"Line# %d: Syntax error at unit of program\n", $2->getStartLine());						
	}
	| program error setErrUnit SEMICOLON
	{
		$2=demi;
		$$=new symbolInfo("program : program unit","COMPONENT");
		$$->setChild((symbolInfo*)$1);
		$$->setChild((symbolInfo*)$2);
		
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());
		fprintf(logout,"program : program unit \n"); 

		error_count++;
		fprintf(errorout,"Line# %d: Syntax error at unit of program\n", $2->getStartLine());						
	}
	| unit
	{
		$$=new symbolInfo("program : unit", "COMPONENT");
		$$->setChild((symbolInfo*)$1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		fprintf(logout,"program : unit \n"); 
	}
	| error
	{
		$1=createTerminal("error", "unit", line_count);
		$$=new symbolInfo("program : unit","COMPONENT");
		$$->setChild((symbolInfo*)$1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		fprintf(logout,"program : unit \n");

		error_count++;
		fprintf(errorout,"Line# %d: Syntax error at unit of program\n", $1->getStartLine());						
	}
	;

setErrUnit : {
	demi= createTerminal("error", "unit", line_count);
}

unit : var_declaration
	{
		$$=new symbolInfo("unit : var_declaration", string($1->getType()));
		$$->setChild((symbolInfo*)$1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		fprintf(logout,"unit : var_declaration \n"); 
	}
     | func_declaration
	{
		$$=new symbolInfo("unit : func_declaration", string($1->getType()));	
		$$->setChild((symbolInfo*)$1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		fprintf(logout,"unit : func_declaration \n"); 
	}
     | func_definition
	{
		$$=new symbolInfo("unit : func_definition", string($1->getType()));
		$$->setChild((symbolInfo*)$1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		fprintf(logout,"unit : func_definition \n"); 		
	}
     ;

 //func dec error recovered  
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			$$=new symbolInfo("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON", string($2->getName()));	//type changed to name
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$5);
			$$->setChild((symbolInfo*)$6);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($6->getEndLine());

			bool b=st.Insert(string($2->getName()),string($1->getType()));
			if(b){
				symbolInfo* sym =st.lookUp(string($2->getName()));	//function
				sym->setIdType("decFunc");
				
				demo.enterScope();
				
				for(int i=0; i<paraList.size(); i++){
					if(paraList[i].second=="VOID"){
						fprintf(errorout,"Line# %d: Function parameter '%s' can not be void\n",line_count,paraList[i].first.c_str());
						error_count++;
						paraList[i].second="INT"; //default
					}
					
					bool t=demo.Insert(paraList[i].first, paraList[i].second);
					if(t){
						sym->insertParam(paraList[i].first, paraList[i].second);
					}
					else{
						if(paraList[i].first == "type_specifier"){
							sym->insertParam(paraList[i].first, paraList[i].second);
						}
						else{
							fprintf(errorout,"Line# %d: Redefinition of parameter '%s'\n",line_count,paraList[i].first.c_str());
							error_count++;
						}
					}
					
				}
				// demo.printAll(logout);
				demo.exitScope();
			}
			else{
				symbolInfo* sym =st.lookUp(string($2->getName()));
				if(sym->isFun()=="decFunc"){
					fprintf(errorout,"Line# %d: Warning Function '%s' is already decleared\n",line_count,$2->getName().c_str());
				}
				else if(sym->isFun()=="defFunc"){
					fprintf(errorout,"Line# %d: Multiple declaration of Function '%s'\n",line_count,$2->getName().c_str());
					error_count++;
				}
				else{
					fprintf(errorout,"Line# %d: '%s' redeclared as different kind of symbol\n",line_count,$2->getName().c_str());
					error_count++;
				}
			}

			paraList.clear();
			fprintf(logout,"func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON \n"); 
		}
		// | type_specifier ID LPAREN parameter_list error setErrNode RPAREN SEMICOLON
		// {
		// 	$5=demi;
		// 	$$=new symbolInfo("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON ", string($2->getName()));		//type changed to name
		// 	$$->setChild((symbolInfo*)$1);
		// 	$$->setChild((symbolInfo*)$2);
		// 	$$->setChild((symbolInfo*)$3);
		// 	$$->setChild((symbolInfo*)$4);
		// 	$$->setChild((symbolInfo*)$5);
		// 	$$->setChild((symbolInfo*)$7);
		// 	$$->setChild((symbolInfo*)$8);
		// 	$$->setStartLine($1->getStartLine());
		// 	$$->setEndLine($8->getEndLine());
						
		// 	paraList.clear();

		// 	error_count++;
		// 	fprintf(errorout,"Line# %d: Syntax error at parameter list of function declaration\n", $5->getStartLine());						
		// }
		| type_specifier ID LPAREN parameter_list RPAREN error setErrSemi
		{
			$6=demi;
			$6->setStartLine($5->getEndLine());
			$6->setEndLine($5->getEndLine());
			$$=new symbolInfo("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON", string($2->getName()));	//type to  name
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$5);
			$$->setChild((symbolInfo*)$6);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($6->getEndLine());

			bool b=st.Insert(string($2->getName()),string($1->getType()));
			if(b){
				symbolInfo* sym =st.lookUp(string($2->getName()));	//function
				sym->setIdType("decFunc");
				
				demo.enterScope();
				
				for(int i=0; i<paraList.size(); i++){
					if(paraList[i].second=="VOID"){
						fprintf(errorout,"Line# %d: Function parameter '%s' can not be void\n",line_count,paraList[i].first.c_str());
						error_count++;
						paraList[i].second="INT"; //default
					}
					
					bool t=demo.Insert(paraList[i].first, paraList[i].second);
					if(t){
						sym->insertParam(paraList[i].first, paraList[i].second);
					}
					else{
						if(paraList[i].first == "type_specifier"){
							sym->insertParam(paraList[i].first, paraList[i].second);
						}
						else{
							fprintf(errorout,"Line# %d: Redefinition of parameter '%s'\n",line_count,paraList[i].first.c_str());
							error_count++;
						}
					}
					
				}
				demo.exitScope();
			}
			else{
				symbolInfo* sym =st.lookUp(string($2->getName()));
				if(sym->isFun()=="decFunc"){
					fprintf(errorout,"Line# %d: Warning Function '%s' is already decleared\n",line_count,$2->getName().c_str());
				}
				else if(sym->isFun()=="defFunc"){
					fprintf(errorout,"Line# %d: Multiple declaration of Function '%s'\n",line_count,$2->getName().c_str());
					error_count++;
				}
				else{
					fprintf(errorout,"Line# %d: '%s' redeclared as different kind of symbol\n",line_count,$2->getName().c_str());
					error_count++;
				}
			}

			paraList.clear();
			error_count++;
			fprintf(errorout,"Line# %d: No semicolon at the end of function declaration\n", $6->getStartLine());								 
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			$$=new symbolInfo("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON", string($2->getName()));
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$5);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($5->getEndLine());

			bool b=st.Insert(string($2->getName()),string($1->getType()));
			if(b){
				symbolInfo* sym =st.lookUp(string($2->getName()));
				sym->setIdType("decFunc");
			}
			else{
				symbolInfo* sym =st.lookUp(string($2->getName()));
				if(sym->isFun()=="decFunc"){
					fprintf(errorout,"Line# %d: Warning Function '%s' is already decleared\n",line_count,$2->getName().c_str());
				}
				else if(sym->isFun()=="defFunc"){
					fprintf(errorout,"Line# %d: Multiple declaration of Function '%s'\n",line_count,$2->getName().c_str());
					error_count++;
				}
				else{
					fprintf(errorout,"Line# %d: '%s' redeclared as different kind of symbol\n",line_count,$2->getName().c_str());
					error_count++;
				}
			}


			paraList.clear();
			fprintf(logout,"func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON \n"); 
		}
		| type_specifier ID LPAREN error setErrNode RPAREN SEMICOLON
		{
			$4=demi;
			$$=new symbolInfo("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON ", string($2->getName()));	//type to name
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$6);
			$$->setChild((symbolInfo*)$7);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($7->getEndLine());
						
			paraList.clear();

			error_count++;
			fprintf(errorout,"Line# %d: Syntax error at parameter list of function declaration\n", $4->getStartLine());						
		}
		| type_specifier ID LPAREN RPAREN error setErrSemi
		{
			$5=demi;
			$5->setStartLine($4->getEndLine());
			$5->setEndLine($4->getEndLine());
			$$=new symbolInfo("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON", string($2->getName()));  //type to name
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$5);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($5->getEndLine());

			bool b=st.Insert(string($2->getName()),string($1->getType()));
			if(b){
				symbolInfo* sym =st.lookUp(string($2->getName()));
				sym->setIdType("decFunc");
			}
			else{
				symbolInfo* sym =st.lookUp(string($2->getName()));
				if(sym->isFun()=="decFunc"){
					fprintf(errorout,"Line# %d: Warning Function '%s' is already decleared\n",line_count,$2->getName().c_str());
				}
				else if(sym->isFun()=="defFunc"){
					fprintf(errorout,"Line# %d: Multiple declaration of Function '%s'\n",line_count,$2->getName().c_str());
					error_count++;
				}
				else{
					fprintf(errorout,"Line# %d: '%s' redeclared as different kind of symbol\n",line_count,$2->getName().c_str());
					error_count++;
				}
			}


			paraList.clear();
			error_count++;
			fprintf(errorout,"Line# %d: No semicolon at the end of function declaration\n", $5->getStartLine());						
		}	
		| type_specifier ID LPAREN error setErrNode RPAREN error
		{
			$4=demi;
			$7=createTerminal("error","SEMICOLON",line_count);
			$$=new symbolInfo("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON ", string($2->getName()));	//type to name
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$6);
			$$->setChild((symbolInfo*)$7);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($7->getEndLine());
						
			paraList.clear();

			error_count++;
			fprintf(errorout,"Line# %d: Syntax error at parameter list of function declaration\n", $4->getStartLine());		
			error_count++;
			fprintf(errorout,"Line# %d: No semicolon at the end of function declaration\n", $7->getStartLine());										
		}	
		;

setErrSemi : {
	demi=createTerminal("error", "SEMICOLON", line_count);
}

setErrNode : {
	demi=createTerminal("error", "parameter_list", line_count);
}

//... ok with scope
func_definition : type_specifier ID LPAREN parameter_list RPAREN {initializeFunDef(string($2->getName()), string($1->getType()));} compound_statement
		{
			$$=new symbolInfo("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement", string($2->getName())); 	//type to name
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$5);
			$$->setChild((symbolInfo*)$7);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($7->getEndLine());
						
			paraList.clear();	
			fprintf(logout,"func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement \n"); 

			checkRSTMT($1,$7);
		}
		// | type_specifier ID LPAREN parameter_list error setErrNode RPAREN setup compound_statement
		// {
		// 	$5=demi;
		// 	$$=new symbolInfo("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement", string($2->getName()));		//type to name
		// 	$$->setChild((symbolInfo*)$1);
		// 	$$->setChild((symbolInfo*)$2);
		// 	$$->setChild((symbolInfo*)$3);
		// 	$$->setChild((symbolInfo*)$4);
		// 	$$->setChild((symbolInfo*)$5);
		// 	$$->setChild((symbolInfo*)$7);
		// 	$$->setChild((symbolInfo*)$9);
		// 	$$->setStartLine($1->getStartLine());
		// 	$$->setEndLine($9->getEndLine());
						
		// 	paraList.clear();

		// 	error_count++;
		// 	fprintf(errorout,"Line# %d: Syntax error at parameter list of function definition\n", $5->getStartLine());	
		//return stmt
		// checkRSTMT($1,$9);					
		// }
		| type_specifier ID LPAREN RPAREN {initFunDef(string($2->getName()), string($1->getType()));} compound_statement
		{
			
			$$=new symbolInfo("func_definition : type_specifier ID LPAREN RPAREN compound_statement", string($2->getName()));	//type to name
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$6);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($6->getEndLine());


			paraList.clear();
			fprintf(logout,"func_definition : type_specifier ID LPAREN RPAREN compound_statement \n"); 

			checkRSTMT($1,$6);
		}
		| type_specifier ID LPAREN error setErrNode RPAREN setup compound_statement
		{
			$4=demi;
			$$=new symbolInfo("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement", string($2->getName()));	//type to name
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$6);
			$$->setChild((symbolInfo*)$8);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($8->getEndLine());
						
			paraList.clear();

			error_count++;
			fprintf(errorout,"Line# %d: Syntax error at parameter list of function definition\n", $4->getStartLine());

			//return stmt
			checkRSTMT($1,$8);					
		}
 		;				

//... ok
parameter_list  : parameter_list COMMA type_specifier ID
		{
			$$=new symbolInfo("parameter_list : parameter_list COMMA type_specifier ID", "PARAM");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($4->getEndLine());
			
			pair<string, string> p={string($4->getName()), string($3->getType())};
			paraList.push_back(p);
			fprintf(logout,"parameter_list  : parameter_list COMMA type_specifier ID \n"); 
		}
		| parameter_list COMMA type_specifier
		{
			$$=new symbolInfo("parameter_list : parameter_list COMMA type_specifier", "PARAM");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());

			pair<string, string> p={string($3->getName()), string($3->getType())};
			paraList.push_back(p);
			fprintf(logout,"parameter_list  : parameter_list COMMA type_specifier \n"); 
		}
 		| type_specifier ID
		{
			$$=new symbolInfo("parameter_list : type_specifier ID", "PARAM");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($2->getEndLine());

			pair<string, string> p={string($2->getName()), string($1->getType())};
			paraList.push_back(p);
			fprintf(logout,"parameter_list  : type_specifier ID \n");
		}
		| type_specifier
		{
			$$=new symbolInfo("parameter_list : type_specifier", "PARAM");
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());

			pair<string, string> p={string($1->getName()), string($1->getType())};
			paraList.push_back(p);
			fprintf(logout,"parameter_list  : type_specifier \n"); 
		}
 		;

 //func scope error handled
 //return stmt handled
compound_statement : LCURL statements RCURL
			{
				$$=new symbolInfo("compound_statement : LCURL statements RCURL", "COMPOUND");
				$$->setChild((symbolInfo*)$1);
				$$->setChild((symbolInfo*)$2);
				$$->setChild((symbolInfo*)$3);
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($3->getEndLine());
				fprintf(logout,"compound_statement : LCURL statements RCURL \n"); 
				st.printAll(logout);
				st.exitScope();

				if($2->isFun()=="RETSTMT"){
					$$->setIdType("RETSTMT");
					$$->setType($2->getType());
				}
			}
			| LCURL statements func_declaration setErrFunDec statements RCURL
			{
				st.Remove($3->getType());
				$3=demi;
				$$=new symbolInfo("compound_statement : LCURL statements RCURL", "COMPOUND");
				$$->setChild((symbolInfo*)$1);
				$$->setChild((symbolInfo*)$2);
				$$->setChild((symbolInfo*)$3);
				$$->setChild((symbolInfo*)$5);
				$$->setChild((symbolInfo*)$6);
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($6->getEndLine());
				
				error_count++;
				fprintf(logout,"Error at line no %d : out of scope function declaration\n",$3->getStartLine()); 
				fprintf(errorout,"Line# %d: Function declaration is not allowed between { }\n",$3->getStartLine()); 
				st.printAll(logout);
				st.exitScope();

				if($2->isFun()=="RETSTMT"){
					$$->setIdType("RETSTMT");
					$$->setType($2->getType());
				}
				else if($5->isFun()=="RETSTMT"){
					$$->setIdType("RETSTMT");
					$$->setType($5->getType());
				}
			}
			| LCURL statements func_definition setErrFunDef statements RCURL
			{
				st.Remove($3->getType());
				$3=demi;
				$$=new symbolInfo("compound_statement : LCURL statements RCURL", "COMPOUND");
				$$->setChild((symbolInfo*)$1);
				$$->setChild((symbolInfo*)$2);
				$$->setChild((symbolInfo*)$3);
				$$->setChild((symbolInfo*)$5);
				$$->setChild((symbolInfo*)$6);
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($6->getEndLine());
				
				error_count++;
				fprintf(logout,"Error at line no %d : out of scope function definition\n",$3->getStartLine()); 
				fprintf(errorout,"Line# %d: Function definition is not allowed between { }\n",$3->getStartLine()); 
				st.printAll(logout);
				st.exitScope();

				if($2->isFun()=="RETSTMT"){
					$$->setIdType("RETSTMT");
					$$->setType($2->getType());
				}
				else if($5->isFun()=="RETSTMT"){
					$$->setIdType("RETSTMT");
					$$->setType($5->getType());
				}
			}
			| LCURL statements func_declaration setErrFunDec RCURL
			{
				st.Remove($3->getType());
				$3=demi;
				$$=new symbolInfo("compound_statement : LCURL statements RCURL", "COMPOUND");
				$$->setChild((symbolInfo*)$1);
				$$->setChild((symbolInfo*)$2);
				$$->setChild((symbolInfo*)$3);
				$$->setChild((symbolInfo*)$5);
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($5->getEndLine());

				if($2->isFun()=="RETSTMT"){
					$$->setIdType("RETSTMT");
					$$->setType($2->getType());
				}
				
				error_count++;
				fprintf(logout,"Error at line no %d : out of scope function declaration\n",$3->getStartLine()); 
				fprintf(errorout,"Line# %d: Function declaration is not allowed between { }\n",$3->getStartLine()); 
				st.printAll(logout);
				st.exitScope();
			}
			| LCURL statements func_definition setErrFunDef RCURL
			{
				st.Remove($3->getType());
				$3=demi;
				$$=new symbolInfo("compound_statement : LCURL statements RCURL", "COMPOUND");
				$$->setChild((symbolInfo*)$1);
				$$->setChild((symbolInfo*)$2);
				$$->setChild((symbolInfo*)$3);
				$$->setChild((symbolInfo*)$5);
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($5->getEndLine());

				if($2->isFun()=="RETSTMT"){
					$$->setIdType("RETSTMT");
					$$->setType($2->getType());
				}
				
				error_count++;
				fprintf(logout,"Error at line no %d : out of scope function definition\n",$3->getStartLine()); 
				fprintf(errorout,"Line# %d: Function definition is not allowed between { }\n",$3->getStartLine()); 
				st.printAll(logout);
				st.exitScope();
			}
			| LCURL func_declaration setErrFunDec statements RCURL
			{
				st.Remove($2->getType());
				$2=demi;
				$$=new symbolInfo("compound_statement : LCURL statements RCURL", "COMPOUND");
				$$->setChild((symbolInfo*)$1);
				$$->setChild((symbolInfo*)$2);
				$$->setChild((symbolInfo*)$4);
				$$->setChild((symbolInfo*)$5);
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($5->getEndLine());

				if($4->isFun()=="RETSTMT"){
					$$->setIdType("RETSTMT");
					$$->setType($4->getType());
				}
				
				error_count++;
				fprintf(logout,"Error at line no %d : out of scope function declaration\n",$2->getStartLine()); 
				fprintf(errorout,"Line# %d: Function declaration is not allowed between { }\n",$2->getStartLine()); 
				st.printAll(logout);
				st.exitScope();
			}
			| LCURL func_definition setErrFunDef statements RCURL
			{
				st.Remove($2->getType());
				$2=demi;
				$$=new symbolInfo("compound_statement : LCURL statements RCURL", "COMPOUND");
				$$->setChild((symbolInfo*)$1);
				$$->setChild((symbolInfo*)$2);
				$$->setChild((symbolInfo*)$4);
				$$->setChild((symbolInfo*)$5);
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($5->getEndLine());

				if($4->isFun()=="RETSTMT"){
					$$->setIdType("RETSTMT");
					$$->setType($4->getType());
				}
				
				error_count++;
				fprintf(logout,"Error at line no %d : out of scope function definition\n",$2->getStartLine()); 
				fprintf(errorout,"Line# %d: Function definition is not allowed between { }\n",$2->getStartLine()); 
				st.printAll(logout);
				st.exitScope();
			}
 		    | LCURL RCURL
			{
				$$=new symbolInfo("compound_statement : LCURL RCURL","COMPOUND");
				$$->setChild((symbolInfo*)$1);
				$$->setChild((symbolInfo*)$2);
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($2->getEndLine());
				fprintf(logout,"compound_statement : LCURL RCURL \n"); 
				st.printAll(logout);
				st.exitScope();
			}
			| LCURL func_definition setErrFunDef RCURL
			{
				st.Remove($2->getType());
				$2=demi;
				$$=new symbolInfo("compound_statement : LCURL statements RCURL","COMPOUND");
				$$->setChild((symbolInfo*)$1);
				$$->setChild((symbolInfo*)$2);
				$$->setChild((symbolInfo*)$4);
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($4->getEndLine());

				error_count++;
				fprintf(logout,"Error at line no %d : out of scope function definition\n",$2->getStartLine()); 
				fprintf(errorout,"Line# %d: Function definition is not allowed between { }\n",$2->getStartLine()); 
				st.printAll(logout);
				st.exitScope();
			}
			| LCURL func_declaration setErrFunDec RCURL
			{
				st.Remove($2->getType());	//removing invalid func
				$2=demi;
				$$=new symbolInfo("compound_statement : LCURL statements RCURL","COMPOUND");
				$$->setChild((symbolInfo*)$1);
				$$->setChild((symbolInfo*)$2);
				$$->setChild((symbolInfo*)$4);
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($4->getEndLine());			

				error_count++;
				fprintf(logout,"Error at line no %d : out of scope function declaration\n",$2->getStartLine()); 
				fprintf(errorout,"Line# %d: Function declaration is not allowed between { }\n",$2->getStartLine()); 
				st.printAll(logout);
				st.exitScope();
			}
 		    ;

setErrFunDef : {
	demi=createTerminal("error", "func_definition", line_count);
}

setErrFunDec : {
	demi=createTerminal("error", "func_declaration", line_count);
}

//ok void handled
var_declaration : type_specifier declaration_list SEMICOLON
		{
			$$=new symbolInfo("var_declaration : type_specifier declaration_list SEMICOLON", string($1->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());

			if($1->getType()=="VOID"){
				fprintf(errorout,"Line# %d: Variable or field '%s' declared void\n",line_count, varList[0]->getName().c_str());
				error_count++;
			}
			else {
				for(int i=0; i<varList.size(); i++){
					bool b = st.Insert(string(varList[i]->getName()),string($1->getType()));
					if(b){
						symbolInfo* sm = st.lookUp(string(varList[i]->getName()));
						sm->setArrSize(varList[i]->getArrSize());
						if(sm->getArrSize()>=0)
							sm->setIdType("array");
					}
					else if(b==false){
						fprintf(errorout,"Line# %d: Conflicting types for'%s'\n",line_count, varList[i]->getName().c_str());
						error_count++;
					}			
				}
			}
			varList.clear();
			fprintf(logout,"var_declaration : type_specifier declaration_list SEMICOLON \n"); 
		}
		// |type_specifier declaration_list error setErrSemi
		// {
		// 	$3=demi;
		// 	$$=new symbolInfo("var_declaration : type_specifier declaration_list SEMICOLON", string($1->getType()));
		// 	$$->setChild((symbolInfo*)$1);
		// 	$$->setChild((symbolInfo*)$2);
		// 	$$->setChild((symbolInfo*)$3);
		// 	$$->setStartLine($1->getStartLine());
		// 	$$->setEndLine($3->getEndLine());

		// 	if($1->getType()=="VOID"){
		// 		fprintf(errorout,"Line# %d: Variable or field '%s' declared void\n",line_count, varList[0]->getName().c_str());
		// 		error_count++;
		// 	}
		// 	else {
		// 		for(int i=0; i<varList.size(); i++){
		// 			bool b = st.Insert(string(varList[i]->getName()),string($1->getType()));
		// 			if(b){
		// 				symbolInfo* sm = st.lookUp(string(varList[i]->getName()));
		// 				sm->setArrSize(varList[i]->getArrSize());
		// 				if(sm->getArrSize()>=0)
		// 					sm->setIdType("array");
		// 			}
		// 			else if(b==false){
		// 				fprintf(errorout,"Line# %d: Conflicting types for'%s'\n",line_count, varList[i]->getName().c_str());
		// 				error_count++;
		// 			}			
		// 		}
		// 	}
		// 	varList.clear();
		// 	error_count++;
		// 	fprintf(errorout,"Line# %d: No semicolon at the end of variable declaration\n", $3->getStartLine());						
		// }
		| type_specifier error {$2=createTerminal("error", "declaration_list", line_count); } SEMICOLON
		{
			$$=new symbolInfo("var_declaration : type_specifier declaration_list SEMICOLON", string($1->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$4);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($4->getEndLine());
						
			varList.clear();

			error_count++;
			fprintf(errorout,"Line# %d: Syntax error at declaration list of variable declaration\n",$2->getStartLine());						
		}
		// | type_specifier error {$2=createTerminal("error", "declaration_list", line_count); } error setErrSemi
		// {
		// 	$4=demi;
		// 	$$=new symbolInfo("var_declaration : type_specifier declaration_list SEMICOLON", string($1->getType()));
		// 	$$->setChild((symbolInfo*)$1);
		// 	$$->setChild((symbolInfo*)$2);
		// 	$$->setChild((symbolInfo*)$4);
		// 	$$->setStartLine($1->getStartLine());
		// 	$$->setEndLine($4->getEndLine());
						
		// 	varList.clear();

		// 	error_count++;
		// 	fprintf(errorout,"Line# %d: Syntax error at declaration list of variable declaration\n",$2->getStartLine());	
		// 	error_count++;
		// 	fprintf(errorout,"Line# %d: No semicolon at the end of varible declaration\n", $4->getStartLine());										
		// }
		;
 		 
//ok 		 
type_specifier	: INT 
		{
			$$=new symbolInfo("type_specifier : INT", string($1->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			fprintf(logout,"type_specifier	: INT \n");        
		}
 		| FLOAT
		{
			$$=new symbolInfo("type_specifier : FLOAT", string($1->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			fprintf(logout,"type_specifier	: FLOAT \n");
		}
 		| VOID
		{
			$$=new symbolInfo("type_specifier : VOID", string($1->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			fprintf(logout,"type_specifier	: VOID \n");
		}
 		;

//ok 		
declaration_list : declaration_list COMMA ID
		{
			$$=new symbolInfo("declaration_list : declaration_list COMMA ID", "DECLIST");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());

			varList.push_back((symbolInfo*)$3);	
			fprintf(logout,"declaration_list : declaration_list COMMA ID  \n");
		}
 		  | declaration_list COMMA ID LSQUARE CONST_INT RSQUARE
	    {
			
			$$=new symbolInfo("declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE", "DECLIST");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$5);
			$$->setChild((symbolInfo*)$6);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($6->getEndLine());
			
			$3->setArrSize($5->getArrSize());
			$3->setIdType("array");
			varList.push_back((symbolInfo*)$3);			
			fprintf(logout,"declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE \n");
		}
 		  |ID
		{
			$$=new symbolInfo("declaration_list : ID", "DECLIST");
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
				
			varList.push_back((symbolInfo*)$1);
			fprintf(logout,"declaration_list : ID \n");
		}
 		  | ID LSQUARE CONST_INT RSQUARE
		{
			$$=new symbolInfo("declaration_list : ID LSQUARE CONST_INT RSQUARE", "DECLIST");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($4->getEndLine());
			
			$1->setArrSize($3->getArrSize());
			$1->setIdType("array");
			varList.push_back((symbolInfo*)$1);
			fprintf(logout,"declaration_list : ID LSQUARE CONST_INT RSQUARE \n");
		}
 		  ;
 		
statements : statement
		{
			$$=new symbolInfo("statements : statement", "STMTS");
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			if($1->isFun()=="RETSTMT"){
				$$->setIdType("RETSTMT");
				$$->setType($1->getType());
			}
			fprintf(logout,"statements : statement \n");
		}
	   | statements statement
	   	{
			$$=new symbolInfo("statements : statements statement", "STMTS");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($2->getEndLine());

			if($1->isFun()=="RETSTMT"){
				$$->setIdType("RETSTMT");
				$$->setType($1->getType());
			}
			else if($2->isFun()=="RETSTMT"){
				$$->setIdType("RETSTMT");
				$$->setType($2->getType());
			}
			fprintf(logout,"statements : statements statement \n");
		}
	   ;
	   
setup : {
	st.enterScope();
}

statement : var_declaration
		{
			$$=new symbolInfo("statement : var_declaration", string($1->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());	
			fprintf(logout,"statement : var_declaration \n");
		}
		| expression_statement
		{
			$$=new symbolInfo("statement : expression_statement", string($1->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			fprintf(logout,"statement : expression_statement \n");
			//it can be void
		}
		| setup compound_statement
		{
			$$=new symbolInfo("statement : compound_statement", string($2->getType()));
			$$->setChild((symbolInfo*)$2);
			$$->setStartLine($2->getStartLine());
			$$->setEndLine($2->getEndLine());
			$$->setIdType($$->isFun());
			fprintf(logout,"statement : compound_statement \n");
		}
		| FOR LPAREN expression_statement expression_statement expression RPAREN statement
		{			
			$$=new symbolInfo("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement", "STMT");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$5);
			$$->setChild((symbolInfo*)$6);
			$$->setChild((symbolInfo*)$7);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($7->getEndLine());
			//intentinally arr ind not checked as per c standard
			//for(;;) is permitted

			if($5->getName()=="error"){
				error_count++;
				fprintf(errorout,"Line# %d: Syntax error at expression of statement\n",$5->getStartLine());							
			}
			else
				fprintf(logout,"statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement \n");
		}
		| IF LPAREN expression RPAREN statement	%prec LOWER_THAN_ELSE
		{			
			$$=new symbolInfo("statement : IF LPAREN expression RPAREN statement", "STMT");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$5);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($5->getEndLine());

			checkVoid($3, line_count,"Void cannot be used in expression");
			
			if($3->getName()=="error"){
				error_count++;
				fprintf(errorout,"Line# %d: Syntax error at expression of statement\n",$3->getStartLine());							
			}
			else
				fprintf(logout,"statement : IF LPAREN expression RPAREN statement \n");
		}
		| IF LPAREN expression RPAREN statement ELSE statement
		{			
			$$=new symbolInfo("statement : IF LPAREN expression RPAREN statement ELSE statement", "STMT");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$5);
			$$->setChild((symbolInfo*)$6);
			$$->setChild((symbolInfo*)$7);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($7->getEndLine());

			checkVoid($3, line_count,"Void cannot be used in expression");

			if($3->getName()=="error"){
				error_count++;
				fprintf(errorout,"Line# %d: Syntax error at expression of statement\n",$3->getStartLine());							
			}
			else
				fprintf(logout,"statement : IF LPAREN expression RPAREN statement ELSE statement \n");
		}
		| WHILE LPAREN expression RPAREN statement
		{			
			$$=new symbolInfo("statement : WHILE LPAREN expression RPAREN statement", "STMT");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$5);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($5->getEndLine());
	
			checkVoid($3, line_count,"Void cannot be used in expression");

			if($3->getName()=="error"){
				error_count++;
				fprintf(errorout,"Line# %d: Syntax error at expression of statement\n",$3->getStartLine());							
			}
			else
				fprintf(logout,"statement : WHILE LPAREN expression RPAREN statement \n");
		}
		| PRINTLN LPAREN ID RPAREN SEMICOLON
		{			
			$$=new symbolInfo("statement : PRINTLN LPAREN ID RPAREN SEMICOLON", "STMT");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$5);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($5->getEndLine());

			symbolInfo* v=st.lookUp($3->getName());
			
			if(v->getName()==""){
				fprintf(errorout,"Line# %d: Undeclared variable '%s'\n", line_count, $3->getName().c_str());
				error_count++;
			}
			else if(v->isFun()=="decFunc" || v->isFun()=="defFunc" || v->isFun()=="errFunc" || v->isFun()=="array"){
				fprintf(errorout,"Line# %d: '%s' is not a variable\n", line_count, $3->getName().c_str());
				error_count++;
			}
			
			fprintf(logout,"statement : PRINTLN LPAREN ID RPAREN SEMICOLON \n");
		}
		| PRINTLN LPAREN ID RPAREN error setErrSemi
		{	
			$5=demi;		
			$$=new symbolInfo("statement : PRINTLN LPAREN ID RPAREN SEMICOLON", "STMT");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setChild((symbolInfo*)$4);
			$$->setChild((symbolInfo*)$5);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($5->getEndLine());

			symbolInfo* v=st.lookUp($3->getName());
			
			if(v->getName()==""){
				fprintf(errorout,"Line# %d: Undeclared variable '%s'\n", line_count, $3->getName().c_str());
				error_count++;
			}
			else if(v->isFun()=="decFunc" || v->isFun()=="defFunc" || v->isFun()=="errFunc" || v->isFun()=="array"){
				fprintf(errorout,"Line# %d: '%s' is not a variable\n", line_count, $3->getName().c_str());
				error_count++;
			}
			
			error_count++;
			fprintf(errorout,"Line# %d: No semicolon at the end of statement\n", $5->getStartLine());						
		}
		| RETURN expression SEMICOLON
		{			
			$$=new symbolInfo("statement : RETURN expression SEMICOLON", string($2->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->setIdType("RETSTMT");
			
			checkVoid($2, line_count,"Void cannot be used in expression");
			$$->setType($2->getType());

			if($2->isFun()=="testarray"){
				error_count++;
				fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
			}
			
			if($2->getName()=="error"){
				error_count++;
				fprintf(errorout,"Line# %d: Syntax error at expression of return statement\n",$2->getStartLine());							
			}
			else			
				fprintf(logout,"statement : RETURN expression SEMICOLON \n");
		}
		| RETURN expression error setErrSemi
		{		
			$3=demi;	
			$$=new symbolInfo("statement : RETURN expression SEMICOLON", string($2->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->setIdType("RETSTMT");
			
			checkVoid($2, line_count,"Void cannot be used in expression");
			$$->setType($2->getType());
			
			if($2->getName()=="error"){
				error_count++;
				fprintf(errorout,"Line# %d: Syntax error at expression of return statement\n",$2->getStartLine());							
			}
			else			
				fprintf(logout,"statement : RETURN expression SEMICOLON \n");

			if($2->isFun()=="testarray"){
				error_count++;
				fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
			}
			
			error_count++;
			fprintf(errorout,"Line# %d: No semicolon at the end of statement\n", $3->getStartLine());						
		}
		;
	  
expression_statement : SEMICOLON
		{			
			$$=new symbolInfo("expression_statement : SEMICOLON", "EXP");
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			
			fprintf(logout,"expression_statement : SEMICOLON \n");
		}
		| expression SEMICOLON 
		{			
			$$=new symbolInfo("expression_statement : expression SEMICOLON", string($1->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($2->getEndLine());
			//no arr type checking needed
			
			if($1->getName()=="error"){
				error_count++;
				fprintf(errorout,"Line# %d: Syntax error at expression of expression statement\n",$1->getStartLine());							
			}
			else
				fprintf(logout,"expression_statement : expression SEMICOLON \n");
		}
		// | expression error setErrSemi
		// {			
		// 	$2=demi;
		// 	$$=new symbolInfo("expression_statement : expression SEMICOLON", string($1->getType()));
		// 	$$->setChild((symbolInfo*)$1);
		// 	$$->setChild((symbolInfo*)$2);
		// 	$$->setStartLine($1->getStartLine());
		// 	$$->setEndLine($2->getEndLine());
			
		// 	if($1->getName()=="error"){
		// 		error_count++;
		// 		fprintf(errorout,"Line# %d: Syntax error at expression of expression statement\n",$1->getStartLine());							
		// 	}
		// 	else
		// 		fprintf(logout,"expression_statement : expression SEMICOLON \n");
			
		// 	error_count++;
		// 	fprintf(errorout,"Line# %d: No semicolon at the end of expression statement\n", $2->getStartLine());						
		// }
		// | error {$1=createTerminal("error", "expression", line_count); } SEMICOLON
		// {
		// 	$$=new symbolInfo("expression_statement : expression SEMICOLON", string($1->getType()));
		// 	$$->setChild((symbolInfo*)$1);
		// 	$$->setChild((symbolInfo*)$3);
		// 	$$->setStartLine($1->getStartLine());
		// 	$$->setEndLine($3->getEndLine());

		// 	error_count++;
		// 	fprintf(errorout,"Line# %d: Syntax error at expression of expression statement\n",$1->getStartLine());							
		// }
		;
//ok
variable : ID 	
	{
		$$=new symbolInfo("variable : ID", string($1->getType()));
		$$->setChild((symbolInfo*)$1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		fprintf(logout,"variable : ID \n");

		symbolInfo* v=st.lookUp($1->getName());
		$$->setType(v->getType());
		$$->setIdType(v->isFun());

		if(v->getName()==""){
			fprintf(errorout,"Line# %d: Undeclared variable '%s'\n", line_count, $1->getName().c_str());
			error_count++;
			$$->setType("INT");
		}
		else if(v->isFun()=="array"){
			//2 types, in func(a) ok, other a>2 err
			$$->setIdType("testarray");
		}
		else if(v->isFun()=="decFunc" || v->isFun()=="defFunc" || v->isFun()=="errFunc"){
			fprintf(errorout,"Line# %d: '%s' is not a variable\n", line_count, $1->getName().c_str());
			error_count++;
			$$->setIdType(v->isFun());
		}	

	}	
	 | ID LSQUARE expression RSQUARE 
	{
		$$=new symbolInfo("variable : ID LSQUARE expression RSQUARE", string($1->getType()));
		$$->setChild((symbolInfo*)$1);
		$$->setChild((symbolInfo*)$2);
		$$->setChild((symbolInfo*)$3);
		$$->setChild((symbolInfo*)$4);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($4->getEndLine());

		symbolInfo* v=st.lookUp($1->getName());
		$$->setType(v->getType());
		$$->setIdType(v->isFun());

		if(v->getName()==""){
			fprintf(errorout,"Line# %d: Undeclared variable '%s'\n", line_count, $1->getName().c_str());
			error_count++;
			$$->setType("INT");
		}
		else if(v->isFun()!="array"){
			fprintf(errorout,"Line# %d: '%s' is not an array\n", line_count, $1->getName().c_str());
			error_count++;
		}
		else if($3->getType()!="INT"){
			fprintf(errorout,"Line# %d: Array subscript is not an integer\n", line_count);
			error_count++;
		}
		else if($3->getType()=="VOID"){
				checkVoid($3, line_count,"Void cannot be used in expression");
				$$->setType("INT");
		}
		
		if($3->isFun()=="testarray"){
			error_count++;
			fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
		}

		if($3->getName()=="error"){
			error_count++;
			fprintf(errorout,"Line# %d: Syntax error at expression of variable\n",$3->getStartLine());							
		}
		else
			fprintf(logout,"variable : ID LSQUARE expression RSQUARE \n");
	}
	 ;
	 
expression 	: logic_expression	
		{
			$$=new symbolInfo("expression : logic_expression", string($1->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->setIdType($1->isFun());
			fprintf(logout,"expression 	: logic_expression \n");
		}
	   | variable ASSIGNOP logic_expression 	
	  	{
			$$=new symbolInfo("expression : variable ASSIGNOP logic_expression", string($1->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());

			if($1->getType()=="VOID" || $3->getType()=="VOID"){
				checkVoidDouble($1, $3, line_count,"Void cannot be used in expression");
				$$->setType($1->getType());
			}
			//Float is set in the vari after finding the type of ID
			else if($1->getType()=="INT" && $3->getType()=="FLOAT"){
				fprintf(errorout,"Line# %d: Warning: possible loss of data in assignment of FLOAT to INT\n", line_count);
				error_count++;
				$1->setType("FLOAT");
				$$->setType("FLOAT");
			}
			else if(($1->getType()=="FLOAT" || $1->getType()=="INT") && ($3->getType()=="INT" || $3->getType()=="FLOAT")){
			}
			else{
				fprintf(errorout,"Line# %d: Inconsistant type for assignment\n", line_count);
				error_count++;
			}

			if($1->isFun()=="testarray" && $3->isFun()=="testarray"){

			}
			else if($1->isFun()=="testarray"){
				error_count++;
				fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
			}
			else if($3->isFun()=="testarray"){
				error_count++;
				fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
			}

			//3=a; err, 3=fun; err, a=f(); err, recover done

			fprintf(logout,"expression 	: variable ASSIGNOP logic_expression \n");
		}
		| error
		{
			$$=createTerminal("error", "expression", line_count);
		}
	   ;
			
logic_expression : rel_expression 
		{
			$$=new symbolInfo("logic_expression : rel_expression", string($1->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->setIdType($1->isFun());
			fprintf(logout,"logic_expression : rel_expression \n");
		}
		| rel_expression LOGICOP rel_expression 
		{
			$$=new symbolInfo("logic_expression : rel_expression LOGICOP rel_expression", "INT");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());

			checkVoidDouble($1, $3, line_count,"Void cannot be used in expression");
			//type checking
			if($1->isFun()=="testarray"){
				error_count++;
				fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
			}
			else if($3->isFun()=="testarray"){
				error_count++;
				fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
			}

			fprintf(logout,"logic_expression : rel_expression LOGICOP rel_expression \n");
		}	
		;
			
rel_expression	: simple_expression 
		{
			$$=new symbolInfo("rel_expression : simple_expression", string($1->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->setIdType($1->isFun());
			fprintf(logout,"rel_expression	: simple_expression \n");
		}
		| simple_expression RELOP simple_expression	
		{
			$$=new symbolInfo("rel_expression : simple_expression RELOP simple_expression", "INT");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());

			checkVoidDouble($1, $3, line_count,"Void cannot be used in expression");
		
			//type checking
			if($1->isFun()=="testarray"){
				error_count++;
				fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
			}
			else if($3->isFun()=="testarray"){
				error_count++;
				fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
			}

			fprintf(logout,"rel_expression	: simple_expression RELOP simple_expression \n");
		}
		;
				
simple_expression : term 
		{
			$$=new symbolInfo("simple_expression : term", string($1->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->setIdType($1->isFun());
			fprintf(logout,"simple_expression : term \n");
		}
		| simple_expression ADDOP term 
		{
			$$=new symbolInfo("simple_expression : simple_expression ADDOP term", "");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setChild((symbolInfo*)$3);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());

			checkVoidDouble($1, $3, line_count,"Void cannot be used in expression");

			//type cast
			$$->setType($1->getType());
			if($1->getType()=="FLOAT")
					$$->setType("FLOAT");
			if($3->getType()=="FLOAT")
				$3->setType("FLOAT");

			if($1->isFun()=="testarray"){
				error_count++;
				fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
			}
			else if($3->isFun()=="testarray"){
				error_count++;
				fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
			}

			fprintf(logout,"simple_expression : simple_expression ADDOP term \n");
		}
		;
//div by zero!!!
term :	unary_expression
	{
		$$=new symbolInfo("term : unary_expression", string($1->getType()));
		$$->setChild((symbolInfo*)$1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		$$->setIdType($1->isFun());
		fprintf(logout,"term :	unary_expression \n");

		if($1->getType()=="0"){
				$$->setType("INT");
		}
	}
	|  term MULOP unary_expression
	{
		$$=new symbolInfo("term : term MULOP unary_expression", "");
		$$->setChild((symbolInfo*)$1);
		$$->setChild((symbolInfo*)$2);
		$$->setChild((symbolInfo*)$3);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($3->getEndLine());
		
		checkVoidDouble($1, $3, line_count,"Void cannot be used in expression");
		$$->setType($1->getType());
		
		if($3->getType()=="FLOAT")
			$$->setType("FLOAT");
		
		if($2->getName()=="%"){
			if($3->getType()=="0"){
				fprintf(errorout,"Line# %d: Warning: division by zero\n", line_count);
				error_count++;
				$$->setType("INT");
			}
			else if($1->getType()!="INT" || $3->getType()!="INT"){
				fprintf(errorout,"Line# %d: Operands of modulus must be integers\n", line_count);
				error_count++;
				$$->setType("INT");
			}
			
		}
		else if($2->getName()=="/"){
			//div by 0
			if($3->getType()=="0"){
				fprintf(errorout,"Line# %d: Warning: division by zero\n", line_count);
				error_count++;
				$$->setType("INT");
			}
		}

		if($3->isFun()=="testarray"){
			error_count++;
			fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
		}
		else if($1->isFun()=="testarray"){
			error_count++;
			fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
		}

		fprintf(logout,"term :	term MULOP unary_expression \n");
	}
	;

unary_expression : ADDOP unary_expression 
		{
			$$=new symbolInfo("unary_expression : ADDOP unary_expression", string($2->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($2->getEndLine());
			fprintf(logout,"unary_expression : ADDOP unary_expression \n");

			checkVoid($2,line_count, "Void cannot be used in expression");
			if($2->isFun()=="testarray"){
				error_count++;
				fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
			}
			$$->setType($2->getType());
		}
		| NOT unary_expression 
		{
			$$=new symbolInfo("unary_expression : NOT unary_expression", "INT");
			$$->setChild((symbolInfo*)$1);
			$$->setChild((symbolInfo*)$2);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($2->getEndLine());
			fprintf(logout,"unary_expression : NOT unary_expression \n");

			checkVoid($2,line_count, "Void cannot be used in expression");
			if($2->isFun()=="testarray"){
				error_count++;
				fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
			}

		}
		| factor 
		{
			$$=new symbolInfo("unary_expression : factor", string($1->getType()));
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->setIdType($1->isFun());
			fprintf(logout,"unary_expression : factor \n");
		}
		;
	//func ret type mismatch handled above //factor can not be void handled //func();<- void :it's ok
factor	: variable 
	{
		$$=new symbolInfo("factor : variable", string($1->getType()));
		$$->setChild((symbolInfo*)$1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		$$->setIdType($1->isFun());
		fprintf(logout,"factor	: variable \n");
	}
	| ID LPAREN argument_list RPAREN
	{
		$$=new symbolInfo("factor : ID LPAREN argument_list RPAREN", string($1->getType()));
		//fix line
		if($3->getStartLine()==0){
			$3->setStartLine($2->getEndLine());
		}
		if($3->getEndLine()==0){
			$3->setEndLine($4->getStartLine());
		}

		$$->setChild((symbolInfo*)$1);
		$$->setChild((symbolInfo*)$2);
		$$->setChild((symbolInfo*)$3);
		$$->setChild((symbolInfo*)$4);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($4->getEndLine());
		
		fprintf(logout,"factor	: ID LPAREN argument_list RPAREN \n");
		symbolInfo* sym=st.lookUp($1->getName());
		$$->setType(sym->getType());
		$$->setIdType(sym->isFun());

		if(sym->getName()==""){
			fprintf(errorout,"Line# %d: Undeclared function '%s'\n", line_count, $1->getName().c_str());
			error_count++;
			$$->setType("INT");
		}
		else if(sym->isFun()=="array"){
			fprintf(errorout,"Line# %d: '%s' is not a function\n", line_count, $1->getName().c_str());
			error_count++;
		}
		else if(sym->isFun()=="decFunc" || sym->isFun()=="errFunc"){
			fprintf(errorout,"Line# %d: Undefined function '%s'\n", line_count, $1->getName().c_str());
			error_count++;
			$$->setType("INT");	
		}
		else if(sym->isFun()=="defFunc"){
			//arg
			vector<pair<string, string> > alist = sym->getParam();
			if(sym->getParaCount()>argList.size()){
				fprintf(errorout,"Line# %d: Too few arguments to function '%s'\n", line_count, $1->getName().c_str());
				error_count++;
			}
			else if(sym->getParaCount()<argList.size()){
				fprintf(errorout,"Line# %d: Too many arguments to function '%s'\n", line_count, $1->getName().c_str());
				error_count++;
			}
			else{
				for(int i=0; i<sym->getParaCount(); i++){
					//void checking done in arguments
					//general type mismatch-given test case
					if(alist[i+1].second != argList[i].second){
						fprintf(errorout,"Line# %d: Type mismatch for argument %d of '%s'\n", line_count, (i+1), $1->getName().c_str());
						error_count++;
					}
					//only float
					// if(alist[i+1].second=="INT" && argList[i].second=="FLOAT"){
					// 	fprintf(errorout,"Line# %d: Type mismatch for argument %d of '%s'\n", line_count, (i+1), $1->getName().c_str());
					//  	error_count++;
					// }
				}
			}
		}
		else{
			fprintf(errorout,"Line# %d: '%s' is not a function\n", line_count, $1->getName().c_str());
			error_count++;
		}

		argList.clear();
	}
	| LPAREN expression RPAREN
	{//vari is arr? need checking ? may be not...
		$$=new symbolInfo("factor : LPAREN expression RPAREN", string($2->getType()));
		$$->setChild((symbolInfo*)$1);
		$$->setChild((symbolInfo*)$2);
		$$->setChild((symbolInfo*)$3);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($3->getEndLine());

		if($2->getName()=="error"){
			error_count++;
			fprintf(errorout,"Line# %d: Syntax error at expression of factor\n",$2->getStartLine());							
		}
		else
			fprintf(logout,"factor	: LPAREN expression RPAREN \n");
	}
	| CONST_INT 
	{
		$$=new symbolInfo("factor : CONST_INT", "INT");
		$$->setChild((symbolInfo*)$1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		fprintf(logout,"factor	: CONST_INT \n");
		//div by zero
		if($1->getName()=="0"){
			$$->setType("0");
		}
	}
	| CONST_FLOAT
	{
		$$=new symbolInfo("factor : CONST_FLOAT", "FLOAT");
		$$->setChild((symbolInfo*)$1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		fprintf(logout,"factor	: CONST_FLOAT \n");
	}
	| variable INCOP 
	{
		$$=new symbolInfo("factor : variable INCOP", string($1->getType()));
		$$->setChild((symbolInfo*)$1);
		$$->setChild((symbolInfo*)$2);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());
		fprintf(logout,"factor	: variable INCOP \n");

		symbolInfo* sym = $1->getChild(0);		//the first child of vari is ID

		if(sym->isFun()=="decFUNC" || sym->isFun()=="defFunc" || sym->isFun()=="errFunc"){
			fprintf(errorout,"Line# %d: lvalue required as increment operand\n",line_count);
		}
		else if(sym->isFun()=="testarray"){
			error_count++;
			fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
		}
	}
	| variable DECOP
	{
		$$=new symbolInfo("factor : variable DECOP", string($1->getType()));
		$$->setChild((symbolInfo*)$1);
		$$->setChild((symbolInfo*)$2);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());
		fprintf(logout,"factor	: variable DECOP \n");

		symbolInfo* sym = $1->getChild(0);	

		if(sym->isFun()=="decFUNC" || sym->isFun()=="defFunc" || sym->isFun()=="errFunc"){
			error_count++;
			fprintf(errorout,"Line# %d: lvalue required as increment operand\n",line_count);
		}
		else if(sym->isFun()=="testarray"){
			error_count++;
			fprintf(errorout,"Line# %d: Array index is missing\n", line_count);
		}
	}
	;
//empty arg is handled
argument_list : arguments
			{
				$$=new symbolInfo("argument_list : arguments", "");
				$$->setChild((symbolInfo*)$1);
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($1->getEndLine());
				fprintf(logout,"argument_list : arguments \n");
			}
			|
			{
				$$=new symbolInfo("argument_list :", "");
				fprintf(logout,"argument_list :  \n");
			}
			;
	//about void think think...done
arguments : arguments COMMA logic_expression
			{
				$$=new symbolInfo("arguments : arguments COMMA logic_expression", "");
				$$->setChild((symbolInfo*)$1);
				$$->setChild((symbolInfo*)$2);
				$$->setChild((symbolInfo*)$3);
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($3->getEndLine());
				fprintf(logout,"arguments : arguments COMMA logic_expression \n");

				checkVoid($3,line_count, "Void cannot be used in expression(arg)");

				pair<string, string> p={"arg",string($3->getType())};
				argList.push_back(p);
			}
			| logic_expression
			{
				$$=new symbolInfo("arguments : logic_expression", "");
				$$->setChild((symbolInfo*)$1);
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($1->getEndLine());
				fprintf(logout,"arguments : logic_expression \n");

				checkVoid($1,line_count, "Void cannot be used in expression(arg)");

				pair<string, string> p={"arg",string($1->getType())};
				argList.push_back(p);
			}
			;
 

%%
int main(int argc, char** argv) {	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}	
	
	logout= fopen("1905108_log.txt","w");
	errorout= fopen("1905108_error.txt","w");
	parseout= fopen("1905108_parseTree.txt","w");
	
	yyin= fin;
	yyparse();
    
	// st.printAll(logout);
	// st.exitRootScope();
	fprintf(logout,"Total Lines: %d\n",line_count);
    fprintf(logout,"Total Errors: %d\n",error_count);
	
	fclose(yyin);
	fclose(errorout);
	fclose(logout);
	fclose(parseout);
	return 0;
}

/*
cases handled-

function dec-
uniqueness, between func and also among other sym
has declaration or not
has definition or not before calling
scope checking

func call-
return type check, arg mismatch
dec or not 
is func or not
def is consistent with dec or not

excluding pre-processing directives

variable dec-
scope

variable call-
scope
dec or not
is arr or var


ambiguity handled

type checking-
in assign, logic, add, mul, fun
arr index is int or not
operand of modulus is int
void func call as exp
non-fun is called as fun or not

type conv-
asgn, relop, logicop

uniqueness-
multimple dec of var, func in same scope

arr have ind or not

--------------
error-

vari can not be arr, func
a[2]=3 ok
a/0 not possible
a%0 not possible
type conversion in add, mul, fun parameter
type conversion in assignment
array ind checking
f(arr); ok
and given in test cases


--------------
err recover-

given in test cases

f()=2 not possible
3=f not possible
a[] not possible, vice versa
a[3], a=3 not possible
a>3 not possible
if f(), f not possible
s()<2 .. ok
2<s() .. ok
a[1]<2 ..ok
a[2]<s() .. ok
2&&3 .. ok and others

func returing must have return stmt
void fun can not have return stmt
return type mismatch in return stmt

print(a)->a is not arr, fun
return f-> f is not fun..return f();
void fun can't be used in return stmt
out of scope func not possible F(){f()}
out of scope stmt not possible { } a=3;
SEMICOLON checking
expression can not be void
erronious expression
void checking
f(;;) ok as per c standard
...
...
*/