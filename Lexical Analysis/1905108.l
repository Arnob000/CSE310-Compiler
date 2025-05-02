%option noyywrap

%x STATE1
%x STATE11
%x STATE2
%x STATE22
%x STATE3
%x STATE33

%{
#include<cstdio>
#include<cstdlib>
#include<string>
#include<vector>
#include "1905108_SymbolTable.cpp"

using namespace std;

int line_count=1;
int error_count=0;
int lstart=0;
bool flag=true;
symbolTable st(10);
string str="";
string stok="";

FILE *logout;
FILE *tokenout;

string up(char* text){
    string s="";
    int i=0;
    while((text[i]>='A' && text[i]<='Z') || (text[i]>='a' && text[i]<='z')){
        s+=char(toupper(text[i]));
        i++;
    }
    return s;
}

%}

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE \n

%%

{NEWLINE} {line_count++;}
{WHITESPACE}+ {}

(if|for|do|int|float|void|switch|default|else|while|break|char|double|return|case|continue)	{
        fprintf(tokenout,"<%s, %s>\n",up(yytext).c_str(),yytext);
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        }

{DIGIT}+ 	{
        fprintf(tokenout,"<CONST_INT, %s>\n",yytext);
        fprintf(logout,"Line# %d: Token <CONST_INT> Lexeme %s found\n",line_count,yytext);
        }

{DIGIT}*\.?{DIGIT}+(E[+-]?{DIGIT}+)? 	{
        fprintf(tokenout,"<CONST_FLOAT, %s>\n",yytext);
        fprintf(logout,"Line# %d: Token <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);		
        }

[']     {        
        error_count++;
        fprintf(logout,"Error at line# %d: UNFINISHED_CONST_CHAR %s\n",line_count,yytext);
        }

['][']  {
		error_count++;
		fprintf(logout,"Error at line# %d: EMPTY_CONST_CHAR %s\n",line_count,yytext);						
        }

[']\\\'[']  {
        fprintf(tokenout,"<CONST_CHAR, '>\n");
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme ' found\n",line_count);	        
        }

[']\\\"['] {
        fprintf(tokenout,"<CONST_CHAR, \">\n");
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \" found\n",line_count);        
        }

[']\\n[']  {
        fprintf(tokenout,"<CONST_CHAR, \n>\n");
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \n found\n",line_count);        
        }

[']\\t[']  {
        fprintf(tokenout,"<CONST_CHAR, \t>\n");
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \t found\n",line_count);        
        }

[']\\\\['] {
        fprintf(tokenout,"<CONST_CHAR, \\>\n");
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \\ found\n",line_count);        
        }

[']\\a[']  {
        fprintf(tokenout,"<CONST_CHAR, \a>\n");
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \a found\n",line_count);        
        }

[']\\f[']  {
        fprintf(tokenout,"<CONST_CHAR, %c>\n",'\f');
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \f found\n",line_count);
        }

[']\\r[']  {
        fprintf(tokenout,"<CONST_CHAR, \r>\n");
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \r found\n",line_count);        
        }

[']\\b[']  {
        fprintf(tokenout,"<CONST_CHAR, %c>\n",'\b');
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \b found\n",line_count);
        }

[']\\v[']  {
        fprintf(tokenout,"<CONST_CHAR, %c>\n",'\v');
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme %c found\n",line_count,'\v');        
        }

[']\\0[']  {
        stok+="\0";
        fprintf(tokenout,"<CONST_CHAR, %s>\n",stok.c_str());
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme %s found\n",line_count,stok.c_str());
        stok="";
        }

[']\\[']   {
        error_count++;
        fprintf(logout,"Error at line# %d: UNFINISHED_CONST_CHAR %s\n",line_count,yytext);
        }

['].[']    {
        str+=yytext[1];
        fprintf(tokenout,"<CONST_CHAR, %s>\n",str.c_str());
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme %s found\n",line_count,str.c_str());
        str="";
        }

[']..*[']  {
        error_count++;
        fprintf(logout,"Error at line# %d: MULTICHAR_CONST_CHAR %s\n",line_count,yytext);        
        }

['][^;]    {        
        error_count++;
        fprintf(logout,"Error at line# %d: UNFINISHED_CONST_CHAR %s\n",line_count,yytext);
        }

"+"|"-"		    {
			fprintf(tokenout,"<ADDOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <ADDOP> Lexeme %s found\n",line_count,yytext);
		}

"*"|"/"|"%"		{
			fprintf(tokenout,"<MULOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <MULOP> Lexeme %s found\n",line_count,yytext);
		}


"++"|"--"		{
			fprintf(tokenout,"<INCOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <INCOP> Lexeme %s found\n",line_count,yytext);
		}

"<"|"<="|">"|">="|"=="|"!="		{
			fprintf(tokenout,"<RELOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <RELOP> Lexeme %s found\n",line_count,yytext);
		}			

"="	    {
			fprintf(tokenout,"<ASSIGNOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <ASSIGNOP> Lexeme %s found\n",line_count,yytext);
		}	

"&&"	{
			fprintf(tokenout,"<LOGICOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <LOGICOP> Lexeme %s found\n",line_count,yytext);
		}	

"||"	{
			fprintf(tokenout,"<LOGICOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <LOGICOP> Lexeme %s found\n",line_count,yytext);
		}	

"&"|"^"|"<<"|">>"		{
			fprintf(tokenout,"<BITOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <BITOP> Lexeme %s found\n",line_count,yytext);
		}


"|" 	{
			fprintf(tokenout,"<BITOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <BITOP> Lexeme %s found\n",line_count,yytext);
		}

"!"	    {
			fprintf(tokenout,"<NOT, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <NOTOP> Lexeme %s found\n",line_count,yytext);
		}

"("	    {
			fprintf(tokenout,"<LPAREN, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <LPAREN> Lexeme %s found\n",line_count,yytext);
		}		

")"	    {
			fprintf(tokenout,"<RPAREN, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <RPAREN> Lexeme %s found\n",line_count,yytext);
		}	

"{"	    {
			fprintf(tokenout,"<LCURL, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <LCURL> Lexeme %s found\n",line_count,yytext);
            st.enterScope();
        }		

"}"	    {
			fprintf(tokenout,"<RCURL, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <RCURL> Lexeme %s found\n",line_count,yytext);
            st.exitScope();
        }	

"["	    {
			fprintf(tokenout,"<LSQUARE, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <LSQUARE> Lexeme %s found\n",line_count,yytext);
		}		

"]"	    {
			fprintf(tokenout,"<RSQUARE, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <RSQUARE> Lexeme %s found\n",line_count,yytext);
		}	

"," 	{
			fprintf(tokenout,"<COMMA, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <COMMA> Lexeme %s found\n",line_count,yytext);
		}		

";"	    {
			fprintf(tokenout,"<SEMICOLON, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <SEMICOLON> Lexeme %s found\n",line_count,yytext);
		}	

({LETTER}|"_")({LETTER}|{DIGIT}|"_")*   {
            fprintf(tokenout,"<ID, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <ID> Lexeme %s found\n",line_count,yytext);
            bool b=st.Insert(string(yytext),"ID");
            if(b)
                st.printAll(logout);
            else{
                fprintf(logout,"\t%s already exisits in the current ScopeTable\n",yytext);	
            }
        }

{DIGIT}+({LETTER}|{DIGIT}|"_")*   {  
			error_count++;         
			fprintf(logout,"Error at line# %d: INVALID_ID_SUFFIX_NUM_PREFIX %s\n",line_count,yytext);
        }


["] {
	BEGIN STATE3;
	str="";
    stok="";
	str+=yytext;
	lstart=line_count;
    flag=true;
}

<STATE3>["] {
    str+=yytext;
    if(flag){
        fprintf(tokenout,"<SINGLE LINE STRING, %s>\n",stok.c_str());
        fprintf(logout,"Line# %d: Token <SINGLE LINE STRING> Lexeme %s found\n",lstart,str.c_str());
    }
    else{
        fprintf(tokenout,"<MULTI LINE STRING, %s>\n",stok.c_str());
        fprintf(logout,"Line# %d: Token <MULTI LINE STRING> Lexeme %s found\n",lstart,str.c_str());
    }
    str="";
    stok="";
    BEGIN INITIAL;
}

<STATE3>{NEWLINE} {
	error_count++;
	str+=yytext;
	fprintf(logout,"Error at line# %d: UNFINISHED_STRING %s",line_count,str.c_str());
	BEGIN INITIAL;
	line_count++;
}

<STATE3><<EOF>> {
	error_count++;
	str+="\n";
	fprintf(logout,"Error at line# %d: UNFINISHED_STRING %s",line_count,str.c_str());
	BEGIN INITIAL;
}

<STATE3>"\\" {
	str+=yytext;
	BEGIN STATE33;
}

<STATE3>[^\n\r] {
	str+=yytext;
    stok+=yytext;
}

<STATE33>{NEWLINE} {
    flag=false;
	line_count++;
	str+=yytext;
    stok+="";
	BEGIN STATE3;
}

<STATE33>"t" {
    str+="t";
    stok+="\t";
    BEGIN STATE3;
}

<STATE33>"n" {
    str+="n";
    stok+="\n";
    BEGIN STATE3;
}

<STATE33>"\"" {
    str+="\"";
    stok+="\"";
    BEGIN STATE3;
}

<STATE33>"a" {
    str+="a";
    stok+="\a";
    BEGIN STATE3;
}

<STATE33>"f" {
    str+="f";
    stok+="\f";
    BEGIN STATE3;
}

<STATE33>"r" {
    str+="r";
    stok+="\r";
    BEGIN STATE3;
}

<STATE33>"b" {
    str+="b";
    stok+="\b";
    BEGIN STATE3;
}

<STATE33>"v" {
    str+="v";
    stok+="\v";
    BEGIN STATE3;
}

<STATE33>"0" {
    str+="0";
    stok+="\0";
    BEGIN STATE3;
}

<STATE33>"\\" {
    stok+=yytext;
	str+=yytext;
}

<STATE33>[^\n\r] {
	str+=yytext;
    stok+=yytext;
	BEGIN STATE3;
}


"//" {
    BEGIN STATE1;
    fprintf(logout,"Line# %d: Token <SINGLE LINE COMMENT> Lexeme %s",line_count,yytext);
}

<STATE1>{NEWLINE} {
    line_count++;
    fprintf(logout," found\n");
    BEGIN INITIAL;
}
<STATE1><<EOF>> {
    fprintf(logout," found\n");
    BEGIN INITIAL;
}

<STATE1>"\\" {
	fprintf(logout,"%s",yytext);
	BEGIN STATE11;
}

<STATE1>[^\n\r] {fprintf(logout,"%s",yytext);}


<STATE11>{NEWLINE} {
	line_count++;
    fprintf(logout,"%s",yytext);
    BEGIN STATE1;
}

<STATE11><<EOF>> {
    fprintf(logout," found\n");
    BEGIN INITIAL;
}

<STATE11>"\\" {
    fprintf(logout,"%s",yytext);
}

<STATE11>[^\n\r] {
    fprintf(logout,"%s",yytext);
    BEGIN STATE1;
}


"/*" {
		BEGIN STATE2;
		str=""; 
		str+=yytext;
		lstart=line_count;
}

<STATE2>{NEWLINE} {
        line_count++;
        str+="\n";
}

<STATE2>"*"	{
        BEGIN STATE22;
        str+=yytext;
}

<STATE2>[^*]  {
	    str+=yytext;
}

<STATE2><<EOF>> {
        error_count++;
        fprintf(logout,"Error at line# %d: UNFINISHED_COMMENT %s\n",line_count, str.c_str());
        BEGIN INITIAL;
}

<STATE22>"/" {
			str+=yytext;
			fprintf(logout,"Line# %d: Token <MULTI LINE COMMENT> Lexeme %s found\n",lstart, str.c_str());
			BEGIN INITIAL;
}

<STATE22>{NEWLINE} {
    line_count++;
    str+=yytext;
	BEGIN STATE2;
}

<STATE22>"*" {
		str+=yytext;
}

<STATE22>[^/] {
			str+=yytext;
			BEGIN STATE2;
}

<STATE22><<EOF>> {
			error_count++;
			fprintf(logout,"Error at line# %d: UNFINISHED_COMMENT %s\n",line_count, str.c_str());
			BEGIN INITIAL;
}

. {
	error_count++;
	fprintf(logout,"Error at line# %d: UNRECOGNIZED_CHAR %s\n",line_count, yytext);
}  

{DIGIT}*\.?{DIGIT}+(E[+-]?{DIGIT}*)\.+({DIGIT}|\.)* 	{
				error_count++;
				fprintf(logout,"Error at line# %d: ILLFORMED_NUMBER %s\n",line_count,yytext);
}

({DIGIT}|\.)+(E[+-]?({DIGIT}|\.)*)? 	{
				error_count++;
				fprintf(logout,"Error at line# %d: TOO_MANY_DECIMAL_POINTS %s\n",line_count,yytext);
}



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
	tokenout= fopen("1905108_token.txt","w");

	yyin= fin;
	yylex();
    st.printAll(logout);
	fprintf(logout,"Total lines: %d\n",line_count);
    fprintf(logout,"Total errors: %d\n",error_count);
	fclose(yyin);
	fclose(tokenout);
	fclose(logout);
	return 0;
}