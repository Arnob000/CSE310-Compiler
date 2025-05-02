#include<bits/stdc++.h>
#include "1905108_ScopeTable.cpp"

using namespace std;

class symbolTable{
    scopeTable* currentScopeTable;  //current scope table
    long long bucketSize;           //bucket size
    long long scopeSerial;          //for finding scope serial
    long long scopes;               //total scopes
    pair<long long, long long> position;    //symbol position

public:
    symbolTable(long long n){
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

    void printCurrent(ofstream& file){
        if(file.is_open())
            currentScopeTable->Print(file);
    }

    void printAll(ofstream& file){
        scopeTable* scp=currentScopeTable;
        while(scp != NULL && file.is_open()){
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

int main(){
    long long n,c=1;
    int i=0;
    bool flag;
    string s;
    string arr[5]={"","","","",""};

    stringstream x;
    ifstream inputFile("sample_input.txt");
    ofstream outputFile("1905108_output.txt");


    if(inputFile.is_open()){
        inputFile>>n;
        getline(inputFile,s);
        symbolTable table(n);       //creating symbol table
        if(table.getScopeSerial()>0){
            outputFile<<"\tScopeTable# "<<table.getScopeSerial()<<" created\n";
        }
        while(getline(inputFile,s) && outputFile.is_open()){
            i=1;
            flag=true;
            outputFile<<"Cmd "<<c<<": "<<s<<endl;
            c++;
            x.clear();
            x.str(s);
            getline(x,arr[0],' ');

            if(arr[0]=="I"){        //insertion of symbol
                while(getline(x,arr[i],' ')){
                    if(i>3){
                        break;
                    }
                    i++;
                }
                if(i!=3)
                    outputFile<<"\tNumber of parameters mismatch for the command "<<arr[0]<<endl;
                else{
                    flag=table.Insert(arr[1],arr[2]);
                    if(flag){
                        outputFile<<"\tInserted in ScopeTable# "<<table.getScopeSerial()<<" at position "<<table.getPosition().first<<", "<<table.getPosition().second<<endl;
                    }
                    else{
                        outputFile<<"\t'"<<arr[1]<<"' already exists in the current ScopeTable"<<endl;
                    }
                }
            }

            else if(arr[0]=="L"){       //lookup
                while(getline(x,arr[i],' ')){
                    if(i>3){
                        break;
                    }
                    i++;
                }
                if(i!=2)
                    outputFile<<"\tNumber of parameters mismatch for the command "<<arr[0]<<endl;
                else{
                    symbolInfo* sym;
                    sym=table.lookUp(arr[1]);
                    if(sym->getName()==arr[1]){
                        outputFile<<"\t'"<<arr[1]<<"' found in ScopeTable# "<<table.getScopeSerial()<<" at position "<<table.getPosition().first<<", "<<table.getPosition().second<<endl;
                    }
                    else{
                        outputFile<<"\t'"<<arr[1]<<"' not found in any of the ScopeTables\n";
                    }
                }
            }
            else if(arr[0]=="D"){       //deletion of symbol
                while(getline(x,arr[i],' ')){
                    if(i>3){
                        break;
                    }
                    i++;
                }
                if(i!=2)
                    outputFile<<"\tNumber of parameters mismatch for the command "<<arr[0]<<endl;
                else{
                    flag=table.Remove(arr[1]);
                    if(flag){
                        outputFile<<"\tDeleted '"<<arr[1]<<"' from ScopeTable# "<<table.getScopeSerial()<<" at position "<<table.getPosition().first<<", "<<table.getPosition().second<<endl;
                    }
                    else{
                        outputFile<<"\tNot found in the current ScopeTable\n";
                    }
                }
            }

            else if(arr[0]=="P"){       //printing symbol table
                while(getline(x,arr[i],' ')){
                    if(i>3){
                        break;
                    }
                    i++;
                }
                if(i!=2)
                    outputFile<<"\tNumber of parameters mismatch for the command "<<arr[0]<<endl;
                else if(arr[1]=="A")        //print all scope table
                    table.printAll(outputFile);
                else if(arr[1]=="C"){       //print current scope table
                    table.printCurrent(outputFile);
                }
             }

             else if(arr[0]=="S"){          //entering new scope
                while(getline(x,arr[i],' ')){
                    i=-1;
                    break;
                }
                if(i==-1)
                    outputFile<<"\tNumber of parameters mismatch for the command "<<arr[0]<<endl;
                else{
                    table.enterScope();
                    if(table.getScopeSerial()>0){
                        outputFile<<"\tScopeTable# "<<table.getScopeSerial()<<" created\n";
                    }
                }
             }

            else if(arr[0]=="E"){           //exiting current scope
                while(getline(x,arr[i],' ')){
                    i=-1;
                    break;
                }
                if(i==-1)
                    outputFile<<"\tNumber of parameters mismatch for the command "<<arr[0]<<endl;
                else{
                    table.exitScope();
                    if(table.getScopeSerial()>1){
                        outputFile<<"\tScopeTable# "<<table.getScopeSerial()<<" removed\n";
                    }
                    else if(table.getScopeSerial()==1){
                        outputFile<<"\tScopeTable# "<<table.getScopeSerial()<<" cannot be removed\n";
                    }
                }
            }

            else if(arr[0]=="Q"){           //quit
                while(table.lastScopeSerial()>1){
                    table.exitScope();
                    outputFile<<"\tScopeTable# "<<table.getScopeSerial()<<" removed\n";
                }
                table.exitRootScope();
                outputFile<<"\tScopeTable# "<<table.getScopeSerial()<<" removed\n";
                break;
            }

            else{
                outputFile<<"\tInvalid Operation\n";
            }
        }
    }
    inputFile.close();
    outputFile.close();

}
