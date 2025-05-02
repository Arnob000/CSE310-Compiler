#include<bits/stdc++.h>

using namespace std;

class symbolInfo{
    string name;
    string type;
    int arrsize;
    symbolInfo* next;
    bool isTer; //parsetree
    int sline;
    int fline;
    vector<symbolInfo*> childList;
    vector<pair<string,string> > attribute;     //extra attr checking
public:
    symbolInfo(string n="", string t=""){
        name=n;
        type=t;
        arrsize=-1;
        next=NULL;
        isTer=false;
        sline=0;
        fline=0;
        setAtr();
    }

    void setName(string n){
        name=n;
    }

    string getName(){
        return name;
    }

    void setType(string t){
        type=t;
    }

    string getType(){
        return type;
    }

    void setNext(symbolInfo* n){        //pointer
        next=n;
    }

    symbolInfo* getNext(){
        return next;
    }

    void setArrSize(int n){
        //if variable is an array
        arrsize=n;
    }

    int getArrSize(){
        return arrsize;
    }

    void setTerminal(bool b){
        isTer=b;
    }
    bool isTerminal(){
        return isTer;
    }

    void setStartLine(int n){
        sline=n;
    }

    int getStartLine(){
        return sline;
    }

    void setEndLine(int n){
        fline=n;
    }

    int getEndLine(){
        return fline;
    }

    void setChild(symbolInfo* n){        //pointer
        childList.push_back(n);
    }

    symbolInfo* getChild(int ind){
        if(ind >=0 && ind < childList.size())
            return childList[ind];
    }

    vector<symbolInfo*> getChildList(){
        return childList;
    }

    void clearChild(){
        for(int i=0; i<childList.size(); i++)
            delete childList[i];
        childList.clear();
    }

    void setAtr(){
        pair<string, string> p={"",""};
        attribute.push_back(p);
    }

    void setIdType(string s){
        //decFunc declared func
        //defFunc defined func
        //var variable
        //array array
        //errFunc
        //RETSTMT
        //testarray
        pair<string,string> p = {s,s};
        attribute[0]=p;
    }

    string isFun(){
        //decFunc declared func
        //defFunc defined func
        //var variable
        //array array
        //errFunc
        //RETSTMT
        //testarray
        return attribute[0].first;
    }

    void insertParam(string a, string b){
        pair<string,string> p = {a,b};
        attribute.push_back(p);
    }

    void insertParam(string a, string b, int ind){
        pair<string,string> p = {a,b};
        if(ind>=0 && ind < attribute.size())
            attribute[ind]=p;
    }

    vector<pair<string,string> > getParam(){
        return attribute;
    }

    int getParaCount(){
        return (attribute.size()-1);
    }

    void clearAtr(){
        attribute.clear();
    }

    ~symbolInfo(){
        clearAtr();
        clearChild();
        next=NULL;
    }
};