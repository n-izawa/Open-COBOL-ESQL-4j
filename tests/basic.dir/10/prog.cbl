
       IDENTIFICATION              DIVISION.
      ******************************************************************
       PROGRAM-ID.                 prog.
      ******************************************************************
       DATA                        DIVISION.
      ******************************************************************
       WORKING-STORAGE             SECTION.
       01  TEST-DATA.
         03 FILLER       PIC X(28) VALUE "0001�k�C�@���Y          0400".
         03 FILLER       PIC X(28) VALUE "0002�X�@���Y          0350".
         03 FILLER       PIC X(28) VALUE "0003�H�c�@�O�Y          0300".
         03 FILLER       PIC X(28) VALUE "0004���@�l�Y          025p".
         03 FILLER       PIC X(28) VALUE "0005�{��@�ܘY          020p".
         03 FILLER       PIC X(28) VALUE "0006�����@�Z�Y          0150".
         03 FILLER       PIC X(28) VALUE "0007�Ȗ؁@���Y          010p".
         03 FILLER       PIC X(28) VALUE "0008���@���Y          0050".
         03 FILLER       PIC X(28) VALUE "0009�Q�n�@��Y          020p".
         03 FILLER       PIC X(28) VALUE "0010��ʁ@�\�Y          0350".

       01  TEST-DATA-R   REDEFINES TEST-DATA.
         03  TEST-TBL    OCCURS  10.
           05  TEST-NO             PIC S9(04).
           05  TEST-NAME           PIC  X(20) .
           05  TEST-SALARY         PIC S9(04).
       01  IDX                     PIC  9(02).
       01 LOG-COUNT PIC 9999 VALUE 1.

       01 SQL-COMMAND.
         03 SQL-COMMAND-LEN PIC 99 VALUE 0.
         03 SQL-COMMAND-ARR PIC X(50)
            VALUE "DELETE FROM EMP WHERE EMP_NO > ?".
       01 SQL-COMMAND-ARG PIC 99 VALUE 5.

       EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01  DBNAME                  PIC  X(30) VALUE SPACE.
       01  USERNAME                PIC  X(30) VALUE SPACE.
       01  PASSWD                  PIC  X(10) VALUE SPACE.

       01  EMP-REC-VARS.
         03  EMP-NO                PIC S9(04) VALUE ZERO.
         03  EMP-NAME              PIC  X(20) .
         03  EMP-SALARY            PIC S9(04) VALUE ZERO.
       EXEC SQL END DECLARE SECTION END-EXEC.

       EXEC SQL INCLUDE SQLCA END-EXEC.
      ******************************************************************
       PROCEDURE                   DIVISION.
      ******************************************************************
       MAIN-RTN.

       PERFORM SETUP-DB.

      *    PREPARE
           EXEC SQL
               PREPARE st FROM :SQL-COMMAND
           END-EXEC.
           PERFORM OUTPUT-RETURN-CODE-TEST.

      *    EXECUTE
           EXEC SQL
               EXECUTE st USING :SQL-COMMAND-ARG
           END-EXEC.
           PERFORM OUTPUT-RETURN-CODE-TEST.

      *    DECLARE CURSOR
           EXEC SQL
               DECLARE C1 CURSOR FOR
               SELECT EMP_NO, EMP_NAME, EMP_SALARY
                      FROM EMP
                      ORDER BY EMP_NO
           END-EXEC.

      *    OPEN CURSOR
           EXEC SQL
               OPEN C1
           END-EXEC.

           EXEC SQL
               FETCH C1 INTO :EMP-NO, :EMP-NAME, :EMP-SALARY
           END-EXEC.
           PERFORM UNTIL SQLCODE NOT = ZERO

              DISPLAY LOG-COUNT " <log> success fetch_record "
                      EMP-NO ", " EMP-NAME ", " EMP-SALARY
              ADD 1 TO LOG-COUNT
              EXEC SQL
                  FETCH C1 INTO :EMP-NO, :EMP-NAME, :EMP-SALARY
              END-EXEC
           END-PERFORM.

       PERFORM CLEANUP-DB.

      *    END
           STOP RUN.

      ******************************************************************
       SETUP-DB.
      ******************************************************************

      *    SERVER
           MOVE  "<|DB_NAME|>@<|DB_HOST|>:<|DB_PORT|>"
             TO DBNAME.
           MOVE  "<|DB_USER|>"
             TO USERNAME.
           MOVE  "<|DB_PASSWORD|>"
             TO PASSWD.

           EXEC SQL
               CONNECT :USERNAME IDENTIFIED BY :PASSWD USING :DBNAME
           END-EXEC.

           EXEC SQL
               DROP TABLE IF EXISTS EMP
           END-EXEC.

           EXEC SQL
                CREATE TABLE EMP
                (
                    EMP_NO     NUMERIC(4,0) NOT NULL,
                    EMP_NAME   CHAR(20),
                    EMP_SALARY NUMERIC(4,0),
                    CONSTRAINT IEMP_0 PRIMARY KEY (EMP_NO)
                )
           END-EXEC.

      *    INSERT ROWS USING HOST VARIABLE
           PERFORM VARYING IDX FROM 1 BY 1 UNTIL IDX > 10
              MOVE TEST-NO(IDX)     TO  EMP-NO
              MOVE TEST-NAME(IDX)   TO  EMP-NAME
              MOVE TEST-SALARY(IDX) TO  EMP-SALARY
              EXEC SQL
                 INSERT INTO EMP VALUES
                        (:EMP-NO,:EMP-NAME,:EMP-SALARY)
              END-EXEC
           END-PERFORM.

      ******************************************************************
       CLEANUP-DB.
      ******************************************************************
           EXEC SQL
               CLOSE C1
           END-EXEC.

           EXEC SQL
               DROP TABLE IF EXISTS EMP
           END-EXEC.

           EXEC SQL
               DISCONNECT ALL
           END-EXEC.

      ******************************************************************
       OUTPUT-RETURN-CODE-TEST.
      ******************************************************************
           IF  SQLCODE = ZERO
             THEN

               DISPLAY LOG-COUNT " <log> success test_return_code"

             ELSE
               DISPLAY LOG-COUNT " <log> fail test_return_code    "
                   NO ADVANCING
               DISPLAY "SQLCODE=" SQLCODE " ERRCODE="  SQLSTATE " "
                   NO ADVANCING
               EVALUATE SQLCODE
                  WHEN  +10
                     DISPLAY "Record_not_found"
                  WHEN  -01
                     DISPLAY "Connection_falied"
                  WHEN  -20
                     DISPLAY "Internal_error"
                  WHEN  -30
                     DISPLAY "PostgreSQL_error" NO ADVANCING
                     DISPLAY SQLERRMC
                  *> TO RESTART TRANSACTION, DO ROLLBACK.
                     EXEC SQL
                         ROLLBACK
                     END-EXEC
                  WHEN  OTHER
                     DISPLAY "Undefined_error" NO ADVANCING
                     DISPLAY SQLERRMC
               END-EVALUATE.

           ADD 1 TO LOG-COUNT.
      ******************************************************************



