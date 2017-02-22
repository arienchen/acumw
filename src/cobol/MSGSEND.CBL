        IDENTIFICATION DIVISION.
        PROGRAM-ID. MSGSEND.
        WORKING-STORAGE SECTION.        
        COPY "MWAPI.DEF".
        
        77  ERR-TXT             PIC X(80).
        77  ERR-LEN             SIGNED-INT VALUE 0.
        77  RET-CODE            SIGNED-INT VALUE 0.
        
        
        01  MSG-ID              SIGNED-INT VALUE 0.
        01  MSG-QUE.
            05  QUE-NAME        PIC X(IPC-NAME-LEN).
            05  FILLER          PIC X.
        
        01  MSG-DATA.
            05  MSG-LEN         SIGNED-INT.
            05  MSG-TYPE        SIGNED-LONG VALUE 1.
            05  MSG-BODY        PIC X(255).
                		
            		
        PROCEDURE               DIVISION.
        MAIN-RTN                SECTION.
        0000-BEGIN.
      	   
      	    ACCEPT QUE-NAME FROM COMMAND-LINE.
            
            IF QUE-NAME = SPACE 
                DISPLAY "MSGSEND - Send Msg (SYS/V)";
                DISPLAY "Usage:";
                DISPLAY "  runcbl MSGSEND $que_name";
                DISPLAY " ";
                GO TO 0000-EXIT;
            END-IF.
            
            CALL 'IPC$MSG' USING 
                BY VALUE		IPC-MSG-OPEN,
                BY REFERENCE    MSG-ID,
           	    BY REFERENCE    MSG-QUE,
           	    BY VALUE        IPC_CREAT, 
           	    GIVING INTO RET-CODE.
           	   
            IF RET-CODE NOT = IPCERR_OK
                GO TO 1000-ERR;
            END-IF.
            
            DISPLAY "-----------------------------------------------".
            DISPLAY "SYS/V MSG QUE : " QUE-NAME(1:60).
            DISPLAY "        MSGID : " MSG-ID.
            DISPLAY "------------------------------------------------".
            
            ACCEPT MSG-BODY FROM TIME.
            MOVE 8 TO MSG-LEN.
            
            CALL 'IPC$MSG' USING 
                BY VALUE		IPC-MSG-SEND,
                BY VALUE        MSG-ID,
                BY REFERENCE    MSG-DATA,
                BY VALUE        IPC-BLOCK,
                GIVING INTO RET-CODE.
                
            IF RET-CODE NOT = IPCERR_OK
                GO TO 1000-ERR;
            END-IF.
                
            DISPLAY "SENT:" MSG-BODY(1:MSG-LEN).
            
                      
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
                    
            DISPLAY "RUN ERROR : " RET-CODE.
            DISPLAY "          : " ERR-TXT(1:ERR-LEN).
                
            GO TO 0000-EXIT.
            
        END PROGRAM MSGSEND.