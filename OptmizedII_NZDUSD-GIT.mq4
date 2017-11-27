//+------------------------------------------------------------------+
//|                                        Done_Optimized_NZDUSD.mq4 |
//|                                                            alkas |
//|                                                         alkas.gr |
//+------------------------------------------------------------------+
#property copyright "alkas"
#property link      "alkas.gr"

extern double lotsize=0.05;
extern int maxnumoftrades=2;
extern int maxtradesperday=1;
extern bool range=false;
extern int magic=10;
extern int step=10; // number of pips
extern bool fivedigits=true;
extern double startprice=0.8;
extern double startprice3=100;
extern string out1="---------------END OF BASIC PARAMS-----------------";
//extern int tp=10;
//extern int sl=20;
extern int maxspread=120;

extern int slipage=1;


extern int starthour=0;
extern int startmin=0;
extern int endhour=22;
extern int endmin=0;

//+------------------------------------------------------------------+
//Print lines VARIABLES
//+------------------------------------------------------------------+
extern double endprice=2.0;
extern double endprice3=200;

//+------------------------------------------------------------------+
// Internal Static variables
//+------------------------------------------------------------------+
double borders[3000];
bool intrade=false;
double borderup=0;
double borderdown=0;

int opentradescounter=0;
bool buyroute=false;
string stringprice;
string stringspread;
double levelzero=0;
bool readyfortrade=true;
int tradesfortheday=0;

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
   checktime();   
   if (readyfortrade==false) return;
   
   if (tradesfortheday==maxtradesperday) return;
      
   if (!intrade)
      {         
         if (MarketInfo(Symbol(),MODE_SPREAD)>maxspread) {Print("Start: Spread is bigger than max spread. "+ MarketInfo(Symbol(),MODE_SPREAD));return;} //check for spread
         if (borderup==0 || borderdown==0) {Print("Start: Oops! borderup or down found to be 0. I will call whereami. Borderup: "+borderup+" borderdown: "+borderdown);whereami();}
         startnewtrade();      
         checkforwhereami();     
      }
else
   {
      if (fivedigits) {mainlogic();}
      else {mainlogic100();}
   }      

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
         if (Minute()==startmin && !firstwhereami) {Print("checktime: I will start to work. I will run whereami.");whereami();firstwhereami=true;}
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
            {tradesfortheday=0;readyfortrade=false;firstwhereami=false;} 
      }         

   if (!readyfortrade && intrade==true) {Print("Checktime: Time not for trade but orders are open. I will close them.");closeorders(false);}      

}
//-------------------------------------------------------------------------
// START NEW TRADE
//-------------------------------------------------------------------------
void startnewtrade()
{
 if (Bid>=borderup) 
            {
               if (range)
                  {
                     Print("startnewtrade: Bid > borderup. Range. 1st trade. I will sell now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);
                     sendsellorder(lotsize);
                     buyroute=false;
                     levelzero=borderup;
                  }
               else 
                  {
                     Print("startnewtrade: Bid > borderup. TREND. 1st trade. I will buy now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);
                     sendbuyorder(lotsize);buyroute=true;              
                  }
            }
if (Bid<=borderdown)
            {  
               if (range) 
                  {
                     Print("startnewtrade: Bid < borderdown. Range. 1st trade. I will buy now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);
                     sendbuyorder(lotsize);buyroute=true;levelzero=borderdown;
                  }
               else  
                  {
                     Print("startnewtrade: Bid < borderdown. TREND. 1st trade. I will sell now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);
                     sendsellorder(lotsize);buyroute=false;levelzero=borderdown;
                  }
            }            
}


//-------------------------------------------------------------------------
// MAIN LOGIC
//-------------------------------------------------------------------------
void mainlogic()
{
//win?
      if (buyroute)
         {
            if (range)
               {                 
                  if (Bid>=borderup) {Print("mainlogic: We WON (1 trade)! Bid > borderup. Range. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);closeorders(false);}
                  if (opentradescounter>1 && Bid>=borderdown) {Print("mainlogic: We WON (many trades)! Bid > borderup. Range. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);closeorders(false);}
                  if (maxnumoftrades==opentradescounter && Bid<=borderdown-(step*opentradescounter)/10000.0) {Print("mainlogic: We LOST! Bid < borderdown. Range. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);closeorders(false);}
                  if (opentradescounter<maxnumoftrades && Bid<=borderdown-(step*opentradescounter)/10000.0) {Print("mainlogic: Bid < borderdown. Range. 1 more order. I will BUY now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);sendbuyorder(lotsize);}
               }
            else
               {
                  if (Bid>=borderup + (step*opentradescounter)/10000.0) {Print("mainlogic 1: We WON (1 trade)! Bid > borderup. TREND. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);closeorders(false);}                 
                  if (opentradescounter==1 && Bid<=borderdown) {Print("mainlogic 2: We LOST 1st trade! Bid < borderdown. TREND. I will close all orders now and SELL"+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);closeorders(true);sendsellorder(lotsize*2);}
                  if (maxnumoftrades==opentradescounter && Bid>=borderup)  {Print("mainlogic 3: We LOST! Bid > borderup. TREND. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);closeorders(false);}
                  if (maxnumoftrades==opentradescounter && Bid<=borderdown-(step)/10000.0) {Print("mainlogic 4: WE WON! Bid < borderdown. TREND. I will CLOSE ORDERS now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);closeorders(false);}
               }
         }
       else
         {
             if (range)
               {
                  if (Bid<=borderdown) {Print("mainlogic: We WON! Bid < borderup. Range. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);closeorders(false);}
                  if (opentradescounter>1 && Bid<=borderup) {Print("mainlogic: We WON (many trades)! Bid < borderup. Range. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderup);closeorders(false);}
                  if (maxnumoftrades==opentradescounter && Bid>=borderup+(step*opentradescounter)/10000.0) {Print("mainlogic: We LOST! Bid > borderup. Range. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);closeorders(false);}
                  if (opentradescounter<maxnumoftrades && Bid>=borderup+(step*opentradescounter)/10000.0) {Print("mainlogic: Bid > borderup. Range. 1 more order. I will SELL now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);sendsellorder(lotsize);}
               }
            else
               {
                  if (Bid<=borderdown - (step*opentradescounter)/10000.0) {Print("mainlogic 1: We WON (1 trade)! Bid < borderdown. TREND. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);closeorders(false);}                 
                  if (opentradescounter==1 && Bid>=borderup) {Print("mainlogic 2: We LOST 1st trade! Bid > borderup. TREND. I will close all orders now and BUY"+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);closeorders(true);sendbuyorder(lotsize*2);}
                  if (maxnumoftrades==opentradescounter && Bid<=borderdown)  {Print("mainlogic 3: We LOST! Bid < borderdown. TREND. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderdown);closeorders(false);}
                  if (maxnumoftrades==opentradescounter && Bid>=borderup+(step)/10000.0) {Print("mainlogic 4: WE WON! Bid > borderup. TREND. I will CLOSE ORDERS now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);closeorders(false);}
               }
         }
}

//-------------------------------------------------------------------------
// MAIN LOGIC100
//-------------------------------------------------------------------------
void mainlogic100()
{
//win?
      if (buyroute)
         {
            if (range)
               {                 
                  if (Bid>=borderup) {Print("mainlogic: We WON (1 trade)! Bid > borderup. Range. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);closeorders(false);}
                  if (opentradescounter>1 && Bid>=borderdown) {Print("mainlogic: We WON (many trades)! Bid > borderup. Range. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);closeorders(false);}
                  if (maxnumoftrades==opentradescounter && Bid<=borderdown-(step*opentradescounter)/100.0) {Print("mainlogic: We LOST! Bid < borderdown. Range. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);closeorders(false);}
                  if (opentradescounter<maxnumoftrades && Bid<=borderdown-(step*opentradescounter)/100.0) {Print("mainlogic: Bid < borderdown. Range. 1 more order. I will BUY now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);sendbuyorder(lotsize);}
               }
            else
               {
                  if (Bid>=borderup + (step*opentradescounter)/100.0) {Print("mainlogic 1: We WON (1 trade)! Bid > borderup. TREND. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);closeorders(false);}                 
                  if (opentradescounter==1 && Bid<=borderdown) {Print("mainlogic 2: We LOST 1st trade! Bid < borderdown. TREND. I will close all orders now and SELL"+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);closeorders(true);sendsellorder(lotsize*2);}
                  if (maxnumoftrades==opentradescounter && Bid>=borderup)  {Print("mainlogic 3: We LOST! Bid > borderup. TREND. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);closeorders(false);}
                  if (maxnumoftrades==opentradescounter && Bid<=borderdown-(step)/100.0) {Print("mainlogic 4: WE WON! Bid < borderdown. TREND. I will CLOSE ORDERS now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);closeorders(false);}
               }
         }
       else
         {
             if (range)
               {
                  if (Bid<=borderdown) {Print("mainlogic: We WON! Bid < borderup. Range. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);closeorders(false);}
                  if (opentradescounter>1 && Bid<=borderup) {Print("mainlogic: We WON (many trades)! Bid < borderup. Range. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderup);closeorders(false);}
                  if (maxnumoftrades==opentradescounter && Bid>=borderup+(step*opentradescounter)/100.0) {Print("mainlogic: We LOST! Bid > borderup. Range. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);closeorders(false);}
                  if (opentradescounter<maxnumoftrades && Bid>=borderup+(step*opentradescounter)/100.0) {Print("mainlogic: Bid > borderup. Range. 1 more order. I will SELL now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);sendsellorder(lotsize);}
               }
            else
               {
                  if (Bid<=borderdown - (step*opentradescounter)/100.0) {Print("mainlogic 1: We WON (1 trade)! Bid < borderdown. TREND. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderdown: "+borderdown);closeorders(false);}                 
                  if (opentradescounter==1 && Bid>=borderup) {Print("mainlogic 2: We LOST 1st trade! Bid > borderup. TREND. I will close all orders now and BUY"+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);closeorders(true);sendbuyorder(lotsize*2);}
                  if (maxnumoftrades==opentradescounter && Bid<=borderdown)  {Print("mainlogic 3: We LOST! Bid < borderdown. TREND. I will close all orders now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderdown);closeorders(false);}
                  if (maxnumoftrades==opentradescounter && Bid>=borderup+(step)/100.0) {Print("mainlogic 4: WE WON! Bid > borderup. TREND. I will CLOSE ORDERS now."+ " Bid: "+Bid+" Ask: "+Ask+" borderup: "+borderup);closeorders(false);}
               }
         }
}
//-------------------------------------------------------------------------
// CHECK FOR WHERE AMI
//-------------------------------------------------------------------------
void checkforwhereami()
{
if (!intrade)
   {
      if (fivedigits)
               {
                  if (Bid-borderdown>step/10000.0) 
                     {
                        Print("Checkforwhereami: Borderdown is out of step. I will call whereami.");
                        Print("Checkforwhereami: Borderdown is: "+borderdown+" and BID is: "+Bid+ " and Step is: "+ DoubleToStr(step/10000.0,5));
                        whereami();
                     }
               }
      else
               {
                  if (Bid-borderdown>step/100.0) 
                     {
                        Print("Checkforwhereami: Borderdown is out of step. I will call whereami");
                        Print("Checkforwhereami: Borderdown is: "+borderdown+" and BID is: "+Bid+ " and Step is: "+ DoubleToStr(step/100.0,5));
                        whereami();
                     }
               }
   }               
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
//WHERE AM I
//-------------------------------------------------------------------------
void whereami()
{
int i;   
   if (fivedigits)
     {
      for (i=1;i<=3000;i++)
         {
            if (Bid-borders[i]<=step/10000.0)
               {               
                  borderdown=borders[i];
                  borderup=borders[i]+step/10000.0;
                  break;
               }
         }
      }
   else
      {
               for (i=1;i<=3000;i++)
         {
            if (Bid-borders[i]<=step/100.0)
               {               
                  borderdown=borders[i];
                  borderup=borders[i]+step/100.0;
                  break;
               }
         }
      }
Print("Whereami:I just found where i am. Borderup: "+borderup+" borderdown: "+borderdown + " and BID: "+Bid);
}
//-------------------------------------------------------------------------
//   SENDBUYORDER
//-------------------------------------------------------------------------
void sendbuyorder(double lsize)
{
Print("Send buy order");
int ticket;
   
         Print("send ASK: "+Ask+ " Bid: "+Bid+" Opentrdescnt: "+opentradescounter);        
         ticket=OrderSend(Symbol(),OP_BUY,lsize,Ask,slipage,0,0,"",magic,0,Green );
         if(ticket<0)
           {
            Print("sendbuyorder: OrderSend failed with error #",GetLastError());
            return(0);
           }
          else
             {
                intrade=true;
                opentradescounter++;
             }              
}
//-------------------------------------------------------------------------
//   SENDSELLORDER
//-------------------------------------------------------------------------
void sendsellorder(double lsize)
{
Print("Send sell order");
int ticket;
   
         Print("send BID: "+Bid+ " Ask: "+Ask+" Opentrdescnt: "+opentradescounter);        
         ticket=OrderSend(Symbol(),OP_SELL,lsize,Bid,slipage,0,0,"",magic,0,Red);
         if(ticket<0)
           {
            Print("sendsellorder: OrderSend failed with error #",GetLastError());
            return(0);
           }
          else
             {
                intrade=true;
                opentradescounter++;
             }          
}
//-------------------------------------------------------------------------
//   CLOSEORDERS OLD
//-------------------------------------------------------------------------
void closeorders(bool middle)
{
int order_type;
int i;
string Symb=Symbol(); 
Print("closeorders: I will close all orders now for "+Symb);
double price;
Print("closeorders: Total orders: "+OrdersTotal());  
bool allok=false;

int total = OrdersTotal();
  for(i=total-1;i>=0;i--) 
     {
      if (OrderSelect(i,SELECT_BY_POS)==true) // If the next is available
        {                                       // Order analysis:
         //----------------------------------------------------------------------- 3 --
            if (OrderSymbol()!= Symb) continue;    // Symbol is not ours
                 //----------------------------------------------------------------------- 4 --
            int Ticket=OrderTicket();           // Order ticket
            order_type=OrderType();
            double lsize=OrderLots();
            
            if (order_type==0) price=Bid;
            if (order_type==1) price=Ask;
            
            Print("closeorders: Bid: "+Bid+ " Ask: " + Ask);
            bool Ans=OrderClose(Ticket,lsize,price,slipage,Blue);// Order closing
      //-------------------------------------------------------------------------- 8 --
         if (Ans==true)                            // Got it! :)
           {
               Print ("Closeorders: Closed order "," ",Ticket);allok=true;
           }
         else
            {
               int Error=GetLastError();  
               Print("Closeorders: Order closing failed with error code: ",Error);
               allok=false;
            }
         }
      }         
                
if (allok && !middle) {tradesfortheday++;clearparams();Print("Closeorders: I have closed all orders. I have to find where am. ");whereami();}
//--------------

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








