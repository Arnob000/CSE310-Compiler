#include<bits/stdc++.h>

using namespace std;

class symbolInfo{
    string name;
    string type;
    symbolInfo* next;

public:
    symbolInfo(string n="", string t=""){
        name=n;
        type=t;
        next=NULL;
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
    ~symbolInfo(){
     next=NULL;
    }
};
