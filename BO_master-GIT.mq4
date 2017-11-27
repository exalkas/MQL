//+------------------------------------------------------------------+
//|                                                    BO_master.mq4 |
//|                                                            alkas |
//|                                                         alkas.gr |
//|                                                        04/08/2013|
//+------------------------------------------------------------------+
#property copyright "alkas"
#property link      "alkas.gr"

extern int expips=0;
extern string strbordersup="0=iHigh,iclose, iOpen";
extern int exborderup=0;
extern string strbordersdown="0=iLow,iclose, iOpen";
extern int exborderdown=0;
extern string ihighparams="TF: 0=M1, 1=M5, 2=M15, 3=M30, 4=H1, 5=H4...8=Month";
extern int extf=6;
extern string shiftbuffer="Shift: 1=1, 2=2 κλπ";
extern int shift=1;



extern int extp=10;
extern int exsl=10;

extern double lsize=0.01;
extern int slipage=1;
extern int magic=7;
extern string strdoublenexttrade="Double next trade: false=0, true=1";
extern int doublenexttrade=0;
extern int maxtradesperday=1;

//TIME EXTERNAL VARIABLES
extern string timevariables="TIME VARIABLES";
extern int starthour=0;
extern int maxstarthour=20;
extern int endhour=22;


//+------------------------------------------------------------------+
// Internal Static variables
//+------------------------------------------------------------------+
int opentradescounter=0;
bool intrade=false;
bool buyroute=false;
int tradesfortheday=0;
double borderup=0;
double borderdown=0;
bool lost=false;
int oldday=0;
int tf=0;
double pips;
double tp;
double sl;


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   definetf();
   defineborders();
   definepips();
   definetpandsl();
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
   if (Day()!=oldday) {clearparams2();defineborders();}
   oldday=Day();
   
   if (intrade) {tradechangestop();}
   
   else
      {
         tradestart();
      }
//----
   return(0);
  }
//+------------------------------------------------------------------+

//------------------------------------------------------------------------+
//FUNCTIONS
//------------------------------------------------------------------------+


//------------------------------------------------------------------------+
//tradestart
//------------------------------------------------------------------------+

void tradestart()
{
   if (borderup==0 || borderdown==0) defineborders();
   if (tradesfortheday>=maxtradesperday) return;
   if (Hour()>=maxstarthour || Hour()<starthour) return;
   if (Bid>borderup+pips) {sendbuyorder(lsize);Print("Tradestart: borderup="+borderup);}
   if (Bid<borderdown+pips) {sendsellorder(lsize);Print("Tradestart: borderdown="+borderdown);}
}

//------------------------------------------------------------------------+
//tradechangestop
//------------------------------------------------------------------------+

void tradechangestop()
{
   
   if (buyroute==true) 
      {
         if (Hour()>=endhour) {if (Bid<borderup-pips) {lost=true;}closeorders();}
          
         if (Bid>borderup+pips+tp) {if (lost) {lost=false;} closeorders();}
         if (Bid<borderup-pips-sl) {lost=true;closeorders();} //SL hit
      }
   
   else
      {
         if (Hour()>=endhour) {if (Bid>borderdown+pips) {lost=true;} closeorders();}
         if (Bid<borderdown-pips-tp) {if (lost) {lost=false;} closeorders();}
         if (Bid>borderdown+pips+sl) {lost=true;closeorders();} //Sl HIt
      }
}


//------------------------------------------------------------------------+
//sendbuyorder
//------------------------------------------------------------------------+
void sendbuyorder(double lsize)
{
Print("Send buy order");
if (lost && doublenexttrade==1) lsize=lsize*2;
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
                buyroute=true;
                opentradescounter++;
             }              
}

//------------------------------------------------------------------------+
//sendsellorder
//------------------------------------------------------------------------+
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
                buyroute=false;
                opentradescounter++;               
             }          
}

//-------------------------------------------------------------------------
//   CLOSEORDERS
//-------------------------------------------------------------------------
void closeorders()
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
                
if (allok) {tradesfortheday++;clearparams();Print("Closeorders: I have closed all orders.");}
//--------------

}   

//------------------------------------------------------------------------+
//CLEAR PARAMS
//------------------------------------------------------------------------+
void clearparams()
{
   Print("clearparams");
   opentradescounter=0;
   intrade=false;
}
//------------------------------------------------------------------------+
// Clear params
//------------------------------------------------------------------------+
void clearparams2()
{
   Print("clearparams2");
   tradesfortheday=0;

}
//------------------------------------------------------------------------+
//define borders
//------------------------------------------------------------------------+
void defineborders()
{
   switch (exborderup)
      {
         case 0: borderup=iHigh(Symbol(),tf,shift); break;
         case 1: borderup=iClose(Symbol(),tf,shift); break;
         case 2: borderup=iOpen(Symbol(),tf,shift); break;
      }

   switch (exborderdown)
      {
         case 0: borderdown=iLow(Symbol(),tf,shift); break;
         case 1: borderdown=iClose(Symbol(),tf,shift); break;
         case 2: borderdown=iOpen(Symbol(),tf,shift); break;
      }
}

//------------------------------------------------------------------------+
//define tf
//------------------------------------------------------------------------+
void definetf()
{
   switch (extf)
      {
      case 0: tf=1;break;
      case 1: tf=5;break;
      case 2: tf=15;break;
      case 3: tf=30;break;
      case 4: tf=60;break;
      case 5: tf=240;break;
      case 6: tf=1440;break;
      case 7: tf=10080;break;
      case 8: tf=43200;break;
      }
}

//------------------------------------------------------------------------+
//define definepips
//------------------------------------------------------------------------+
void definepips()
{
   if (Symbol()=="GOLD") pips=expips/10.0;Print("Pips="+pips);  
   
}
//------------------------------------------------------------------------+
//define definetpandsl
//------------------------------------------------------------------------+
void definetpandsl()
{
   if (Symbol()=="GOLD") tp=extp/100.0;Print("tp="+tp);  
   if (Symbol()=="GOLD") sl=exsl/100.0;Print("sl="+sl);  
   
}  