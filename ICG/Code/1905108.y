%{
#include<bits/stdc++.h>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include "1905108_SymbolTable.h"
#include "1905108_Asm.cpp"
#define YYSTYPE symbolInfo*


using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

int line_count=1;
int error_count=0;
int prevOffset=0;

FILE *logout;
FILE *errorout;
FILE *parseout;
FILE *temp_asm;
FILE *asmout;

symbolTable st(11);
symbolTable demo(5);
symbolInfo* demi;
vector<symbolInfo*> varList;
vector<pair<string,string> > paraList;
vector<pair<string,string> > argList;
vector<symbolInfo*> globalList;


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
				printParseTree(lst[i], space+1);
			}
			node->clearChild();
		}
		
	}
	
}

void initFunDef(string fName, string fType){			
		//setting up function scope
		//asm
		prevOffset=0;
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
		//asm
		symbolInfo* para;		
		prevOffset=0;

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
						//asm
						para=st.lookUp(paraList[i].first);
						para->setIdType("arg");
						para->setOffset(12+(i*2));			
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
					if(flag==false){
						sym->insertParam(paraList[i-1].first, funPara[i].second, i);
						//asm
						para=st.lookUp(paraList[i-1].first);
						para->setIdType("arg");
						para->setOffset(12+((i-1)*2));
					}
				}
				if(paraList.size()>len){
					for(int i=len; i<paraList.size(); i++){
						st.Insert(paraList[i-1].first, paraList[i-1].second); //redef or not?
					
						//asm
						para=st.lookUp(paraList[i-1].first);
						para->setIdType("arg");
						para->setOffset(12+((i-1)*2));
					}
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

				for(int i=0; i<paraList.size(); i++)	//arg lage na
						bool t=st.Insert(paraList[i].first, paraList[i].second);
					
			}
			else{
				fprintf(errorout,"Line# %d: '%s' redeclared as different kind of symbol\n",line_count,fName.c_str());
				error_count++;
				for(int i=0; i<paraList.size(); i++)	//arg lage na
						bool t=st.Insert(paraList[i].first, paraList[i].second);
					
			}
		}

		paraList.clear();
}

//asm functions

int labelCount=0;
int tempCount=0;
int globalOffset=0;
bool localVari=false;
string funName;
string lret;

string newLabel()
{
	string label;
	char *lb= new char[4];
	strcpy(lb,"    ");
	strcpy(lb,"L");
	char b[3];
	sprintf(b,"%d", labelCount);
	labelCount++;
	strcat(lb,b);
	label=lb;
	return label;
}

string newTemp()
{
	string temp;
	char *t= new char[4];
	strcpy(t,"T");
	char b[3];
	sprintf(b,"%d", tempCount);
	tempCount++;
	strcat(t,b);
	temp=t;
	return temp;
}

void basicAsm(FILE* temp_asm){
    fprintf(temp_asm,".MODEL SMALL\n.STACK 1000H\n.Data\n");
    fprintf(temp_asm,"\tCR EQU 0DH\n\tLF EQU 0AH\n\tnumber DB \"00000$\"\n");
	for(int i=0; i<globalList.size(); i++){
		if(globalList[i]->isFun()=="array"){
			fprintf(temp_asm,"\t%s DW %d DUP (0000H)\n", globalList[i]->getName().c_str(),globalList[i]->getArrSize());
		}
		else
        	fprintf(temp_asm,"\t%s DW 1 DUP (0000H)\n", globalList[i]->getName().c_str());
    }
	// fclose(asmout);	//prob
	// asmout=fopen("1905108_asm.asm","r");
	// char ch='0';
	// while(ch!=EOF){
	// 	ch=fgetc(asmout);
	// 	fprintf(temp_asm,"%c",ch);
	// 	printf("%c",ch);
	// }
    fprintf(temp_asm,".CODE\n");
}

void finalAsm(FILE* temp_asm){
    fprintf(temp_asm,"END main\n");
}

void newLine(FILE* temp_asm){
    fprintf(temp_asm, "new_line PROC\n\tPUSH AX\n\tPUSH DX\n\tMOV AH , 2\n");
    fprintf(temp_asm,"\tMOV dl , cr\n\tINT 21h\n\tMOV AH , 2\n\tMOV dl , lf\n");
    fprintf(temp_asm,"\tINT 21h\n\tPOP DX\n\tPOP AX\n\tRET\nnew_line ENDP\n\n");  
}

void printLn(FILE* temp_asm){
    fprintf(temp_asm,"print_output PROC  ;print what is in ax\n\tPUSH AX\n\tPUSH BX\n");
    fprintf(temp_asm,"\tPUSH CX\n\tPUSH DX\n\tPUSH SI\n\tLEA SI , number\n\tMOV BX , 10\n");
    fprintf(temp_asm,"\tADD SI , 4\n\tCMP AX , 0\n\tJNGE negate\nprint:\n\tXOR DX , DX\n\tDIV BX\n\tMOV [SI] , dl\n");
    fprintf(temp_asm,"\tADD [SI], '0'\n\tDEC SI\n\tCMP AX , 0\n\tJNE print\n\tINC SI\n\tLEA DX , SI\n\tMOV AH , 9\n\tINT 21h\n\tPOP SI\n");
    fprintf(temp_asm,"\tPOP DX\n\tPOP CX\n\tPOP BX\n\tPOP AX\n\tRET\nnegate:\n\tPUSH AX\n\tMOV AH , 2\n\tMOV dl , '-'\n\tINT 21h\n\tPOP AX\n");
    fprintf(temp_asm,"\tNEG AX\n\tJMP print\nprint_output ENDP\n");
}

void genarateAsmCode(symbolInfo* node){
	vector<symbolInfo*> lst;
	lst=node->getChildList();
	string labl;
	
	if(node->getName()=="start : program"){
		basicAsm(temp_asm);
		for(int i=0; i<lst.size(); i++){
			genarateAsmCode(lst[i]);
		}		
		newLine(temp_asm);
		printLn(temp_asm);
    	finalAsm(temp_asm);
	}

	else if(node->getName()=="func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement"){
		globalOffset=0;
		fprintf(temp_asm,";line: %d--function\n%s PROC\n",lst[0]->getStartLine(), lst[1]->getName().c_str());
		funName=lst[1]->getName();
		lret=newLabel();

		if(lst[1]->getName()=="main"){
			fprintf(temp_asm,"\tMOV AX , @DATA\n\tMOV DS ,  AX\n");
		}
		else{
			fprintf(temp_asm,"\tPUSH AX\n\tPUSH BX\n\tPUSH CX\n\tPUSH SI\n");
		}

		fprintf(temp_asm,"\tPUSH BP\n\tMOV BP , SP\n");
				
		for(int i=0; i<lst.size(); i++){
			genarateAsmCode(lst[i]);
		}	
		//some fix is done
		//change is done here, globaloff and lret
		fprintf(temp_asm,"%s:\n\tADD SP , %d\n",lret.c_str(), globalOffset);
	 	globalOffset=0;
		//
		fprintf(temp_asm,"\tPOP BP\n");

		if(lst[1]->getName()=="main"){
			fprintf(temp_asm,"\tMOV AH , 4CH\n\tINT 21H\n");
		}
		else{
			fprintf(temp_asm,"\tPOP SI\n\tPOP CX\n\tPOP BX\n\tPOP AX\n\tRET\n");
		}

		fprintf(temp_asm,"%s ENDP\n\n",lst[1]->getName().c_str());

	}

	else if(node->getName()=="func_definition : type_specifier ID LPAREN RPAREN compound_statement"){
		globalOffset=0;
		fprintf(temp_asm,";line: %d--function\n%s PROC\n",lst[0]->getStartLine(), lst[1]->getName().c_str());
		funName=lst[1]->getName();
		lret=newLabel();

		if(lst[1]->getName()=="main"){
			fprintf(temp_asm,"\tMOV AX , @DATA\n\tMOV DS , AX\n");
		}	
		else{
			fprintf(temp_asm,"\tPUSH AX\n\tPUSH BX\n\tPUSH CX\n\tPUSH SI\n");
		}

		fprintf(temp_asm,"\tPUSH BP\n\tMOV BP , SP\n");

		for(int i=0; i<lst.size(); i++){
			genarateAsmCode(lst[i]);
		}	
		//some fix is done
		fprintf(temp_asm,"%s:\n\tADD SP , %d\n",lret.c_str(), globalOffset);
		globalOffset=0;
		//
		fprintf(temp_asm,"\tPOP BP\n");

		if(lst[1]->getName()=="main"){
			fprintf(temp_asm,"\tMOV AH , 4CH\n\tINT 21H\n");
		}
		else{
			fprintf(temp_asm,"\tPOP SI\n\tPOP CX\n\tPOP BX\n\tPOP AX\n\tRET\n");
		}

		fprintf(temp_asm,"%s ENDP\n\n",lst[1]->getName().c_str());

	}

	else if(node->getName()=="declaration_list : declaration_list COMMA ID"){
		genarateAsmCode(lst[0]);
		if(localVari==true){
			if(lst[2]->isFun()!="array"){
				globalOffset+=2;
				// lst[2]->setOffset(globalOffset);
				fprintf(temp_asm,"\tSUB SP , 2\n");
			}
		}
		//debug
		// printf("%s offset:%d\n",lst[2]->getName().c_str(),lst[2]->getOffset());
			
	}

	else if(node->getName()=="declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE"){
		genarateAsmCode(lst[0]);
		if(localVari==true){
			if(lst[2]->isFun()=="array"){
				globalOffset+=lst[2]->getArrSize()*2;
				// lst[2]->setOffset(globalOffset);//may be some fix
				fprintf(temp_asm,"\tSUB SP , %d\n", lst[2]->getArrSize()*2);
			}
			//arr
			//?arr er jonno int a[2],b;
			//now a[2] er jonno sp-4 naki, b er jonno sp-4?
			//curr using for a[2] sp-2,for b  sp-4, kono ekta te save kore ...(prev arrlen=x; sp-prevarrlen);	
		}
		//debug
		// printf("%s offset:%d\n",lst[0]->getName().c_str(),lst[0]->getOffset());	
	}

	else if(node->getName()=="declaration_list : ID"){
		if(localVari==true){
			if(lst[0]->isFun()!="array"){
				globalOffset+=2;//ofset update korte hobe---
				fprintf(temp_asm,"\tSUB SP , 2\n");
			}
		}
		//debug
		// printf("%s offset:%d\n",lst[0]->getName().c_str(),lst[0]->getOffset());		
	}

	else if(node->getName()=="declaration_list : ID LSQUARE CONST_INT RSQUARE"){
		if(localVari==true){
			if(lst[0]->isFun()=="array"){
				globalOffset+=lst[0]->getArrSize()*2;//ofset update korte hobe--
				fprintf(temp_asm,"\tSUB SP , %d\n", lst[0]->getArrSize()*2);
			}
		}
		//debug
		// printf("%s offset:%d\n",lst[0]->getName().c_str(),lst[0]->getOffset());	
	}

	else if(node->getName()=="statement : var_declaration"){
		localVari=true;
		for(int i=0; i<lst.size(); i++){
			genarateAsmCode(lst[i]);
		}
		localVari=false;
	}

	else if(node->getName()=="statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement"){
		//etar code???
		string lBegin=newLabel();
		string lEnd=newLabel();
		genarateAsmCode(lst[2]);
		fprintf(temp_asm,";Line %d: FOR(ES1;ES2;E)S\n%s:\n",lst[0]->getStartLine(), lBegin.c_str());
		genarateAsmCode(lst[3]);
		//2nd expr_stmt true hole stmt or end
		fprintf(temp_asm,"\tCMP CX , 0\n\tJE %s\n",lEnd.c_str());	//changed 
		genarateAsmCode(lst[6]);
		genarateAsmCode(lst[4]);
		fprintf(temp_asm,"\tJMP %s\n",lBegin.c_str());
		fprintf(temp_asm,"%s:\n", lEnd.c_str());

	}

	//IF ELSE, WHILE...
	else if(node->getName()=="statement : IF LPAREN expression RPAREN statement"){
		fprintf(temp_asm,";Line %d: S:if(B)S1\n%s:\n",lst[0]->getStartLine(),newLabel().c_str());
		string lf=newLabel();
		genarateAsmCode(lst[2]);
		fprintf(temp_asm,"\tCMP CX , 0\n\tJE %s\n",lf.c_str());	//c
		genarateAsmCode(lst[4]);
		fprintf(temp_asm,"%s:\n",lf.c_str());
	}

	else if(node->getName()=="statement : IF LPAREN expression RPAREN statement ELSE statement"){
		fprintf(temp_asm,";Line %d: S:if(B)S1 else S2\n%s:\n",lst[0]->getStartLine(),newLabel().c_str());
		string lt=newLabel();
		string lf=newLabel();
		genarateAsmCode(lst[2]);
		fprintf(temp_asm,"\tCMP CX , 0\n\tJE %s\n\n",lf.c_str());
		genarateAsmCode(lst[4]);	//true stmt
		fprintf(temp_asm,"\tJMP %s\n%s:\n",lt.c_str(),lf.c_str());
		genarateAsmCode(lst[6]); 	//false stmt
		fprintf(temp_asm,"%s:\n",lt.c_str());
	}

	else if(node->getName()=="statement : WHILE LPAREN expression RPAREN statement"){
		string lbegin=newLabel();
		string lf=newLabel();
		fprintf(temp_asm,";Line %d: S:while(B)S1\n%s:\n",lst[0]->getStartLine(),lbegin.c_str());
		genarateAsmCode(lst[2]);
		fprintf(temp_asm,"\tCMP CX , 0\n\tJE %s\n\n",lf.c_str());
		genarateAsmCode(lst[4]);	//true stmt
		fprintf(temp_asm,"\tJMP %s\n%s:\n",lbegin.c_str(),lf.c_str());
	}

	else if(node->getName()=="statement : PRINTLN LPAREN ID RPAREN SEMICOLON"){
		if(lst[2]->getOffset()==0){
			fprintf(temp_asm,";Line %d: println\n",lst[0]->getStartLine());
			fprintf(temp_asm,"%s:\n\tMOV AX , %s\n\tCALL print_output\n\tCALL new_line\n",newLabel().c_str(), lst[2]->getName().c_str());
		}
		//arg
		else if(lst[2]->isFun()=="arg"){
			fprintf(temp_asm,";Line %d: println\n",lst[0]->getStartLine());
			fprintf(temp_asm,"%s:\n\tMOV AX , [BP+%d]\n\tCALL print_output\n\tCALL new_line\n",newLabel().c_str(), lst[2]->getOffset());
		}
		else{
			fprintf(temp_asm,";Line %d: println\n",lst[0]->getStartLine());
			fprintf(temp_asm,"%s:\n\tMOV AX , [BP-%d]\n\tCALL print_output\n\tCALL new_line\n",newLabel().c_str(), lst[2]->getOffset());
		}
		//bp+offset e may be halka prob -- global offset use hobe for--bp+2, bp+4 etc...
	}

	else if(node->getName()=="statement : RETURN expression SEMICOLON"){
		if(funName!="main"){
			fprintf(temp_asm,"\t;Line %d: return stmt\n",lst[0]->getStartLine());
			genarateAsmCode(lst[1]);
			fprintf(temp_asm,"\tMOV DX , CX\n\tJMP %s\n",lret.c_str()); //lret
		}
	}

	//arr er jonno ofset er bodole arrsize diye use hobe
	else if(node->getName()=="variable : ID"){
		if(lst[0]->getOffset()==0){
			fprintf(temp_asm,"\tMOV CX , %s\n",lst[0]->getName().c_str()); 
			//for factor =var // etate prob hoy // so->
			//fprintf(temp_asm,"%s",lst[0]->getName().c_str());	//lval handled separately
		}

		//arg
		else if(lst[0]->isFun()=="arg"){
			fprintf(temp_asm,"\tMOV CX , [BP+%d]\n",lst[0]->getOffset());
		}

		else{
			fprintf(temp_asm,"\tMOV CX , [BP-%d]\n",lst[0]->getOffset());
			//fprintf(temp_asm,"[BP-%d]",lst[0]->getOffset());
		}
		//debug
		// printf("%s offset:%d\n",lst[0]->getName().c_str(),lst[0]->getOffset());
			
	}

	else if(node->getName()=="variable : ID LSQUARE expression RSQUARE"){
		genarateAsmCode(lst[2]);
		if(lst[0]->getOffset()==0){
			//global arr;
			fprintf(temp_asm,"\tMOV AX , 2\n\tIMUL CX\n");
			fprintf(temp_asm,"\tMOV BX , SI\n\tADD BX , AX\n\tMOV CX , %s[BX]\n",lst[0]->getName().c_str());
		}//arg lagbe na
		//local arr
		//lst[0]->getOffset() eta holo arr[0] er offset;
		//off arr[d]=arr[0]+d*(2);
		//may be done
		else{
			fprintf(temp_asm,"\tMOV AX , 2\n\tIMUL CX\n\tADD AX , %d\n",lst[0]->getOffset());
			fprintf(temp_asm,"\tMOV BX , BP\n\tSUB BX , AX\n\tMOV CX , [BX]\n");
		}
	}

	else if(node->getName()=="expression : variable ASSIGNOP logic_expression"){
		// assign expr e var er val push korte hoy
		//asgn e var alada vabe handle
		labl=newLabel();
		symbolInfo* varChild=lst[0]->getChild(0);
		fprintf(temp_asm,"%s:\n\t;logic expr\n",labl.c_str());
		genarateAsmCode(lst[2]);

		if(varChild->isFun()!="array"){		//for the time \tPUSH CX\n is not used
			if(varChild->getOffset()==0)
				fprintf(temp_asm,"\t;var=val\n\tMOV %s , CX\n",varChild->getName().c_str());
			else if(varChild->isFun()=="arg")
				fprintf(temp_asm,"\t;arg=val\n\tMOV [BP+%d] , CX\n",varChild->getOffset());	
			else
				fprintf(temp_asm,"\t;var=val\n\tMOV [BP-%d] , CX\n",varChild->getOffset());		
		}

		else if(varChild->isFun()=="array"){ //arr part a[3]=3...			
			if(varChild->getOffset()==0){
				fprintf(temp_asm,"\t;g_arr=val\n\tPUSH CX\n");
				genarateAsmCode(lst[0]);
				fprintf(temp_asm,"\tPOP CX\n\tMOV %s[BX] , CX\n",varChild->getName().c_str());
			}//arg nei
			else{
				fprintf(temp_asm,"\t;arr=val\n\tPUSH CX\n");
				genarateAsmCode(lst[0]);
				fprintf(temp_asm,"\tPOP CX\n\tMOV [BX] , CX\n");
			}		
		}
		//debug
		// printf("%s offset:%d\n",varChild->getName().c_str(),varChild->getOffset());
			
	}

	else if(node->getName()=="logic_expression : rel_expression LOGICOP rel_expression"){
		string label=newLabel();
		genarateAsmCode(lst[0]);
		
		if(lst[1]->getName()=="&&"){
			fprintf(temp_asm,"\tCMP CX , 0\n\tJE %s\n",label.c_str()); //
		}
		else{
			fprintf(temp_asm,"\tCMP CX , 0\n\tJNZ %s\n",label.c_str());
		}
		
		genarateAsmCode(lst[2]);
		fprintf(temp_asm,"%s:\n",label.c_str());
	}

	else if(node->getName()=="rel_expression : simple_expression RELOP simple_expression"){
		string l1=newLabel();
		string l2=newLabel();

		genarateAsmCode(lst[0]);
		fprintf(temp_asm,"\tMOV AX , CX\n");
		genarateAsmCode(lst[2]);
		fprintf(temp_asm,"\tCMP AX , CX\n");

		if(lst[1]->getName()=="<"){
			fprintf(temp_asm,"\tJL %s\n",l1.c_str());
		}
		else if(lst[1]->getName()=="<="){
			fprintf(temp_asm,"\tJLE %s\n",l1.c_str());
		}
		else if(lst[1]->getName()==">"){
			fprintf(temp_asm,"\tJG %s\n",l1.c_str());
		}
		else if(lst[1]->getName()==">="){
			fprintf(temp_asm,"\tJGE %s\n",l1.c_str());
		}
		else if(lst[1]->getName()=="=="){
			fprintf(temp_asm,"\tJE %s\n",l1.c_str());
		}
		else if(lst[1]->getName()=="!="){
			fprintf(temp_asm,"\tJNE %s\n",l1.c_str());
		}

		fprintf(temp_asm,"\tMOV CX , 0\n\tJMP %s\n%s:\n\tMOV CX , 1\n%s:",l2.c_str(),l1.c_str(),l2.c_str());
	}

	else if(node->getName()=="simple_expression : simple_expression ADDOP term"){
		genarateAsmCode(lst[0]);		
		fprintf(temp_asm,"\tPUSH CX\n");
		genarateAsmCode(lst[2]);
		if(lst[1]->getName()=="+"){
			fprintf(temp_asm,"\tPOP AX\n\tADD CX , AX\n");	//can be optimized: (simple exp e AX use hote pare)... ADD CX, AX
		}
		else{
			//can be used as "POPING AX\nSUBTRACTING AX , CX\nMOVING CX , AX" as another form
			fprintf(temp_asm,"\tMOV AX , CX\n\tPOP CX\n\tSUB CX , AX\n"); 
		}
	}

	else if(node->getName()=="term : term MULOP unary_expression"){
		genarateAsmCode(lst[0]);
		fprintf(temp_asm,"\tPUSH CX\n");
		genarateAsmCode(lst[2]);		
		
		if(lst[1]->getName()=="*"){
			fprintf(temp_asm,"\tPOP AX\n\tCWD\n\tIMUL CX\n\tMOV CX , AX\n");	//cwd korte hobe...
		}
		else if(lst[1]->getName()=="/"){
			fprintf(temp_asm,"\tPOP AX\n\tCWD\n\tIDIV CX\n\tMOV CX , AX\n");
		}
		else if(lst[1]->getName()=="%"){
			fprintf(temp_asm,"\tPOP AX\n\tCWD\n\tIDIV CX\n\tMOV CX , DX\n");
		}
	}

	else if(node->getName()=="unary_expression : ADDOP unary_expression"){
		genarateAsmCode(lst[1]);
		if(lst[0]->getName()=="-"){
			fprintf(temp_asm,"\tNEG CX\n"); 
		}
	}

	else if(node->getName()=="unary_expression : NOT unary_expression"){
		string lz=newLabel();
		string lo=newLabel();
		genarateAsmCode(lst[1]);		//(not korle 2's complement hoy)
		fprintf(temp_asm,"\tCMP CX , 0\n\tJE %s\n\tMOV CX , 0\n\tJMP %s\n%s:\n\tMOV CX , 1\n%s:\n",lo.c_str(),lz.c_str(),lo.c_str(),lz.c_str());
		//cmp cx,0\n jne l0\n mov cx,1\n jmp l1\n l0:mov cx,0\nl1:
	}

	else if(node->getName()=="factor : ID LPAREN argument_list RPAREN"){
		genarateAsmCode(lst[2]);
		fprintf(temp_asm,"\tCALL %s\n\tMOV CX , DX\n",lst[0]->getName().c_str());
		fprintf(temp_asm,"\tADD SP , %d\n", lst[2]->getOffset());
		//func er arglist er offset fix : sp+offset
	}

	else if(node->getName()=="factor : CONST_INT"){
		fprintf(temp_asm,"\tMOV CX , %s\n", lst[0]->getName().c_str());
	}

	else if(node->getName()=="factor : CONST_FLOAT"){
		fprintf(temp_asm,"\tMOV CX , %s\n", lst[0]->getName().c_str());
	}

	else if(node->getName()=="factor : variable INCOP"){
		labl=newLabel();
		fprintf(temp_asm,"%s:\n",labl.c_str());
		//local global handle korte hobe
		//id part
		if(lst[0]->getChild(0)->isFun()!="array"){
			if(lst[0]->getChild(0)->getOffset()==0){
				fprintf(temp_asm,"\tMOV CX , %s\n", lst[0]->getChild(0)->getName().c_str());
				fprintf(temp_asm,"\tMOV AX , CX\n\tINC AX\n\tMOV %s , AX\n",lst[0]->getChild(0)->getName().c_str());
			}
			else if(lst[0]->getChild(0)->isFun()=="arg"){
				fprintf(temp_asm,"\tMOV CX , [BP+%d]\n", lst[0]->getChild(0)->getOffset());
				fprintf(temp_asm,"\tMOV AX , CX\n\tINC AX\n\tMOV [BP+%d] , AX\n",lst[0]->getChild(0)->getOffset());
			}
			else{
				fprintf(temp_asm,"\tMOV CX , [BP-%d]\n", lst[0]->getChild(0)->getOffset());
				fprintf(temp_asm,"\tMOV AX , CX\n\tINC AX\n\tMOV [BP-%d] , AX\n",lst[0]->getChild(0)->getOffset());
			}
		}
		//arr part
		else{
			if(lst[0]->getChild(0)->getOffset()==0){
				//global arr
				genarateAsmCode(lst[0]);
				fprintf(temp_asm,"\tMOV AX , CX\n\tINC AX\n\tMOV %s[BX] , AX\n",lst[0]->getChild(0)->getName().c_str());
			}
			else{
				genarateAsmCode(lst[0]);
				fprintf(temp_asm,"\tMOV AX , CX\n\tINC AX\n\tMOV [BX] , AX\n");
			}
		}
	//debug
	// printf("%s offset:%d\n",lst[0]->getChild(0)->getName().c_str(),lst[0]->getChild(0)->getOffset());		
	//inc %s can be used? gen(ls[0]; inc %s; ?)
	}

	else if(node->getName()=="factor : variable DECOP"){
		labl=newLabel();
		fprintf(temp_asm,"%s:\n",labl.c_str());
		
		if(lst[0]->getChild(0)->isFun()!="array"){
			if(lst[0]->getChild(0)->getOffset()==0){
				fprintf(temp_asm,"\tMOV CX , %s\n", lst[0]->getChild(0)->getName().c_str());
				fprintf(temp_asm,"\tMOV AX , CX\n\tDEC AX\n\tMOV %s , AX\n",lst[0]->getChild(0)->getName().c_str());
			}
			else if(lst[0]->getChild(0)->isFun()=="arg"){
				fprintf(temp_asm,"\tMOV CX , [BP+%d]\n", lst[0]->getChild(0)->getOffset());
				fprintf(temp_asm,"\tMOV AX , CX\n\tDEC AX\n\tMOV [BP+%d] , AX\n",lst[0]->getChild(0)->getOffset());
			}
			else{
				fprintf(temp_asm,"\tMOV CX , [BP-%d]\n", lst[0]->getChild(0)->getOffset());
				fprintf(temp_asm,"\tMOV AX , CX\n\tDEC AX\n\tMOV [BP-%d] , AX\n",lst[0]->getChild(0)->getOffset());
			}
		}

		else {
			//cx next stage e use hote pare
			if(lst[0]->getChild(0)->getOffset()==0){
				genarateAsmCode(lst[0]);
				fprintf(temp_asm,"\tMOV AX , CX\n\tDEC AX\n\tMOV %s[BX] , AX\n",lst[0]->getChild(0)->getName().c_str());
			}
			else{
				genarateAsmCode(lst[0]);
				fprintf(temp_asm,"\tMOV AX , CX\n\tDEC AX\n\tMOV [BX] , AX\n");
			}
		}
	}

	else if(node->getName()=="arguments : arguments COMMA logic_expression"){
		genarateAsmCode(lst[2]);
		fprintf(temp_asm,"\tPUSH CX\n");
		genarateAsmCode(lst[0]);		
	}

	else if(node->getName()=="arguments : logic_expression"){
		genarateAsmCode(lst[0]);
		fprintf(temp_asm,"\tPUSH CX\n");
	}
	
	else{
		for(int i=0; i<lst.size(); i++){
			genarateAsmCode(lst[i]);
		}
	}  	
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
		//asm
		if(error_count==0){
			genarateAsmCode((symbolInfo*)$$);
		}

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
						if(paraList[i].first == "type_specifier"){  //fixed here f(int,int)
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
						if(paraList[i].first == "type_specifier"){      //fixed here
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
			prevOffset=0;
		}
		// | type_specifier ID LPAREN parameter_list error setErrNode RPAREN setup {prevOffset=0;} compound_statement
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
			prevOffset=0;
		}
		| type_specifier ID LPAREN error setErrNode RPAREN setup {prevOffset=0;} compound_statement
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
			prevOffset=0;				
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
			$4->setIdType("arg");
			$4->setOffset($1->getOffset()+2);
			$$->setOffset($1->getOffset()+2);
			
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
			$3->setIdType("arg");
			$3->setOffset($1->getOffset()+2);
			$$->setOffset($1->getOffset()+2);

			// pair<string, string> p={string($3->getName()), string($3->getType())};  //after change may be correct
            pair<string, string> p={"type_specifier", string($3->getType())};
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
			$2->setIdType("arg");
			$2->setOffset(4);
			$$->setOffset(4);

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
			$1->setIdType("arg");
			$1->setOffset(4);
			$$->setOffset(4);

			// pair<string, string> p={string($1->getName()), string($1->getType())};  //after change may be correct
            pair<string, string> p={"type_specifier", string($1->getType())};
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
			$$->setOffset($2->getOffset());
			prevOffset=$2->getOffset();

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
						//asm
						sm->copy(varList[i]);
						if(sm->getArrSize()>=0){
							sm->setIdType("array");
							//asm offset
						}//asm
						// else{
						// 	sm->setOffset(2);
						// 	varList[i]->setOffset(2);
						// }
					}
					else if(b==false){
						fprintf(errorout,"Line# %d: Conflicting types for'%s'\n",line_count, varList[i]->getName().c_str());
						error_count++;
					}			
				}
			}
			//asm
		//original
			if(st.lastScopeSerial()==1){
				for(int i=0; i<varList.size(); i++){
					// if(varList[i]->getArrSize()<0)
					// 	varList[i]->setOffset(0);
					globalList.push_back(varList[i]);
				}
			}

			//trial
			// if(st.lastScopeSerial()==1){
			// 	for(int i=0; i<varList.size(); i++){
			// 		fprintf(asmout,"\t%s DW 1 DUP (0000H)\n", varList[i]->getName().c_str());
			// 	}
			// }
			
			//local vari set korte hobe...
			//stack offset is set
			//how to recog local vari,  not sure!
			//isGlobal flag? or sym table num?(1 means global) 
			//keeping global flag : when stmt: var_dec then local var
			

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

			//asm
			if(st.lastScopeSerial()==1){
				$3->setOffset(0);
				$$->setOffset(0);		
			}
			else {
				$3->setOffset(2+$1->getOffset());
				$$->setOffset(2+$1->getOffset());
			}

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
			//asm
			//curr global arr as var
			if(st.lastScopeSerial()==1){
					$3->setOffset(0);
					$$->setOffset(0);			
			}
			else {
				$3->setOffset(2+$1->getOffset());
				$$->setOffset(($3->getArrSize()*2)+$1->getOffset());
			}

			varList.push_back((symbolInfo*)$3);			
			fprintf(logout,"declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE \n");
		}
 		  |ID
		{
			$$=new symbolInfo("declaration_list : ID", "DECLIST");
			$$->setChild((symbolInfo*)$1);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());

			//asm
			if(st.lastScopeSerial()==1){
					$1->setOffset(0);	
					$$->setOffset(0);		
			}
			else {
				$1->setOffset(2+prevOffset);
				$$->setOffset(2+prevOffset);
			}
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
			//asm
			if(st.lastScopeSerial()==1){
					$1->setOffset(0);
					$$->setOffset(0);			
			}
			else {
				$1->setOffset(2+prevOffset);//some confusion--change korlam int a; int b; handle er jonno
				$$->setOffset(($1->getArrSize()*2)+prevOffset);
			}

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
			$3->copy(v);

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
			$3->copy(v);
			
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
		$1->copy(v);
		$$->setOffset(v->getOffset());
//debug
// printf("rule:%s offset:%d\n",v->getName().c_str(),v->getOffset());
// debug
// printf("rule:%s offset:%d\n",$1->getName().c_str(),$1->getOffset());		
			
	

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
		$1->copy(v);
		$$->setOffset(v->getOffset());
//debug
// printf("rule:%s offset:%d\n",v->getName().c_str(),v->getOffset());


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
		// else if(sym->isFun()=="decFunc" || sym->isFun()=="errFunc"){
		// 	fprintf(errorout,"Line# %d: Undefined function '%s'\n", line_count, $1->getName().c_str());
		// 	error_count++;
		// 	$$->setType("INT");	
		// }
        //only checking undec func 
        else if(sym->isFun()=="errFunc"){
			fprintf(errorout,"Line# %d: Undefined function '%s'\n", line_count, $1->getName().c_str());
			error_count++;
			$$->setType("INT");	
		}
		else if(sym->isFun()=="decFunc" || sym->isFun()=="defFunc"){ //some change to accomodate decFunc
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
				$$->setOffset($1->getOffset());
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
				$$->setOffset($1->getOffset()+2);
				$3->setIdType("arg");
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
				$$->setOffset(2);
				$1->setIdType("arg");
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
	
	FILE *fin=fopen(argv[1] , "r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}	
	
	logout= fopen("1905108_log.txt","w");
	errorout= fopen("1905108_error.txt","w");
	parseout= fopen("1905108_parseTree.txt","w");
	asmout= fopen("1905108_optimised_asm.asm","w");
	temp_asm= fopen("1905108_asm.asm","w");
	
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
	fclose(asmout);
	fclose(temp_asm);
	optimizedASM();
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
a[3],  a=3 not possible
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

/*
probs faced----
global done
local var:--done
array--done

local arr '-a[2]' te kaj kore na-- done
k[1]<=k[5] e kaj kore na--done
global arr -lea korlam na... kaj korchhe

int a;
int b;-- done

not handled--offset 2, 2 rakhe global er use!--handled


fun e prob --done
func theke ret hoy na? -- sp te jhamela chilo global offset changer por done

arglist not handled?--done (onek kichu handle korte holo, sp, bp+c, local ar arg diff etc)

f(){
	expr;----ok
}

f(){
	if---ok
}

f(){
	if else--- ok(global offset func e set)
}

f(){
	for---ok
	for--ok
	ret--ok
}

f(){
	for---ok
	while--ok--same reason func e
	ret--ok
}


f(){
	while--ok
	ret--ok
}

f(){
	while--ok
}
--nested loop done
--recurcive func done
f(){
	if return

	return f()
}

optimization-
ADD AX , 0
SUB AX , 0
MUL AX , 1
PUSH AX
POP AX

*/