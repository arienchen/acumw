        IDENTIFICATION DIVISION.
        PROGRAM-ID. MSGRM.
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
                DISPLAY "MSGRM - Remove MSg Que(SYS/V)";
                DISPLAY "Usage:";
                DISPLAY "  runcbl MSGRM $que_name";
                GO TO 0000-EXIT;
            END-IF.
            
            CALL 'IPC$MSG' USING 
                BY VALUE		IPC-MSG-RM,
           	    BY REFERENCE    MSG-QUE,
           	    GIVING INTO RET-CODE.
           	   
            IF RET-CODE NOT = IPCERR_OK
                GO TO 1000-ERR;
            END-IF.
            
            DISPLAY "-----------------------------------------------".
            DISPLAY "SYS/V MSG QUE : " QUE-NAME(1:60).
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
            
        END PROGRAM MSGRM.