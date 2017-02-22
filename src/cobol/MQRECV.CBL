      */--------------------------------------------------------------
      * MQRECV.CBL 
      * ���� POSIX Msg Que ��ܩ�e�� 
      *
      * LAST MODIFIED : V1.0 2016-08-19 ARIEN CHEN
      *
      * DESCRIPTION
      * 1. �ϥ� BLOCK MODE �} Msg Que 
      * 2. �T���j�p���̤j 1024  
      * 3. �۰ʶ} QUE MSG-FLAG += IPC_CREAT 
      * 
      * CHANGED LOSG
      * -------------------------------------------------------------
      * 2016-06-19 ARIEN 
      *     COPY FROM MSGRECV.CBL 
      *  
      */
        IDENTIFICATION DIVISION.
        PROGRAM-ID. MQRECV.
        WORKING-STORAGE SECTION.        
        COPY "MWAPI.DEF".
        
        77  ERR-TXT             PIC X(80).
        77  ERR-LEN             SIGNED-INT VALUE 0.
        77  RET-CODE            SIGNED-INT VALUE 0.
        
        
        01  MSG-ID              SIGNED-INT VALUE 0.
        01  MSG-FLAG            SIGNED-INT VALUE 0.
        01  MSG-QUE.
            05  QUE-NAME        PIC X(IPC-NAME-LEN).
            05  FILLER          PIC X.
        
        01  MQ-DATA.
            05  MSG-LEN         SIGNED-INT.
            05  MSG-PRIOR       SIGNED-INT VALUE 1.
            05  MSG-BODY        PIC X(1024).
                		
            		
        PROCEDURE               DIVISION.
        MAIN-RTN                SECTION.
        0000-BEGIN.
      	   
      	    ACCEPT QUE-NAME FROM COMMAND-LINE.
            
            IF QUE-NAME = SPACE 
                DISPLAY "MQRECV - Recv Msg (POSIX)";
                DISPLAY "Usage:";
                DISPLAY "  runcbl MQRECV $que_name";
                DISPLAY " ";
                GO TO 0000-EXIT;
            END-IF.
            
            CALL 'IPC$MQ' USING 
                BY VALUE		IPC-MQ-OPEN,
                BY REFERENCE    MSG-ID,
           	    BY REFERENCE    MSG-QUE,
           	    BY VALUE        MSG-FLAG,
           	    GIVING INTO RET-CODE.
           	   
            IF RET-CODE NOT = IPCERR_OK
                GO TO 1000-ERR;
            END-IF.
            
            DISPLAY "-----------------------------------------------".
            DISPLAY "POSIX MSG QUE : " QUE-NAME(1:60).
            DISPLAY "        MSGID : " MSG-ID.
            DISPLAY "------------------------------------------------".
            
            MOVE LENGTH OF MSG-BODY TO MSG-LEN.
            
            CALL 'IPC$MQ' USING 
                BY VALUE		IPC-MQ-RECV,
                BY VALUE        MSG-ID,
                BY REFERENCE    MQ-DATA,
                GIVING INTO RET-CODE.
                
            IF RET-CODE NOT = IPCERR_OK
                GO TO 1000-ERR;
            END-IF.
                
            DISPLAY "RECV " MSG-LEN " bytes -> [" 
                    MSG-BODY(1:MSG-LEN) "]".
            
                      
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
            
        END PROGRAM MQRECV.