//+------------------------------------------------------------------+
//|                                                          abc.mq4 |
//|  Copyright (c) 2010 Area Creators Co., Ltd. All rights reserved. |
//|                                          http://www.mars-fx.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2010 Area Creators Co., Ltd. All rights reserved."
#property link      "http://www.mars-fx.com/"

//+------------------------------------------------------------------+
//| �w�b�_�[�t�@�C���Ǎ�                                             |
//+------------------------------------------------------------------+
#include <stderror.mqh>
#include <stdlib.mqh>
#include <WinUser32.mqh>

//+------------------------------------------------------------------+
//| �萔�錾��                                                       |
//+------------------------------------------------------------------+
#define URL "http://www.mars-fx.com/"      //URL
#define ERR_TITLE1 "�p�����[�^�[�G���["    //�G���[�^�C�g��(����1)
#define MAIL_TITLE "MarsFX MailAlert"      //���[���^�C�g��
#define R_SUCCESS         0                //�߂�l(����)
#define R_ERROR          -1                //�߂�l(�G���[)
#define R_ALERT          -2                //�߂�l(�x��1)
#define R_WARNING        -3                //�߂�l(�x��2)
#define BUY_SIGNAL        1                //�G���g���[�V�O�i��(�����O)
#define SELL_SIGNAL       2                //�G���g���[�V�O�i��(�V���[�g)
#define BUY_EXIT_SIGNAL   1                //���σV�O�i��(�����O)
#define SELL_EXIT_SIGNAL  2                //���σV�O�i��(�V���[�g)
#define ORDER_TYPE_ALL    1                //�I�[�_�[�Z���N�g�^�C�v(�S��)
#define ORDER_TYPE_BUY    2                //�I�[�_�[�Z���N�g�^�C�v(�����O)
#define ORDER_TYPE_SELL   3                //�I�[�_�[�Z���N�g�^�C�v(�V���[�g)
#define LAST_ORDER        4                //�I�[�_�[�Z���N�g�^�C�v(����)
#define LAST_HIS          1                //�I�[�_�[����(����)
#define LAST_BUT_ONE_HIS  2                //�I�[�_�[����(��O)

//+------------------------------------------------------------------+
//| �O���p�����[�^�[�錾                                             |
//+------------------------------------------------------------------+
extern int MagicNumber       = 12345678;      //�}�W�b�N�i���o�[
extern double Lots           = 0.1;                   //���b�g��
extern int Slippage          = 3;                 //�X���b�y�[�W
extern double TakeProfitPips = 0;         //���H��Pips
extern double StopLossPips   = 0;           //���؂�Pips
extern int OpenOrderMax      = 1;           //�ő�ۗL�|�W�V������
extern double CloseLotsMax   = 0;           //�������σ|�W�V������
extern int AutoLotsType      = 0;    //�������b�g�Z�o�^�C�v(0:�Ȃ��A1:%�w��A2:�}�[�`���Q�[���A3:�t�}�[�`���Q�[��)


//�G���g���[����2(�V���[�g) Start------------------------------------------------------------------------------------------------------------------------------
//BB
extern int Entry002_BB_Period       = 20;         //����
extern int Entry002_BB_Deviation    = 2;       //�΍�
extern int Entry002_BB_Mode         = 1;            //���C��
extern int Entry002_BB_TimeFrame    = 0;      //���Ԏ�
extern int Entry002_BB_AppliedPrice = 0;   //���i
//�G���g���[����2(�V���[�g) End--------------------------------------------------------------------------------------------------------------------------------


//���Ϗ���2(�����O����) Start------------------------------------------------------------------------------------------------------------------------------
//MA
extern int Exit002_MA_Period       = 14;          //����
extern int Exit002_MA_Method       = 0;           //�Z�o����
extern int Exit002_MA_TimeFrame    = 0;       //���Ԏ�
extern int Exit002_MA_AppliedPrice = 0;    //���i
//���Ϗ���2(�����O����) End--------------------------------------------------------------------------------------------------------------------------------




//+------------------------------------------------------------------+
//| �O���[�o���ϐ��錾                                               |
//+------------------------------------------------------------------+
string PGName = "abc";     //�v���O������
int RETRY_TIMEOUT    = 60;               //���M�҂�����(�b)
int RETRY_INTERVAL   = 15000;            //���g���C�C���^�[�o��
int PLDigits         = 2;                //���v�����_
double wk_point      = 0;                //3���A5���Ή�Point
double order[1][12];                    //�I�[�_�[�i�[�p   
double order_his[1][12];                //�I�[�_�[�����i�[�p
double exception[1][2];                 //��O�I�[�_�[�i�[�p
int OrderCount       = 0;                //�I�[�_�[����
bool MailFlag        = false;            //���[�����m�点�@�\(true:�L���Afalse:����)
bool AlertFlag       = false;            //�A���[�g���m�点�@�\(true:�L���Afalse:����)

//+------------------------------------------------------------------+
//| ��������                                                         |
//+------------------------------------------------------------------+
int init()
{
   //Pips�ϊ�����
   if(Digits==3 || Digits==5)
   {
      wk_point = Point * 10;
   }
   else
   {
      wk_point = Point;
   }
   
   //�I�[�_�[����
   ArrayInitialize(order,0);                     //�I�[�_�[�z�񏉊���
   OrderCount = OrderCheck(order,MagicNumber,ORDER_TYPE_ALL);
   if(OrderCount == R_ERROR) return(R_ERROR);    //�G���[����
   
   return(0);
}

//+------------------------------------------------------------------+
//| �I������                                                         |
//+------------------------------------------------------------------+
int deinit()
{
   //�I�u�W�F�N�g�̍폜
   ObjectDelete("PGName");
   
   return(0);
}

//+------------------------------------------------------------------+
//| ���C������                                                       |
//+------------------------------------------------------------------+
int start()
{
   //�ϐ��錾
   bool result_flag       = false;                            //�������ʊi�[�p
   int result_code        = R_ERROR;                          //�������ʊi�[�p
   int order_count        = R_ERROR;                          //�|�W�V������������
   int order_his_count    = 0;                                //�����|�W�V������
   bool buy_entry_filter  = true;                             //�t�B���^�[�t���O(�����O�G���g���[)
   bool sell_entry_filter = true;                             //�t�B���^�[�t���O(�V���[�g�G���g���[)
   bool buy_exit_filter   = true;                             //�t�B���^�[�t���O(�����O����)
   bool sell_exit_filter  = true;                             //�t�B���^�[�t���O(�V���[�g����)
   int entry_sig          = 0;                                //�G���g���[�V�O�i��
   int exit_sig           = 0;                                //���σV�O�i��
   int type               = OP_BUY;                           //�����敪
   double wk_mn           = 0;                                //�}�W�b�N�i���o�[
   double wk_lots         = Lots;                             //���b�g��
   double open_price      = 0;                                //��艿�i�i�[�p
   string comment         = "";                               //�I�[�_�[�R�����g�i�[�p
   color arrow_color      = CLR_NONE;                         //�F
   double wk_close_lots   = CloseLotsMax;                     //���σ��b�g��
   double takeprofit      = 0;                                //TakeProfit�i�[�p
   double stoploss        = 0;                                //StopLoss�i�[�p   
   int i                  = 0;                                //�ėp�J�E���^
   int x                  = 0;                                //�ėp�J�E���^
   int err_code           = 0;                                //�G���[�R�[�h�擾�p
   string err_title       = "[�I�u�W�F�N�g�����G���[] ";      //�G���[���b�Z�[�W�^�C�g��
   string err_title02     = "[��O�G���[] ";                  //�G���[���b�Z�[�W�^�C�g��02
   
   //�G���g���[����-�I�l�m�� Start----------------------------------------------------------------------------------------------------------------------
   int entry_shift_01 = 1;
   //�G���g���[����-�I�l�m�� End------------------------------------------------------------------------------------------------------------------------
   
   //���Ϗ���-�I�l�m�� Start----------------------------------------------------------------------------------------------------------------------------
   int exit_shift_01 = 1;
   //���Ϗ���-�I�l�m�� End------------------------------------------------------------------------------------------------------------------------------
   
   //�t�B���^�[����-�I�l�m�� Start----------------------------------------------------------------------------------------------------------------------
   //�t�B���^�[����-�I�l�m�� End------------------------------------------------------------------------------------------------------------------------
   
   //���x���I�u�W�F�N�g����(PGName)
   if(ObjectFind("PGName")!=WindowOnDropped())
   {
      result_flag = ObjectCreate("PGName",OBJ_LABEL,WindowOnDropped(),0,0);
      if(result_flag == false)          
      {
         err_code = GetLastError();
         Print(err_title,err_code, " ", ErrorDescription(err_code));
      }
   }
   ObjectSet("PGName",OBJPROP_CORNER,3);              //�A���J�[�ݒ�
   ObjectSet("PGName",OBJPROP_XDISTANCE,3);           //���ʒu�ݒ�
   ObjectSet("PGName",OBJPROP_YDISTANCE,5);           //�c�ʒu�ݒ�
   ObjectSetText("PGName",PGName,8,"Arial",Gray);     //�e�L�X�g�ݒ�


   //�I�[�_�[����
   ArrayInitialize(order,0);                      //�I�[�_�[�z�񏉊���
   order_count = OrderCheck(order,MagicNumber,ORDER_TYPE_ALL);
   if(order_count == R_ERROR) return(R_ERROR);    //�G���[����

   //TP/SL���Ϗ���
   if(OrderCount > order_count)
   {
      //�ϐ��ݒ�
      int y = 0;
      ArrayInitialize(exception,0);

      for(x=OrderCount;x>order_count;x--)
      {
         //�I�[�_�[��������
         ArrayInitialize(order_his,0);                      //�I�[�_�[�z�񏉊���
         order_his_count = OrderCheckHis(order_his,MagicNumber,exception,LAST_BUT_ONE_HIS);
         if(order_his_count == R_ERROR) return(R_ERROR);    //�G���[����
         
         //�ϐ��ݒ�
         string str_type    = "";                                                           //�I�[�_�[�^�C�v
         if(order_his[order_his_count-1][1]==OP_BUY) str_type  = "Buy";                     //����
         if(order_his[order_his_count-1][1]==OP_SELL) str_type = "Sell";                    //����
         double order_time  = order_his[order_his_count-1][7];                              //���ώ����擾
         double close_price = NormalizeDouble(order_his[order_his_count-1][8],Digits);      //���ω��i
         double op          = NormalizeDouble(order_his[order_his_count-1][9],PLDigits);     //�I�[�_�[�v���t�B�b�g
         double swap        = NormalizeDouble(order_his[order_his_count-1][10],PLDigits);    //�X���b�v���v         
         double comm        = NormalizeDouble(order_his[order_his_count-1][11],PLDigits);    //�萔��
         double pl          = op + swap + comm;                                             //���v���v
         exception[y][0]    = order_his[order_his_count-1][0];                              //�}�W�b�N�i���o�[�擾(���O�I�[�_�[)
         exception[y][1]    = order_his[order_his_count-1][7];                              //���ώ����擾(���O�I�[�_�[)
         y = y + 1;                                                                         //�J�E���g�A�b�v
         
         
         OrderCount = OrderCount - 1;
      }
   }
  
   
   //�I�[�_�[����(�����O����)
   ArrayInitialize(order,0);                             //�I�[�_�[�z�񏉊���
   order_count = OrderCheck(order,MagicNumber,ORDER_TYPE_BUY);
   if(order_count == R_ERROR) return(R_ERROR);           //�G���[����

   //���σV�O�i�����菈��
   if(order_count > 0)
   {
      for(x=order_count-1;x>=0;x--)
      {
         //�����O�|�W�V�������ϔ���
         if(order[x][1] == OP_BUY)
         {
            
            //�t�B���^�[����(����) Start-------------------------------------------------------------------------------------------------------------------------
            //�t�B���^�[����(����) End---------------------------------------------------------------------------------------------------------------------------
            
            //���Ϗ���1 Start----------------------------------------------------------------------------------------------------------------------------  
            //�ϐ��錾
            int exit001_price_digits = Digits;    //�����_
            
            //���Ϗ���1
            double exit001_before = Close[exit_shift_01+1];        //�I�l1
            double exit001_after  = Close[exit_shift_01];          //�I�l2
            
            //�����_���K�� 
            exit001_before = NormalizeDouble(exit001_before,exit001_price_digits);
            exit001_after  = NormalizeDouble(exit001_after,exit001_price_digits);
            //���Ϗ���1 End------------------------------------------------------------------------------------------------------------------------------  

            //���Ϗ���2 Start----------------------------------------------------------------------------------------------------------------------------  
            //�ϐ��錾
            int exit002_ma_digits = Digits;    //�����_
            
            //���Ϗ���2
            double exit002_before = iMA(NULL,Exit002_MA_TimeFrame,Exit002_MA_Period,0,Exit002_MA_Method,Exit002_MA_AppliedPrice,exit_shift_01+1);    //�ړ����ϐ�1
            double exit002_after  = iMA(NULL,Exit002_MA_TimeFrame,Exit002_MA_Period,0,Exit002_MA_Method,Exit002_MA_AppliedPrice,exit_shift_01);      //�ړ����ϐ�2
            
            //�����_���K�� 
            exit002_before = NormalizeDouble(exit002_before,exit002_ma_digits);
            exit002_after  = NormalizeDouble(exit002_after,exit002_ma_digits);
            //���Ϗ���2 End------------------------------------------------------------------------------------------------------------------------------  

            
            //���σV�O�i������(�����O)
            exit_sig = 0;
            
            //���Ϗ���(����-�����O) Start------------------------------------------------------------------------------------------------------------------------
            if((exit001_before >= exit002_before) && (exit001_after < exit002_after))
            {
               if(exit_sig==0) exit_sig = BUY_EXIT_SIGNAL;     //���σV�O�i��(�����O)
            }
            else exit_sig = -1;
            
            //���Ϗ���(����-�����O) End-------------------------------------------------------------------------------------------------------------------------- 
           
            //�������Ϗ���(�����O)
            if((exit_sig == BUY_EXIT_SIGNAL) && (buy_exit_filter == true))
            {         
               //���[�g�X�V
               RefreshRates();

               //�ϐ��ݒ�
               arrow_color = Blue;      //�F
               
               //���σ��b�g���ݒ�
               if(CloseLotsMax==0) wk_close_lots = order[x][5];
               else wk_close_lots = CloseLotsMax;

               //�|�W�V��������(�����O)
               result_code = OrderCloseOrg(Slippage,order[x][0],wk_close_lots,MailFlag,AlertFlag,arrow_color);
               if(result_code!=R_SUCCESS) return(R_ERROR);    //�G���[����
               OrderCount = OrderCount - 1;                   //�I�[�_�[�����Z  

               //�������ϑΉ�
               for(i=0; i<OrdersTotal(); i++)
               {
                  if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
                  {
                     //�}�W�b�N�i���o�[�Ǝ���ʉ݃y�A�̊m�F
                     if(OrderSymbol() == Symbol() && OrderMagicNumber() == order[x][0])
                     {
                         OrderCount = OrderCount + 1;         //�I�[�_�[�����Z  
                         break;
                     }
                  }
               }
            }
         }
      }
   }
   
   //�I�[�_�[����(�V���[�g����)
   ArrayInitialize(order,0);                             //�I�[�_�[�z�񏉊���
   order_count = OrderCheck(order,MagicNumber,ORDER_TYPE_SELL);
   if(order_count == R_ERROR) return(R_ERROR);           //�G���[����

   //���σV�O�i�����菈��
   if(order_count > 0)
   {
      for(x=order_count-1;x>=0;x--)
      {
         //�V���[�g�|�W�V�������ϔ���
         if(order[x][1] == OP_SELL)
         {
            
            //�t�B���^�[����(����) Start-------------------------------------------------------------------------------------------------------------------------
            //�t�B���^�[����(����) End---------------------------------------------------------------------------------------------------------------------------
            
            
            //���σV�O�i������(�V���[�g)
            exit_sig = 0;
            
            //���Ϗ���(����-�V���[�g) Start------------------------------------------------------------------------------------------------------------------------
            //���Ϗ���(����-�V���[�g) End-------------------------------------------------------------------------------------------------------------------------- 
           
            //�������Ϗ���(�V���[�g)
            if((exit_sig == SELL_EXIT_SIGNAL) && (sell_exit_filter == true))
            {         
               //���[�g�X�V
               RefreshRates();

               //�ϐ��ݒ�
               arrow_color = Red;      //�F
               
               //���σ��b�g���ݒ�
               if(CloseLotsMax==0) wk_close_lots = order[x][5];
               else wk_close_lots = CloseLotsMax;

               //�|�W�V��������(�V���[�g)
               result_code = OrderCloseOrg(Slippage,order[x][0],wk_close_lots,MailFlag,AlertFlag,arrow_color);
               if(result_code!=R_SUCCESS) return(R_ERROR);    //�G���[����
               OrderCount = OrderCount - 1;                   //�I�[�_�[�����Z
               
               //�������ϑΉ�
               for(i=0; i<OrdersTotal(); i++)
               {
                  if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
                  {
                     //�}�W�b�N�i���o�[�Ǝ���ʉ݃y�A�̊m�F
                     if(OrderSymbol() == Symbol() && OrderMagicNumber() == order[x][0])
                     {
                         OrderCount = OrderCount + 1;         //�I�[�_�[�����Z  
                         break;
                     }
                  }
               }
            }
         }
      }
   }
   
   //�I�[�_�[����(�����O�G���g���[)
   ArrayInitialize(order,0);                             //�I�[�_�[�z�񏉊���
   order_count = OrderCheck(order,MagicNumber,ORDER_TYPE_ALL);
   if(order_count == R_ERROR) return(R_ERROR);           //�G���[����
   
   
   //�t�B���^�[����(����) Start-------------------------------------------------------------------------------------------------------------------------
   //�t�B���^�[����(����) End---------------------------------------------------------------------------------------------------------------------------
   
   
   //�G���g���[�V�O�i������(�����O)
   entry_sig = 0;
   
   //�G���g���[����(����-�����O) Start------------------------------------------------------------------------------------------------------------------
   //�G���g���[����(����-�����O) End--------------------------------------------------------------------------------------------------------------------

   //�������M����(�����O)
   if((entry_sig == BUY_SIGNAL) && (buy_entry_filter == true) && (order_count < OpenOrderMax))
   {         
      //���[�g�X�V
      RefreshRates();

      //�ϐ��ݒ�
      type        = OP_BUY;    //�����O
      open_price  = Ask;       //���l
      arrow_color = Blue;      //�F
      
      //�}�W�b�N�i���o�[�Z�o
      wk_mn = MagicNumControl(MagicNumber);   
      
  
      //�I�[�_�[�̑��M
      result_code = OrderSendOrg(type,wk_lots,open_price,Slippage,0,0,comment,wk_mn,MailFlag,AlertFlag,arrow_color);
      if((result_code == R_ALERT) || (result_code == R_ERROR)) return(R_ERROR);      //�G���[����
      OrderCount = OrderCount + 1;                                                   //�I�[�_�[�����Z    
   }
   
   //�I�[�_�[����(�V���[�g�G���g���[)
   ArrayInitialize(order,0);                             //�I�[�_�[�z�񏉊���
   order_count = OrderCheck(order,MagicNumber,ORDER_TYPE_ALL);
   if(order_count == R_ERROR) return(R_ERROR);           //�G���[����
   
   
   //�t�B���^�[����(����) Start-------------------------------------------------------------------------------------------------------------------------
   //�t�B���^�[����(����) End---------------------------------------------------------------------------------------------------------------------------
   
   //�G���g���[����1 Start----------------------------------------------------------------------------------------------------------------------
   //�ϐ��錾
   int entry001_price_digits = Digits;    //�����_
   
   //�G���g���[����1
   double entry001_before = Close[entry_shift_01+1];    //�I�l1
   double entry001_after  = Close[entry_shift_01];      //�I�l2
   
   //�����_���K�� 
   entry001_before = NormalizeDouble(entry001_before,entry001_price_digits);
   entry001_after  = NormalizeDouble(entry001_after,entry001_price_digits);
   //�G���g���[����1 End------------------------------------------------------------------------------------------------------------------------

   //�G���g���[����2 Start----------------------------------------------------------------------------------------------------------------------
//�ϐ��錾
   int entry002_bb_digits = Digits;    //�����_
   
   //�G���g���[����2
   double entry002_before = iBands(NULL,Entry002_BB_TimeFrame,Entry002_BB_Period,Entry002_BB_Deviation,0,Entry002_BB_AppliedPrice,Entry002_BB_Mode,entry_shift_01+1);  //BB1
   double entry002_after  = iBands(NULL,Entry002_BB_TimeFrame,Entry002_BB_Period,Entry002_BB_Deviation,0,Entry002_BB_AppliedPrice,Entry002_BB_Mode,entry_shift_01);    //BB2
   
   //�����_���K�� 
   entry002_before = NormalizeDouble(entry002_before,entry002_bb_digits);
   entry002_after  = NormalizeDouble(entry002_after,entry002_bb_digits);
   //�G���g���[����2 End------------------------------------------------------------------------------------------------------------------------

   
   //�G���g���[�V�O�i������(�V���[�g)
   entry_sig = 0;
   
   //�G���g���[����(����-�V���[�g) Start------------------------------------------------------------------------------------------------------------------
   if((entry001_before <= entry002_before) && (entry001_after > entry002_after))
   {
      if(entry_sig==0) entry_sig = SELL_SIGNAL;    //�G���g���[�V�O�i��(�V���[�g)
   }
   else entry_sig = -1;
  
   //�G���g���[����(����-�V���[�g) End--------------------------------------------------------------------------------------------------------------------

   //�������M����(�V���[�g)
   if((entry_sig == SELL_SIGNAL) && (sell_entry_filter == true) && (order_count < OpenOrderMax))
   {
      //���[�g�X�V
      RefreshRates();
      
      //�ϐ��ݒ�
      type        = OP_SELL;    //�V���[�g
      open_price  = Bid;        //���l
      arrow_color = Red;        //�F

      //�}�W�b�N�i���o�[�Z�o
      wk_mn = MagicNumControl(MagicNumber);   
      

      //�I�[�_�[�̑��M
      result_code = OrderSendOrg(type,wk_lots,open_price,Slippage,0,0,comment,wk_mn,MailFlag,AlertFlag,arrow_color);
      if((result_code == R_ALERT) || (result_code == R_ERROR)) return(R_ERROR);      //�G���[����
      OrderCount = OrderCount + 1;                                                   //�I�[�_�[�����Z    
   }
      
   //�I�[�_�[����(SL/TP�ݒ�p)
   ArrayInitialize(order,0);                             //�I�[�_�[�z�񏉊���
   order_count = OrderCheck(order,MagicNumber,ORDER_TYPE_ALL);
   if(order_count == R_ERROR) return(R_ERROR);           //�G���[����

   //SL/TP�̐ݒ�
   for(i=order_count-1;i>=0;i--)
   {
      //StopLoss�̐ݒ�
      if(StopLossPips > 0)
      {
         //���[�g�X�V
         RefreshRates();

         //StopLoss�Z�o(�����O)
         if(order[i][1] == OP_BUY)
         {
            stoploss = order[i][2] - StopLossPips * wk_point;
            stoploss = NormalizeDouble(stoploss,Digits);      //�����_���K��
         }
         //StopLoss�Z�o(�V���[�g)
         else if (order[i][1] == OP_SELL)
         {
            stoploss = order[i][2] + StopLossPips * wk_point;
            stoploss = NormalizeDouble(stoploss,Digits);      //�����_���K��
         }
         else
         {
            Print("�s���ȃI�[�_�[���I������܂����B");
            return(R_ERROR);           //�G���[����
         }
         if(NormalizeDouble(order[i][3],Digits) == 0)
         {
            //�I�[�_�[�ύX����
            result_code = OrderModifyOrg(stoploss,0,order[i][0],MailFlag,AlertFlag,arrow_color);  
            if(result_code != R_SUCCESS) return(R_ERROR);    //�G���[����
         }
      }
      //TakeProfit�̐ݒ�
      if(TakeProfitPips > 0)
      {     
         //TakeProfit�Z�o(�����O)
         if(order[i][1] == OP_BUY)
         {
            takeprofit = order[i][2] + TakeProfitPips * wk_point;
            takeprofit = NormalizeDouble(takeprofit,Digits);      //�����_���K��
         }
         //TakeProfit�Z�o(�V���[�g)
         else if (order[i][1] == OP_SELL)
         {
            takeprofit = order[i][2] - TakeProfitPips * wk_point;
            takeprofit = NormalizeDouble(takeprofit,Digits);      //�����_���K��
         }
         else
         {
            Print("�s���ȃI�[�_�[���I������܂����B");
            return(R_ERROR);           //�G���[����
         }
         if(NormalizeDouble(order[i][4],Digits) == 0)
         {
            //�I�[�_�[�ύX����
            result_code = OrderModifyOrg(0,takeprofit,order[i][0],MailFlag,AlertFlag,arrow_color);  
            if(result_code != R_SUCCESS) return(R_ERROR);    //�G���[����
         }
      }
   }
   return(0);
}
//+------------------------------------------------------------------+
//| ������  �F�}�W�b�N�i���o�[�Z�o����                               |
//| �����ڍׁF�}�W�b�N�i���o�[�̎Z�o���s���B                         |
//| ����    �Fmagic_base �}�W�b�N�i���o�[�̊�l                    |
//| �߂�l  �Fmagic_num 0�ȏ�c�}�W�b�N�i���o�[                      |
//|                     R_ERROR�c�G���[                              |
//| ���l    �F                                                       |
//+------------------------------------------------------------------+
int MagicNumControl(int magic_num)
{
   int order_total  = OrdersTotal();                      //�I�[�_�[�J�E���g�p
   int err_code     = 0;                                  //�G���[�R�[�h�擾�p
   string err_title = "[�}�W�b�N�i���o�[�Z�o�G���[] ";    //�G���[���b�Z�[�W�^�C�g��
   
   //�}�W�b�N�i���o�[��������
   for(int x = magic_num;x < magic_num+OpenOrderMax;x++)
   {
      bool unused_flag = false;
      if (order_total > 0) 
      {
         for(int i=0; i<order_total; i++)
         {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
            {
               //�}�W�b�N�i���o�[�Ǝ���ʉ݃y�A�̊m�F
               if((OrderSymbol() == Symbol()) && (OrderMagicNumber() == x))
               {
                  unused_flag = true;
                  break;
               }
            }
            //�I�[�_�[�Z���N�g�G���[
            else          
            {
               err_code = GetLastError();
               Print(err_title,err_code, " ", ErrorDescription(err_code));
               magic_num = R_ERROR;
               break;
            }
         }
      }
      if(unused_flag == false) break;
   }
   return(x);
}
//+------------------------------------------------------------------+
//| ������  �F�I�[�_�[�J�E���g����                                   |
//| �����ڍׁF�I�[�_�[�̑����J�E���g���s���B                         |
//| ����    �F&order[][] �}�W�b�N�i���o�[/�R�����g                   |
//|           magic_base �}�W�b�N�i���o�[�̊�l                    |
//|           type �������                                          |
//| �߂�l  �Fmagic_num 0�ȏ�c�I�[�_�[����                          |
//|                     R_ERROR�c�G���[                              |
//| ���l    �F                                                       |
//+------------------------------------------------------------------+
int OrderCheck(double &order[][],int magic_base,int type)
{
   //�ϐ��錾
   int order_total          = OrdersTotal();                  //�I�[�_�[�J�E���g�p
   int order_count          = 0;                              //������
   datetime order_open_date = 0;                              //�ŐV�I�[�_�[���t�i�[�p
   int err_code             = 0;                              //�G���[�R�[�h�擾�p
   string err_title         = "[�I�[�_�[�J�E���g�G���[] ";    //�G���[���b�Z�[�W�^�C�g��

   //�I�[�_�[�̃J�E���g
   for(int i=0; i<order_total; i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
      {
         //�}�W�b�N�i���o�[�Ǝ���ʉ݃y�A�̊m�F
         if(OrderSymbol() == Symbol() && (OrderMagicNumber() >= magic_base && OrderMagicNumber() < (magic_base + OpenOrderMax)))
         {
            switch(type)
            {
               //�S�I�[�_�[
               case ORDER_TYPE_ALL:
                  if (OrderType() == OP_BUY || OrderType() == OP_SELL)
                  {
                     //�}�W�b�N�i���o�[�擾
                     order[order_count][0] = OrderMagicNumber();

                     //�I�[�_�[�^�C�v�擾
                     order[order_count][1] = OrderType();

                     //�I�[�v���v���C�X
                     order[order_count][2] = OrderOpenPrice();
               
                     //�X�g�b�v���X
                     order[order_count][3] = OrderStopLoss();
                  
                     //�e�C�N�v���t�B�b�g
                     order[order_count][4] = OrderTakeProfit();
                  
                     //���b�g��
                     order[order_count][5] = OrderLots();
                  
                     //��莞��
                     order[order_count][6] = OrderOpenTime();
                  
                     //���ώ���
                     order[order_count][7] = OrderCloseTime();
                  
                     //���ω��i
                     order[order_count][8] = OrderClosePrice();
                  
                     //�]�����v
                     order[order_count][9] = OrderProfit();
                                    
                     //�X���b�v���v
                     order[order_count][10] = OrderSwap();
                  
                     //�萔��
                     order[order_count][11] = OrderCommission();

                     order_count++;
                  }
               break;
               
               //�����O�I�[�_�[
               case ORDER_TYPE_BUY:
                  if (OrderType() == OP_BUY)
                  {
                     //�}�W�b�N�i���o�[�擾
                     order[order_count][0] = OrderMagicNumber();

                     //�I�[�_�[�^�C�v�擾
                     order[order_count][1] = OrderType();

                     //�I�[�v���v���C�X
                     order[order_count][2] = OrderOpenPrice();
               
                     //�X�g�b�v���X
                     order[order_count][3] = OrderStopLoss();
                  
                     //�e�C�N�v���t�B�b�g
                     order[order_count][4] = OrderTakeProfit();
                  
                     //���b�g��
                     order[order_count][5] = OrderLots();

                     //��莞��
                     order[order_count][6] = OrderOpenTime();
                  
                     //���ώ���
                     order[order_count][7] = OrderCloseTime();
                  
                     //���ω��i
                     order[order_count][8] = OrderClosePrice();
                  
                     //�]�����v
                     order[order_count][9] = OrderProfit();
                                    
                     //�X���b�v���v
                     order[order_count][10] = OrderSwap();
                  
                     //�萔��
                     order[order_count][11] = OrderCommission();

                     order_count++;
                  }
               break;
               
               //�V���[�g�I�[�_�[
               case ORDER_TYPE_SELL:
                  if (OrderType() == OP_SELL)
                  {
                     //�}�W�b�N�i���o�[�擾
                     order[order_count][0] = OrderMagicNumber();

                     //�I�[�_�[�^�C�v�擾
                     order[order_count][1] = OrderType();

                     //�I�[�v���v���C�X
                     order[order_count][2] = OrderOpenPrice();
               
                     //�X�g�b�v���X
                     order[order_count][3] = OrderStopLoss();
                  
                     //�e�C�N�v���t�B�b�g
                     order[order_count][4] = OrderTakeProfit();
                  
                     //���b�g��
                     order[order_count][5] = OrderLots();
                  
                     //��莞��
                     order[order_count][6] = OrderOpenTime();
                  
                     //���ώ���
                     order[order_count][7] = OrderCloseTime();
                  
                     //���ω��i
                     order[order_count][8] = OrderClosePrice();
                  
                     //�]�����v
                     order[order_count][9] = OrderProfit();
                                    
                     //�X���b�v���v
                     order[order_count][10] = OrderSwap();
                  
                     //�萔��
                     order[order_count][11] = OrderCommission();

                     order_count++;
                  }
               break;
               
               //�S�I�[�_�[
               case LAST_ORDER:
                  if (OrderType() == OP_BUY || OrderType() == OP_SELL)
                  {
                     //�ŐV�I�[�_�[���t�擾
                     if(order_open_date < OrderOpenTime())
                     {
                        order_open_date = OrderOpenTime();
                     }
                     else
                     { 
                        continue;
                     }
                     //�ϐ��ݒ�
                     order_count = 0;    //�ŐV���ŏ㏑�� 
                     
                     //�}�W�b�N�i���o�[�擾
                     order[order_count][0] = OrderMagicNumber();

                     //�I�[�_�[�^�C�v�擾
                     order[order_count][1] = OrderType();

                     //�I�[�v���v���C�X
                     order[order_count][2] = OrderOpenPrice();
               
                     //�X�g�b�v���X
                     order[order_count][3] = OrderStopLoss();
                  
                     //�e�C�N�v���t�B�b�g
                     order[order_count][4] = OrderTakeProfit();
                  
                     //���b�g��
                     order[order_count][5] = OrderLots();
                  
                     //��莞��
                     order[order_count][6] = OrderOpenTime();
                  
                     //���ώ���
                     order[order_count][7] = OrderCloseTime();
                  
                     //���ω��i
                     order[order_count][8] = OrderClosePrice();
                  
                     //�]�����v
                     order[order_count][9] = OrderProfit();
                                    
                     //�X���b�v���v
                     order[order_count][10] = OrderSwap();
                  
                     //�萔��
                     order[order_count][11] = OrderCommission();

                     order_count++;
                  }
               break;
                              
               //��O�G���[
               default:
                  Print(err_title,OrderType()," �s���ȃI�[�_�[�^�C�v���I������܂����B");
                  order_count = R_ERROR;
               break;
            }
         }
      }
      //�G���[����
      else          
      {
         err_code = GetLastError();
         Print(err_title,err_code, " ", ErrorDescription(err_code));
         order_count = R_ERROR;
         break;
      }
   }
   return(order_count);
}
//+------------------------------------------------------------------+
//| ������  �F�I�[�_�[�J�E���g�����i�����j                           |
//| �����ڍׁF�I�[�_�[�̑����J�E���g���s���B                         |
//| ����    �F&order[][] �I�[�_�[���i�[�p�z��                      |
//|           magic_base �}�W�b�N�i���o�[�̊�l                    |
//|           type �������                                          |
//|           &exception[][] ���O�I�[�_�[                            |
//| �߂�l  �Fmagic_num 0�ȏ�c�I�[�_�[����                          |
//|                     R_ERROR�c�G���[                              |
//| ���l    �F                                                       |
//+------------------------------------------------------------------+
int OrderCheckHis(double &order[][],int magic_base,double &exception[][],int type)
{
   //�ϐ��錾
   int order_history        = OrdersHistoryTotal();           //�I�[�_�[�J�E���g
   int order_count          = 0;                              //������
   datetime order_open_date = 0;                              //�ŐV�I�[�_�[���t�i�[�p(���)
   datetime his_order_date  = 0;                              //�ŐV�I�[�_�[���t�i�[�p(����)
   int err_code             = 0;                              //�G���[�R�[�h�擾�p
   string err_title         = "[�I�[�_�[�J�E���g�G���[] ";    //�G���[���b�Z�[�W�^�C�g��

   //�I�[�_�[�̃J�E���g
   for(int i=order_history-1; i>=0; i--)
   {  
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true)
      {
         //�}�W�b�N�i���o�[�Ǝ���ʉ݃y�A�̊m�F
         if(OrderSymbol() == Symbol() && (OrderMagicNumber() >= magic_base && OrderMagicNumber() < (magic_base + OpenOrderMax)))
         {  
            switch(type)
            {
               case LAST_HIS:
                  if (OrderType() == OP_BUY || OrderType() == OP_SELL)
                  {  
                     //�ŐV�I�[�_�[���t�擾
                     if(his_order_date <= OrderCloseTime())
                     {
                        //���ώ����������ꍇ
                        if(his_order_date == OrderCloseTime())
                        {
                           //��������r
                           if(order_open_date > OrderOpenTime())
                           {
                              continue;
                           }
                        }
                        order_open_date = OrderOpenTime();
                        his_order_date  = OrderCloseTime();
                     }
                     else
                     { 
                        continue;
                     }

                     //�ϐ��ݒ�
                     order_count = 0;    //�ŐV���ŏ㏑��  
                                  
                     //�}�W�b�N�i���o�[�擾
                     order[order_count][0] = OrderMagicNumber();

                     //�I�[�_�[�^�C�v�擾
                     order[order_count][1] = OrderType();
               
                     //�I�[�v���v���C�X
                     order[order_count][2] = OrderOpenPrice();
               
                     //�X�g�b�v���X
                     order[order_count][3] = OrderStopLoss();
                  
                     //�e�C�N�v���t�B�b�g
                     order[order_count][4] = OrderTakeProfit();
                  
                     //���b�g��
                     order[order_count][5] = OrderLots();
                  
                     //��莞��
                     order[order_count][6] = OrderOpenTime();
                  
                     //���ώ���
                     order[order_count][7] = OrderCloseTime();
                  
                     //���ω��i
                     order[order_count][8] = OrderClosePrice();
                  
                     //�]�����v
                     order[order_count][9] = OrderProfit();
                                    
                     //�X���b�v���v
                     order[order_count][10] = OrderSwap();
                  
                     //�萔��
                     order[order_count][11] = OrderCommission();

                     order_count++;
                  }
               break;
               case LAST_BUT_ONE_HIS:
                  //�w�莞������O�̗���
                  if (OrderType() == OP_BUY || OrderType() == OP_SELL)
                  {
                     //��O�̓��t�擾
                     if(his_order_date < OrderCloseTime())
                     {
                        bool begin_flag = false;
                        for(int x = 0;x<OpenOrderMax;x++)
                        {
                           if((OrderMagicNumber() == exception[x][0]) && (OrderCloseTime() == exception[x][1]))
                           {
                              begin_flag = true;
                              break;
                           }
                        }
                        if (begin_flag == true) continue;
                        his_order_date = OrderCloseTime();
                     }
                     else
                     { 
                        continue;
                     }

                     //�ϐ��ݒ�
                     order_count = 0;    //�ŐV���ŏ㏑��  
                               
                     //�}�W�b�N�i���o�[�擾
                     order[order_count][0] = OrderMagicNumber();

                     //�I�[�_�[�^�C�v�擾
                     order[order_count][1] = OrderType();
            
                     //�I�[�v���v���C�X
                     order[order_count][2] = OrderOpenPrice();
            
                     //�X�g�b�v���X
                     order[order_count][3] = OrderStopLoss();
               
                     //�e�C�N�v���t�B�b�g
                     order[order_count][4] = OrderTakeProfit();
               
                     //���b�g��
                     order[order_count][5] = OrderLots();
               
                     //��莞��
                     order[order_count][6] = OrderOpenTime();
               
                     //���ώ���
                     order[order_count][7] = OrderCloseTime();
               
                     //���ω��i
                     order[order_count][8] = OrderClosePrice();
               
                     //�]�����v
                     order[order_count][9] = OrderProfit();
                                 
                     //�X���b�v���v
                     order[order_count][10] = OrderSwap();
               
                     //�萔��
                     order[order_count][11] = OrderCommission();

                     order_count++;
                  }
               break;
               default:
                  Print(err_title,OrderType()," �s���ȃI�[�_�[�^�C�v���I������܂����B");
                  order_count = R_ERROR;
               break;
            }
         }
      }
      //�G���[����
      else          
      {
         err_code = GetLastError();
         Print(err_title,err_code, " ", ErrorDescription(err_code));
         order_count = R_ERROR;
         break;
      }
   }
   return(order_count);
}
//+------------------------------------------------------------------+
//| ������  �F���b�g���K������                                       |
//| �����ڍׁF���b�g�̐��K�����s���B                                 |
//| ����    �Flots ���K���O���b�g��                                  |
//| �߂�l  �Flots 0�ȏ�c���K���ネ�b�g��                           |
//|                R_ERROR�c�G���[                                   |
//| ���l    �F                                                       |
//+------------------------------------------------------------------+
double LotNorm(double lots)
{
   //�ϐ��錾
   double min_lots = MarketInfo(Symbol(), MODE_MINLOT);     //���b�g�ŏ��l
   double max_lots = MarketInfo(Symbol(), MODE_MAXLOT);     //���b�g�ő�l   
   double lot_step = MarketInfo(Symbol(), MODE_LOTSTEP);    //���b�g�X�e�b�v��   
   
   //���b�g�����K��
   lots = MathRound(lots / lot_step) * lot_step;
   
   //�ŏ��E�ő�l�ݒ�
   if(lots < min_lots) lots = min_lots;
   if(lots > max_lots) lots = max_lots; 

   return(lots);
}


//+------------------------------------------------------------------+
//| ������  �F�I�[�_�[���M����                                       |
//| �����ڍׁF�I�[�_�[�̑��M���s���B                                 |
//| ����    �Ftype ����敪                                          |
//|           lots ���b�g��                                          |
//|           price ����񎦉��i                                     |
//|           slippage �ő�X���b�y�[�W                              |
//|           stop_loss ���؂艿�i                                   |
//|           take_profit ���H�����i                                 |
//|           comment �I�[�_�[�̃R�����g                             |
//|           magic_num �}�W�b�N�i���o�[                             |
//|           mail_flag ���[�����m�点�@�\(true:�L���Afalse:����)    |
//|           alert_flag �A���[�g���m�点�@�\(true:�L���Afalse:����) |
//|           arrow_color ���̐F                                   |
//| �߂�l  �Fticket_num 0�ȏ�c�`�P�b�g�ԍ�                         |
//|                      R_ERROR�c�G���[                             |
//|                      R_ALERT�cAlert                              |
//| ���l    �F                                                       |
//+------------------------------------------------------------------+
int OrderSendOrg(int type,double lots,double price,int slippage,double stop_loss,
double take_profit,string comment,int magic_num,bool mail_flag,bool alert_flag,color arrow_color)
{
   //�ϐ��錾
   int ticket_num   = R_ERROR;                           //�`�P�b�g�ԍ�
   int err_code     = 0;                                 //�G���[�R�[�h�擾�p
   int s_time       = 0;                                 //�J�n�����擾�p
   string err_title = "[�I�[�_�[���M�G���[] ";           //�G���[���b�Z�[�W�^�C�g��
   string str_type  = "";                                //�I�[�_�[���

   //�J�n�����擾
   s_time = GetTickCount();

   //�I�[�_�[���M
   while(true)
   {
      //�^�C���A�E�g����
      if(GetTickCount() - s_time > RETRY_TIMEOUT * 1000)
      {
         Print(err_title,"�I�[�_�[���M�������^�C���A�E�g���܂����B");
         ticket_num = R_ALERT;
         break;
      }
      if(IsTradeAllowed() == true)
      {       
         //���[�g�X�V
         RefreshRates();

         //�����_�̐��K��
         price       = NormalizeDouble(price,Digits);          //������i
         stop_loss   = NormalizeDouble(stop_loss,Digits);      //���؂艿�i
         take_profit = NormalizeDouble(take_profit,Digits);    //���H�����i

         //�I�[�_�[���M
         switch(type)
         {
            case OP_BUY:
               ticket_num = OrderSend(Symbol(),type,lots,Ask,slippage,stop_loss,take_profit,comment,magic_num,0,arrow_color);
            break;
            case OP_SELL:
               ticket_num = OrderSend(Symbol(),type,lots,Bid,slippage,stop_loss,take_profit,comment,magic_num,0,arrow_color);
            break;
            default:
               ticket_num = OrderSend(Symbol(),type,lots,price,slippage,stop_loss,take_profit,comment,magic_num,0,arrow_color);
            break;
         }
         
         //�G���[�R�[�h�擾
         err_code = GetLastError();

         //����I��
         if(ticket_num >= 0)
         {
            break;
         }
         //�ُ�I��
         else
         {
            //�G���[����
            Print(err_title,err_code, " ", ErrorDescription(err_code));
            ticket_num  = R_ALERT;
            
            //��O�G���[
            if(err_code == ERR_INVALID_PRICE) break;
            if(err_code == ERR_INVALID_STOPS) break;
            if(IsTesting()) break;
         }
      }
      Sleep(RETRY_INTERVAL);    //���g���C�C���^�[�o��
   }
   

   return(ticket_num);
}

//+------------------------------------------------------------------+
//| ������  �F�I�[�_�[�ύX����                                       |
//| �����ڍׁF�I�[�_�[�̕ύX���s���B                                 |
//| ����    �Fstop_loss ���؂艿�i                                   |
//|           take_profit ���H�����i                                 |
//|           magic_num �}�W�b�N�i���o�[                             |
//|           mail_flag ���[�����m�点�@�\(true:�L���Afalse:����)    |
//|           alert_flag �A���[�g���m�点�@�\(true:�L���Afalse:����) |
//|           arrow_color ���̐F                                   |
//| �߂�l  �Ferr_ck_num 0�c����I��                                 |
//|                      R_ERROR�c�G���[                             |
//|                      R_ALERT�cAlert                              |
//|                      R_WARNING�cWarning                          |
//| ���l    �F                                                       |
//+------------------------------------------------------------------+
int OrderModifyOrg(double stop_loss,double take_profit,int magic_num,bool mail_flag,bool alert_flag,color arrow_color)
{
   //�ϐ��錾
   int ticket_num   = 0;                          //�`�P�b�g�ԍ�
   int err_code     = 0;                          //�G���[�R�[�h�擾�p
   int err_ck_num   = R_ERROR;                    //�G���[�`�F�b�N�p
   int s_time       = 0;                          //�J�n�����擾�p
   string str_type  = "";                         //�I�[�_�[���
   string err_title = "[�I�[�_�[�ύX�G���[] ";    //�G���[���b�Z�[�W�^�C�g��

   //�����`�F�b�N
   if(stop_loss == 0 && take_profit == 0)
   {
      err_ck_num = R_WARNING;
      return(err_ck_num);
   }

   //�`�P�b�g�ԍ��擾
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == magic_num)
         {
            if(OrderType() == OP_BUY)
            {
               //�`�P�b�g�ԍ��擾
               ticket_num = OrderTicket();
               str_type   = "Buy";     //�����I�[�_�[
               break;
            }
            if(OrderType() == OP_SELL)
            {
               //�`�P�b�g�ԍ��擾
               ticket_num = OrderTicket();
               str_type   = "Sell";    //����I�[�_�[
               break;
            }
         }
      }
      //�G���[����
      else          
      {
         err_code = GetLastError();
         Print(err_title,err_code, " ", ErrorDescription(err_code));
         err_ck_num  = R_ERROR;
         return(err_ck_num);
      }
   }
   
   //1�������݂��Ȃ������ꍇ
   if(ticket_num == 0)
   {
      err_ck_num = R_WARNING;
      return(err_ck_num);
   }
   
   //���ݒl�擾(�p�����[�^��0�̏ꍇ�̂�)
   if(stop_loss == 0) stop_loss = OrderStopLoss();
   if(take_profit == 0) take_profit = OrderTakeProfit();

   //�����_�̐��K��
   stop_loss = NormalizeDouble(stop_loss, Digits);
   take_profit = NormalizeDouble(take_profit, Digits);

   //�J�n�����擾
   s_time = GetTickCount();

   //�I�[�_�[�ύX
   while(true)
   {
      //�^�C���A�E�g����
      if(GetTickCount() - s_time > RETRY_TIMEOUT * 1000)
      {
         Print(err_title,"�I�[�_�[�ύX�������^�C���A�E�g���܂����B");
         err_ck_num = R_ALERT;
         break;
      }
      if(IsTradeAllowed() == true)
      {       
         //���[�g�X�V
         RefreshRates();

         //�I�[�_�[�ύX
         bool err_ck_flag = OrderModify(ticket_num,0,stop_loss,take_profit,0,arrow_color);
      
         //�G���[�R�[�h�擾
         err_code = GetLastError();

         //����I��
         if(err_ck_flag == true)
         {
            err_ck_num = R_SUCCESS;
            break;
         }
         //�ُ�I��
         else
         {
            //�G���[����
            err_ck_num = R_ERROR;
            Print(err_title,err_code, " ", ErrorDescription(err_code));

            //��O�G���[
            if(err_code == ERR_NO_RESULT) break;
            if(err_code == ERR_INVALID_STOPS) break;
            if(IsTesting()) break;
         }
      }
      Sleep(RETRY_INTERVAL);    //���g���C�C���^�[�o��
   }
   

   return(err_ck_num);
}
//+------------------------------------------------------------------+
//| ������  �F�I�[�_�[���Ϗ���                                       |
//| �����ڍׁF�I�[�_�[�̌��ς��s���B                                 |
//| ����    �Fslippage �ő�X���b�y�[�W                              |
//|           magic_num �}�W�b�N�i���o�[                             |
//|           lots ���b�g��                                          |
//|           mail_flag ���[�����m�点�@�\(true:�L���Afalse:����)    |
//|           alert_flag �A���[�g���m�点�@�\(true:�L���Afalse:����) |
//|           arrow_color ���̐F                                   |
//| �߂�l  �Ferr_ck_num 0�c����I��                                 |
//|                      R_ERROR�c�G���[                             |
//|                      R_ALERT�cAlert                              |
//|                      R_WARNING�cWarning                          |
//| ���l    �F                                                       |
//+------------------------------------------------------------------+
int OrderCloseOrg(int slippage,int magic_num,double lots,bool mail_flag,bool alert_flag,color arrow_color)
{
   //�ϐ��錾
   int ticket_num   = 0;                          //�`�P�b�g�ԍ�
   int err_code     = 0;                          //�G���[�R�[�h�擾�p
   int err_ck_num   = R_ERROR;                    //�G���[�`�F�b�N�p
   int s_time       = 0;                          //�J�n�����擾�p
   double op        = 0;                          //�v���t�B�b�g�i�[�p
   double swap      = 0;                          //�X���b�v���v�i�[�p  
   double comm      = 0;                          //�萔���i�[�p
   double pl        = 0;                          //���v���v�i�[�p
   datetime sv_time = 0;                          //�I�[�_�[���ώ���
   bool err_ck_flag = false;                      //�G���[�`�F�b�N�t���O
   string str_type  = "";                         //�I�[�_�[���
   string err_title = "[�I�[�_�[���σG���[] ";    //�G���[���b�Z�[�W�^�C�g��

   //�`�P�b�g�ԍ��擾
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == magic_num)
         {
            if(OrderType() == OP_BUY)
            {
               ticket_num = OrderTicket();
               str_type   = "Buy";
               break;
            }
            if(OrderType() == OP_SELL)
            {
               ticket_num = OrderTicket();
               str_type   = "Sell";
               break;
            }
         }
      }
      //�G���[����
      else          
      {
         err_code = GetLastError();
         Print(err_title,err_code, " ", ErrorDescription(err_code));
         err_ck_num  = R_ERROR;
         return(err_ck_num);
      }
   }
 
   //1�������݂��Ȃ������ꍇ
   if(ticket_num == 0)
   {
      err_ck_num = R_WARNING;
      return(err_ck_num);
   }
   
   //���b�g������
   if((lots > OrderLots()) || (lots == 0)) lots = OrderLots();
   
   //�J�n�����擾
   s_time = GetTickCount();

   //�I�[�_�[����
   while(true)
   {
      //�^�C���A�E�g����
      if(GetTickCount() - s_time > RETRY_TIMEOUT * 1000)
      {
         Print(err_title,"�I�[�_�[���Ϗ������^�C���A�E�g���܂����B");
         err_ck_num = R_ALERT;
         break;
      }
      if(IsTradeAllowed() == true)
      {       
         //���[�g�X�V
         RefreshRates();
         double close_price = NormalizeDouble(OrderClosePrice(),Digits);    //�����_���K��

         //�I�[�_�[����
         err_ck_flag = OrderClose(ticket_num,lots,close_price,slippage,arrow_color);
         
         //�G���[�R�[�h�擾
         err_code = GetLastError();
           
         //����I��
         if(err_ck_flag == true)
         {
            err_ck_num = R_SUCCESS;
            break;
         }
         //�ُ�I��
         else
         {
            //�G���[����
            err_ck_num = R_ERROR;
            Print(err_title,err_code, " ", ErrorDescription(err_code));
            
            //��O�G���[
            if(err_code == ERR_INVALID_PRICE) break;
            if(IsTesting()) break;
         }
      }
      Sleep(RETRY_INTERVAL);    //���g���C�C���^�[�o��
   }
   
   //�I�[�_�[��������
   if(OrderSelect(ticket_num,SELECT_BY_TICKET,MODE_HISTORY)==true)
   {
      sv_time = OrderCloseTime();                              //�I�[�_�[���ώ���
      op      = NormalizeDouble(OrderProfit(),PLDigits);        //�I�[�_�[�v���t�B�b�g
      swap    = NormalizeDouble(OrderSwap(),PLDigits);          //�X���b�v���v
      comm    = NormalizeDouble(OrderCommission(),PLDigits);    //�萔��
      pl      = op + swap + comm;                              //���v���v
   }
   //�G���[����
   else Print(err_title,"�I�[�_�[���ώ����̎擾�Ɏ��s���܂����B");
   

   return(err_ck_num);
}
//+------------------------------------------------------------------+