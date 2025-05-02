#include<bits/stdc++.h>

using namespace std;

void optimizedASM(){
   ifstream inputFile("1905108_asm.asm");
   ofstream outputFile("1905108_optimised_asm.asm");
   string s1;
   string p1;
   string p2;
   string s;
   stringstream x;
   vector<string> tok1;
   vector<string> tok2;
   bool push=false;
   bool mov=false;

   if(inputFile.is_open()){
    while(getline(inputFile,s1) && outputFile.is_open()){
        x.clear();
        x.str(s1);

        while(getline(x, s, ' '))
        {
            tok1.push_back(s);
        }

        for(int i=0; i<tok1.size(); i++)    //2nd time
        {
            x.clear();
            x.str(tok1[i]);
            while(getline(x,s,','))
                tok2.push_back(s);
        }

//debug
//        for(int i = 0; i < tok2.size(); i++)
//            cout << tok2[i] <<" ";
//        cout<<tok2.size();
//        cout<<endl;

        if(tok2[0]=="\tADD")
        {
            if(push){
                outputFile<<p1<<" "<<p2<<endl;
            }

            if(tok2[3]=="0")
                outputFile<<";optimized"<<endl;
            else
                outputFile<<s1<<endl;

            push=false;
            mov=false;
        }
        else  if(tok2[0]=="\tSUB")
        {
            if(push){
                outputFile<<p1<<" "<<p2<<endl;
            }

            if(tok2[3]=="0")
                outputFile<<";optimized"<<endl;
            else
                outputFile<<s1<<endl;
            push=false;
            mov=false;
        }
        else  if(tok2[0]=="\tMUL")
        {
            if(push){
                outputFile<<p1<<" "<<p2<<endl;
            }

            if(tok2[3]=="1")
                outputFile<<";optimized"<<endl;
            else
                outputFile<<s1<<endl;
            push=false;
            mov=false;

        }
        else if (push && tok2[0]=="\tPOP")
        {
            if(tok2[1]==p2)
            {
                outputFile<<";optimized\n";
            }
            else
            {
                outputFile<<p1<<" "<<p2<<endl;
                outputFile<<tok2[0]<<" "<<tok2[1]<<endl;
            }
            push=false;
            mov=false;
        }
        else if(tok2[0]=="\tPUSH")
        {
            if(push){
                outputFile<<p1<<" "<<p2<<endl;
            }
            p1=tok2[0];
            p2=tok2[1];
            push=true;
            mov=false;
        }
        else if(tok2[0]=="\tMOV" && mov==false)
        {
            if(push){
                outputFile<<p1<<" "<<p2<<endl;
            }

            outputFile<<s1<<endl;
            p1=tok2[1];
            p2=tok2[2];
            push=false;
            mov=true;
        }
        else if(tok2[0]=="\tMOV" && mov==true)
        {
            if(push){
                outputFile<<p1<<" "<<p2<<endl;
            }

            if(p1==tok2[1] && p2==tok2[2])
            {
                push=false;
                mov=false;
                outputFile<<";optimized\n";
            }
            else if(p1==tok2[2] && p2==tok2[1])
            {
                push=false;
                mov=false;
                outputFile<<";optimized\n";
            }
            else
            {
                outputFile<<s1<<endl;
                p1=tok2[1];
                p2=tok2[2];
                push=false;
                mov=true;
            }
        }
        else
        {
            if(push){
                outputFile<<p1<<" "<<p2<<endl;
            }

            push=false;
            mov=false;
            outputFile<<s1<<endl;
        }
        tok1.clear();
        tok2.clear();
    }
   }
}
