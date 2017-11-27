//+------------------------------------------------------------------+
//|                                          Tend_Explorer.mq4       |
//|                                                            alkas |
//|                                                         alkas.gr |
//+------------------------------------------------------------------+
//Purpose is to find how price is moving between borders and outpout the results
//

#property copyright "alkas"
#property link      "alkas.gr"

extern double lotsize=0.01;
extern int maxnumoftrades=1;
extern int maxtradesperday=100;
extern bool range=false;
extern int magic=7;
extern int step=50; // number of pips

extern int tp=10;
extern int sl=10;

extern bool fivedigits=true;
extern double startprice=0.7;
extern double startprice3=100;
extern bool usema=true;
extern int maperiod=14;
extern string out1="---------------END OF BASIC PARAMS-----------------";
extern int maxspread=120;

extern int slipage=1;


extern int starthour=0;
extern int startmin=0;
extern int endhour=22;
extern int endmin=0;

//------------------------------------------------
//Print lines VARIABLES

extern double endprice=2.0;
extern double endprice3=200;

//------------------------------------------------
// Internal Static variables
double borders[3000];
bool intrade=false;
int borderup=0;
int borderdown=0;

int opentradescounter=0;
bool buyroute=false;
string stringprice;
string stringspread;
double levelzero=0;
bool readyfortrade=true;
int tradesfortheday=0;

bool firsttrade=false;
double divider;
bool firsttradestarted=false;
string results[100];
int resultscounter=0;
int lasttradeindex;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   clearparams();
   printlines();
   createlabels();
   printlabels();
   printstaticlabels();
   if (fivedigits) divider=10000.0; else divider=100.0;
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
   clearparams();
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
static int previousday;

if (borderup==0) whereami();
if (Day()!=previousday) {previousday=Day();resultscounter++;}
  // checktime();   
   //if (readyfortrade==false) return;
   
  // if (tradesfortheday==maxtradesperday) return;

                    
   if (!firsttrade)  {checkfirsttrade();}
   else {checknexttrade();}
          

   printlabels();
//----
   return(0);
  }
//+------------------------------------------------------------------+

//-------------------------------------------------------------------------
//FUNCTIONS
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
// CHECK TIME
//-------------------------------------------------------------------------
void checktime()
{
   static bool firstwhereami=false;
   if (Hour()<starthour) readyfortrade=false;
   if (Hour()==starthour) 
      {
         if (Minute()>=startmin) 
            {
               readyfortrade=true;
               
            }
        else
            {
               readyfortrade=false;   
            }   
      }
   if (Hour()>starthour)
      {
         if (Hour()<endhour) readyfortrade=true;
         if (Hour()==endhour)
            {
               if (Minute()<=endmin) 
                  {
                     readyfortrade=true;
                  }
               else
                  {
                     readyfortrade=false;
                  }
            } 
         if (Hour()>endhour) 
            {tradesfortheday=0;readyfortrade=false;firstwhereami=false;resultscounter++;firsttrade=false;} 
      }             

}
//-------------------------------------------------------------------------
// CHECK FIRST TRADE
//-------------------------------------------------------------------------
void checkfirsttrade()
{
   if (firsttradestarted) 
      {
         if (buyroute) 
            {if (Bid>=borders[borderup]+step/divider) {buyroute=true;firsttrade=true;results[resultscounter]=Day()+"."+Month()+"."+Year()+" "+"T, ";lasttradeindex=borderup+1;printresults();} //TREND
             if (Bid<=borders[borderdown]) {buyroute=false;firsttrade=true;results[resultscounter]=Day()+"."+Month()+"."+Year()+" R, ";lasttradeindex=borderdown;printresults();}} //RANGE  
         else 
            {if (Bid<=borders[borderdown]-step/divider) {buyroute=false;firsttrade=true;results[resultscounter]=Day()+"."+Month()+"."+Year()+" "+"T, ";lasttradeindex=borderdown-1;printresults();}
             if (Bid>=borders[borderup]) {buyroute=true;firsttrade=true;results[resultscounter]=Day()+"."+Month()+"."+Year()+" "+"R, ";lasttradeindex=borderup;printresults();}}
       }
   else 
      {if (Bid>=borders[borderup]) {buyroute=true;firsttradestarted=true;Print("firsttradestarted, buyroute"+" division: "+step/divider+" border[down]:" +borders[borderdown] );} 
       if (Bid<=borders[borderdown]) {buyroute=false;firsttradestarted=true;Print("firsttradestarted, sellroute");}}
}
//-------------------------------------------------------------------------
// CHECK NEXT TRADE
//-------------------------------------------------------------------------
void checknexttrade()
{
   if (buyroute)
      {
         if (Bid>=borders[lasttradeindex+1]) {lasttradeindex++;results[resultscounter]=results[resultscounter]+"T, ";printresults();buyroute=true;}
         if (Bid<=borders[lasttradeindex-1]) {lasttradeindex--;results[resultscounter]=results[resultscounter]+"R, ";printresults();buyroute=false;}
      }
   else
      {
         if (Bid>=borders[lasttradeindex+1]) {lasttradeindex++;results[resultscounter]=results[resultscounter]+"R, ";printresults();buyroute=true;}
         if (Bid<=borders[lasttradeindex-1]) {lasttradeindex--;results[resultscounter]=results[resultscounter]+"T, ";printresults();buyroute=false;}
      }
  
}
//-------------------------------------------------------------------------
// PRINT RESULTS
//-------------------------------------------------------------------------
void printresults()
{
   for (int i=1;i<=resultscounter;i++) {Print(i+". resultscounter: "+results[i]);}
}

//-------------------------------------------------------------------------
// PRINT STATIC LABELS
//-------------------------------------------------------------------------
void printstaticlabels()
{
   ObjectSetText("magic","Magic: " + magic,10,"Arial",White);
   ObjectSetText("lotsize","Lot Size: " + DoubleToStr(lotsize,2),10,"Arial",White);
   ObjectSetText("maxnumoftrades","Max trades per trade: " + maxnumoftrades,10,"Arial",White);
   ObjectSetText("range","Range: " + range,10,"Arial",White);
   ObjectSetText("maxnumoftradesperday","Max trades per day: " + maxtradesperday,10,"Arial",White);
   ObjectSetText("step","Step: " + step,10,"Arial",White);
   if (fivedigits) {ObjectSetText("stp","Start price: " + DoubleToStr(startprice,2),10,"Arial",White);}
   else {ObjectSetText("stp","Start price: " + DoubleToStr(startprice3,2),10,"Arial",White);}
   ObjectSetText("stime","Start: " +starthour+":"+startmin,10,"Arial",White);
   ObjectSetText("etime","End: " +endhour+":"+endmin,10,"Arial",White);
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
ObjectSetText("opentradescounter","Open trades: " + opentradescounter,10,"Arial",White);
ObjectSetText("intrade","Intrade: " + intrade,10,"Arial",White);
ObjectSetText("buyroute","Buy route: " + buyroute,10,"Arial",White);
ObjectSetText("borderup","Border up: " + DoubleToStr(borderup,5),12,"Arial",White);
ObjectSetText("borderdown","Border down: " + DoubleToStr(borderdown,5),12,"Arial",White);

ObjectSetText("tradestoday","Today traded: " + tradesfortheday+ " times",10,"Arial",White);
ObjectSetText("timenow",Hour()+":" + Minute(),10,"Arial",White);
}
//-------------------------------------------------------------------------
//Print lines
//-------------------------------------------------------------------------
void printlines()
{
Print("Print Lines");
   double stp=startprice;
   double enp=endprice;
   double stp3=startprice3;
   double enp3=endprice3;      
   int i=1;
   
   if (fivedigits)
      {
         while (stp<=enp)  
            {
               ObjectCreate("line"+stp, OBJ_HLINE, 0, Time[0], stp, 0, 0);
               ObjectSet("line"+stp,OBJPROP_COLOR,Blue);
               borders[i]=stp;
               stp+=step/10000.0;
               i++;
            }
      }
   else
      {
         while (stp3<=enp3)  
            {
               ObjectCreate("line"+stp3, OBJ_HLINE, 0, Time[0], stp3, 0, 0);
               ObjectSet("line"+stp3,OBJPROP_COLOR,Blue);
               borders[i]=stp3;
               stp3+=step/100.0;
               i++;
            }
      }
Print(borders[90]);
}
//-------------------------------------------------------------------------
//WHERE AM I
//-------------------------------------------------------------------------
void whereami()
{
int i;   
      for (i=1;i<=3000;i++)
         {
            if (Bid-borders[i]<=step/divider)
               {               
                  borderdown=i;
                  borderup=i+1;
                  break;
               }
         }
Print("Whereami:I just found where i am. Borderup: "+borderup+" borderdown: "+borderdown + " and BID: "+Bid);
}
//-------------------------------------------------------------------------
//CLEAR PARAMS
//-------------------------------------------------------------------------
void clearparams()
{
   Print("clearparams");
   opentradescounter=0;
   intrade=false;
}

//-------------------------------------------------------------------------
//   CREATE LABELS
//-------------------------------------------------------------------------
void createlabels()
{
Print("Create Labels");
//---- PRICE RELATIVE LABELS 
ObjectCreate("pricelabel",OBJ_LABEL, 0, 0, 0);
ObjectSet( "pricelabel", OBJPROP_CORNER, 1);
ObjectSet( "pricelabel", OBJPROP_XDISTANCE,10 );
ObjectSet( "pricelabel", OBJPROP_YDISTANCE,50 );

ObjectCreate("spreadlabel",OBJ_LABEL, 0, 0, 0);
ObjectSet( "spreadlabel", OBJPROP_CORNER, 1);
ObjectSet( "spreadlabel", OBJPROP_XDISTANCE,10 );
ObjectSet( "spreadlabel", OBJPROP_YDISTANCE,80 );

ObjectCreate("borderup",OBJ_LABEL, 0, 0, 0);
ObjectSet( "borderup", OBJPROP_CORNER, 1);
ObjectSet( "borderup", OBJPROP_XDISTANCE,10 );
ObjectSet( "borderup", OBJPROP_YDISTANCE,110 );

ObjectCreate("borderdown",OBJ_LABEL, 0, 0, 0);
ObjectSet( "borderdown", OBJPROP_CORNER, 1);
ObjectSet( "borderdown", OBJPROP_XDISTANCE,10 );
ObjectSet( "borderdown", OBJPROP_YDISTANCE,130 );
//-------------------------------------------------

// STATIC LABELS

ObjectCreate("etime",OBJ_LABEL, 0, 0, 0);
ObjectSet( "etime", OBJPROP_CORNER, 3);
ObjectSet( "etime", OBJPROP_XDISTANCE,10 );
ObjectSet( "etime", OBJPROP_YDISTANCE,10 );

ObjectCreate("stime",OBJ_LABEL, 0, 0, 0);
ObjectSet( "stime", OBJPROP_CORNER, 3);
ObjectSet( "stime", OBJPROP_XDISTANCE,10 );
ObjectSet( "stime", OBJPROP_YDISTANCE,30 );

ObjectCreate("magic",OBJ_LABEL, 0, 0, 0);
ObjectSet( "magic", OBJPROP_CORNER, 3);
ObjectSet( "magic", OBJPROP_XDISTANCE,10 );
ObjectSet( "magic", OBJPROP_YDISTANCE,50 );

ObjectCreate("range",OBJ_LABEL, 0, 0, 0);
ObjectSet( "range", OBJPROP_CORNER, 3);
ObjectSet( "range", OBJPROP_XDISTANCE,10 );
ObjectSet( "range", OBJPROP_YDISTANCE,70 );

ObjectCreate("maxnumoftrades",OBJ_LABEL, 0, 0, 0);
ObjectSet( "maxnumoftrades", OBJPROP_CORNER, 3);
ObjectSet( "maxnumoftrades", OBJPROP_XDISTANCE,10 );
ObjectSet( "maxnumoftrades", OBJPROP_YDISTANCE,90 );

ObjectCreate("maxnumoftradesperday",OBJ_LABEL, 0, 0, 0);
ObjectSet( "maxnumoftradesperday", OBJPROP_CORNER, 3);
ObjectSet( "maxnumoftradesperday", OBJPROP_XDISTANCE,10 );
ObjectSet( "maxnumoftradesperday", OBJPROP_YDISTANCE,110 );

ObjectCreate("stp",OBJ_LABEL, 0, 0, 0);
ObjectSet( "stp", OBJPROP_CORNER, 3);
ObjectSet( "stp", OBJPROP_XDISTANCE,10 );
ObjectSet( "stp", OBJPROP_YDISTANCE,130 );

ObjectCreate("lotsize",OBJ_LABEL, 0, 0, 0);
ObjectSet( "lotsize", OBJPROP_CORNER, 3);
ObjectSet( "lotsize", OBJPROP_XDISTANCE,10 );
ObjectSet( "lotsize", OBJPROP_YDISTANCE,150 );

ObjectCreate("step",OBJ_LABEL, 0, 0, 0);
ObjectSet( "step", OBJPROP_CORNER, 3);
ObjectSet( "step", OBJPROP_XDISTANCE,10 );
ObjectSet( "step", OBJPROP_YDISTANCE,170 );
//-------------------------------------------------

// DYNAMIC LABELS

ObjectCreate("opentradescounter",OBJ_LABEL, 0, 0, 0);
ObjectSet( "opentradescounter", OBJPROP_CORNER, 2);
ObjectSet( "opentradescounter", OBJPROP_XDISTANCE,10 );
ObjectSet( "opentradescounter", OBJPROP_YDISTANCE,10 );

ObjectCreate("intrade",OBJ_LABEL, 0, 0, 0);
ObjectSet( "intrade", OBJPROP_CORNER, 2);
ObjectSet( "intrade", OBJPROP_XDISTANCE,10 );
ObjectSet( "intrade", OBJPROP_YDISTANCE,30 );

ObjectCreate("buyroute",OBJ_LABEL, 0, 0, 0);
ObjectSet( "buyroute", OBJPROP_CORNER, 2);
ObjectSet( "buyroute", OBJPROP_XDISTANCE,10 );
ObjectSet( "buyroute", OBJPROP_YDISTANCE,50 );

ObjectCreate("tradestoday",OBJ_LABEL, 0, 0, 0);
ObjectSet( "tradestoday", OBJPROP_CORNER, 2);
ObjectSet( "tradestoday", OBJPROP_XDISTANCE,10 );
ObjectSet( "tradestoday", OBJPROP_YDISTANCE,70 );

ObjectCreate("timenow",OBJ_LABEL, 0, 0, 0);
ObjectSet( "timenow", OBJPROP_CORNER, 2);
ObjectSet( "timenow", OBJPROP_XDISTANCE,10 );
ObjectSet( "timenow", OBJPROP_YDISTANCE,90 );
//-------------------------------------------------

//ObjectCreate("finishedfortheday",OBJ_LABEL, 0, 0, 0);
//ObjectSet( "finishedfortheday", OBJPROP_CORNER, 2);
//ObjectSet( "finishedfortheday", OBJPROP_XDISTANCE,10 );
//ObjectSet( "finishedfortheday", OBJPROP_YDISTANCE,110 );
}
//---------------------------  
// END
//---------------------------