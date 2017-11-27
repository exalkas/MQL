//+------------------------------------------------------------------+
//|                                                 PriceLess0540.mq4|
//|                                                            alkas |
//|                                                         alkas.gr |
//+------------------------------------------------------------------+
//Simple version. We start at a level and keep open trades until there is profit
//Bug fixed with wrong alpha & beta. 
//Day & hour labels got bigger
//added labels for lots & maxlotsperlevel//closeall improved to set false inbusiness and readytotrade as well
//trade function fixed bug
//5.3 uses a>=b and test minbuy instead of maxbuy and maxsell instead of minsell
//fixed bug with lots calculation
//5.3.1 fixed bug with countprofit so it returns true if >0.001
//also fixed bug with calc lots @trade function
//created new function calclots
//5.3.2 added functionality to stop trade when opposites are more than allowed from ext parameter
//Also update profit function to show how much money is profit.
//Added external parameter to close all after win without opposites
//Added external parameter for minimum profit.
//Added external parameter for danger level.
//Added external parameter to close 1st trade if in profit.
//0534 has corrected a small bug in trade function with "}" when it was sell
//Added functionality to stop trade if bigger than danger zone
//0535 added functinality to trade with MAs cross
//Also 1st trade can be traded reversed
//Added functinality to close all immediately if you wish
//When trading with MAs, choose if you want to trade with direction of MAs
//0538 added functionality to combine MA with time
//0540 no reverse. we scale lots at legs. We don't touch first legs from each side to absorb changes of direction
//For countprofit we count moneyprofit instead of lots
//Analyze data modified
//Trade function modified
//Close all if maxbuy-minsell less than external param
#property copyright "alkas"
#property link      "alkas.gr"
#property version   "1.00"
#property strict

//External Variables

extern double step=30.0;
extern int starthour=0;
extern int startday=1;
extern int id=11;
extern int legavanta=2;
extern int terminatelevel=10;
extern string hordivider="------------------------------------------------";
extern double extlots=0.02;
extern double maxlotsperlevel=0.04;
extern int maxtradesperlevel=2;
extern double steplots=0.01;
extern double addlots=0.03;
extern string hordivider3="------------------------------------------------";
extern bool usemas=true;
extern bool tradewithmas=true;
extern int smallma=9;
extern int bigma=20;
extern int matf=60;
extern string hordivider4="------------------------------------------------";

extern double minprofit=0.001;
extern int flexibility=3;
extern int maxtrades=30;

extern bool closeiffirstinprofit=true;
extern bool continueafterclosefromwininarow=false;
extern bool debug=true;
extern int slip=5;
extern bool closeall=false;

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES
//+------------------------------------------------------------------+
int losses=0;

double divider;
double marketdigits;
double stepdivider;

double bot;
double top;

double endprice=0.0;
double startprice=0.0;

int magic;
int cid;
int buybook[50];
int sellbook[50];
double buybooklots[50];
double sellbooklots[50];
double totalbuybooklots[50];
double totalsellbooklots[50];
double maxbuylots;
double maxselllots;
int buycounter;
int sellcounter;

int minbuy;
int minsell;
int maxsell;
int maxbuy;

double lots=0.0;

double stepflexibility;
double moneyprofit=0.0;
double lotsatlevel=0.0;
double lotsatpreviouslevel=0.0;
string stringprice="";
string stringspread="";
string expertname="";
string magicstr="";
string message;

bool intrade=false;
bool readytotrade;
bool tradedforthebar=false;
bool inbusiness=false;

datetime lastbar;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
// Find dividers, set magic numbers, get expert name to create unique id
// Print all graphics on screen

int OnInit()
  {
//---
   if (closeall) {if(debug) {Print("CLOSE ALL IS TRUE. I WILL CLOSE EVERYTHING!");} closeall(true,false);}
   
   if(debug) {Print("OnInit: Will find divider.");} findDivider();
   if(debug) {Print("OnInit: Will set magic Number.");} setmagicnumber();
   if(debug) {Print("OnInit: Will find expertname.");} findexpertname();

   if(debug) {Print("OnInit: Will Check if there are trades already.");} checkiftradesalready();
   if(debug) {Print("OnInit: Will find start and end prices.");} findStartandEndPrices();
   if(debug) {Print("OnInit: Will Print Lines.");} printlines(); 
   if(debug) {Print("OnInit: Will Create Labels.");} createlabels(); 
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,OBJ_LABEL);
   ObjectsDeleteAll(0,OBJ_HLINE);
//---  
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
//Check if it's time and new bar and in trade
void OnTick()
  {
//---  
if(intrade)
  { 
     checkcloseborders();
  }
else 
{
   if (readytotrade)
   {
      checkopenborders();
   }      
   else
   {
      if (checkfornewbar())
      {
         if (inbusiness)
         {
         if(debug) {Print("OnTick: inbusiness and it's a NEWBAR. Will calcborders."," Bid=",Bid);} 
         readytotrade=true;calcborders();
         }
         else
         {
            if (usemas)
            {if (checkmascross()) 
               {
               if(debug) {Print("OnTick: NEWBAR: It's time. Will calcborders. MA start"," Bid=",Bid);} 
               calcborders(); 
               readytotrade=true;               
               }            
            }
            else
            {
            if (Hour()==starthour && DayOfWeek()==startday)
            {
            if(debug) {Print("OnTick: NEWBAR: It's time. Will calcborders."," Bid=",Bid," hour=",Hour(), " day=", DayOfWeek());} 
            calcborders(); 
            readytotrade=true;    
            }
            }
         }   
      }   
  } 
}

//////////////////////  
printlabels();
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Analyze Situation When Cross Bottom
//+------------------------------------------------------------------+
//We have bottom cross. What should do next
void analyzedatabot()
{
if (!intrade) {if (debug) {Print("AnalyzedataBOT: Not in trade. Will sell");} 
if (tradewithmas)
   {
   if (debug) {Print("AnalyzedataBOT: tradewithmas");} 
   if (findwhichmaisup()) 
      {buy(extlots);return;} 
      else 
      {sell(extlots);return;}} 
else {sell(extlots);return;}
}
if (buycounter==0) {if (debug) {Print("AnalyzedataBOT: Sellcounter=0. Will Sell");} if (closeiffirstinprofit) {closeall(true,false);intrade=false;inbusiness=false;readytotrade=false;return;} else {sell(extlots);return;}}
if (buycounter>0 && sellcounter==0) {if (debug) {Print("AnalyzedataBOT: Sellcounter=0 & Buycounter>0. Will Sell");}sell(extlots);return;}
if (buycounter>2 && sellcounter==0) {if (debug) {Print("AnalyzedataBOT: Sellcounter>0 & buycounter==0. Will closeall and sell");}if (continueafterclosefromwininarow) {closeall(false,false);sell(extlots);return;} else {closeall(true,false);intrade=false;inbusiness=false;readytotrade=false;return;}}
if (countprofit() && buycounter>0) {if (debug) {Print("AnalyzedataBOT: Profit. Will Close ALL");}closeall(true,false);intrade=false;inbusiness=false;readytotrade=false;return;}
if (maxbuy-minsell>=terminatelevel && terminatelevel>0) {if (debug) {Print("AnalyzedataBOT: Terminate level reached! Will Close ALL");}closeall(true,false);intrade=false;inbusiness=false;readytotrade=false;return;}
if (countlotsatlevel(cid,false)>=maxtradesperlevel) {if (debug) {Print("AnalyzedataBOT: MAXLOTSPERLEVEL REACHED! Will EXIT");}return;}
if (sellcounter==0) {if (debug) {Print("AnalyzedataBOT: SELLS=0. Will SELL");}sell(extlots);return;}
if (cid>minbuy) {if (debug) {Print("AnalyzedataBOT: CID >MAXBUY. Will EXIT");}return;}
if (findinbooks(cid,true)) {if (debug) {Print("AnalyzedataBOT: Found in buybook. Will EXIT");}return;}
if (cid==maxsell) {if (debug) {Print("AnalyzedataBOT: CID =MAXSELL. Will EXIT");}return;}
if (cid==maxsell-1) {if (lotsatlevel<=maxbuylots) {if (debug) {Print("AnalyzedataBOT: Cid=maxsell-1. Will SELL");}trade(false,true);return;} else {return;}}

if (!findinbooks(cid,false)) 
{
   if (calcavanda(false)) {if (debug) {Print("AnalyzedataBOT: We have Avanta. Will sell");}trade(false,false);}
}
else
{
   if (lotsatlevel>=lotsatpreviouslevel-extlots) {if (debug) {Print("AnalyzedataBOT: lots at level are ok. Will EXIT");}return;}
   else {if (debug) {Print("AnalyzedataBOT: Found in books. Will SELL");}trade(false,false);}
}
}

//+------------------------------------------------------------------+
//| Analyze Situation When Cross top
//+------------------------------------------------------------------+
//We have top cross. What should do next

void analyzedatatop()
{
if (!intrade) 
{if (debug) {Print("AnalyzedataTOP: Not in trade. Will buy");} 
if (tradewithmas) 
      {
      if (debug) {Print("AnalyzedataTOP: tradewithmas");} 
      if (findwhichmaisup()) 
         {buy(extlots);return;} 
       else {sell(extlots);return;}} 
   else {buy(extlots);return;}

}
if (sellcounter==0) {if (debug) {Print("AnalyzedataTOP: Sellcounter=0. Will buy");} if (closeiffirstinprofit) {closeall(true,true);intrade=false;inbusiness=false;readytotrade=false;return;} else {buy(extlots);return;}}
if (buycounter>0 && sellcounter==0) {if (debug) {Print("AnalyzedataBOT: Sellcounter=0 & Buycounter>0. Will Sell");}sell(extlots);return;}
if (sellcounter>2 && buycounter==0) {if (debug) {Print("AnalyzedataTOP: Sellcounter>0 & buycounter==0. Will closeall and buy");}if (continueafterclosefromwininarow) {closeall(false,true);buy(extlots);return;} else {closeall(true,false);intrade=false;inbusiness=false;readytotrade=false;return;}}
if (countprofit() && sellcounter>0) {if (debug) {Print("AnalyzedataTOP: Profit. Will Close ALL");}closeall(true,true);intrade=false;inbusiness=false;readytotrade=false;return;}
if (maxbuy-minsell>=terminatelevel && terminatelevel>0) {if (debug) {Print("AnalyzedataTOP: Terminate level reached! Will Close ALL");}closeall(true,true);intrade=false;inbusiness=false;readytotrade=false;return;}
if (countlotsatlevel(cid,true)>=maxtradesperlevel) {if (debug) {Print("AnalyzedataTOP: MAXLOTSPERLEVEL REACHED! Will EXIT");}return;}
if (buycounter==0) {if (debug) {Print("AnalyzedataTOP: BUYS=0. Will BUY");}buy(extlots);return;}
if (cid<maxsell) {if (debug) {Print("AnalyzedataTOP: CID <MINSELL. Will EXIT");}return;}
if (findinbooks(cid,false)) {if (debug) {Print("AnalyzedataTOP: CID Found in sellbook. Will EXIT");}return;}
if (cid==minbuy) {if (debug) {Print("AnalyzedataTOP: CID =MINBUY. Will EXIT");}return;}
if (cid==minbuy+1) {if (lotsatlevel<=maxselllots) {if (debug) {Print("AnalyzedataTOP: Cid=minbuy+1. Will BUY");}trade(true,true);return;} else {return;}}

if (!findinbooks(cid,true)) 
{
   if (calcavanda(true)) {if (debug) {Print("AnalyzedataTOP: We have Avanta. Will BUY");}trade(true,false);}
}
else
{
   if (lotsatlevel>=lotsatpreviouslevel-extlots) {if (debug) {Print("AnalyzedataTOP: lots at level are ok. Will EXIT");}return;}
   else {if (debug) {Print("AnalyzedataTOP: Found in books. Will BUY");}trade(true,false);}
}
}

//+------------------------------------------------------------------+
//| Analyze pool
//+------------------------------------------------------------------+
void analyzepool(bool buy)
{
readpool();
calccid();
calctopprofit();
if (buy) {calclevellots(true);analyzedatatop();} else {calclevellots(false);analyzedatabot();}
}

//+------------------------------------------------------------------+
//| Build Comment
//+------------------------------------------------------------------+
void buildcomment()
{
string strcid=string(cid);
string strstep=string(step);

message="cid="+strcid+";"+expertname+"s"+strstep;
if (debug) {Print("BuildComment: message=",message);}
}

//+------------------------------------------------------------------+
//| Buy
//+------------------------------------------------------------------+
int buy(double internallots)
  {
   if (debug) {Print("Buy: I will buy with lots=",internallots);}
   buildcomment();
      
   int error;
   int ticket=OrderSend(Symbol(),OP_BUY,internallots,Ask,slip,0,0,message,magic,0,clrGreen);
   if(ticket<0) {error=GetLastError();Print("OrderSend failed with error #",error);return(error);}
   else 
     {
      Print("OrderSend placed successfully");
      intrade=true; 
      calctopprofit();    
      return(0);
     }
   return (0);
  }

//+------------------------------------------------------------------+
//| Calc Avanda
//+------------------------------------------------------------------+
bool calcavanda(bool buy)
{
int difftop=0;
int diffbot=0;
difftop=maxbuy-minbuy;
diffbot=maxsell-minsell;
int diffbuy=0;
int diffsell=0;

diffbuy=difftop-diffbot;
diffsell=diffbot-difftop;

if (debug) {Print("CalcAvanda: difftop=",difftop, " diffbot=",diffbot);}     
if (debug) {Print("CalcAvanda: diffbuy=",diffbuy, " diffsell=",diffsell);}    

if (buy)
{if (diffbuy<legavanta) {return true;} else {return false;}}
else
{if (diffsell<legavanta) {return true;} else {return false;}}
}

//+------------------------------------------------------------------+
//| Calc Borders
//+------------------------------------------------------------------+
void calcborders()
{
bool done=false;
double price=0;


while(!done)
     {
      if(Bid>=price && Bid<price+stepdivider)
        {          
            top=price+stepdivider;
            bot=price;            
            done=true;
        }   
        else {price+=stepdivider;}
     }

printborders();     
if (debug) {Print("calcborders: Bid=",Bid," Ask=",Ask," Top=",top," bottom=",bot);}     
}

//+------------------------------------------------------------------+
//| Calc Cid
//+------------------------------------------------------------------+
void calccid()
{
double tcid=Bid/stepdivider;
cid=int(NormalizeDouble(tcid,0));
if (debug) {Print("calcCID: cid=",cid);}     
}

//+------------------------------------------------------------------+
//| Calc Level Lots
//+------------------------------------------------------------------+
void calclevellots(bool buy)
{
lotsatlevel=0.0;
lotsatpreviouslevel=0.0;

if (buy)
{
 for(int i=0;i<maxtrades;i++)
   {
      if (buybook[i]==cid) {lotsatlevel+=buybooklots[i];}
      if (buybook[i]==cid-1) {lotsatpreviouslevel+=buybooklots[i];}
   }
 }
 else
 {
 for(int i=0;i<maxtrades;i++)
   {
      if (sellbook[i]==cid) {lotsatlevel+=sellbooklots[i];}
      if (sellbook[i]==cid+1) {lotsatpreviouslevel+=sellbooklots[i];}
   }
 }
 
if (debug) {Print("CalcLevelLots: lotsatlevel=",lotsatlevel, ", lotsatpreviouslevel=",lotsatpreviouslevel);}
}

//+------------------------------------------------------------------+
//| Calc Top Profit
//+------------------------------------------------------------------+
void calctopprofit()
{
top=(cid*stepdivider)+stepdivider;
bot=(cid*stepdivider)-stepdivider;

printborders();     
if (debug) {Print("calcTopProfit: Bid=",Bid," Ask=",Ask," Topprofit=",top," bottomprofit=",bot);}     
}

//+------------------------------------------------------------------+
//| Check Close Borders
//+------------------------------------------------------------------+
void checkcloseborders()
{
         if (Bid>=top-stepflexibility)
         {
            if(debug) {Print("CheckCloseBorders: ----------------------CROSSED TOP -FLEXIBILITY--------------------------------");}
            if(debug) {Print("CheckCloseBorders: Intrade:Bid>=topprofit"," Bid=",Bid, " topprofit=",top);}
            analyzepool(true);     
         }
         else if (Bid<=bot+stepflexibility)
         {
            if(debug) {Print("CheckCloseBorders: ----------------------CROSSED BOT -FLEXIBILITY--------------------------------");}
            if(debug) {Print("CheckCloseBorders: Intrade:Bid<=botprofit"," Bid=",Bid, " botprofit=",bot);}
            analyzepool(false);
         }
}

//+------------------------------------------------------------------+
//| Check For New Bar
//+------------------------------------------------------------------+
bool checkfornewbar()
{
datetime curbar=Time[0];

if (lastbar!=curbar)
{
lastbar=curbar;
tradedforthebar=false;
if (debug) {Print("CheckForNewBar: NEW BAR");}
return true;
}
else
{return false;}
}

//+------------------------------------------------------------------+
//| Check if in trade already
//+------------------------------------------------------------------+
void checkiftradesalready()
{
readpool();
if (buycounter>0 || sellcounter>0)
{
intrade=true;
inbusiness=true;
readytotrade=true;
calcborders();
Print("Check in in Trade already: TRUE");
}
else
{Print("Check in in Trade already: FALSE");}
}

//+------------------------------------------------------------------+
//| Check MAs cross
//+------------------------------------------------------------------+
bool checkmascross()
{
if ((iMA(NULL,matf,smallma,0,0,1,0)>iMA(NULL,matf,bigma,0,0,1,0)&& iMA(NULL,matf,smallma,0,0,1,1)<=iMA(NULL,matf,bigma,0,0,1,1)) ||
    (iMA(NULL,matf,smallma,0,0,1,0)<iMA(NULL,matf,bigma,0,0,1,0)&& iMA(NULL,matf,smallma,0,0,1,1)>=iMA(NULL,matf,bigma,0,0,1,1)) ) 
    {
    if(debug) {Print("CheckMAsCross: MA Crossed");} 
    return true;}
else {return false;}
}

//+------------------------------------------------------------------+
//| Check Open Borders
//+------------------------------------------------------------------+
void checkopenborders()
{
      if(Bid>=top)
      {     
         if(debug) {Print("CheckOpenBorders: ----------------------CROSSED TOP--------------------------------");}
         if(debug) {Print("CheckOpenBorders: Intrade:Bid>=top"," Bid=",Bid, " top=",top);}
         calccid();
         analyzedatatop();
         //buy(extlots);               
      }
      else if(Bid<=bot)
      {           
         if(debug) {Print("CheckOpenBorders: ----------------------CROSSED BOTTOM------------------------------");}
         if(debug) {Print("CheckOpenBorders: Intrade:Bid<=bot"," Bid=",Bid, " botprofit=",bot);}  
         calccid();
         analyzedatabot();
         //sell(extlots);
      }
}

//+------------------------------------------------------------------+
//| Close all trades
//+------------------------------------------------------------------+
void closeall(bool done, bool buy)
  {
   int ordertype;
   int total=OrdersTotal();
   string comment;
   int ordercid;
   
   for(int i=total-1;i>=0;i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=magic) continue;

           if (!done) 
         {
            comment=OrderComment();
            ordercid=getcidfromcomment(comment);
            if (buy) 
            {
               if (ordercid<cid) 
               {
                  continue;
               } 
            }
            else 
            {
               if (ordercid>cid) 
               {
                  continue;
               }
            }
         }
         
         ordertype=OrderType();
         bool result=false;
         if(ordertype==0)
           {
            result=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),slip,Red);
           }
         else if(ordertype==1)
           {
            result=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),slip,Red);
           }
         if(!result)
           {
            int error=GetLastError();
            Print("Closeall: Failed to close order with ticket ",OrderTicket()," with error: ",error);
           }
         else
           {
            Print("Closeall: Order with ticket ",OrderTicket()," closed good!");
           }
        }
      else {if (debug){Print("Closeall: Error at orderselect! Returned false!");}return;}        
     }
     if (done) 
     {
     intrade=false;readytotrade=false;inbusiness=false;   
     ObjectSetText("prof","profit: 0",18,"Arial",White);
     ObjectSetText("moneyprof","Money: 0",18,"Arial",White);
     ObjectSetText("alpha","alpha: 0",10,"Arial",White);
     ObjectSetText("beta","beta: 0",10,"Arial",White);
     
     }
  }

//+------------------------------------------------------------------+
//| Close Order
//+------------------------------------------------------------------+
bool closeorder(bool buy, int incid)
{
int total=OrdersTotal();
bool result=false;
bool olakala=true;

for(int i=total-1;i>=0;i--)
  {
   if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
   {
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=magic) continue;
      string comment=OrderComment();
      int ordercid=getcidfromcomment(comment);
      if (incid!=ordercid) continue;
 
      if(buy) {result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), slip, Red );}
      else {result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), slip, Red );}
      
      if(!result) 
      {int error=GetLastError();
      Print("CloseOrder: Failed to close order with ticket ",OrderTicket(), " with error: ",error);return false; 
      }      
      else
      {
      Print("CloseOrder: Order with ticket ",OrderTicket()," closed good!");
      }
   }
   else {if (debug){Print("CloseOrder: Error at orderselect! Returned false!");}return false;}  
  }
return olakala;  
}

//+------------------------------------------------------------------+
//| Count Lots at level
//+------------------------------------------------------------------+
int countlotsatlevel (int level,bool buy)
{
int internalcounter=0;

if (buy)
{
for(int i=0;i<maxtrades;i++)
  {
   if (buybook[i]==level) {internalcounter++;}
  }
return internalcounter;  
}
else
{
for(int i=0;i<maxtrades;i++)
  {
   if (sellbook[i]==level) {internalcounter++;}
  }
return internalcounter;
}
}

//+------------------------------------------------------------------+
//| Count Profit
//+------------------------------------------------------------------+
bool countprofit()
{
double profit=0;
   string lprof=(string)NormalizeDouble(profit,2);
   string lmoneyprof=(string)NormalizeDouble(moneyprofit,2);
   ObjectSetText("prof","profit: "+lprof,18,"Arial",White);
   ObjectSetText("moneyprof","Money: "+lmoneyprof,18,"Arial",White);

if (debug) {Print("CountProfit: MoneyProfit=",moneyprofit);}  
if (moneyprofit>minprofit) {return true;}
else
{return false;}
/*
for(int i=0;i<maxtrades;i++)
  {
   if (buybook[i]>0) {profit+=(cid-buybook[i])*buybooklots[i];}
   if (sellbook[i]>0) {profit+=(sellbook[i]-cid)*sellbooklots[i];}
  }
if (debug) {Print("CountProfit: Profit=",profit);}  
   

if (profit>minprofit) {return true;} else {return false;} */
}

//-------------------------------------------------------------------------
// Create Labels
//-------------------------------------------------------------------------
void createlabels()
  {
//----
//Right Column
   ObjectCreate("pricelabel",OBJ_LABEL,0,0,0);
   ObjectSet("pricelabel",OBJPROP_CORNER,1);
   ObjectSet("pricelabel",OBJPROP_XDISTANCE,10);
   ObjectSet("pricelabel",OBJPROP_YDISTANCE,20);

   ObjectCreate("spreadlabel",OBJ_LABEL,0,0,0);
   ObjectSet("spreadlabel",OBJPROP_CORNER,1);
   ObjectSet("spreadlabel",OBJPROP_XDISTANCE,10);
   ObjectSet("spreadlabel",OBJPROP_YDISTANCE,50);
   
   ObjectCreate("step",OBJ_LABEL,0,0,0);
   ObjectSet("step",OBJPROP_CORNER,1);
   ObjectSet("step",OBJPROP_XDISTANCE,10);
   ObjectSet("step",OBJPROP_YDISTANCE,80);
 

   ObjectCreate("top",OBJ_LABEL,0,0,0);
   ObjectSet("top",OBJPROP_CORNER,1);
   ObjectSet("top",OBJPROP_XDISTANCE,10);
   ObjectSet("top",OBJPROP_YDISTANCE,110);

   ObjectCreate("bot",OBJ_LABEL,0,0,0);
   ObjectSet("bot",OBJPROP_CORNER,1);
   ObjectSet("bot",OBJPROP_XDISTANCE,10);
   ObjectSet("bot",OBJPROP_YDISTANCE,140);

   ObjectCreate("mag",OBJ_LABEL,0,0,0);
   ObjectSet("mag",OBJPROP_CORNER,1);
   ObjectSet("mag",OBJPROP_XDISTANCE,10);
   ObjectSet("mag",OBJPROP_YDISTANCE,170);
   
   ObjectCreate("day",OBJ_LABEL,0,0,0);
   ObjectSet("day",OBJPROP_CORNER,1);
   ObjectSet("day",OBJPROP_XDISTANCE,10);
   ObjectSet("day",OBJPROP_YDISTANCE,200);
   
   ObjectCreate("hour",OBJ_LABEL,0,0,0);
   ObjectSet("hour",OBJPROP_CORNER,1);
   ObjectSet("hour",OBJPROP_XDISTANCE,10);
   ObjectSet("hour",OBJPROP_YDISTANCE,230);
   
   ObjectCreate("prof",OBJ_LABEL,0,0,0);
   ObjectSet("prof",OBJPROP_CORNER,1);
   ObjectSet("prof",OBJPROP_XDISTANCE,10);
   ObjectSet("prof",OBJPROP_YDISTANCE,260);
   
   ObjectCreate("alpha",OBJ_LABEL,0,0,0);
   ObjectSet("alpha",OBJPROP_CORNER,1);
   ObjectSet("alpha",OBJPROP_XDISTANCE,10);
   ObjectSet("alpha",OBJPROP_YDISTANCE,290);

   ObjectCreate("beta",OBJ_LABEL,0,0,0);
   ObjectSet("beta",OBJPROP_CORNER,1);
   ObjectSet("beta",OBJPROP_XDISTANCE,10);
   ObjectSet("beta",OBJPROP_YDISTANCE,320);

   ObjectCreate("lots",OBJ_LABEL,0,0,0);
   ObjectSet("lots",OBJPROP_CORNER,1);
   ObjectSet("lots",OBJPROP_XDISTANCE,10);
   ObjectSet("lots",OBJPROP_YDISTANCE,350);
    
   ObjectCreate("mxlotsperlevel",OBJ_LABEL,0,0,0);
   ObjectSet("mxlotsperlevel",OBJPROP_CORNER,1);
   ObjectSet("mxlotsperlevel",OBJPROP_XDISTANCE,10);
   ObjectSet("mxlotsperlevel",OBJPROP_YDISTANCE,380);   
   
   ObjectCreate("moneyprof",OBJ_LABEL,0,0,0);
   ObjectSet("moneyprof",OBJPROP_CORNER,1);
   ObjectSet("moneyprof",OBJPROP_XDISTANCE,10);
   ObjectSet("moneyprof",OBJPROP_YDISTANCE,410);
//Top
   ObjectCreate("swaplonglabel",OBJ_LABEL,0,0,0);
   ObjectSet("swaplonglabel",OBJPROP_CORNER,4);
   ObjectSet("swaplonglabel",OBJPROP_XDISTANCE,300);
   ObjectSet("swaplonglabel",OBJPROP_YDISTANCE,0);

   ObjectCreate("swapshortlabel",OBJ_LABEL,0,0,0);
   ObjectSet("swapshortlabel",OBJPROP_CORNER,4);
   ObjectSet("swapshortlabel",OBJPROP_XDISTANCE,500);
   ObjectSet("swapshortlabel",OBJPROP_YDISTANCE,0);

   ObjectCreate("lastticklabel",OBJ_LABEL,0,0,0);
   ObjectSet("lastticklabel",OBJPROP_CORNER,4);
   ObjectSet("lastticklabel",OBJPROP_XDISTANCE,700);
   ObjectSet("lastticklabel",OBJPROP_YDISTANCE,0);

//Bottom
   ObjectCreate("tickvaluelabel",OBJ_LABEL,0,0,0);
   ObjectSet("tickvaluelabel",OBJPROP_CORNER,2);
   ObjectSet("tickvaluelabel",OBJPROP_XDISTANCE,0);
   ObjectSet("tickvaluelabel",OBJPROP_YDISTANCE,0);

   ObjectCreate("minlot",OBJ_LABEL,0,0,0);
   ObjectSet("minlot",OBJPROP_CORNER,2);
   ObjectSet("minlot",OBJPROP_XDISTANCE,200);
   ObjectSet("minlot",OBJPROP_YDISTANCE,0);

   ObjectCreate("margininit",OBJ_LABEL,0,0,0);
   ObjectSet("margininit",OBJPROP_CORNER,2);
   ObjectSet("margininit",OBJPROP_XDISTANCE,400);
   ObjectSet("margininit",OBJPROP_YDISTANCE,0);


   string Lswap   = (string)MarketInfo(Symbol(),MODE_SWAPLONG);
   string Sswap   = (string)MarketInfo(Symbol(),MODE_SWAPSHORT);
   string lstep=(string)step;
   string lhour=(string)starthour;
   string lday=(string)startday;
   string llots=(string)extlots;
   string lmxlots=(string)maxlotsperlevel;

   ObjectSetText("top","Top:0 ",10,"Arial",White);
   ObjectSetText("bot","Bot:0 ",10,"Arial",White);

   ObjectSetText("mag","magic= "+magicstr,12,"Arial",White);
   ObjectSetText("hour","Hour= "+lhour,16,"Arial",White);
   ObjectSetText("day","Day= "+lday,16,"Arial",White);
   
   ObjectSetText("lastticklabel","Lasttick:0 ",10,"Arial",White);
   ObjectSetText("swaplonglabel","Swap Long: "+Lswap,10,"Arial",White);
   ObjectSetText("swapshortlabel","Swap Short: "+Sswap,10,"Arial",White);
   ObjectSetText("tickvaluelabel","Tick value: "+DoubleToString(MarketInfo(Symbol(),MODE_TICKVALUE),2),16,"Arial",White);
   ObjectSetText("minlot","Min Lot: "+DoubleToString(MarketInfo(Symbol(),MODE_MINLOT),2),10,"Arial",White);
   ObjectSetText("margininit","Margin required to open 1 lot: "+DoubleToString(MarketInfo(Symbol(),MODE_MARGINREQUIRED)/100,2),10,"Arial",White);
   ObjectSetText("step","step: "+lstep,18,"Arial",White);
   ObjectSetText("prof","profit: 0",18,"Arial",White);
   ObjectSetText("moneyprof","Money: 0",18,"Arial",White);
   ObjectSetText("alpha","alpha: 0",10,"Arial",White);
   ObjectSetText("beta","beta: 0",10,"Arial",White);
   ObjectSetText("lots","Lots: "+llots,10,"Arial",White);
   ObjectSetText("mxlotsperlevel","Max lots: "+lmxlots,10,"Arial",White);
  }

//+------------------------------------------------------------------+
//| Find Divider and Calc Divided
//+------------------------------------------------------------------+
void findDivider()
  {
   marketdigits=MarketInfo(Symbol(),MODE_DIGITS);
   if(MarketInfo(Symbol(),MODE_DIGITS)>3)
     {
      divider=10000.0;     
     }
   else
     {
      divider=100.0;
     }
   stepdivider=step/divider; 
   stepflexibility=flexibility/divider;
   if(debug) {Print("Finddevider: stepdivider=",stepdivider);}
  }
  
//+------------------------------------------------------------------+
//| Find Expert Name
//+------------------------------------------------------------------+
void findexpertname()
  {
   string texpert="";
   texpert=WindowExpertName();
   expertname=StringSubstr(texpert,StringLen(texpert)-3,3);
   Print("Findexpertname:Expert=",expertname);
  }

//+------------------------------------------------------------------+
//| Find in books
//+------------------------------------------------------------------+
bool findinbooks(int incid, bool buy)
{
int i;

if (buy)
{
for(i=0;i<maxtrades;i++)
  {
   if (buybook[i]==incid) {return true;}
  }
return false;  
}
else
{
for(i=0;i<maxtrades;i++)
  {
   if (sellbook[i]==incid) {return true;}
  }
return false;  
}
}

//+------------------------------------------------------------------+
//| Find Minimum from buybook and maximum from sellbook
//+------------------------------------------------------------------+
void findminmax()
{
maxsell=0;
maxbuy=0;
minbuy=1000000;
minsell=1000000;

for(int i=0;i<maxtrades;i++)
  {
   if (minbuy>=buybook[i] && buybook[i]>0) {minbuy=buybook[i];}
   if (minsell>=sellbook[i] && sellbook[i]>0) {minsell=sellbook[i];}
   if (sellbook[i]>=maxsell) {maxsell=sellbook[i];}
   if (buybook[i]>=maxbuy) {maxbuy=buybook[i];}
  }
if (minbuy==1000000) minbuy=0; 
if (minsell==1000000) minsell=0;
if (debug) {Print("FindMinMax: minbuy=",minbuy," minsell=",minsell," maxbuy=",maxbuy," maxsell=",maxsell);}  
findmaxlots();
}

//+------------------------------------------------------------------+
//| Find Max Lots
//+------------------------------------------------------------------+
void findmaxlots()
{
maxbuylots=0.0;
maxselllots=0.0;
int tempbuybook[50];
int tempsellbook[50];


for(int i=0;i<maxtrades;i++)
  {
   totalbuybooklots[i]=buybooklots[i];
   totalsellbooklots[i]=sellbooklots[i];
   tempbuybook[i]=buybook[i];
   tempsellbook[i]=sellbook[i];
  }

//Update arrays so you can find max  
for(int i=0;i<maxtrades;i++)
  {
   if (tempbuybook[i]>0) 
      {
      for(int i1=i+1;i1<maxtrades;i1++)
        {
         if (tempbuybook[i]==tempbuybook[i1] && tempbuybook[i1]>0)
            {
            totalbuybooklots[i]+=buybooklots[i1];
            tempbuybook[i1]=0;
            }
        }
      }

   if (tempsellbook[i]>0) 
      {
      for(int i1=i+1;i1<maxtrades;i1++)
        {
         if (tempsellbook[i]==tempsellbook[i1] && tempsellbook[i1]>0)
            {
            totalsellbooklots[i]+=sellbooklots[i1];
            tempsellbook[i1]=0;
            }
        }
      }
      
  }  

//Sort arrays to find max
for(int i=0;i<maxtrades;i++)
  {
   if (totalbuybooklots[i]>maxbuylots) {maxbuylots=totalbuybooklots[i];}
   if (totalsellbooklots[i]>maxselllots) {maxselllots=totalsellbooklots[i];}
  } 

if (debug) {Print("FindMaxLots: maxbuylots=",maxbuylots," maxselllots=",maxselllots);}  
}

//-------------------------------------------------------------------------
// Find Start and End Prices to print lines
//-------------------------------------------------------------------------
void findStartandEndPrices()
  {
   double tendprice=0.0;

   for(int i=0;i<Bars;i++)
     {
      if(iHigh(NULL,0,i)>tendprice)
        {
         tendprice=iHigh(NULL,0,i);
        }
     }
   if(divider>100)
     {
      endprice=NormalizeDouble(tendprice,3);
     }
   else
     {
      endprice=NormalizeDouble(tendprice,0);
     }
  }

//-------------------------------------------------------------------------
// Find which MA is up
//-------------------------------------------------------------------------
bool findwhichmaisup()
{
if (debug) {Print("FindWhichMaisUP: SmallMA=",iMA(NULL,matf,smallma,0,0,1,0)," BigMA=",iMA(NULL,matf,bigma,0,0,1,0));}  
//returns true when small ma>big ma and false when big ma>small ma
if (iMA(NULL,matf,smallma,0,0,1,0)>iMA(NULL,matf,bigma,0,0,1,0)) {return true;}
else {return false;}
}
//+------------------------------------------------------------------+
//| Get cid from comment
//+------------------------------------------------------------------+
int getcidfromcomment(string comment)
{
int startpos=StringFind(comment,"cid=",0);
int endpos=StringFind(comment,";",0);
int len=endpos-startpos;
string cidstring=StringSubstr(comment,startpos+4,len-4);
int value=StrToInteger(cidstring);

if (debug) {Print("getcidfromcomment: cid=",value);}
return (value);
}

//+------------------------------------------------------------------+
//| Print Borders
//+------------------------------------------------------------------+
void printborders()
  {
   int digits=(int)MarketInfo(Symbol(),MODE_DIGITS);
   double ttop=NormalizeDouble(top,digits);
   double tbot=NormalizeDouble(bot,digits);
   string ltop=(string)ttop;
   string lbot=(string)tbot;
   ObjectSetText("top","Top: "+ltop,10,"Arial",White);
   ObjectSetText("bot","Bottom: "+lbot,10,"Arial",White);
  }
//+------------------------------------------------------------------+
//| Print Labels
//+------------------------------------------------------------------+
void printlabels()
  {
   string lspread=(string)MarketInfo(Symbol(),MODE_SPREAD);
   string lprice=(string)Bid;
   datetime lastick=(datetime)MarketInfo(Symbol(),MODE_TIME);
   string ltick=(string)lastick;
   ObjectSetText("pricelabel",lprice,18,"Arial",White);
   ObjectSetText("spreadlabel","Spread: "+lspread,12,"Arial",White);
   ObjectSetText("lastticklabel","Last tick: "+ltick,8,"Arial",White);
  }
//+------------------------------------------------------------------+
//| Print Lines
//+------------------------------------------------------------------+
void printlines()
  {
   startprice=0;
   string strprice;
   while(startprice<=endprice)
     {
      strprice=(string)startprice;
      ObjectCreate("line"+strprice,OBJ_HLINE,0,Time[0],startprice,0,0);
      ObjectSet("line"+strprice,OBJPROP_COLOR,Red);
      startprice+=stepdivider;
     }
  }
//+------------------------------------------------------------------+
//| Read Pool 
//+------------------------------------------------------------------+
void readpool()
{
int ordertype=0;
int total=OrdersTotal();
moneyprofit=0.0;

int ordercid=0;
double orderlots=0.0;
int bbookcnt=0;
int sbookcnt=0;
string ordercomment;

if (debug) {Print("ReadPool: ---------------------------START------------------------------");}
resetparams();
moneyprofit=0.0;
for(int i=total-1;i>=0;i--)
  {
   if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
      {       
         if(OrderSymbol()!=Symbol()) continue;
         if(OrderMagicNumber()!=magic) continue;  
         ordertype=OrderType();
         ordercomment=OrderComment();
         ordercid=getcidfromcomment(ordercomment);
         orderlots=OrderLots();
         moneyprofit+=OrderProfit();
         
         if (debug) {Print("ReadPool: ordercid=", ordercid,  " orderype=",ordertype);} 
         
         if (ordertype==0) {buycounter++;buybook[bbookcnt]=ordercid;buybooklots[bbookcnt]=orderlots;bbookcnt++;}
         if (ordertype==1) {sellcounter++;sellbook[sbookcnt]=ordercid;sellbooklots[sbookcnt]=orderlots;sbookcnt++;}
      }      
  else
    {Print("Readpool: OrderSelect returned the error of ",GetLastError());}
  }
if (debug) {Print("ReadPool: buycounter=",buycounter, " sellcounter=", sellcounter);}
findminmax();
}

//+------------------------------------------------------------------+
//| Reset Params
//+------------------------------------------------------------------+
void resetparams()
{
buycounter=0;
sellcounter=0;
for(int i=0;i<maxtrades;i++)
  {
   buybook[i]=0;
   sellbook[i]=0;
   buybooklots[i]=0.0;
   sellbooklots[i]=0.0;
  }
if(debug) {Print("ResetParams: Params reset done.");}
}


//+------------------------------------------------------------------+
//| Sell
//+------------------------------------------------------------------+
int sell(double internallots)
  {
   if (debug) {Print("Sell: I will sell with lots=",internallots);}
   buildcomment();
   
   int error;
   int ticket=OrderSend(Symbol(),OP_SELL,internallots,Bid,slip,0,0,message,magic,0,clrRed);
   if(ticket<0) {error=GetLastError();Print("OrderSend failed with error #",error);return(error);}
   else 
     {
      Print("OrderSend placed successfully");
      intrade=true;
      calctopprofit();
      return(0);
     }
   return (0);
  }
//+------------------------------------------------------------------+
//| Set Magic Number
//+------------------------------------------------------------------+
void setmagicnumber()
  {
   string pair=Symbol();
   magicstr="";

   if(debug) {Print("setmagicnumber: Symbol=",pair);}
   int pos;
   int i=1;
   string pairs[9]={"","GBP","EUR","AUD","NZD","JPY","GOLD","CAD","USD"};

   for(i=1;i<9;i++)
     {
      pos=StringFind(pair,pairs[i],0);
      if(pos>-1)
        {
         magicstr+=IntegerToString(i,1);
        }
     }

   string lid=(string)id;
   magicstr=magicstr+lid;
   magic=StrToInteger(magicstr);
   Print("Setmagicnumber: Magic=",magicstr);
  }
  
//+------------------------------------------------------------------+
//| Trade
//+------------------------------------------------------------------+  
void trade(bool buy,bool firstlegscalable)
{

if (firstlegscalable)
{
   if (buy)
   {
   lots=maxselllots-lotsatlevel+steplots;
   if (lots+lotsatlevel>maxlotsperlevel) {lots=maxlotsperlevel-lotsatlevel;}   
   if (lots>0) {buy(lots);}
   }
   else
   {
   lots=maxbuylots-lotsatlevel+steplots;
   if (lots+lotsatlevel>maxlotsperlevel) {lots=maxlotsperlevel-lotsatlevel;}   
   if (lots>0) {sell(lots);}
   }
}
else
{
   if (buy)
   {
   lots=lotsatpreviouslevel+addlots-lotsatlevel;
   if (lotsatlevel+lots>maxlotsperlevel) {lots=maxlotsperlevel-lotsatlevel;}
   if (lots<=0) {lots=extlots;}
   if (lots>0) {buy(lots);}
   }
   else
   {
   lots=lotsatpreviouslevel+addlots-lotsatlevel;
   if (lotsatlevel+lots>maxlotsperlevel) {lots=maxlotsperlevel-lotsatlevel;}
   if (lots<=0) {lots=extlots;}
   if (lots>0) {sell(lots);}  
   }   
}

if (debug) {Print("Trade: lots=",lots);}
}
 //+------------------------------------------------------------------+
