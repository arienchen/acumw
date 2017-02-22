        IDENTIFICATION DIVISION.
        PROGRAM-ID. MSGPERF.
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
            88 PARAM-END        VALUE 'Y'.
        
        
        01  STIME               SIGNED-LONG VALUE 0.  
        01  TIME_NOW            SIGNED-LONG VALUE 0. 
        01  TIME_LAG            SIGNED-LONG VALUE 0.
        01  TPS                 SIGNED-LONG VALUE 0.   
        01  MSG-SLEEP           SIGNED-LONG VALUE 0.
        01  MSG-CNT             SIGNED-LONG VALUE 0.
        01  MSG-SIZE            SIGNED-INT VALUE 100.
        01  MSG-FLAG            SIGNED-INT VALUE IPC-BLOCK.     
        01  MSG-ID              SIGNED-INT VALUE 0.
        01  MSG-QUE.
            05  QUE-NAME        PIC X(IPC-NAME-LEN) 
                                VALUE SPACES.
            05  FILLER          PIC X.
      
      * MSG-BODY �̤j 10240 (10K) ��ڤj�p�� MSG-SIZE  
        01  MSG-DATA.
            05  MSG-LEN         SIGNED-INT.
            05  MSG-TYPE        SIGNED-LONG VALUE 1.
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

      * ���o COMMAND-LINE �Ѽ�            
            PERFORM 2000-PARAM.

      * ��ܰ���Ѽ�            
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

      * OPEN MSG QUE �Y�w�� MSGID (ex: ipcs -q) �h�i�ٲ�            
            CALL 'IPC$MSG' USING 
                BY VALUE        IPC-MSG-OPEN,
                BY REFERENCE    MSG-ID,
                BY REFERENCE    MSG-QUE,
                BY VALUE        IPC_CREAT,
                GIVING INTO RET-CODE.
               
            IF RET-CODE NOT = IPCERR_OK
                DISPLAY "IPC$MSG OPEN FAILED : " RET-CODE;
                GO TO 1000-ERR
            END-IF.
            
            DISPLAY "-----------------------------------------------".
            DISPLAY "MSGID    : " MSG-ID.
            
            IF HDR-FILE NOT = SPACES
                PERFORM 6000-HDRINIT;
            END-IF.
            
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

      * PARSING COMMAND-LINE ���e
      * ��ܩʰѼ� : -n , -c msg_cnt, -s msg_size , -o hdr_out
      * ���n�Ѽ�   : que_name (�������̫�@��)             
            PERFORM UNTIL PARAM-FLAG = "Y"  
                UNSTRING PARAM-LIST 
                    DELIMITED BY ALL SPACE 
                    INTO PARAM 
                    POINTER STRING-PTR
                    ON OVERFLOW 
                        IF STRING-PTR > PARAM-LIST-SIZE THEN   
                            MOVE "Y" TO PARAM-FLAG   
      * �̫�@�ӰѼơA������ que_name                            
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
            
            DISPLAY "MSGPERF - SYS/V Msg Que Performance Profiler".
            DISPLAY "Usage:".
            DISPLAY "  runcbl MSGPERF [options] $que_name".
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
      * �ǰe MSG-CNT ����ơA��Ƥ��e�� NANO TICKS 
      * �ǰe MSG-TICKS = 0 �q�������ݡA��Ƥw����
      *-----------------------------------------------------------
        4000-SEND.
            DISPLAY "------------------------------------------------".
            DISPLAY "START SENDING ...".
            
      * �]�w�T�����e
            MOVE MSG-SIZE TO MSG-LEN.
            MOVE 1 TO MSG-TYPE.
            MOVE IPCERR_OK TO RET-CODE.
             
      * �����}�l�ɶ� MICRO SECOND      
            CALL 'MW$UTILS' USING 
                BY VALUE     TICKS_USEC  
                BY REFERENCE STIME.
            
      * �ǰe�j�� 
            MOVE 1 TO MSG-IDX;
                   
            PERFORM MSG-CNT TIMES
                 
      * �ǰe IPC MSG  
                PERFORM TEST AFTER UNTIL RET-CODE = IPCERR_OK       
     
      * ���o�t�ήɶ� NANO TICK (10^-9)     
                    CALL 'MW$UTILS' USING 
                        BY VALUE     TICKS_NSEC  
                        BY REFERENCE MSG-TICKS;
     
                    CALL 'IPC$MSG' USING 
                        BY VALUE        IPC-MSG-SEND,
                        BY VALUE        MSG-ID,
                        BY REFERENCE    MSG-DATA,
                        BY VALUE        MSG-FLAG,
                        GIVING INTO RET-CODE;
                    
      * �ˬd�ǰe���G              
                    IF RET-CODE NOT = IPCERR_OK
                        IF RET-CODE NOT = IPCERR_EAGAIN
                            DISPLAY "IPC$MSG SEND FAILED : " RET-CODE 
                            GO TO 1000-ERR
                        END-IF 
                        
      * �� MSG-FLAG = IPC_NOWAIT -> QUE FULL      
      * �Y�����w IPC_NOWAIT �� QUE FULL �|�O BLOCK MODE           
                        DISPLAY "MSG QUE FULL";
                        CONTINUE;
                    END-IF;
                
                END-PERFORM;
      
      * �p��ǰe LATENCY �A�üg�J HDR HISTOGRAM           
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
                        BY VALUE	SLEEP_USEC,
                        BY VALUE	MSG-SLEEP;
                END-IF;    
                
            END-PERFORM.    
            
      * �ǰe�����A�q�������ݡA�w�ǰe����      
            MOVE 0 TO MSG-IDX.
            CALL 'MW$UTILS' USING 
                BY VALUE     TICKS_NSEC  
                BY REFERENCE MSG-TICKS;
                        
            CALL 'IPC$MSG' USING 
                BY VALUE        IPC-MSG-SEND,
                BY VALUE        MSG-ID,
                BY REFERENCE    MSG-DATA,
                BY VALUE        IPC-BLOCK,
                GIVING INTO RET-CODE.
                 
      * �ǰe�����A�έp�ǰe�ɶ�
            CALL 'MW$UTILS' USING 
                BY VALUE     SPENT_USEC
                BY VALUE     STIME  
                BY REFERENCE STIME.
                
            
      *-----------------------------------------------------------  
      * ���� IPC MSG �íp�� LATENCY      
      * ������� 1 �ɡA�����t�ήɶ��� TPS �p�⤧�}�l�ɶ�
      * �� MSG-IDX �� 0 �ɡA���ܬ������A�����t�ήɶ��� TPS �p�⤧�����ɶ�
      *-----------------------------------------------------------
        5000-RECV.
            DISPLAY "------------------------------------------------".
            DISPLAY "START RECEIVING ...".
            
            PERFORM TEST AFTER UNTIL MSG-IDX = 0  
            
      * �]�w��������(�C��)
                MOVE 0 TO MSG-TYPE;
                MOVE LENGTH OF MSG-BODY TO MSG-LEN;
                
      * �����T�� 
                PERFORM TEST AFTER UNTIL RET-CODE = IPCERR_OK      
                    CALL 'IPC$MSG' USING 
                        BY VALUE        IPC-MSG-RECV,
                        BY VALUE        MSG-ID,
                        BY REFERENCE    MSG-DATA,
                        BY VALUE        MSG-FLAG,
                        GIVING INTO RET-CODE;
      
      * �� MSG-FLAG = IPC_NOWAIT �B QUE EMPTY �|���� ENOMSG 
      * �Y�����w IPC_NOWAIT �� QUE EMPTY �ɬ� BLOCK MODE             
                    IF RET-CODE NOT = IPCERR_OK
                        IF RET-CODE NOT = IPCERR_ENOMSG 
                            DISPLAY "IPC$MSG RECV FAILED : " RET-CODE;
                            GO TO 1000-ERR;
                        END-IF;
                        
                        DISPLAY "MSG QUE EMPTY";
                        CONTINUE;                   
                    END-IF;
                END-PERFORM;
                
      * ������s�T���A���O���t�ήɶ�
                CALL 'MW$UTILS' USING 
                    BY VALUE     TICKS_NSEC  
                    BY REFERENCE TIME-NOW;
      
      * �P�_�O�_�������έp�� LATENCY       
      * �� 1 ���ݬ����}�l�ɶ� STIME�A���ഫ NANO �� MICRO SECOND       
                IF MSG-IDX = 0 
                    NEXT SENTENCE;
                END-IF;
                
                COMPUTE MSG-CNT = MSG-CNT + 1;
            
                IF MSG-CNT = 1 
                    COMPUTE STIME = TIME-NOW / 1000;
                END-IF;
            
                COMPUTE TIME-LAG = TIME-NOW - MSG-TICKS;
            
      * ���� HDR HISTOGRAM 
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
            
      * ���������A�έp�����ɶ�
            CALL 'MW$UTILS' USING 
                BY VALUE     SPENT_USEC
                BY VALUE     STIME  
                BY REFERENCE STIME.
            
        
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
            DISPLAY "------------------------------------------------".
                      
                
        END PROGRAM MSGPERF.