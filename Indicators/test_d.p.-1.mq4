//--------------------------------------------------------------------
// test_d.p.-1.mq4
// 2016/11/22 12:17:43
// 
// <Usage>
// - 
// 
//--------------------------------------------------------------------
//+------------------------------------------------------------------+
//| Includes                                                                 |
//+------------------------------------------------------------------+
#include <utils.mqh>

//+------------------------------------------------------------------+
//| vars                                                                 |
//+------------------------------------------------------------------+
extern int Period_MA = 21;            // Calculated MA period

bool Fact_Up = true;                  // Fact of report that price..
bool Fact_Dn = true;                  //..is above or below MA

int HOURS_PER_DAY = 24;

int HIT_INDICES[];   // indices of matched bars

int NUMOF_HIT_INDICES = 0;

int FILE_HANDLE;

//+------------------------------------------------------------------+
//| infra vars                                                                 |
//+------------------------------------------------------------------+
string SUBFOLDER = "Research\\37_1";      // subfolder name

int NUMOF_BARS_PER_HOUR　= 1;        // default: 1 bar per hour

int NUMOF_TARGET_BARS = 0;

//+------------------------------------------------------------------+
//| input vars                                                                 |
//+------------------------------------------------------------------+
input string   SYMBOL_STR = "USDJPY";

input int      NUMOF_DAYS = 30;

// default: PERIOD_H1
input int      TIME_FRAME = 60;

// default: half the starting bar
input double   DOWN_X_PERCENT = 0.5;

// default: if more than this value, then
//          a trend is being formed
input int      NUMOF_BARS_IN_TREND = 10;

//--------------------------------------------------------------------
int start()                           // Special function start()
  {

   //test
   if(Fact_Up == true)           // initially, Fact_Up is set to be true
     {
     
         setup();
     
         detect_Trend_Up();

         write_file__Trend_Up();
         
         Fact_Up = false;        // no more executions

     }



//--------------------------------------------------------------------
   return 0;                            // Exit start()
   
}//int start()
//--------------------------------------------------------------------

void setup() {

   //+------------------------------------------------------------------+
   //| set: symbol
   //+------------------------------------------------------------------+
   
   ChartSetSymbolPeriod(0, SYMBOL_STR, 0);  // set symbol
   
   Alert("symbol set to => ",SYMBOL_STR,"");

   //+------------------------------------------------------------------+
   //| set: time frame
   //+------------------------------------------------------------------+
   switch(TIME_FRAME)
     {
      case  60:
        
            NUMOF_TARGET_BARS = NUMOF_DAYS * 24;
        
        break;

      case  1: // 1 minute: "NUMOF_DAYS" value is now interpreted as
               //             "NUMOF_HOURS"
        
            NUMOF_TARGET_BARS = NUMOF_DAYS * 60;
        
        break;

      default:
      
            NUMOF_TARGET_BARS = NUMOF_DAYS * 24;
            
        break;
     }

   //+------------------------------------------------------------------+
   //| Array
   //+------------------------------------------------------------------+
   ArrayResize(HIT_INDICES, NUMOF_TARGET_BARS);
   

}//setup

void write_file__Trend_Up() {

      datetime t = TimeLocal();

      string title = "Detect trend: Up" 
                     //+ "", MathRound(X_UPS_AFTER_BREAK * 100)," pips up (inspect: p-10A)";
                     + (string) NUMOF_BARS_IN_TREND + " Bars in one trend"
                     ;

      string fname = "d.p.-1.detect-trend_up" 

                  + "." + SYMBOL_STR
                  + ".SL-" + (string) (MathRound(DOWN_X_PERCENT * 100)) + "-percent"        // file name


                  + "." + (string) NUMOF_DAYS + "-Days"
                  
                  + ".SEQ-"  + (string) NUMOF_BARS_IN_TREND + "-bars"
                  //+ conv_DateTime_2_SerialTimeLabel(TimeCurrent()) 
                  //+ conv_DateTime_2_SerialTimeLabel(t) 
                  + "." + conv_DateTime_2_SerialTimeLabel((int)t) 
                  + ".csv";

      //+------------------------------------------------------------------+
      //| File: open                                                                 |
      //+------------------------------------------------------------------+
      FILE_HANDLE = FileOpen(SUBFOLDER + "\\" + fname, FILE_WRITE|FILE_CSV);
      
      //if(FILE_HANDLE!=INVALID_HANDLE) {
      if(FILE_HANDLE == INVALID_HANDLE) {
      
            Print("File open failed, error ",GetLastError());
               
            //alert
            Alert("[",__LINE__,"] File open failed, error");
            
            return;
            
        }
      
      else  //if(FILE_HANDLE == INVALID_HANDLE)
        {
         
            Alert("[",__LINE__,"] file => opened!");
            
            //+------------------------------------------------------------------+
            //| File: seek
            //+------------------------------------------------------------------+
            //ref https://www.mql5.com/en/forum/3239
            FileSeek(FILE_HANDLE,0,SEEK_END);
            
            Alert("[",__LINE__,"] FileSeek => done");
   
            //+------------------------------------------------------------------+
            //| File: write: metadata
            //+------------------------------------------------------------------+
            FileWrite(FILE_HANDLE, 
                     "file created = " + TimeToStr(t, TIME_DATE|TIME_SECONDS), 
                     "symbol = " + SYMBOL_STR,
                     //PERIOD_CURRENT
                     //ref https://www.mql5.com/en/forum/133159
                     "time frame = " + (string)Period()
                     
                     );

            FileWrite(FILE_HANDLE, 
            
                  title
                     
            );
            
            FileWrite(FILE_HANDLE, 
            
                  "NUMOF_TARGET_BARS = " + (string)NUMOF_TARGET_BARS
                  
            );
            
            FileWrite(FILE_HANDLE,
      
               "start = " + TimeToStr(iTime(Symbol(), Period(), (NUMOF_TARGET_BARS - 1))),
               
               "end = " + TimeToStr(iTime(Symbol(), Period(), 0)),
               
               "days = " + (string)NUMOF_DAYS
         
            );

         
            //+------------------------------------------------------------------+
            //| File: write: header
            //+------------------------------------------------------------------+
            FileWrite(filehandle,
            
               "no.", "index", "time", "close", "open", "SMA-25"
               
            );    // header

            //debug
            Alert("[",__LINE__,"] header => written");
            
            //+------------------------------------------------------------------+
            //| File: write: data
            //+------------------------------------------------------------------+
            
            
         
         }//if(FILE_HANDLE == INVALID_HANDLE)
      
      //+------------------------------------------------------------------+
      //| File: close                                                                 |
      //+------------------------------------------------------------------+
      
      FileClose(FILE_HANDLE);

      Alert("[",__LINE__,"] file => closed");

}//write_file__Trend_Up()

void detect_Trend_Up() {

   //Alert("detect_Trend_Up");
   
   //Alert("Bars => ",Bars," / Period => ",Period(),"");
   //Alert("Close[Bars] => ",Close[Bars - 1],"");
   
   //+------------------------------------------------------------------+
   //| vars
   //+------------------------------------------------------------------+
   int i;      // index for for-loop
   int offset = 0;
   
   int numof_total_bar = 0;
   
   //+------------------------------------------------------------------+
   //| setup
   //+------------------------------------------------------------------+
   double   body = 0;     // Close - Open
   
   //double   open;
   double   close = 0;
   
   double threshold = 0;
   
   int numof_inspected_bars = 0;
   
   //for(i = NUMOF_TARGET_BARS; i >= 0 ; i--)
   for(i = NUMOF_TARGET_BARS - 1; i >= 0 ; i--)
     {

         //debug
         Alert("[",__LINE__,"] i = ",i," / offset = ",offset,"");

         // count
         numof_inspected_bars += 1;

         // get: close and open
         body = Close[i + offset] - Open[i + offset];
         
         // if up?
         if(body < 0)
           {
               
               continue;
            
           }//if(body >= 0)
         
         // set: threshold
         threshold = Close[i + offset] - body * DOWN_X_PERCENT;

         //debug
         //Alert("i = ",i," / body = ",body," / threshold = ",threshold,"");


         //+------------------------------------------------------------------+
         //| loop
         //+------------------------------------------------------------------+
         while(true)
           {

               // decrement: offset
               offset += -1;
               
               //debug
               Alert("[",__LINE__,"] i = ",i," / offset = ",offset,"");
               
               // validate: out of index
               if(i + offset < 0)   // offset came to the beginning of
                                    //    the first bar, i.e. the latest
                                    //    --> quit the for-loop
                 {
                     //debug
                     Alert("[",__LINE__,"] i + offset --> less than 0");
                     
                     if(offset * (-1) > (NUMOF_BARS_IN_TREND - 1))
                       {

                           // add this index to the array
                           HIT_INDICES[NUMOF_HIT_INDICES] = i;
                           
                           // increment the count of the HIT_INDICES
                           NUMOF_HIT_INDICES += 1;
                        
                       }//if(offset * (-1) > (NUMOF_BARS_IN_TREND - 1))
                     
                     // reset: offset
                     offset = 0;
                     
                     // count out the for-loop index
                     i = 0;
                     
                     // break the while loop
                     break;
                     
                 }//if(i + offset < 0)
               
               // get: closing price of the next bar
               close = Close[i + offset];
               
               //debug
               Alert("[",__LINE__,"] i = ",i,""
                     + " / ",TimeToStr(iTime(Symbol(), Period(), i)),""
                     + " / body = ",NormalizeDouble(body, 5),""
                     + " / threshold = ",threshold,""
                     + " / offset = ",offset,""
                     + " / close = ",NormalizeDouble(close, 5),""
                     );
               

               // closing --> less than the threshold?
               if(close < threshold)
                 {
                 
                     //debug
                     Alert("[",__LINE__,"] close => less than threshold");
                     
                     // reset: offset
                     offset = 0;
                     
                     // next index of the for loop
                     break;
                     
                 }//if(close < threshold)
               else
                 {
                     
                  
                 }//if(close < threshold)

               // judge: a trend is being formed
               if(offset * (-1) > (NUMOF_BARS_IN_TREND - 1))
                 {
                     // add this index to the array
                     HIT_INDICES[NUMOF_HIT_INDICES] = i;
                     
                     // increment the count of the HIT_INDICES
                     NUMOF_HIT_INDICES += 1;
                     
                     // forward the index of for-loop
                     i += (offset + 1);
                     
                     // validate: if i gets less than 0
                     //             then, reset i to 0
                     if(i < 0)
                       {
                           
                           i = 0;
                           
                       }//if(i < 0)

                     // reset: offset
                     offset = 0;
                     
                     // next for-loop index
                     break;
                  
                 }//if(offset * (-1) > (NUMOF_BARS_IN_TREND - 1))
               else
                 {
                  
                 }//if(offset * (-1) > (NUMOF_BARS_IN_TREND - 1))

           }//while(true)

     }//for(i = NUMOF_TARGET_BARS; i >= 0 ; i--)
   
   //+------------------------------------------------------------------+
   //| report
   //+------------------------------------------------------------------+
   Alert("Total = ",NUMOF_TARGET_BARS,""
         
         + " / Inspected = ",numof_inspected_bars,""
         + " (",NormalizeDouble(numof_inspected_bars * 1.0 / NUMOF_TARGET_BARS, 5),")"
         
         + " / NUMOF_HIT_INDICES => ",NUMOF_HIT_INDICES,""
         + " (",NormalizeDouble(NUMOF_HIT_INDICES * 1.0 / NUMOF_TARGET_BARS, 5),")"
         
         
         );
         

}//detect_Trend_Up

