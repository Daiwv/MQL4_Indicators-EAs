//--------------------------------------------------------------------
//    loc   :  C:\Users\iwabuchiken\AppData\Roaming\MetaQuotes\Terminal\34B08C83A5AAE27A4079DE708E60511E\MQL4\Indicators\lab\24_18
//    file  :  t_24_18.mq4
//    time  :  2018/01/05 10:42:45
//    generated files : C:\Users\iwabuchiken\AppData\Roaming\MetaQuotes\Terminal\34B08C83A5AAE27A4079DE708E60511E\MQL4\Files\Research
// 
// <Usage>
// - 
// <steps>
//    1. update
//          *1) comment block: file name, created-at string
//          *2) "SUBFOLDER" value
//          *2-2) "FNAME" value
//          *3) "string title" value
//          4) _file_write__header() --> column names
//          5) _file_write__data() --> edit variables

//--------------------------------------------------------------------
//+------------------------------------------------------------------+
//| Includes                                                                 |
//+------------------------------------------------------------------+
#include <utils.mqh>

//+------------------------------------------------------------------+
//| vars                                                                 |
//+------------------------------------------------------------------+
extern int Period_MA=21;            // Calculated MA period

int HOURS_PER_DAY=24;

int HIT_INDICES[];   // indices of matched bars

                     // counter
int NUMOF_HIT_INDICES=0;

int FILE_HANDLE;

//+------------------------------------------------------------------+
//| infra vars                                                                 |
//+------------------------------------------------------------------+
int      NUMOF_BARS_PER_HOUR　=1;        // default: 1 bar per hour

int      NUMOF_TARGET_BARS=0;

string   FNAME;

string   session_ID = "24_16";

string   FNAME_THIS = "t_" + session_ID + ".(1).mq4";

string   STRING_TIME;

datetime T;

//string DATA[][6];

int      NUMOF_DATA;

// current PERIOD
string   CURRENT_PERIOD = "";   // "D1", "H1", etc.

string   TIME_LABEL = "";

//string MAIN_LABEL = "file-io";
string MAIN_LABEL = "TIME-TO-INDEX";

//+------------------------------------------------------------------+
//| input vars                                                                 |
//+------------------------------------------------------------------+
//input string   SYMBOL_STR="AUDJPY";
input string   SYMBOL_STR="USDJPY";
//input string   SYMBOL_STR = "EURUSD";

//input int      NUMOF_DAYS  = 365; // 1 year
//input int      NUMOF_DAYS  = 60;    // 2 months
input int      NUMOF_DAYS  = 180;    // 6 months

// default: PERIOD_H1
input int      TIME_FRAME  = 60; // 1 hour
//input int      TIME_FRAME  = 1440;  // 1 day

// BB period (Bollinger Band)
input int      BB_PERIOD = 25;

//input string   SUBFOLDER   = "24_16";      // subfolder name ---> same as sessin_ID
input string   SUBFOLDER   = "obs/24_18";      // subfolder name ---> same as sessin_ID
//input string   SUBFOLDER   = "obs\\49_6";      // subfolder name ---> same as sessin_ID

input int      RSI_PERIOD     = 20;
input int      MFI_PERIOD     = 20;

input int      RSI_THRESHOLD  = 75;

input string   TIME_SHIFT     = "2017.01.04 15:00";

input string   SPAN_START     = "2016.04.01 00:00";

input string   SPAN_END     = "2016.10.31 23:00";

input bool     WRITE_DATA_TO_FILE = true;

//--------------------------------------------------------------------
int init() {

   //+------------------------------------------------------------------+
   //| setup
   //+------------------------------------------------------------------+
   setup();

   //debug
   Alert("[", __FILE__, ":",__LINE__,"] NUMOF_TARGET_BARS => ", NUMOF_TARGET_BARS);
   
   //debug
   Alert("[", __FILE__, ":",__LINE__,"] init() done");

   //ref return value -> https://www.mql5.com/en/forum/55560   
   return 0;
  
}//int init()

//void test_4(string symbol_Str) {
void get_BasicData_with_RSI(string symbol_Str) {

   //double   AryOf_BasicData[][4];
   double   AryOf_BasicData[][5];

   // get data
   int pastXBars = NUMOF_DAYS;
   
   FNAME = _get_FNAME(
               SUBFOLDER, MAIN_LABEL, symbol_Str, 
               CURRENT_PERIOD, NUMOF_DAYS, 
               NUMOF_TARGET_BARS, TIME_LABEL);

    //debug
    Alert("[", __FILE__, ":",__LINE__,"] FNAME => ", FNAME);
    
    /******************
      iRSI
    ******************/
    //ref https://docs.mql4.com/indicators/irsi
         /*
         string       symbol,           // symbol
         int          timeframe,        // timeframe
         int          period,           // period
         int          applied_price,    // applied price
         int          shift             // shift
         */
   int shift = 1;
   
   int period_RSI = 20;
   
   int price_Target = PRICE_CLOSE;
   
   double   AryOf_Data[][5];
   
   //int length = 5;
   int length = NUMOF_DAYS;
   
   //debug
   Alert("[", __FILE__, ":",__LINE__,"] calling ---> get_AryOf_RSI");
   
      
   get_AryOf_RSI(
            SYMBOL_STR, 
            (int) CURRENT_PERIOD, 
            period_RSI, 
            price_Target, 
            shift, 
            length,
            AryOf_Data);


    /******************
      data ---> write to file
    ******************/
   write2File_AryOf_BasicData_With_RSI(
      FNAME, SUBFOLDER, AryOf_Data
      
      , length, shift
            
      , SYMBOL_STR
      
      , CURRENT_PERIOD
      
      , NUMOF_DAYS
      
      , NUMOF_TARGET_BARS
      
      , TIME_LABEL
      
      , TIME_FRAME

   );

   
   
   //debug
   Alert("[", __FILE__, ":",__LINE__,"] get_BasicData_with_RSI() => done");
   
}//void get_BasicData_with_RSI

int exec() {

   //+------------------------------------------------------------------+
   //| vars
   //+------------------------------------------------------------------+

   //+------------------------------------------------------------------+
   //| setup
   //+------------------------------------------------------------------+
   //+---------------------------------+
   //| setup   : file
   //+---------------------------------+
   T = TimeLocal();
   
   TIME_LABEL = conv_DateTime_2_SerialTimeLabel((int)T);
   
   //string main_Label = "file-io";
   string main_Label = MAIN_LABEL;
   
   string _FNAME = _get_FNAME(
               SUBFOLDER, main_Label, SYMBOL_STR, 
               CURRENT_PERIOD, NUMOF_DAYS, 
               NUMOF_TARGET_BARS, TIME_LABEL);

    //debug
    Alert("[", __FILE__, ":",__LINE__,"] _FNAME => ", _FNAME);
   
   //+------------------------------------------------------------------+
   //| get : array of basic bar data
   //+------------------------------------------------------------------+
   //get_BasicData_with_RSI(SYMBOL_STR);
	string _symbol_Str   = SYMBOL_STR;
	int _pastXBars       = NUMOF_DAYS;
	string _SUBFOLDER    = SUBFOLDER;
	string _MAIN_LABEL   = MAIN_LABEL;
	string _CURRENT_PERIOD  = CURRENT_PERIOD;
	int _NUMOF_DAYS      = NUMOF_DAYS;
	int _NUMOF_TARGET_BARS  = NUMOF_TARGET_BARS;
	string _TIME_LABEL      = TIME_LABEL;
	int _TIME_FRAME      = TIME_FRAME;
   
   // convert
   //string time_str = "2018.01.04 15:00";
   string _TIME_SHIFT = TIME_SHIFT;
   string symbol = SYMBOL_STR;
   int      limit = 20;
   
   int      _PERIOD_RSI = RSI_PERIOD;
   
   double AryOf_Data[][11];
   
   // get index from time string
   int result = conv_TimeString_2_Index(_TIME_SHIFT, _symbol_Str, _TIME_FRAME, limit);
   
   int _SHIFT = result;
   
    //debug
    Alert("[", __FILE__, ":",__LINE__,"] _TIME_SHIFT => ", _TIME_SHIFT
               , " / "
               , "index => ", result
    
    );
   
   // get data
/*   get_BasicData_with_RSI_BB_MFI__Shifted()
      string symbol_Str, 
      int time_Frame, 
      int period_RSI, 
      int price, 
      int shift, 
      int length,
      double &AryOf_Data[][11]   */
   get_BasicData_with_RSI_BB_MFI__Shifted
         (
         _symbol_Str,         // 1
         _NUMOF_TARGET_BARS,
         _SUBFOLDER,
         _MAIN_LABEL,
         _CURRENT_PERIOD,     // 5
         _NUMOF_DAYS,
         _NUMOF_TARGET_BARS,
         _TIME_LABEL,
         _TIME_FRAME,
         _SHIFT               // 10
         );

   /*********************
      File : write
   *********************/   
   write2File_AryOf_BasicData_With_RSI_BB_MFI(
      _FNAME, _SUBFOLDER, AryOf_Data
      
      , _NUMOF_TARGET_BARS
      , _SHIFT
            
      , _symbol_Str
      
      , _CURRENT_PERIOD
      
      , _NUMOF_DAYS
      
      , _NUMOF_TARGET_BARS
      
      , _TIME_LABEL
      
      , _TIME_FRAME

   );

   
   return   0;

}//exec()

int start() // Special function start()
  {
  
         //+------------------------------------------------------------------+
         //| setup
         //+------------------------------------------------------------------+
         //setup();
         //Alert("[",__LINE__,"] starting...");
   
   
         //+------------------------------------------------------------------+
         //| operations                                                                 |
         //+------------------------------------------------------------------+
         //exec();
         //+------------------------------------------------------------------+
         //| terminating the loop                                                                 |
         //+------------------------------------------------------------------+

//--------------------------------------------------------------------
   return 0;                            // Exit start()

  }//int start()
//--------------------------------------------------------------------

void _setup__BasicParams() {

   int res;
   
   switch(TIME_FRAME)
/*
   #ref https://www.mql5.com/en/forum/140787
   PERIOD_M1   1
   PERIOD_M5   5
   PERIOD_M15  15
   PERIOD_M30  30 
   PERIOD_H1   60
   PERIOD_H4   240
   PERIOD_D1   1440
   PERIOD_W1   10080
   PERIOD_MN1  43200
   */
     {
      case  5:      // 5 minutes

         NUMOF_TARGET_BARS = NUMOF_DAYS;
         
         //ChartSetSymbolPeriod(0,SYMBOL_STR,PERIOD_H1);  // set symbol
         res = set_Symbol(SYMBOL_STR, PERIOD_M5);
         
         //debug
         Alert("[", __FILE__, ":",__LINE__,"] symbol set => ", SYMBOL_STR);
         
         // period name
         CURRENT_PERIOD = "M5";

         break;

      case  60:      // 1 hour

         NUMOF_TARGET_BARS=NUMOF_DAYS*24;
         
         //ChartSetSymbolPeriod(0,SYMBOL_STR,PERIOD_H1);  // set symbol
         res = set_Symbol(SYMBOL_STR, PERIOD_H1);
         
         //debug
         Alert("[", __FILE__, ":",__LINE__,"] symbol set => ", SYMBOL_STR);
         
         // period name
         CURRENT_PERIOD = "H1";

         break;

      case  240: // 4 hours

         NUMOF_TARGET_BARS = NUMOF_DAYS * 6;
         
         //ChartSetSymbolPeriod(0,SYMBOL_STR,PERIOD_H4);  // set symbol
         res = set_Symbol(SYMBOL_STR, PERIOD_H4);
         
         //debug
         Alert("[", __FILE__, ":",__LINE__,"] symbol set => ", SYMBOL_STR);

         // period name
         CURRENT_PERIOD = "H4";

         break;

      case  480: // 8 hours

         NUMOF_TARGET_BARS = NUMOF_DAYS*3;
         
         //ChartSetSymbolPeriod(0,SYMBOL_STR,PERIOD_H8);  // set symbol
         res = set_Symbol(SYMBOL_STR, PERIOD_H8);
         
         //debug
         Alert("[", __FILE__, ":",__LINE__,"] symbol set => ", SYMBOL_STR);
         
         // period name
         CURRENT_PERIOD = "H8";

         break;

      case  1440: // 1 day

         NUMOF_TARGET_BARS = NUMOF_DAYS;
         
         //ChartSetSymbolPeriod(0,SYMBOL_STR,PERIOD_D1);  // set symbol
         res = set_Symbol(SYMBOL_STR, PERIOD_D1);
         
         //debug
         Alert("[", __FILE__, ":",__LINE__,"] symbol set => ", SYMBOL_STR);


         // period name
         CURRENT_PERIOD = "D1";

         break;

      case  10080: // 1 week

         //ref https://www.mql5.com/en/forum/151559
         //NUMOF_TARGET_BARS = (int) NUMOF_DAYS / 7;
         NUMOF_TARGET_BARS = NUMOF_DAYS;
         
         //ChartSetSymbolPeriod(0,SYMBOL_STR,PERIOD_W1);  // set symbol
         res = set_Symbol(SYMBOL_STR, PERIOD_W1);
         
         //debug
         Alert("[", __FILE__, ":",__LINE__,"] symbol set => ", SYMBOL_STR);

         // period name
         CURRENT_PERIOD = "W1";

         break;

      case  1: // 1 minute: "NUMOF_DAYS" value is now interpreted as
         //             "NUMOF_HOURS"

         NUMOF_TARGET_BARS=NUMOF_DAYS*60;
         
         //ChartSetSymbolPeriod(0,SYMBOL_STR,PERIOD_M1);  // set symbol
         res = set_Symbol(SYMBOL_STR, PERIOD_M1);
         
         //debug
         Alert("[", __FILE__, ":",__LINE__,"] symbol set => ", SYMBOL_STR);
         

         // period name
         CURRENT_PERIOD = "M1";

         break;

      default:

         NUMOF_TARGET_BARS=NUMOF_DAYS*24;
         
         //ChartSetSymbolPeriod(0,SYMBOL_STR,PERIOD_H1);  // set symbol
         res = set_Symbol(SYMBOL_STR, PERIOD_H1);
         
         //debug
         Alert("[", __FILE__, ":",__LINE__,"] symbol set => ", SYMBOL_STR);

         // period name
         CURRENT_PERIOD = "H1";

         break;
     }

}//void _setup__BasicParams()

//ref about "tick" --> https://www.mql5.com/en/forum/109552
void setup() 
  {
  
   //+------------------------------------------------------------------+
   //| opening message
   //+------------------------------------------------------------------+
   //Alert("starting TR-5.mq4");
   Alert("[", __FILE__, ":",__LINE__,"] starting" + " " + FNAME_THIS);

   //+------------------------------------------------------------------+
   //| set: time frame
   //+------------------------------------------------------------------+
   _setup__BasicParams();
   
   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+
   Alert("[", __FILE__, ":",__LINE__,"] symbol = ",SYMBOL_STR,""
   
            + " / RSI threshold = ",RSI_THRESHOLD,""
            + " / PERIOD = ",Period(),""         
            
         );

//+------------------------------------------------------------------+
//| Array
//+------------------------------------------------------------------+
   ArrayResize(HIT_INDICES,NUMOF_TARGET_BARS);

   //+------------------------------------------------------------------+
   //| operations                                                                 |
   //+------------------------------------------------------------------+
   exec();

   //debug
   Alert("[", __FILE__, ":",__LINE__,"] setup() --> done");

}//setup

