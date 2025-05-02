#include<bits/stdc++.h>
#include "1905108_SymbolInfo.cpp"

using namespace std;

//SDBM HASH (given)
static unsigned int sdbm(string s, long long m) {
	unsigned int hash = 0;
	unsigned int i = 0;
	unsigned int len = s.length();

	for (i = 0; i < len; i++)
	{
		hash = (s[i]) + (hash << 6) + (hash << 16) - hash;
		hash = hash%m;
	}

	return hash;
}

long long h1(string name, long long m)      //convert into long long
{
    long long res=0;
    res = sdbm(name,m) % m;
    return res;
}

class scopeTable
{
    symbolInfo** hashTable;         //bucket array
    long long maxSize;
    long long currSize;
    scopeTable* parent;             //parent pointer
    long long serial;               //table number
    pair<long long, long long> position;        //symbol position

public:
    scopeTable(long long n)
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

        long long ind=h1(name, maxSize);
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
        long long ind=h1(name, maxSize);
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
        long long ind=h1(name, maxSize);
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

    void Print(ofstream& file)      //print into file
    {
        symbolInfo* pt;
        if(file.is_open()){
            file<<"\tScopeTable# "<<serial<<endl;
            for(long long i=0; i<maxSize; i++)
            {
                file<<"\t"<<i+1<<"--> ";
                pt=hashTable[i];
                while(pt!=NULL)
                {
                    file<<"<"<<pt->getName()<<","<<pt->getType()<<"> ";
                    pt=pt->getNext();
                }
                file<<endl;
            }
        }
    }

    long long length(){
        return currSize;
    }

    void clear(){           //deallocating bucket array
        long long ind;
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
