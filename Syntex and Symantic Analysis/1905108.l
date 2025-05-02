%option noyywrap

%x STATE1
%x STATE11
%x STATE2
%x STATE22
%x STATE3
%x STATE33

%{
#include<bits/stdc++.h>
#include<cstdlib>
#include<cstring>
#include "1905108_SymbolTable.h"
#define YYSTYPE symbolInfo*
#include "y.tab.h"

using namespace std;
extern YYSTYPE yylval;

extern symbolTable st;
extern FILE *logout;
extern FILE *errorout;

extern int line_count;
extern int error_count;

int lstart=0;
bool flag=true;
string str="";
string stok="";


string up(char* text){
    string s="";
    int i=0;
    while((text[i]>='A' && text[i]<='Z') || (text[i]>='a' && text[i]<='z')){
        s+=char(toupper(text[i]));
        i++;
    }
    return s;
}

void createParseNode(string name, string type, int lcount){
    symbolInfo *s= new symbolInfo(name, type);
    s->setTerminal(true);
    s->setStartLine(lcount);
    s->setEndLine(lcount);            
    yylval = s;
}

%}

WHITESPACE [ \t\f\r\v]
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE \n

%%

{NEWLINE} {line_count++;}
{WHITESPACE}+ {}
    

"if"    {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"IF",line_count);
        return IF;
        }
"else"  {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
         createParseNode(yytext,"ELSE",line_count);
        return ELSE;
        }
"for"   {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"FOR",line_count);
        return FOR;
        }
"do"    {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"DO",line_count);
        return DO;
        }
"while" {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"WHILE",line_count);
        return WHILE;
        }
"switch"    {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"SWITCH",line_count);
        return SWITCH;
        }
"default"   {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"DEFAULT",line_count);
        return DEFAULT;
        }
"break"     {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"BREAK",line_count);
        return BREAK;
        }
"case"  {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"CASE",line_count);
        return CASE;
        }
"continue"  {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"CONTINUE",line_count);
        return CONTINUE;
        }
"int"   {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"INT",line_count);
        return INT;
        }
"float" {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"FLOAT",line_count);
        return FLOAT;
        }
"double"  {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"DOUBLE",line_count);
        return DOUBLE;
        }
"char"  {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"CHAR",line_count);
        return CHAR;
        }
"void"  {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"VOID",line_count);
        return VOID;
        }
"return"  {
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"RETURN",line_count);
        return RETURN;

//no grammer rule
// "main"	{
//         return ID;
//         }
        }

"println"	{
        fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,up(yytext).c_str(),yytext);
        createParseNode(yytext,"PRINTLN",line_count);
        return PRINTLN;
        }

        

{DIGIT}+ 	{
        //fprintf(tokenout,"<CONST_INT, %s>\n",yytext);
        fprintf(logout,"Line# %d: Token <CONST_INT> Lexeme %s found\n",line_count,yytext);
        symbolInfo *s= new  symbolInfo(yytext, "CONST_INT");
        s->setArrSize(atoi(yytext));
        s->setTerminal(true);
        s->setStartLine(line_count);
        s->setEndLine(line_count);
		yylval = s;
        return CONST_INT;
        }

{DIGIT}*\.?{DIGIT}+(E[+-]?{DIGIT}+)? 	{
        //fprintf(tokenout,"<CONST_FLOAT, %s>\n",yytext);
        fprintf(logout,"Line# %d: Token <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);	
        symbolInfo *s= new  symbolInfo(yytext, "CONST_FLOAT");
        s->setTerminal(true);
        s->setStartLine(line_count);
        s->setEndLine(line_count);
		yylval = s;
        return CONST_FLOAT;	
        }

[']     {        
        error_count++;
        fprintf(logout,"Error at line# %d: UNFINISHED_CONST_CHAR %s\n",line_count,yytext);
        //return UNFINISHED_CONST_CHAR;
        }

['][']  {
		error_count++;
		fprintf(logout,"Error at line# %d: EMPTY_CONST_CHAR %s\n",line_count,yytext);
        //return EMPTY_CONST_CHAR;
        }

[']\\\'[']  {
        // fprintf(tokenout,"<CONST_CHAR, '>\n");
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme ' found\n",line_count);	        
        symbolInfo *s= new  symbolInfo("'", "CONST_CHAR");
        s->setTerminal(true);
        s->setStartLine(line_count);
        s->setEndLine(line_count);
		yylval = s;
        return CONST_CHAR;
        }

[']\\\"['] {
        str+="\"";
        // fprintf(tokenout,"<CONST_CHAR, \">\n");
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \" found\n",line_count);        
        symbolInfo *s= new  symbolInfo(str, "CONST_CHAR");
        s->setTerminal(true);
        s->setStartLine(line_count);
        s->setEndLine(line_count);
		yylval = s;
        str="";
        return CONST_CHAR;
        }

[']\\n[']  {
        str+="\n";
        // fprintf(tokenout,"<CONST_CHAR, \n>\n");
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \n found\n",line_count);        
        symbolInfo *s= new  symbolInfo(str, "CONST_CHAR");
        s->setTerminal(true);
        s->setStartLine(line_count);
        s->setEndLine(line_count);
		yylval = s;
        str="";
        return CONST_CHAR;
        }

[']\\t[']  {
        // fprintf(tokenout,"<CONST_CHAR, \t>\n");
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \t found\n",line_count);        
        str+="\t";
        symbolInfo *s= new  symbolInfo(str, "CONST_CHAR");
        s->setTerminal(true);
        s->setStartLine(line_count);
        s->setEndLine(line_count);
		yylval = s;
        str="";
        return CONST_CHAR;
        }

[']\\\\['] {
        // fprintf(tokenout,"<CONST_CHAR, \\>\n");
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \\ found\n",line_count);        
        str+="\\";
        symbolInfo *s= new  symbolInfo(str, "CONST_CHAR");
        s->setTerminal(true);
        s->setStartLine(line_count);
        s->setEndLine(line_count);
		yylval = s;
        str="";
        return CONST_CHAR;
        }

[']\\a[']  {
        // fprintf(tokenout,"<CONST_CHAR, \a>\n");
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \a found\n",line_count);        
        str+="\a";
        symbolInfo *s= new  symbolInfo(str, "CONST_CHAR");
        s->setTerminal(true);
        s->setStartLine(line_count);
        s->setEndLine(line_count);
		yylval = s;
        str="";
        return CONST_CHAR;
        }

[']\\f[']  {
        // fprintf(tokenout,"<CONST_CHAR, %c>\n",'\f');
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \f found\n",line_count);
        str+="\f";
        symbolInfo *s= new  symbolInfo(str, "CONST_CHAR");
        s->setTerminal(true);
        s->setStartLine(line_count);
        s->setEndLine(line_count);
		yylval = s;
        str="";
        return CONST_CHAR;
        }

[']\\r[']  {
        // fprintf(tokenout,"<CONST_CHAR, \r>\n");
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \r found\n",line_count);        
        str+="\r";
        symbolInfo *s= new  symbolInfo(str, "CONST_CHAR");
        s->setTerminal(true);
        s->setStartLine(line_count);
        s->setEndLine(line_count);
		yylval = s;
        str="";
        return CONST_CHAR;
        }

[']\\b[']  {
        // fprintf(tokenout,"<CONST_CHAR, %c>\n",'\b');
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme \b found\n",line_count);
        str+="\b";
        symbolInfo *s= new  symbolInfo(str, "CONST_CHAR");
        s->setTerminal(true);
        s->setStartLine(line_count);
        s->setEndLine(line_count);
		yylval = s;
        str="";
        return CONST_CHAR;
        }

[']\\v[']  {
        // fprintf(tokenout,"<CONST_CHAR, %c>\n",'\v');
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme %c found\n",line_count,'\v');        
        str+="\v";
        symbolInfo *s= new  symbolInfo(str, "CONST_CHAR");
        s->setTerminal(true);
        s->setStartLine(line_count);
        s->setEndLine(line_count);
		yylval = s;
        str="";
        return CONST_CHAR;
        }

[']\\0[']  {
        stok+="\0";
        // fprintf(tokenout,"<CONST_CHAR, %s>\n",stok.c_str());
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme %s found\n",line_count,stok.c_str());
        symbolInfo *s= new  symbolInfo(stok, "CONST_CHAR");
        s->setTerminal(true);
        s->setStartLine(line_count);
        s->setEndLine(line_count);
		yylval = s;
        stok="";
        return CONST_CHAR;
        }

[']\\[']   {
        error_count++;
        fprintf(logout,"Error at line# %d: UNFINISHED_CONST_CHAR %s\n",line_count,yytext);
        //return UNFINISHED_CONST_CHAR;
        }

['].[']    {
        str+=yytext[1];
        // fprintf(tokenout,"<CONST_CHAR, %s>\n",str.c_str());
        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme %s found\n",line_count,str.c_str());
        symbolInfo *s= new  symbolInfo(str, "CONST_CHAR");
        s->setTerminal(true);
        s->setStartLine(line_count);
        s->setEndLine(line_count);
		yylval = s;
        str="";
        return CONST_CHAR;
        }

[']..*[']  {
        error_count++;
        fprintf(logout,"Error at line# %d: MULTICHAR_CONST_CHAR %s\n",line_count,yytext);        
        //return MULTICHAR_CONST_CHAR;
        }

['][^;]    {        
        error_count++;
        fprintf(logout,"Error at line# %d: UNFINISHED_CONST_CHAR %s\n",line_count,yytext);
        //return UNFINISHED_CONST_CHAR;
        }

"+"|"-"		    {
			// fprintf(tokenout,"<ADDOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <ADDOP> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"ADDOP",line_count);
            return ADDOP;
    	}

"*"|"/"|"%"		{
			// fprintf(tokenout,"<MULOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <MULOP> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"MULOP",line_count);
            return MULOP;  
        }


"++"	{
			// fprintf(tokenout,"<INCOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <INCOP> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"INCOP",line_count);
            return INCOP;
        }

"--"    {
			// fprintf(tokenout,"<DECOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <DECOP> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"DECOP",line_count);
            return DECOP;
        }

"<"|"<="|">"|">="|"=="|"!="		{
			// fprintf(tokenout,"<RELOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <RELOP> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"RELOP",line_count);
            return RELOP;
        }			

"="	    {
			// fprintf(tokenout,"<ASSIGNOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <ASSIGNOP> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"ASSIGNOP",line_count);
            return ASSIGNOP;
        }	

"&&"	{
			// fprintf(tokenout,"<LOGICOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <LOGICOP> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"LOGICOP",line_count);
            return LOGICOP;
        }	

"||"	{
			// fprintf(tokenout,"<LOGICOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <LOGICOP> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"LOGICOP",line_count);
            return LOGICOP;
        }	

"&"|"^"|"<<"|">>"		{
			// fprintf(tokenout,"<BITOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <BITOP> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"BITOP",line_count);
            return BITOP;
        }


"|" 	{
			// fprintf(tokenout,"<BITOP, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <BITOP> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"BITOP",line_count);
            return BITOP;
        }

"!"	    {
			// fprintf(tokenout,"<NOT, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <NOT> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"NOT",line_count);
            return NOT;
    	}

"("	    {
			// fprintf(tokenout,"<LPAREN, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <LPAREN> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"LPAREN",line_count);
            return LPAREN;
        }		

")"	    {
			// fprintf(tokenout,"<RPAREN, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <RPAREN> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"RPAREN",line_count);
            return RPAREN;
        }	

"{"	    {
			// fprintf(tokenout,"<LCURL, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <LCURL> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"LCURL",line_count);
            //SOME CHANGE IN ENTERING SCOPE
            //st.enterScope();
            return LCURL;
        }		

"}"	    {
			// fprintf(tokenout,"<RCURL, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <RCURL> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"RCURL",line_count);
            //st.exitScope();
            return RCURL;
        }	

"["	    {
			// fprintf(tokenout,"<LSQUARE, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <LSQUARE> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"LSQUARE",line_count);
            return LSQUARE;
        }		

"]"	    {
			// fprintf(tokenout,"<RSQUARE, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <RSQUARE> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"RSQUARE",line_count);
            return RSQUARE;
    	}	

"," 	{
			// fprintf(tokenout,"<COMMA, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <COMMA> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"COMMA",line_count);
            return COMMA;
        }		

";"	    {
			// fprintf(tokenout,"<SEMICOLON, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <SEMICOLON> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"SEMICOLON",line_count);
            return SEMICOLON;
    	}	

({LETTER}|"_")({LETTER}|{DIGIT}|"_")*   {
            // fprintf(tokenout,"<ID, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <ID> Lexeme %s found\n",line_count,yytext);
            createParseNode(yytext,"ID",line_count);
            return ID;
        }

{DIGIT}+({LETTER}|{DIGIT}|"_")*   {  
			error_count++;         
			fprintf(logout,"Error at line# %d: INVALID_ID_SUFFIX_NUM_PREFIX %s\n",line_count,yytext);
            //return INVALID_ID_SUFFIX_NUM_PREFIX;
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
        // fprintf(tokenout,"<SINGLE LINE STRING, %s>\n",stok.c_str());
        fprintf(logout,"Line# %d: Token <SINGLE LINE STRING> Lexeme %s found\n",lstart,str.c_str());
        createParseNode(yytext,"SINGLE LINE STRING",line_count);
        // return SINGLE_LINE_STRING;
    }
    else{
        // fprintf(tokenout,"<MULTI LINE STRING, %s>\n",stok.c_str());
        fprintf(logout,"Line# %d: Token <MULTI LINE STRING> Lexeme %s found\n",lstart,str.c_str());
        createParseNode(yytext,"MULTI LINE STRING",line_count);
        // return MULTI_LINE_STRING;
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
    //return UNFINISHED_STRING;
}

<STATE3><<EOF>> {
	error_count++;
	str+="\n";
	fprintf(logout,"Error at line# %d: UNFINISHED_STRING %s",line_count,str.c_str());
	BEGIN INITIAL;
    //return UNFINISHED_STRING;
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
    //return SINGLE_LINE_COMMENT;
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
        //return UNFINISHED_COMMENT;
}

<STATE22>"/" {
			str+=yytext;
			fprintf(logout,"Line# %d: Token <MULTI LINE COMMENT> Lexeme %s found\n",lstart, str.c_str());
			BEGIN INITIAL;
            //return MULTI_LINE_COMMENT;
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
			//fprintf(logout,"Error at line# %d: UNFINISHED_COMMENT %s\n",line_count, str.c_str());
			BEGIN INITIAL;
            //return UNFINISHED_COMMENT;
}

. {
	error_count++;
	fprintf(logout,"Error at line# %d: UNRECOGNIZED CHAR %s\n",line_count, yytext);
}  

{DIGIT}*\.?{DIGIT}+(E[+-]?{DIGIT}*)\.+({DIGIT}|\.)* 	{
				error_count++;
				fprintf(logout,"Error at line# %d: ILLFORMED_NUMBER %s\n",line_count,yytext);
                //return ILLFORMED_NUMBER;
}

({DIGIT}|\.)+(E[+-]?({DIGIT}|\.)*)? 	{
				error_count++;
				fprintf(logout,"Error at line# %d: TOO_MANY_DECIMAL_POINTS %s\n",line_count,yytext);
                //return TOO_MANY_DECIMAL_POINTS;
}

%%