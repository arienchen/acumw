        IDENTIFICATION DIVISION.
        PROGRAM-ID. MQRM.
        WORKING-STORAGE SECTION.        
        COPY "MWAPI.DEF".
        
        77  ERR-TXT             PIC X(80).
        77  ERR-LEN             SIGNED-INT VALUE 0.
        77  RET-CODE            SIGNED-INT VALUE 0.
        
        
        01  MSG-ID              SIGNED-INT VALUE 0.
        01  MSG-QUE.
            05  QUE-NAME        PIC X(IPC-NAME-LEN).
            05  FILLER          PIC X.
            		
        PROCEDURE               DIVISION.
        MAIN-RTN                SECTION.
        0000-BEGIN.
      	   
      	    ACCEPT QUE-NAME FROM COMMAND-LINE.
            
            IF QUE-NAME = SPACE 
                DISPLAY "MQRM - Remove Msg Que(POSIX)";
                DISPLAY "Usage:";
                DISPLAY "  runcbl MQRM $que_name";
                DISPLAY " ";
                GO TO 0000-EXIT;
            END-IF.
            
            CALL 'IPC$MQ' USING 
                BY VALUE		IPC-MQ-RM,
           	    BY REFERENCE    MSG-QUE,
           	    GIVING INTO RET-CODE.
           	   
            IF RET-CODE NOT = IPCERR_OK
                GO TO 1000-ERR;
            END-IF.
            
            DISPLAY "-----------------------------------------------".
            DISPLAY "POSIX MSG QUE : " QUE-NAME(1:60).
            DISPLAY "REMOVED".
            DISPLAY "------------------------------------------------".
            
                      
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
            
        END PROGRAM MQRM.