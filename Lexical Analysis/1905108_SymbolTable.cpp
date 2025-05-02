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

//SDBM HASH (given)
static unsigned long long sdbm(string s, unsigned long long m) {
	unsigned long long hash = 0;
	unsigned long long i = 0;
	unsigned long long len = s.length();

	for (i = 0; i < len; i++)
	{
		hash = (s[i]) + (hash << 6) + (hash << 16) - hash;
		//hash = hash%m;
	}

	return hash;
}

unsigned long long h1(string name, unsigned long long m)      //convert into long long
{
    unsigned long long res=0;
    res = sdbm(name,m) % m;
    return res;
}

class scopeTable
{
    symbolInfo** hashTable;         //bucket array
    unsigned long long maxSize;
    long long currSize;
    scopeTable* parent;             //parent pointer
    long long serial;               //table number
    pair<long long, long long> position;        //symbol position

public:
    scopeTable(unsigned long long n)
    {
        maxSize=n;
        currSize=0;
        serial=0;
        hashTable = new symbolInfo*[maxSize];
        for(long long i=0; i<maxSize; i++)
        {
            hashTable[i]=NULL;
        }
        parent=NULL;
    }

    void setSerial(long long n){
        serial=n;
    }

    long long getSerial(){
        return serial;
    }

    pair<long long, long long> getPos(){
        return position;
    }

    void setParent(scopeTable* p){
        parent=p;
    }

    scopeTable* getParent(){
        return parent;
    }

    bool Insert(string name, string type)           //Insertion
    {   long long counter=1;
        if(lookUP(name)->getName()==name)
            return false;
        symbolInfo* newNode=new symbolInfo(name, type);

        unsigned long long ind=h1(name, maxSize);
        symbolInfo* pt =hashTable[ind];
        symbolInfo* temp=NULL;
        if(pt==NULL){
            hashTable[ind]=newNode;
            position=make_pair(ind+1,1);
        }
        else
        {
            while(pt!=NULL)
            {
                temp=pt;
                pt=pt->getNext();
                counter++;
            }
            temp->setNext(newNode);
            position=make_pair(ind+1,counter);
        }
        currSize++;
        return true;
    }

    bool Delete(string name)        //deletion of symbol
    {
        long long counter=1;
        unsigned long long ind=h1(name, maxSize);
        symbolInfo* pt = hashTable[ind];
        symbolInfo* temp=pt;
        if (pt!=NULL && pt->getName() == name)
        {
            hashTable[ind]=hashTable[ind]->getNext();
            position=make_pair(ind+1,1);
            delete pt;
            currSize--;
            return true;
        }
        while(pt !=NULL)
        {
            if(pt->getName() == name)
            {
                temp->setNext((temp->getNext())->getNext());
                position=make_pair(ind+1,counter);
                delete pt;
                currSize--;
                return true;
            }
            else
            {
                temp=pt;
                pt=pt->getNext();
                counter++;
            }
        }
        return false;
    }

    symbolInfo* lookUP(string name)     //finding symbol
    {
        long long counter=1;
        unsigned long long ind=h1(name, maxSize);
        symbolInfo* pt =hashTable[ind];
        while(pt !=NULL)
        {
            if(pt->getName() == name){
                position=make_pair(ind+1,counter);
                return pt;
            }
            else{
                pt=pt->getNext();
                counter++;;
            }
        }
        pt = new symbolInfo("","");
        return pt;
    }

    void Print(FILE* file)      //print into file
    {
        symbolInfo* pt;
        bool flag=true;

        fprintf(file,"\tScopeTable# %lld\n",serial);
        for(long long i=0; i<maxSize; i++)
        {
            pt=hashTable[i];
            while(pt!=NULL)
            {
                if(flag){
                    fprintf(file,"\t%lld--> ",i+1);
                    flag=false;
                }
                fprintf(file,"<%s,%s> ",pt->getName().c_str(),pt->getType().c_str());
                pt=pt->getNext();
            }
            if(flag==false){
                fprintf(file,"\n");
                flag=true;
            }
        }

    }

    long long length(){
        return currSize;
    }

    void clear(){           //deallocating bucket array
        unsigned long long ind;
        symbolInfo* pt;
        for(ind=0; ind<maxSize; ind++){
            pt = hashTable[ind];
            while (pt!=NULL)
            {
                hashTable[ind]=hashTable[ind]->getNext();
                delete pt;
                pt=hashTable[ind];
                currSize--;
            }
        }

    }

    ~scopeTable(){
        clear();
        delete [] hashTable;
    }

};


class symbolTable{
    scopeTable* currentScopeTable;  //current scope table
    unsigned long long bucketSize;           //bucket size
    long long scopeSerial;          //for finding scope serial
    long long scopes;               //total scopes
    pair<long long, long long> position;    //symbol position

public:
    symbolTable(unsigned long long n=10){
        scopes=0;
        scopeSerial=0;
        bucketSize=n;
        currentScopeTable=new scopeTable(n);
        if(currentScopeTable->getSerial()==0){
            scopeSerial=1;
            scopes=1;
            currentScopeTable->setSerial(scopes++);
        }
    }

    void enterScope(){          //creating new scope
        scopeSerial=0;
        scopeTable* newScope = new scopeTable(bucketSize);
        if(newScope->getSerial()==0){
            newScope->setParent(currentScopeTable);
            currentScopeTable=newScope;
            scopeSerial=scopes;
            currentScopeTable->setSerial(scopes++);
        }
    }

    void exitScope(){           //deleting current scope table
        scopeTable* parent=currentScopeTable->getParent();
        scopeSerial=currentScopeTable->getSerial();
        if(scopeSerial>1){
            delete currentScopeTable;
            currentScopeTable = parent;
        }
    }

    void exitRootScope(){       //deleting root scope
        scopeTable* parent=currentScopeTable->getParent();
        scopeSerial=currentScopeTable->getSerial();
        if(scopeSerial==1){
            delete currentScopeTable;
            currentScopeTable = parent;
        }
    }

    bool Insert(string name, string type){          //inserting symbol
        bool b=currentScopeTable->Insert(name,type);
        scopeSerial=currentScopeTable->getSerial();
        position=currentScopeTable->getPos();
        return b;
    }

    bool Remove(string name){                       //deleting symbol from current scope table
        bool b=currentScopeTable->Delete(name);
        scopeSerial=currentScopeTable->getSerial();
        position=currentScopeTable->getPos();
        return b;
    }

    symbolInfo* lookUp(string name){                //finding symbol
        scopeTable* scp=currentScopeTable;
        symbolInfo* symbol;
        while(scp != NULL){
            symbol=scp->lookUP(name);
            if(symbol->getName()==name){
                scopeSerial=scp->getSerial();
                position=scp->getPos();
                return symbol;
            }
            else
                scp=scp->getParent();
        }
        symbol=new symbolInfo("","");
        return symbol;
    }

    pair<long long, long long> getPosition(){
        return position;
    }

    long long getScopeSerial(){
        return scopeSerial;
    }

    long long lastScopeSerial(){
        return currentScopeTable->getSerial();
    }

    void printCurrent(FILE* file){
            currentScopeTable->Print(file);
    }

    void printAll(FILE* file){
        scopeTable* scp=currentScopeTable;
        while(scp != NULL ){
            scp->Print(file);
            scp=scp->getParent();
        }
    }
    ~symbolTable(){
        if(currentScopeTable!=NULL){
            scopeSerial=currentScopeTable->getSerial();
            while(scopeSerial>1){
                exitScope();
            }
            exitRootScope();
        }
    }
};
