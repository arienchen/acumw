        IDENTIFICATION DIVISION.
        PROGRAM-ID. MSGSTS.
        WORKING-STORAGE SECTION.        
        COPY "MWAPI.DEF".
        
        77  ERR-TXT             PIC X(80).
        77  ERR-LEN             SIGNED-INT VALUE 0.
        77  RET-CODE            SIGNED-INT VALUE 0.
        
        01  PERM-STR            PIC X(11).
        01  KEY-STR             PIC X(8).
        
        01   MSG-QUE.
            05  QUE-NAME    PIC X(IPC-NAME-LEN).
            05  FILLER      PIC X.
            		
        PROCEDURE               DIVISION.
        MAIN-RTN                SECTION.
        0000-BEGIN.
      	   
      	    ACCEPT QUE-NAME FROM COMMAND-LINE.
            
            IF QUE-NAME = SPACE
                DISPLAY "MSGSTS - Status of Msg Que(SYS/V)"; 
                DISPLAY "Usage:";
                DISPLAY "  runcbl MSGSTS $que_name";
                GO TO 0000-EXIT;
            END-IF.
            
            CALL 'IPC$MSG' USING 
                BY VALUE		IPC-MSG-STATUS,
           	    BY REFERENCE MSG-QUE,
           	    BY REFERENCE IPC-MSG-ATTR-T
           	    GIVING INTO RET-CODE.
           	   
            IF RET-CODE NOT = IPCERR_OK
                GO TO 1000-ERR;
            END-IF.
            
      * 轉換為 8 進位， ex: 0660     
            CALL 'MW$STR' USING
                BY VALUE        OCT_STR, 
                BY VALUE        IPC-MSGATTR-MODE,
                BY REFERENCE    PERM-STR.

      * 轉換為 16 進位
            CALL 'MW$STR' USING 
                BY VALUE        HEX_STR,
                BY VALUE        IPC-MSGATTR-KEY,
                BY REFERENCE    KEY-STR.
                
            DISPLAY "-----------------------------------------------".
            DISPLAY "SYS/V MSG QUE STATUS(same as ipcs -q)".
      	    DISPLAY "  NAME          : " QUE-NAME(1:60).
      	    DISPLAY "  KEY           : " "0x" KEY-STR.
      	    DISPLAY "  MSGID         : " IPC-MSGATTR-MSGID.
      	    DISPLAY "  UID           : " IPC-MSGATTR-UID.
      	    DISPLAY "  GID           : " IPC-MSGATTR-GID.
      	    DISPLAY "  MODE          : " PERM-STR(8:4).
            DISPLAY "  CREATED       : " IPC-MSGATTR-CDATE " "
                                         IPC-MSGATTR-CTIME.
            DISPLAY "  LAST SEND     : " IPC-MSGATTR-SDATE " " 
                                         IPC-MSGATTR-STIME.
            DISPLAY "  LAST RECV     : " IPC-MSGATTR-RDATE " "
                                         IPC-MSGATTR-RTIME .
            DISPLAY "  MSG CNT       : " IPC-MSGATTR-MSGCNT.
            DISPLAY "  MSG SIZE      : " IPC-MSGATTR-MSGSIZE.            
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
            
        END PROGRAM MSGSTS.