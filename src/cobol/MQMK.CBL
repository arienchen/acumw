        IDENTIFICATION DIVISION.
        PROGRAM-ID. MQMK.
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
        
        
        01  MSG-MAX             SIGNED-INT VALUE 10.
        01  MSG-SIZE            SIGNED-INT VALUE 100.
        01  MSG-FLAG            SIGNED-INT.     
        01  MSG-ID              SIGNED-INT VALUE 0.
        01  MSG-QUE.
            05  QUE-NAME        PIC X(IPC-NAME-LEN) 
                                VALUE SPACES.
            05  FILLER          PIC X.
                     
        PROCEDURE               DIVISION.
        MAIN-RTN                SECTION.
        0000-BEGIN.

      * 眔 COMMAND-LINE 把计            
            PERFORM 2000-PARAM.

      * 陪ボ磅︽把计            
            DISPLAY "-----------------------------------------------".
            DISPLAY "MSG QUE  : " QUE-NAME(1:60).
            DISPLAY "MSG MAX  : " MSG-MAX.
            DISPLAY "MSG SIZE : " MSG-SIZE.
            
      * CREATE MSG QUE 璝 QUE 玥肚岿粇        
            COMPUTE MSG-FLAG = IPC_CREAT + IPC_EXCL.
            CALL 'IPC$MQ' USING 
                BY VALUE        IPC-MQ-OPEN,
                BY REFERENCE    MSG-ID,
                BY REFERENCE    MSG-QUE,
                BY VALUE        MSG-FLAG,
                BY VALUE        MSG-MAX,
                BY VALUE        MSG-SIZE,
                GIVING INTO RET-CODE.
            
            DISPLAY "-----------------------------------------------".
               
            IF RET-CODE NOT = IPCERR_OK
                DISPLAY "IPC$MQ OPEN FAILED : " RET-CODE;
                GO TO 1000-ERR;
            END-IF.
            
            DISPLAY "MSGID    : " MSG-ID " CREATED".
            DISPLAY "-----------------------------------------------".
            DISPLAY " ".
                      
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
            DISPLAY "-----------------------------------------------".
            DISPLAY " ".
                
            GO TO 0000-EXIT.
          
          
        2000-PARAM.
            
            ACCEPT PARAM-LIST FROM COMMAND-LINE.
            MOVE 1 TO STRING-PTR.
            SET PARAM-LIST-SIZE TO SIZE OF PARAM-LIST.

      * PARSING COMMAND-LINE ず甧
      * 匡拒┦把计 : -c msg_cnt, -s msg_size 
      * ゲ璶把计   : que_name (ゲ斗程)             
            PERFORM UNTIL PARAM-FLAG = "Y"  
                UNSTRING PARAM-LIST 
                    DELIMITED BY ALL SPACE 
                    INTO PARAM 
                    POINTER STRING-PTR
                    ON OVERFLOW 
                        IF STRING-PTR > PARAM-LIST-SIZE THEN   
                            MOVE "Y" TO PARAM-FLAG   
      * 程把计ゲ斗 que_name                            
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
                WHEN "-c"   MOVE PARAM TO PARAM-PREV
                WHEN "-s"   MOVE PARAM TO PARAM-PREV
                WHEN OTHER 
                    EVALUATE PARAM-PREV
                        WHEN "-c" 
                            COMPUTE MSG-MAX = FUNCTION NUMVAL(PARAM)
                        WHEN "-s" 
                            COMPUTE MSG-SIZE = FUNCTION NUMVAL(PARAM)
                        WHEN OTHER 
                            GO TO 3000-PERR
                    END-EVALUATE
                    MOVE SPACES TO PARAM-PREV
            END-EVALUATE.    
            
        3000-PERR.
            DISPLAY "INVALID PARAMETER".
            DISPLAY " ".
            
            DISPLAY "MQMK - Create Msg Que(POSIX)".
            DISPLAY "Usage:".
            DISPLAY "  runcbl MQMK [options] $que_name".
            DISPLAY " ".
            DISPLAY "options:".
            DISPLAY "  [-c msg_max]       Max Msg in Que, default 10".
            DISPLAY "  [-s msg_size]      Max Size of Msg, default 100".
            DISPLAY " "
            GO TO 0000-EXIT.    
                  
                
        END PROGRAM MQMK.