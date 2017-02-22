        IDENTIFICATION DIVISION.
        PROGRAM-ID. MQPERF.
        WORKING-STORAGE SECTION.        
        COPY "MWAPI.DEF".
        
        77  ERR-TXT             PIC X(80).
        77  ERR-LEN             SIGNED-INT VALUE 0.
        77  RET-CODE            SIGNED-INT VALUE 0.
        
        77  PARAM-LIST          PIC X(255).
        77  PARAM-LIST-SIZE     PIC 9(3).
        77  PARAM               PIC X(80) VALUE SPACE.
        77  PARAM-PREV          PIC X(80) VALUE SPACE. 
        77  STRING-PTR          PIC 9(3).
        77  PARAM-FLAG          PIC X VALUE SPACE.
            88  PARAM-END       VALUE 'Y'.
        
        
        01  STIME               SIGNED-LONG VALUE 0.  
        01  TIME_NOW            SIGNED-LONG VALUE 0. 
        01  TIME_LAG            SIGNED-LONG VALUE 0.
        01  TPS                 SIGNED-LONG VALUE 0.   
        01  MSG-SLEEP           SIGNED-LONG VALUE 0.
        01  MSG-CNT             SIGNED-LONG VALUE 0.
        01  MSG-SIZE            SIGNED-INT  VALUE 100.
        01  MAX-MSG             SIGNED-INT  VALUE 100.
        01  MAX-SIZE            SIGNED-INT  VALUE 10240.
        01  MSG-FLAG            SIGNED-INT  VALUE 0.     
        01  MSG-ID              SIGNED-INT  VALUE 0.
        01  MSG-QUE.
            05  QUE-NAME        PIC X(IPC-NAME-LEN) 
                                VALUE SPACES.
            05  FILLER          PIC X.
      
      * MSG-BODY 最大 10240 (10K) 實際大小為 MSG-SIZE  
        01  MQ-DATA.
            05  MSG-LEN         SIGNED-INT.
            05  MSG-PRIOR       SIGNED-INT VALUE 1.
            05  MSG-BODY        PIC X(10240).
            05  FILLER REDEFINES MSG-BODY.
                10 MSG-IDX      SIGNED-LONG.
                10 MSG-TICKS    SIGNED-LONG.
                
        01  HDR-PARAM.         
            05  HDR-HIST        POINTER VALUE 0.
            05  HDR-MIN         SIGNED-LONG VALUE 1.
            05  HDR-MAX         SIGNED-LONG VALUE 3600000000.
            05  HDR-OUT.
                10  HDR-FILE    PIC X(FILE_NAME_LEN) VALUE SPACES.
                10  FILLER      PIC X.
            05  HDR-TICKS       SIGNED-INT VALUE 5.
            05  HDR-MUL         DOUBLE VALUE 1000.0.
            05  HDR-PREC        SIGNED-INT VALUE 5.
            05  HDR-FMT         SIGNED-INT VALUE HDR_CLASSIC.                 
                     
        PROCEDURE               DIVISION.
        MAIN-RTN                SECTION.
        0000-BEGIN.

      * 取得 COMMAND-LINE 參數            
            PERFORM 2000-PARAM.

      * 顯示執行參數            
            DISPLAY "-----------------------------------------------".
            IF MSG-CNT > 0 THEN
                DISPLAY "RUN MODE : SENDER" 
                DISPLAY "MSG QUE  : " QUE-NAME(1:60)
                DISPLAY "MSG CNT  : " MSG-CNT
                DISPLAY "MSG SIZE : " MSG-SIZE
                DISPLAY "MSG WAIT : " MSG-SLEEP 
            ELSE 
                DISPLAY "RUN MODE : RECEIVER"
                DISPLAY "MSG QUE  : " QUE-NAME(1:60)                
            END-IF.
            DISPLAY "HDR OUT  : " HDR-FILE(1:60).

      * OPEN MSG QUE    
      * 若為 NON-BLOCK 須於開啟時，設定 +IPC_NOWAIT 
            COMPUTE MSG-FLAG = MSG-FLAG + IPC_CREAT.         
            CALL 'IPC$MQ' USING 
                BY VALUE        IPC-MQ-OPEN,
                BY REFERENCE    MSG-ID,
                BY REFERENCE    MSG-QUE,
                BY VALUE        MSG-FLAG,
                BY VALUE        MAX-MSG,
                BY VALUE        MAX-SIZE, 
                GIVING INTO RET-CODE.
               
            IF RET-CODE NOT = IPCERR_OK
                DISPLAY "IPC$MQ OPEN FAILED : " RET-CODE;
                GO TO 1000-ERR
            END-IF.
            
            DISPLAY "-----------------------------------------------".
            DISPLAY "MSGID    : " MSG-ID.
            
            IF HDR-FILE NOT = SPACES
                PERFORM 6000-HDRINIT;
            END-IF.
            
      * 檢查 QUE STATUS 若有資料，則錯誤
            PERFORM 5500-QUECHK.
                   
            IF MSG-CNT > 0 
                PERFORM 4000-SEND;
            ELSE 
                PERFORM 5000-RECV;
            END-IF.
            
            PERFORM 8000-TPS.
            
            IF HDR-HIST NOT = 0 
                PERFORM 7000-HDROUT;
            END-IF.
                      
        0000-EXIT.
            DISPLAY "------------------------------------------------".
            DISPLAY "PRESS <ENTER> TO EXIT".
            ACCEPT OMITTED.                                                     
            STOP RUN.
            
        1000-ERR.
            MOVE LENGTH OF ERR-TXT TO ERR-LEN.
            
            CALL 'MW$STR' USING
                BY VALUE        SERROR,
                BY VALUE        RET_CODE,
                BY REFERENCE    ERR-TXT,
                BY REFERENCE    ERR-LEN. 
                    
            DISPLAY "SERROR : " ERR-TXT(1:ERR-LEN).
                
            GO TO 0000-EXIT.
          
          
        2000-PARAM.
            
            ACCEPT PARAM-LIST FROM COMMAND-LINE.
            MOVE 1 TO STRING-PTR.
            SET PARAM-LIST-SIZE TO SIZE OF PARAM-LIST.

      * PARSING COMMAND-LINE 內容
      * 選擇性參數 : -n , -c msg_cnt, -s msg_size , -o hdr_out
      * 必要參數   : que_name (必須為最後一個)             
            PERFORM UNTIL PARAM-FLAG = "Y"  
                UNSTRING PARAM-LIST 
                    DELIMITED BY ALL SPACE 
                    INTO PARAM 
                    POINTER STRING-PTR
                    ON OVERFLOW 
                        IF STRING-PTR > PARAM-LIST-SIZE THEN   
                            MOVE "Y" TO PARAM-FLAG   
      * 最後一個參數，必須為 que_name                            
                            IF PARAM-PREV NOT = SPACES 
                                GO TO 3000-PERR
                            END-IF
                            MOVE PARAM TO QUE-NAME
                        ELSE 
                            PERFORM 2500-SETPARAM                            
                        END-IF   
                END-UNSTRING
            END-PERFORM.
            
            IF QUE-NAME = SPACES 
                DISPLAY 'Y'
                GO TO 3000-PERR
            END-IF.
             
        2500-SETPARAM.
            EVALUATE PARAM 
                WHEN "-n"   MOVE IPC_NOWAIT TO MSG-FLAG
                WHEN "-c"   MOVE PARAM TO PARAM-PREV
                WHEN "-s"   MOVE PARAM TO PARAM-PREV
                WHEN "-o"   MOVE PARAM TO PARAM-PREV 
                when "-w"   MOVE PARAM TO PARAM-PREV 
                WHEN OTHER 
                    EVALUATE PARAM-PREV
                        WHEN "-c" 
                            COMPUTE MSG-CNT = FUNCTION NUMVAL(PARAM)
                        WHEN "-s" 
                            COMPUTE MSG-SIZE = FUNCTION NUMVAL(PARAM)
                        WHEN "-o" 
                            MOVE PARAM TO HDR-FILE
                        WHEN "-w" 
                            COMPUTE MSG-SLEEP = FUNCTION NUMVAL(PARAM)
                        WHEN OTHER 
                            GO TO 3000-PERR
                    END-EVALUATE
                    MOVE SPACES TO PARAM-PREV
            END-EVALUATE.    
            
        3000-PERR.
            DISPLAY "INVALID PARAMETER".
            DISPLAY " ".
            
            DISPLAY "MQPERF - POSIX Msg Que Performance Profiler".
            DISPLAY "Usage:".
            DISPLAY "  runcbl MQPERF [options] $que_name".
            DISPLAY " ".
            DISPLAY "options:".
            DISPLAY "  [-c msg_cnt]       Producer(Sender) msg count".
            DISPLAY "  [-s msg_size]      Payload of Body".
            DISPLAY "                     default 100".
            DISPLAY "  [-o hdr_out]       Output File of Hdr Histogram".
            DISPLAY "                     default hdr.out".
            DISPLAY "  [-n]               Non-Block Mode". 
            DISPLAY " "
            GO TO 0000-EXIT.    
            
      *-----------------------------------------------------------  
      * 傳送 MSG-CNT 筆資料，資料內容為 NANO TICKS 
      * 傳送 MSG-TICKS = 0 通知接收端，資料已結束
      *-----------------------------------------------------------
        4000-SEND.
            DISPLAY "------------------------------------------------".
            DISPLAY "START SENDING ...".
            
      * 設定訊息內容
            MOVE MSG-SIZE TO MSG-LEN.
            MOVE 1 TO MSG-PRIOR.
            MOVE IPCERR_OK TO RET-CODE.
             
      * 紀錄開始時間 MICRO SECOND      
            CALL 'MW$UTILS' USING 
                BY VALUE     TICKS_USEC  
                BY REFERENCE STIME.
            
      * 傳送迴圈 
            MOVE 1 TO MSG-IDX;
                   
            PERFORM MSG-CNT TIMES
                 
      * 傳送 IPC MSG  
                PERFORM TEST AFTER UNTIL RET-CODE = IPCERR_OK       
     
      * 取得系統時間 NANO TICK (10^-9)     
                    CALL 'MW$UTILS' USING 
                        BY VALUE     TICKS_NSEC  
                        BY REFERENCE MSG-TICKS;
     
                    CALL 'IPC$MQ' USING 
                        BY VALUE        IPC-MQ-SEND,
                        BY VALUE        MSG-ID,
                        BY REFERENCE    MQ-DATA,
                        GIVING INTO RET-CODE;
                    
      * 檢查傳送結果              
                    IF RET-CODE NOT = IPCERR_OK
                        IF RET-CODE NOT = IPCERR_EAGAIN
                            DISPLAY "IPC$MQ SEND FAILED : " RET-CODE 
                            GO TO 1000-ERR
                        END-IF 
                        
      * 當 MSG-FLAG = IPC_NOWAIT -> QUE FULL      
      * 若未指定 IPC_NOWAIT 當 QUE FULL 會是 BLOCK MODE           
                        DISPLAY "MSG QUE FULL";
                        CONTINUE;
                    END-IF;
                
                END-PERFORM;
      
      * 計算傳送 LATENCY ，並寫入 HDR HISTOGRAM           
                CALL 'MW$UTILS' USING 
                    BY VALUE     SPENT_NSEC
                    BY VALUE     MSG-TICKS  
                    BY REFERENCE TIME-LAG;
      
                COMPUTE MSG-IDX = MSG-IDX + 1;    
                
                IF HDR-HIST NOT = 0              
                    CALL 'HDR$HIST' USING 
                        BY VALUE     HDR_VALUE,
                        BY VALUE     HDR-HIST,
                        BY VALUE     TIME-LAG,
                        GIVING INTO RET-CODE;
                    
      *         IF RET-CODE NOT = IPCERR_OK
      *             DISPLAY "HDR$HIST SET VALUE FAILED : " RET-CODE;
      *             GO TO 1000-ERR;
      *         END-IF;    
                    
                END-IF;
                    
                IF MSG-SLEEP NOT = 0 
                    CALL 'MW$UTILS' USING 
                        BY VALUE    SLEEP_USEC,
                        BY VALUE    MSG-SLEEP;
                END-IF;    
                
            END-PERFORM.    
            
      * 傳送末筆，通知接收端，已傳送結束      
            MOVE 0 TO MSG-IDX.
            CALL 'MW$UTILS' USING 
                BY VALUE     TICKS_NSEC  
                BY REFERENCE MSG-TICKS;
                        
            CALL 'IPC$MQ' USING 
                BY VALUE        IPC-MQ-SEND,
                BY VALUE        MSG-ID,
                BY REFERENCE    MQ-DATA,
                GIVING INTO RET-CODE.
                 
      * 傳送結束，統計傳送時間
            CALL 'MW$UTILS' USING 
                BY VALUE     SPENT_USEC
                BY VALUE     STIME  
                BY REFERENCE STIME.
                
            
      *-----------------------------------------------------------  
      * 接收 IPC MSG 並計算 LATENCY      
      * 接收到第 1 時，紀錄系統時間為 TPS 計算之開始時間
      * 當 MSG-IDX 為 0 時，表示為末筆，紀錄系統時間為 TPS 計算之結束時間
      *-----------------------------------------------------------
        5000-RECV.
            DISPLAY "------------------------------------------------".
            DISPLAY "START RECEIVING ...".
            
            PERFORM TEST AFTER UNTIL MSG-IDX = 0  
            
      * 設定接收條件(每次)
                MOVE LENGTH OF MSG-BODY TO MSG-LEN;
                
      * 接收訊息 
                PERFORM TEST AFTER UNTIL RET-CODE = IPCERR_OK      
                    CALL 'IPC$MQ' USING 
                        BY VALUE        IPC-MQ-RECV,
                        BY VALUE        MSG-ID,
                        BY REFERENCE    MQ-DATA,
                        GIVING INTO RET-CODE;
      
      * 當 MSG-FLAG = IPC_NOWAIT 且 QUE EMPTY 會收到 ENOMSG 
      * 若未指定 IPC_NOWAIT 當 QUE EMPTY 時為 BLOCK MODE             
                    IF RET-CODE NOT = IPCERR_OK
                        IF RET-CODE NOT = IPCERR_ENOMSG 
                            DISPLAY "IPC$MQ RECV FAILED : " RET-CODE;
                            GO TO 1000-ERR;
                        END-IF;
                        
                        DISPLAY "MSG QUE EMPTY";
                        CONTINUE;                   
                    END-IF;
                END-PERFORM;
                
      * 接收到新訊息，先記錄系統時間
                CALL 'MW$UTILS' USING 
                    BY VALUE     TICKS_NSEC  
                    BY REFERENCE TIME-NOW;
      
      *         DISPLAY "IDX " MSG-IDX " TICK=" MSG-TICKS;
                
      * 判斷是否為末筆及計算 LATENCY       
      * 第 1 筆需紀錄開始時間 STIME，需轉換 NANO 為 MICRO SECOND       
                IF MSG-IDX = 0 
                    EXIT PERFORM;
                END-IF;
                
                COMPUTE MSG-CNT = MSG-CNT + 1;
            
                IF MSG-CNT = 1 
                    COMPUTE STIME = TIME-NOW / 1000;
                END-IF;
            
                COMPUTE TIME-LAG = TIME-NOW - MSG-TICKS;
            
      * 紀錄 HDR HISTOGRAM 
                IF HDR-HIST NOT = 0 
                    CALL 'HDR$HIST' USING 
                        BY VALUE     HDR_VALUE,
                        BY VALUE     HDR-HIST,
                        BY VALUE     TIME-LAG,
                        GIVING INTO RET-CODE;
                    
      *         IF RET-CODE NOT = IPCERR_OK
      *             DISPLAY "HDR$HIST SET VALUE FAILED : " RET-CODE;
      *             GO TO 1000-ERR;
      *         END-IF;
                END-IF;
                    
            END-PERFORM.
            
      * 接收結束，統計接收時間
            CALL 'MW$UTILS' USING 
                BY VALUE     SPENT_USEC
                BY VALUE     STIME  
                BY REFERENCE STIME.
            
        5500-QUECHK.
            CALL 'IPC$MQ' USING 
                BY VALUE        IPC-MQ-STATUS,
                BY REFERENCE    MSG-QUE,
                BY REFERENCE    IPC-MQ-ATTR-T
                GIVING INTO RET-CODE.
               
            IF RET-CODE NOT = IPCERR_OK
                GO TO 1000-ERR;
            END-IF.
                
            DISPLAY "-----------------------------------------------".
            DISPLAY "POSIX MSG QUE STATUS".
            DISPLAY "  NAME          : " QUE-NAME(1:60).
            DISPLAY "  MSG MAX       : " IPC-MQATTR-MAX.
            DISPLAY "  MSG SIZE      : " IPC-MQATTR-SIZE.
            DISPLAY "  MSG CNT       : " IPC-MQATTR-CNT.
            DISPLAY "  MSG FLAG      : " IPC-MQATTR-FLAG.            
            
            IF IPC-MQATTR-CNT > 0 
                DISPLAY "----------------------------------------------"
                DISPLAY "DATA EXIST, PLEASE PURGE FIRST";
                GO TO 0000-EXIT;
            END-IF.
             
        6000-HDRINIT.
            DISPLAY "------------------------------------------------".
            CALL 'HDR$HIST' USING 
                BY VALUE        HDR_INIT,
                BY REFERENCE    HDR-HIST,
                BY VALUE        HDR-MIN,
                BY VALUE        HDR-MAX,
                BY VALUE        HDR-PREC,
                GIVING INTO RET-CODE.
            
            IF RET-CODE NOT = IPCERR_OK
                DISPLAY "HDR$HIST INIT FAILED : " RET-CODE;
                GO TO 1000-ERR; 
            END-IF.
            
            DISPLAY "HDR$HIST INIT OK".  
                
        7000-HDROUT.
            CALL 'HDR$HIST' USING 
                BY VALUE        HDR_SAVE,
                BY VALUE        HDR-HIST,
                BY REFERENCE    HDR-FILE,
                BY VALUE        HDR-TICKS,
                BY REFERENCE    HDR-MUL,
                BY VALUE        HDR-FMT,
                GIVING INTO RET-CODE.
            
            IF RET-CODE NOT = IPCERR_OK
                DISPLAY "HDR$HIST SAVE FAILED : " RET-CODE;
                GO TO 1000-ERR;
            END-IF.
             
        8000-TPS.
            IF STIME > 0
                COMPUTE TPS = MSG-CNT * 1000000 / STIME
            END-IF.
            
            DISPLAY "------------------------------------------------".
            DISPLAY "SPENT   " STIME " us ".
            DISPLAY "MSG CNT " MSG-CNT.
            DISPLAY "TPS     " TPS " msg/sec". 
                      
                
        END PROGRAM MQPERF.