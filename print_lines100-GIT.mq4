//+------------------------------------------------------------------+
//|                                                  print_lines.mq4 |
//|                                                            alkas |
//|                                                         alkas.gr |
//+------------------------------------------------------------------+
//Actually an indicator prinnting on screen horizontal lines to calculate possible traders

#property copyright "alkas"
#property link      "alkas.gr"

extern double startprice=70;
extern double endprice=200;
extern int step=50; // number of pips
extern bool fivedigits=false;

string stringprice;
string stringspread;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   while (startprice<=endprice)  
   {
   
      if (fivedigits)
         {
            ObjectCreate("line"+startprice, OBJ_HLINE, 0, Time[0], startprice, 0, 0);
            startprice+=step/10000.0;
         }
     else
         {
            ObjectCreate("line"+startprice, OBJ_HLINE, 0, Time[0], startprice, 0, 0);
            startprice+=step/100.0;        
         }
    }
createlabels();
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   ObjectsDeleteAll(0,OBJ_LABEL);
   ObjectsDeleteAll(0,OBJ_HLINE);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
   printlabels();   
//----
   return(0);
  }
//+------------------------------------------------------------------+

//-------------------------------------------------------------------------
// FUNCTIONS
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
// PRINTLABELS
//-------------------------------------------------------------------------
void createlabels()
{
Print("Create Labels");
//----
ObjectCreate("pricelabel",OBJ_LABEL, 0, 0, 0);
ObjectSet( "pricelabel", OBJPROP_CORNER, 1);
ObjectSet( "pricelabel", OBJPROP_XDISTANCE,10 );
ObjectSet( "pricelabel", OBJPROP_YDISTANCE,50 );

ObjectCreate("spreadlabel",OBJ_LABEL, 0, 0, 0);
ObjectSet( "spreadlabel", OBJPROP_CORNER, 1);
ObjectSet( "spreadlabel", OBJPROP_XDISTANCE,10 );
ObjectSet( "spreadlabel", OBJPROP_YDISTANCE,80 );

ObjectCreate("ma30",OBJ_LABEL, 0, 0, 0);
ObjectSet( "ma30", OBJPROP_CORNER, 1);
ObjectSet( "ma30", OBJPROP_XDISTANCE,10 );
ObjectSet( "ma30", OBJPROP_YDISTANCE,140 );

ObjectCreate("mah1",OBJ_LABEL, 0, 0, 0);
ObjectSet( "mah1", OBJPROP_CORNER, 1);
ObjectSet( "mah1", OBJPROP_XDISTANCE,10 );
ObjectSet( "mah1", OBJPROP_YDISTANCE,170 );

ObjectCreate("mah4",OBJ_LABEL, 0, 0, 0);
ObjectSet( "mah4", OBJPROP_CORNER, 1);
ObjectSet( "mah4", OBJPROP_XDISTANCE,10 );
ObjectSet( "mah4", OBJPROP_YDISTANCE,200 );

ObjectCreate("mad1",OBJ_LABEL, 0, 0, 0);
ObjectSet( "mad1", OBJPROP_CORNER, 1);
ObjectSet( "mad1", OBJPROP_XDISTANCE,10 );
ObjectSet( "mad1", OBJPROP_YDISTANCE,230 );

ObjectCreate("maw",OBJ_LABEL, 0, 0, 0);
ObjectSet( "maw", OBJPROP_CORNER, 1);
ObjectSet( "maw", OBJPROP_XDISTANCE,10 );
ObjectSet( "maw", OBJPROP_YDISTANCE,260 );

ObjectCreate("trade30",OBJ_LABEL, 0, 0, 0);
ObjectSet( "trade30", OBJPROP_CORNER, 1);
ObjectSet( "trade30", OBJPROP_XDISTANCE,10 );
ObjectSet( "trade30", OBJPROP_YDISTANCE,360 );

ObjectCreate("tradeh1",OBJ_LABEL, 0, 0, 0);
ObjectSet( "tradeh1", OBJPROP_CORNER, 1);
ObjectSet( "tradeh1", OBJPROP_XDISTANCE,10 );
ObjectSet( "tradeh1", OBJPROP_YDISTANCE,390 );

ObjectCreate("tradeh4",OBJ_LABEL, 0, 0, 0);
ObjectSet( "tradeh4", OBJPROP_CORNER, 1);
ObjectSet( "tradeh4", OBJPROP_XDISTANCE,10 );
ObjectSet( "tradeh4", OBJPROP_YDISTANCE,420 );


ObjectCreate("traded1",OBJ_LABEL, 0, 0, 0);
ObjectSet( "traded1", OBJPROP_CORNER, 1);
ObjectSet( "traded1", OBJPROP_XDISTANCE,10 );
ObjectSet( "traded1", OBJPROP_YDISTANCE,450 );

ObjectCreate("tradew",OBJ_LABEL, 0, 0, 0);
ObjectSet( "tradew", OBJPROP_CORNER, 1);
ObjectSet( "tradew", OBJPROP_XDISTANCE,10 );
ObjectSet( "tradew", OBJPROP_YDISTANCE,480 );


}

//-------------------------------------------------------------------------
// PRINTLABELS
//-------------------------------------------------------------------------
void printlabels()
{
int i;
//Print Objects
if (fivedigits)
{stringprice=DoubleToStr(Bid,5);}
else
{stringprice=DoubleToStr(Bid,3); }

ObjectSetText("pricelabel",stringprice,18,"Arial",White);   
stringspread=DoubleToStr(MarketInfo(Symbol(),MODE_SPREAD),0);
ObjectSetText("spreadlabel","Spread: " + stringspread,12,"Arial",White); 

printsmart(30);
printsmart(60);
printsmart(240);
printsmart(1440);
printsmart(10080  );
}

//-------------------------------------------------------------------------
// PRINTSMART
//-------------------------------------------------------------------------
void printsmart(int tf)
{
bool found;

string tfstring;

switch (tf)
   {
      case 30 :tfstring="30";break;
      case 60 :tfstring="h1";break;
      case 240 :tfstring="h4";break;
      case 1440 :tfstring="d1";break;
      case 10080 :tfstring="w";break;
   }

found=false;
if (iMA(NULL,tf,5,0,2,1,0)>iMA(NULL,tf,5,0,2,1,1) && iMA(NULL,tf,20,0,1,1,0)>iMA(NULL,tf,20,0,1,1,1) && iMA(NULL,tf,50,0,1,1,0)>iMA(NULL,tf,50,0,1,1,1)) {ObjectSetText("ma"+tfstring,"MA"+tfstring+": UP",18,"Arial",Green);found=true;}
if (iMA(NULL,tf,5,0,2,1,0)<iMA(NULL,tf,5,0,2,1,1) && iMA(NULL,tf,20,0,1,1,0)<iMA(NULL,tf,20,0,1,1,1) && iMA(NULL,tf,50,0,1,1,0)<iMA(NULL,tf,50,0,1,1,1)) {ObjectSetText("ma"+tfstring,"MA"+tfstring+": DOWN",18,"Arial",Red);found=true;}

if (!found) ObjectSetText("ma"+tfstring,"MA"+tfstring+": WAIT",18,"Arial",White);

found=false;

if (iMA(NULL,tf,5,0,2,1,0)>iMA(NULL,tf,5,0,2,1,1) && iMA(NULL,tf,20,0,1,1,0)>iMA(NULL,tf,20,0,1,1,1) && iMA(NULL,tf,50,0,1,1,0)>iMA(NULL,tf,50,0,1,1,1) && iClose(NULL,tf,1)>iClose(NULL,tf,2) && iClose(NULL,tf,2)<iOpen(NULL,tf,2)) {ObjectSetText("trade"+tfstring,"Trade"+tfstring+": BUY",18,"Arial",Green);found=true;}
if (iMA(NULL,tf,5,0,2,1,0)<iMA(NULL,tf,5,0,2,1,1) && iMA(NULL,tf,20,0,1,1,0)<iMA(NULL,tf,20,0,1,1,1) && iMA(NULL,tf,50,0,1,1,0)<iMA(NULL,tf,50,0,1,1,1) && iClose(NULL,tf,1)<iClose(NULL,tf,2) && iClose(NULL,tf,2)>iOpen(NULL,tf,2)) {ObjectSetText("trade"+tfstring,"Trade"+tfstring+": SELL",18,"Arial",Red);found=true;}

if (!found) ObjectSetText("trade"+tfstring,"Trade"+tfstring+": WAIT",18,"Arial",White);
}