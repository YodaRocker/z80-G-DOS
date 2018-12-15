;----------------------------------------------------
; Project: G80S.zdsp
; Main File: G80S.asm
; Date: 12-Feb-17 19:16:29
;
; Created with zDevStudio - Z80 Development Studio.
; Design and Code by Doug Gabbard (2017)
;----------------------------------------------------

SIOA_D          EQU     00H    ;SIO CHANNEL A DATA REGISTER
SIOA_C          EQU     02H    ;SIO CHANNEL A CONTROL REGISTER
SIOB_D          EQU     01H    ;SIO CHANNEL B DATA REGISTER
SIOB_C          EQU     03H    ;SIO CHANNEL B CONTROL REGISTER

ROM_TOP         EQU     07FFFH
RAM_BOT         EQU     08000H
RAM_TOP         EQU     0FFFFH
USRSPC_TOP      EQU     0FAFFH
USRSPC_BOT      EQU     08000H
STACK           EQU     0FBFFH
BUF_BOT         EQU     0FFDAH
BUF_TOP         EQU     0FFFFH
BUF_POINTER     EQU     0FFD9H



SPACE           EQU     020H            ; Space
TAB             EQU     09H             ; HORIZONTAL TAB
CTRLC           EQU     03H             ; Control "C"
CTRLG           EQU     07H             ; Control "G"
BKSP            EQU     08H             ; Back space
LF              EQU     0AH             ; Line feed
CS              EQU     0CH             ; Clear screen
CR              EQU     0DH             ; Carriage return
CTRLO           EQU     0FH             ; Control "O"
CTRLQ	        EQU     011H            ; Control "Q"
CTRLR           EQU     012H            ; Control "R"
CTRLS           EQU     013H            ; Control "S"
CTRLU           EQU     015H            ; Control "U"
ESC             EQU     01BH            ; Escape
DEL             EQU     07FH            ; Delete

;-------------------------------------------------------------------------------
; BEGINNING OF CODE
;-------------------------------------------------------------------------------
                ORG     0000h
BOOT:
        DI
        LD SP,STACK                     ;STACK OCCUPIES FBFF AND BELOW.
        JP INIT                         ;GO INITIALIZE THE SYSTEM.

                ORG     0050H
SYS_CALL_PRN_CHAR:
        JP PRINT_CHAR
SYS_CALL_PRN_STRG:
        JP PRINT_STRING






;-------------------------------------------------------------------------------
; SERIAL MONITOR/OS
;-------------------------------------------------------------------------------
                ORG     0100H
; INIT IS THE ROUTINE THAT SETS UP, OR INITIALIZES, THE PERIPHERALS.
INIT:
        CALL SERIAL_INIT
        LD HL,CS_MSG
        CALL PRINT_STRING
        LD HL,SIGNON_MSG
        CALL PRINT_STRING
        CALL PRINT_PROMPT

; SERMAIN_LOOP, THE MAIN LOOP FOR THE SERIAL MONITOR.
MAIN_LOOP:
        CALL RXA_RDY
        JR MAIN_LOOP


;-------------------------------------------------------------------------------
; INITIALIZATION ROUTINES
;-------------------------------------------------------------------------------

; SERIAL_INIT IS A ROUTINE TO INITALIZE THE Z80 DART OR SIO-0 FOR SERIAL
;  TRANSMITTING AND RECEIVING ON BOTH PORT A AND PORT B.  THIS SETS UP
;  BOTH PORTS FOR 57,600 BAUD (WITH 1.8432MHZ CLOCK) WITHOUT HANDSHANKING,
;  AND NO INTERRUPTS. THEN RETURNS.  DESTROYS REGISTERS: A.
SERIAL_INIT:                    ;WORKING MODEL OF SERIAL INITIALIZATION
                                ;SETTING UP FOR 57600 BAUD
        ;SETUP PORT A
        LD A,00H                ;REQUEST REGISTER #0
        OUT (SIOA_C),A
        LD A,18H                ;LOAD #0 WITH 18H - CHANNEL RESET
	OUT (SIOA_C),A
        NOP

	LD A,04H                ;REQUEST TRANSFER TO REGISTER #4
	OUT (SIOA_C),A
        LD A,084H               ;WRITE #4 WITH X/32 CLOCK 1X STOP BIT
        OUT (SIOA_C),A          ;  AND NO PARITY

        LD A,03H                ;REQUEST TRANSFER TO REGISTER #3
        OUT (SIOA_C),A
        LD A,0C1H
        OUT (SIOA_C),A          ;WRITE #3 WITH COH - RECEIVER 8 BITS & RX ENABLE

        LD A,05H                ;REQUEST TRANSFER TO REGISTER #5
        OUT (SIOA_C),A
        LD A,068H
        OUT (SIOA_C),A          ;WRITE #5 WITH 60H - TRANSMIT 8 BITS & TX ENABLE

        ;SETUP PORT B
        LD A,00H                ;REQUEST REGISTER #0
        OUT (SIOB_C),A
        LD A,18H                ;LOAD #0 WITH 18H - CHANNEL RESET
	OUT (SIOB_C),A
        NOP

	LD A,04H                ;REQUEST TRANSFER TO REGISTER #4
	OUT (SIOB_C),A
        LD A,084H               ;WRITE #4 WITH X/32 CLOCK 1X STOP BIT
        OUT (SIOB_C),A          ;  AND NO PARITY

        LD A,03H                ;REQUEST TRANSFER TO REGISTER #3
        OUT (SIOB_C),A
        LD A,0C1H
        OUT (SIOB_C),A          ;WRITE #3 WITH COH - RECEIVER 8 BITS & RX ENABLE

        LD A,05H                ;REQUEST TRANSFER TO REGISTER #5
        OUT (SIOB_C),A
        LD A,068H
        OUT (SIOB_C),A          ;WRITE #5 WITH 60H - TRANSMIT 8 BITS & TX ENABLE

        RET
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
; MESSAGES
;-------------------------------------------------------------------------------
CS_MSG:
        DB      ESC,"[2J",ESC,"[H",00H
SIGNON_MSG:
        DB      LF
        DB      "G80-S Computer by Doug Gabbard - 2017",CR,LF
        DB      "G-DOS Prototype v0.25b",CR,LF,LF
        DB      "Type 'HELP' for command list.",CR,LF,LF,00H

MEMORY_CLR_MSG:
        DB      "CLEARING MEMORY...",00H

STORAGE_CHK_MSG:
        DB      "CHECKING FOR STORAGE...",00H

STORE_NO_FOUND_MSG:
        DB      "STORAGE NOT FOUND.",CR,LF,00H

STORAGE_FOUND_MSG:
        DB      "STORAGE FOUND.",CR,LF,00H

CMD_NOT_IMPLE_MSG:
        DB      " ERROR - COMMAND NOT IMPLEMENTED",CR,LF,00H

CMD_ERROR_MSG:
        DB      CR,LF,"  ERROR - NOT RECOGNIZED ",CR,LF,LF,00H

OVERFLOW_ERROR_MSG:
        DB      CR,LF,"  ERROR - BUFFER OVERFLOW ",CR,LF,00H

LOADING_MSG:
        DB      CR,LF
        DB      " LOADING...",00H

DONE_MSG:
        DB      "DONE.",CR,LF,00H

TEST_MSG:
        DB      CR,LF," COMMAND RECOGNITION TEST WORKED!",CR,LF,00H
DUMP_HEADER_MSG:
        DB      "  ________________________________________________________________________ ",CR,LF
        DB      " |                                DUMPER                                  |",CR,LF
        DB      " |------------------------------------------------------------------------|",CR,LF
        DB      " |       0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F"
        DB      "         ASCII     |",CR,LF
        DB      " |------------------------------------------------------------------------|",CR,LF,00H
DUMP_FOOTER_MSG:
        DB      CR,LF," |________________________________________________________________________|",00H
MODMEM_MSG:
        DB      CR,LF,"  'X' TO EXIT",CR,LF,00H
IN_MSG:
        DB      CR,LF," PORT=",00H
HELP_MSG:
        DB      CR,LF," G80-S COMMANDS:",CR,LF,LF
        DB      TAB,"CALL XXXX - RUN CODE AT LOCATION XXXX",CR,LF
        DB      TAB,"CLS - CLEAR THE TERMINAL SCREEN",CR,LF
        DB      TAB,"DUMP XXXX - DUMP 256 BYTES OF MEMORY",CR,LF
        DB      TAB,"HELP - THIS SCREEN",CR,LF
        DB      TAB,"HEXLOAD - LOAD INTEL HEX FILES OVER SERIAL",CR,LF
        DB      TAB,"IN XX - READ INPUT FROM PORT XX",CR,LF
        DB      TAB,"MODMEM XXXX - MODIFY MEMORY STARTING AT XXXX",CR,LF
        DB      TAB,"OUT XX HH - WRITE HH TO PORT XX",CR,LF
        DB      TAB,"RAMCLR - CLEAR USER AREA OF MEMORY",CR,LF
        DB      TAB,"RESTART - SOFT RESTART",CR,LF,00H
HELP_PORTS_MSG:
        DB      TAB,"PIO (80-83H)",CR,LF,00H

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
; SYSTEM CALLS & SUBROUTINES
;-------------------------------------------------------------------------------

; RAMCLR IS A FUNCTION THAT CLEARS THE RAM FROM BOTTOM TO TOP.
;  IT LOADS THE ADDRESS INTO B&C AND LOADS THE ADDRESS WITH
;  00h UNTIL THE ADDRESS REACHES FAF9h (LEAVING THE STACK INTACT), THEN CLEARS
;  THE MEMORY ABOVE THE STACK, THEN RETURNS.
;  IT DESTROYS: A,B & C REGISTERS
RAM_CLR:
        LD HL,MEMORY_CLR_MSG
        CALL PRINT_STRING
        LD  BC,ROM_TOP
RAM_CLRL:
	INC BC
	LD A, 00H
    	LD (BC),A
        LD A,0FAH
	SUB B
	JR NZ,RAM_CLRL
	LD A, 0F9H
    	SUB C
    	JR NZ ,RAM_CLRL
        LD HL,DONE_MSG
        CALL PRINT_STRING
        CALL PRINT_PROMPT
        RET


; DELAY IS A FUNCTION THAT BURNS 1,499,992 CLOCK CYCLES.
;  AT 6MHZ [(57,692 LOOPS X 26 CLOCKS CYCLES) / 6,000,000] = 0.249998 SECONDS
;  THIS IS A GENERAL PURPOSE DELAY TIMER THAT CAN BE USED TO DEBOUNCE INPUTS,
;  OR ANY OTHER APPLICATION WHERE A DELAY IS NEEDED.
DELAY:
        PUSH AF
        PUSH BC
        LD  BC,0E15CH           ; 57,692 LOOPS
DELAYL:
	DEC BC
	LD  A,C
	OR  B
	JR  NZ,DELAYL
        POP BC
        POP AF
	RET


; HALF_DELAY IS A FUNCTION THAT IS FUNCTIONALLY IDENTICAL TO DELAY.
;  IT IS DESIGNED TO BURN 749,996 CLOCK CYCLES.
;  AT 6MHZ [(28,846 LOOPS X 26 CLOCK CYCLES) / 6,000,000] = 0.124999 SECONDS
HALF_DLY:
        PUSH AF
        PUSH BC
        LD  BC,070AEH           ; 28,846 LOOPS
HALF_DLYL:
	DEC BC
	LD  A,C
	OR  B
	JR  NZ,HALF_DLYL
        POP BC
        POP AF
	RET


; BUF_CLR IS A FUNCTION THAT CLEARS THE BUFFER FROM BOTTOM TO TOP.
;  IT LOADS THE ADDRESS INTO B&C AND LOADS THE ADDRESS WITH
;  00h UNTIL THE ADDRESS REACHES FFFFh, THEN RETURNS.
BUF_CLR:
        PUSH AF                 ;SAVE THE REGISTERS
        PUSH BC
        LD  BC,BUF_POINTER      ;LOAD UP THE POINTER ADDRESS
BUF_CLRL:
	INC BC                  ;INCREMENT THE COUNTER
	LD A, 00H               ;LOAD BYTE TO FILL WITH, AND WRITE
    	LD (BC),A
        LD A,0FFH               ;NOW CHECK IF END OF BUFFER
	SUB C
	JR NZ,BUF_CLRL          ;IF NOT DO AGAIN
        LD BC,BUF_POINTER       ;IF YES RELOAD THE POINTER ADDRESS
        LD A,01H
        LD (BC),A               ;WRITE THE POINTER.
        POP BC
        POP AF
	RET

; BUF_WRITE IS THE ROUTINE FOR WRITING TO THE KEYBOARD BUFFER FROM REGISTER A.
;  IT EXPECTS THE CHARACTER TO BE IN REGISTER A, AND ALSO CHECKS TO MAKE SURE
;  THAT THE BUFFER IS NOT GOING TO OVERFLOW.
BUF_WRITE:
        PUSH AF                 ;SAVE THE REGISTERS
        PUSH HL
        PUSH BC

        LD B,A                  ;SAVE THE CHARACTER
        LD C,CR
        SUB C                   ;CHECK IF CARRIAGE RETURN
        JP Z,BUF_RESTORE


        LD A,B                  ;RESTORE THE BYTE
        LD C,LF
        SUB C                   ;NOW CHECK IF LINE FEED
        JP Z,BUF_RESTORE

        LD A,B
        LD C,BKSP
        SUB C
        JP Z,BUF_BACKSPACE

        LD A,B                  ;RESTORE THE BYTE
        OUT (SIOA_D),A          ;ECHO THE CHARACTER BACK TO TERMINAL

        CALL BUF_LOWERCASE_UPPER ;CALL ROUTINE TO CONVERT THE BYTE TO UPPERCASE

        LD HL,BUF_POINTER       ;LOAD UP THE POINTER
        LD BC,0000H             ;ZERO THE REGISTER, SO THAT THERE IS NO ERROR
        LD C,(HL)
        ADD HL,BC               ;DETERMINE BUFFER LOCATION, STORES IN HL
BUF_WR_CHK:
        LD B,A                  ;SAVE THE BYTE TO BE WRITTEN
        LD A,0FFH               ;LOAD TOP OF BUFFER.
        LD C,L                  ;COMPARE
        SUB C
        JP Z,OVERFLOW           ;IF OVERFLOW, GO TO OVERFLOW ROUTINE
BUF_WR:
        LD A,B                  ;RESTORE THE BYTE
        LD (HL),A               ;WRITE THE BYTE TO THE BUFFER
        LD HL,BUF_POINTER
        LD A,(HL)               ;LOAD THE POINTER
        INC A                   ;INC THE POINTER
        LD (HL),A               ;STORE THE POINTER
        POP BC
        POP HL                  ;RESTORE THE REGISTERS
        POP AF
        RET

BUF_RESTORE:
        LD A,B
        OUT (SIOA_D),A          ;ECHO THE CHARACTER

        LD HL,BUF_POINTER       ;LOAD UP THE POINTER
        LD BC,0000H             ;ZERO THE REGISTER, SO THAT THERE IS NO ERROR
        LD C,(HL)
        ADD HL,BC               ;DETERMINE BUFFER LOCATION, STORES IN HL
        LD A,SPACE
        LD (HL),A               ;WRITE A SPACE SO THAT CMD RECOG CAN DETERMINE

        POP BC                  ;RESTORE THE REGISTERS
        POP HL
        POP AF
        RET                     ;RETURN

BUF_BACKSPACE:
        LD HL,BUF_POINTER       ;FIRST, TEST IF THERE IS SOMETHING TO DELETE
        LD A,(HL)
        LD C,01H
        SUB C
        JP Z,BUF_BACKSPACE_RET  ;RETURN IF SO.
        CALL TXA_RDY
        LD A,B
        OUT (SIOA_D),A          ;SEND THE BACKSPACE TO THE TERMINAL
        CALL TXA_RDY
        LD A,SPACE
        OUT (SIOA_D),A
        CALL TXA_RDY
        LD A,B
        OUT (SIOA_D),A
        LD A,00H
        LD BC,0000H             ;ZERO THE REGISTER, SO THAT THERE IS NO ERROR
        LD C,(HL)
        ADD HL,BC
        LD (HL),A               ;CLEAR THE ITEM FROM THE BUFFER
        LD HL,BUF_POINTER
        LD A,(HL)               ;NOW ADJUST THE POINTER
        DEC A
        LD (HL),A
BUF_BACKSPACE_RET:
        POP BC
        POP HL                  ;RESTORE REGISTERS AND RETURN
        POP AF
        RET

BUF_LOWERCASE_UPPER:            ;CONVERT TO UPPERCASE, OR RETURN IF UPPER
        LD C,061H
        SUB C
        JP M,BUF_UPPER_RETURN   ;RETURN IF UPPER
        LD A,B
        LD C,020H
        SUB C
        RET
BUF_UPPER_RETURN:
        LD A,B                  ;RESTORE THE CHARACTER THEN RETURN
        RET

; OVERFLOW IS THE ROUTINE TO ACKNOWLEDGE THAT THE BUFFER HAS OVERFLOWED, INFORM
;  THE USER OF THE OVERFLOW, CLEAR THE BUFFER, RESETS THE POINTER, RESET THE
;  STACK, AND RETURN TO THE MAIN PROGRAM LOOP. THE SYSTEM ESSENTIALLY RESETS TO
;  THE PROMPT.
OVERFLOW:
        LD HL,OVERFLOW_ERROR_MSG
        CALL PRINT_STRING
        CALL BUF_CLR
        LD SP,STACK
        CALL PRINT_PROMPT
        JP MAIN_LOOP
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
; SERIAL SUBROUTINES
;-------------------------------------------------------------------------------



; PRINT_CHAR IS A ROUTINE THAT PRINTS A CHARACTER TO SERIAL PORT A.
;  IT CALLS TXA_RDY TO SEE IF THE SERIAL PORT IS READY TO TRANSMIT, THEN
;  SENDS WHATEVER CHARACTER IS IN REGISTER A.
PRINT_CHAR:
        PUSH AF
        PUSH BC
        CALL TXA_RDY            ; CHECK IF READY TO SEND
        POP BC
        POP AF
        OUT (SIOA_D),A          ; PRINT IT
        RET

; PRINT_HEX IS A ROUTINE THAT CONVERTS A NUMBER TO THE ASCII REPRESENTATION
;  OF THE NUMBER, AND SENDS THE CHARACTERS TO THE PRINT_CHAR ROUTINE TO BE
;  SENT OVER SERIAL.  IT EXPECTS THE NUMBER TO PRINT TO BE STORED IN A. I HAVE
;  MADE MODIFICATIONS TO THE CODE TO ALLOW IT TO RUN ON THE G80. THIS CODE IS
;  AVAILABLE ON SEVERAL PLACES THROUGHOUT THE WEB, AND I DO NOT KNOW IF THE
;  ORIGINAL AUTHOR'S NAME HAS BEEN LOST TO TIME. THE VERSION I USED IS BELOW.
;  ORIGIN:  WWW.KNOERIG.DE/ELEKTRONIK/Z80/BILDER/MONITOR.ASM
PRINT_HEX:
        PUSH AF
        PUSH BC
        PUSH DE
        LD B,A          ;STORE THE NUMBER
        CALL PRINT_HEX_1
        LD A,B          ;RESTORE THE NUMBER
        CALL PRINT_HEX_3
        POP DE
        POP BC
        POP AF
        RET
PRINT_HEX_1:
        RRA
        RRA
        RRA
        RRA
PRINT_HEX_2:
        OR 0F0H
        DAA
        ADD A,0A0H
        ADC A,040H
        CALL PRINT_CHAR
        ;INC DE         ;I DO NOT THINK THIS IS NEEDED, IF NOT, PRINT_HEX_3
        RET             ;IS NOT NEEDED EITHER.
PRINT_HEX_3:
        OR 0F0H
        DAA
        ADD A,0A0H
        ADC A,040H
        CALL PRINT_CHAR
        RET

; PRINT_STRING IS A ROUTINE THAT PRINTS A STRING TO SERIAL PORT A.
;  IT CALLS TXA_RDY TO SEE IF THE SERIAL PORT IS READY TO TRANSMIT, LOADS
;  A CHARACTER FROM THE MEMORY ADDRESS POINTED TO BY HL, CHECKS IF IT IS 00H,
;  RETURNS IF IT IS 00H, IF NOT IT SENDS THE CHARACTER, INCREMENTS HL,
;  THEN JUMPS BACK TO THE BEGINNING.
PRINT_STRING:
        PUSH AF
        PUSH BC
        CALL TXA_RDY            ;CHECK IF READY TO SEND
        POP BC
        POP AF
        LD A,(HL)               ;GET CHARACTER
        OR A
        RET Z                   ;RETURN IF ZERO
        OUT (SIOA_D),A          ;SEND CHARACTER
        INC HL
        JR PRINT_STRING         ;LOOP FOR NEXT BYTE



; TXA_RDY IS A ROUTINE THAT CHECKS THE STATUS OF THE SERIAL PORT A TO SEE IF
;  THE PORT IS DONE TRANSMITTING THE PREVIOUS BYTE.  IT READS THE STATUS BYTE
;  OF PORT A, ROTATES RIGHT TWICE, THEN ANDS WITH 01h AND SUBS 01h TO DETERMINE
;  IF THE TRANSMIT BUSY FLAG IS SET.  IF NOT IT RETURNS, IF IT IS SET IT
;  CONTINUES TO CHECK BY LOOPING.
;----------------
; DESTROYS A & C.
TXA_RDY:
        LD A,00H
        OUT (SIOA_C),A          ;SELECT REGISTER 0
        IN A,(SIOA_C)           ;READ REGISTER 0
        RRC A
        RRC A
        LD C,01H                ;ROTATE, AND, THEN SUB
        AND C
        SUB C
        RET Z                   ;RETURN IF AVAILABLE
        JR TXA_RDY



; RXA_RDY IS A ROUTINE THAT CHECKS THE STATUS OF THE SERIAL PORT A TO SEE IF
;  THE PORT HAS RECEIVED A BYTE.  IT READS THE STATUS BYTE OF PORT A,
;  ANDS WITH 01h AND SUBS 01h TO DETERMINE IF THE RECEIVER FLAG IS SET.
;  IF NOT IT RETURNS. IF IT IS SET, IT JUMPS TO GET_KEY.
;  DESTROYS REGISTERS: A & C.
RXA_RDY:
        LD A,00H                ;SETUP THE STATUS REGISTER
        OUT (SIOA_C),A
        IN A,(SIOA_C)           ;LOAD THE STATUS BYTE
        LD C,01H                ;LOAD BYTE TO COMPARE THE BIT, AND COMPARE
        AND C
        SUB C
        RET NZ                  ;RETURN IF NOT SET
        JP GET_KEY



; GET_KEY SIMPLY GETS THE KEY AND JUMPS TO ECHO_CHAR AT THE MOMENT. IN THE
;  FUTURE IT WILL EITHER POINT TO A ROUTINE TO STORE THE CHARACTER IN THE
;  BUFFER AND TEST FOR A COMMAND, OR POINT TO A ROUTINE THAT DOES THIS.
; DESTROYS: A
GET_KEY:
        IN A,(SIOA_D)
        CALL BUF_WRITE
        LD C,LF                 ;CHECK IF LINE FEED
        SUB C
        RET NZ
        JP IN_CMD_CHK           ;JUMP TO COMMAND RECOGNITION


; ECHO_CHAR TAKES THE BYTE RECEIVED THROUGH SERIAL, LOCATED IN REGISTER A,
;  AND ECHOS IT BACK TO THE SENDER, SO THAT THE CHARACTER MAY BE DISPLAYED
;  ON THE SCREEN. IF LF, CONTINUES ON TO PRINT_PROMPT.
;  DESTROYS A & C.
;
;  CURRENTLY RETURNS WITHOUT STORING THE BYTE.
ECHO_CHAR:
        OUT (SIOA_D),A          ;GET THE BYTE
        LD C,LF                 ;CHECK IF LF
        SUB C
        RET NZ                  ;RETURN IF NOT
        JP PRINT_PROMPT



; PRINT_PROMPT DOES EXACTLY WHAT IT SAYS, IT PRINTS A PROMPT TO SERIAL
;  PORT A, THEN RETURNS.
;  DESTROYS A.
PRINT_PROMPT:
        LD A,CR
        CALL PRINT_CHAR
        LD A,LF
        CALL PRINT_CHAR
        LD A,'>'               ;PRINT A ">"
        CALL PRINT_CHAR
        CALL BUF_CLR
        RET
;-------------------------------------------------------------------------------
; ASCIIHEX_TO_BYTE IS A ROUTINE THAT CONVERTS TWO ASCII BYTES REPRESENTING A HEX
;  NUMBER IN DE TO THE BINARY NUMBER TO BE RETURNED IN THE ACCUMULATOR.
;  THE D REGISTER SHOULD BE THE MOST SIGNIFICANT NIBBLE, AND THE E REGISTER
;  SHOULD BE THE LEAST SIGNIFICANT NIBBLE.  THIS CODE IS A MODIFIED VERSION
;  OF SOME CODE I FOUND FLOATING AROUND ON THE INTERNET.  I DO NOT KNOW THE
;  SOURCE OF THE ORIGINAL CODE.

ASCIIHEX_TO_BYTE:
        PUSH BC                 ;SAVE REGISTERS
        LD A,D                  ;LOAD UPPER CHARACTER
        CALL CONVERT_HEX_VAL    ;CONVERT THE CHARACTER
        RLA
        RLA
        RLA
        RLA
        LD B,A                  ;STORE THE FIRST NIBBLE
        LD A,E                  ;GET SECOND CHARACTER
        CALL CONVERT_HEX_VAL    ;CONVERT THE CHARACTER
        ADD A,B                 ;ADD THE TWO NIBBLES
        POP BC
        RET

; CONVERTS THE ASCII CHARACTER IN A TO IT'S HEX VALUE IN A, ERROR RETURNS 0FFH
CONVERT_HEX_VAL:
        CP 'G'                  ;GREATER THAN "F"
        JP P,CONVERT_HEX_ERROR    ;IF SO, ERROR.
        CP '0'                  ;LESS THAN "ZERO"
        JP M,CONVERT_HEX_ERROR    ;IF SO, ERROR.
        CP 03AH                 ;LESS THAN OR EQUAL TO "9"
        JP M,CONVERT_MASK         ;IF SO, CONVERT AND RETURN.
        CP 'A'                  ;LESS THAN "A"
        JP M,CONVERT_HEX_ERROR    ;IF SO, ERROR.
        SUB 037H                ;MUST BE "A" TO "F", CONVERT.
        RET
CONVERT_MASK:
        AND 0FH
        RET
CONVERT_HEX_ERROR:
        LD A,0FFH               ;IF ERROR, RETURN 0FFH
        RET
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;COMMAND RECOGNITION
;-------------------------------------------------------------------------------
IN_CMD_CHK:
        LD HL,BUF_BOT-1         ;BOTTOM OF BUFFER-1
        LD DE,CMD_TABLE-1
IN_CMD_CHKL:
        INC HL
        INC DE

        LD A,(HL)               ;GET THE CHAR FROM BUFFER
        EX DE,HL                ;EXCHANGE THE REGISTERS
        LD B,A                  ;STORE THE VALUE
        LD A,(HL)               ;GET THE CHAR FROM THE TABLE
        EX DE,HL                ;RE-EXCHANGE THE REGISTERS

        LD C,00H                ;CHECK IF END OF WORD
        CP C
        JR Z,IN_CMD_TOKEN       ;IF END OF WORD AND PASS, GET TOKEN

        SUB B
        JR Z,IN_CMD_CHKL        ;IF MATCH, GET NEXT CHAR
        JR IN_CMD_NEXT_WORD     ;IF NOT, TRY NEXT WORD



IN_CMD_TOKEN:                   ;FIND THE TOKEN VALUE

        LD A,(HL)               ;FIRST, MAKE SURE THAT IT'S THE END OF
        LD C,020H               ;WORD IN THE BUFFER, BY CHECKING FOR <SPACE>
        SUB C
        JP NZ,CMD_ERROR         ;IF IT'S NOT, JUMP TO THE ERROR ROUTINE.

        LD HL,BUF_BOT-1         ;LOAD BUFFER ADDRESS AND START VALUE
        LD B,00H
IN_CMD_TOKENL:                  ;HEX - 0023H
        INC HL
        LD A,(HL)               ;GET CHARACTER FROM BUFFER
        LD C,020H               ;CHECK IF SPACE
        CP C
        JR Z,IN_CMD_GO          ;GO TO COMMAND IF SO
        ADD A,B
        LD B,A                  ;ADD AND STORE VALUE
        JR IN_CMD_TOKENL        ;GET NEXT CHARACTER

;----------------
;CMD JUMP ROUTINE
;----------------
IN_CMD_GO:                      ;FIND MATCHING TOKEN AND GO  -  002E
        LD A,B                  ;RESTORE THE TOKEN VALUE

        LD C,TOK_CALL
        CP C
        JP Z,CALL_CMD            ;RUN CALL ROUTINE
        LD C,TOK_CLS
        CP C
        JP Z,CLS                ;CLEAR SCREEN ROUTINE
        LD C,TOK_TEST           ;NOW CHECK WHICH COMMAND AND GOTO
        CP C
        JP Z,TEST               ;TEST ROUTINE
        LD C,TOK_DUMP
        CP C
        JP Z,DUMP               ;MEMORY DUMP ROUTINE
        LD C,TOK_HELP
        CP C
        JP Z,HELP               ;HELP ROUTINE
        LD C,TOK_HEXLOAD
        CP C
        JP Z,HEXLOAD
        LD C,TOK_IN
        CP C
        JP Z,IN_CMD             ;IN ROUTINE
        LD C,TOK_MODMEM
        CP C
        JP Z,MODMEM             ;MEMORY MODIFY ROUTINE
        LD C,TOK_OUT
        CP C
        JP Z,OUT_CMD            ;OUT ROUTINE
        LD C,TOK_RAMCLR
        CP C
        JP Z,RAM_CLR            ;RAMCLR ROUTINE
        LD C,TOK_RESTART
        CP C
        JP Z,RESTART            ;RESTART MONITOR


        CALL BUF_CLR
        CALL PRINT_PROMPT

        RET
        ;JP BOOT                 ;RESET IF CRASH
;----------------


IN_CMD_NEXT_WORD:               ;GRAB NEXT WORD
        INC DE

        ;NEED SOMETHING TO SEE IF TOP OF COMMAND TABLE HERE.
        LD HL,CMD_TABLE_END     ;SHOULD BE TOP OF CMD_TABLE
        LD A,L                  ;THE ADDRESS TO TEST FOR
        CP E                    ;COMPARE THE ADDRESS
        JR Z,CMD_ERROR


        LD A,(DE)               ;INCREMENT AND CHECK UNTIL 00H IS FOUND
        LD C,00H
        SUB C
        JR NZ,IN_CMD_NEXT_WORD  ;TRY AGAIN IF NOT FOUND
        LD HL,BUF_BOT-1         ;RESET BUFFER AND CHECK THAT WORD.
        JP IN_CMD_CHKL

CMD_TABLE:                      ;COMMAND WORD LIST
        DB      "CALL",00H
        DB      "CLS",00H
        DB      "TEST",00H
        DB      "DUMP",00H
        DB      "IN",00H
        DB      "HELP",00H
        DB      "HEXLOAD",00H
        DB      "MODMEM",00H
        DB      "OUT",00H
        DB      "RAMCLR",00H
        DB      "RESTART",00H
 CMD_TABLE_END:
        DB      00H
CMD_ERROR:
        LD HL,CMD_ERROR_MSG
        CALL PRINT_STRING
        CALL PRINT_PROMPT
        RET



;COMMAND TOKEN VALUES
TOK_CALL        EQU     01CH
TOK_CLS         EQU     0E2H
TOK_TEST        EQU     040H
TOK_DUMP        EQU     036H
TOK_IN          EQU     097H
TOK_HELP        EQU     029H
TOK_HEXLOAD     EQU     05H
TOK_MODMEM      EQU     0BFH
TOK_OUT         EQU     0F8H
TOK_RAMCLR      EQU     0C1H
TOK_RESTART     EQU     025H
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
;COMMANDS
;-------------------------------------------------------------------------------
; TEST IS A TEST ROUTINE TO SEE IF THE COMMAND RECOGINITION ROUTINES WORK.
;  IT SHOULD JUST PRINT SOME VERY BASIC STUFF TO THE SCREEN.
TEST:
        LD HL,TEST_MSG
        CALL PRINT_STRING
        CALL PRINT_PROMPT
        RET

CALL_CMD:

        LD A,(BUF_BOT+5)        ;GET THE BYTES, CONVERT TO BINARY ADDRESS
        LD D,A
        LD A,(BUF_BOT+6)
        LD E,A
        CALL ASCIIHEX_TO_BYTE
        LD H,A                  ;PLACE UPPER BYTE IN H
        LD A,(BUF_BOT+7)
        LD D,A
        LD A,(BUF_BOT+8)        ;FOR NICE ROUND-NUMBER DUMP.
        LD E,A
        CALL ASCIIHEX_TO_BYTE
        LD L,A                  ;PLACE LOWER BYTE IN L
        JP (HL)

CLS:
        LD HL,CS_MSG
        CALL PRINT_STRING
        CALL PRINT_PROMPT
        RET

;DUMP COMMAND
;-------------------------
DUMP:
        LD HL,CS_MSG
        CALL PRINT_STRING
        LD HL,DUMP_HEADER_MSG
        CALL PRINT_STRING
        LD A,(BUF_BOT+5)          ;GET THE BYTES, CONVERT TO BINARY ADDRESS
        LD D,A
        LD A,(BUF_BOT+6)
        LD E,A
        CALL ASCIIHEX_TO_BYTE
        LD H,A                  ;PLACE UPPER BYTE IN H
        LD A,(BUF_BOT+7)
        LD D,A
        LD A,030H                ;FOR NICE ROUND-NUMBER DUMP.
        LD E,A
        CALL ASCIIHEX_TO_BYTE
        LD L,A                  ;PLACE LOWER BYTE IN L
        LD B,0FH                ;LOAD ROW COUNTER BYTE
        LD C,010H                ;LOAD COLUMN COUNTER BYTE
        LD A, SPACE
        CALL PRINT_CHAR
        LD A,'|'
        CALL PRINT_CHAR
        CALL DUMP_ADDR
        LD A,SPACE
        CALL PRINT_CHAR
        CALL PRINT_CHAR
DUMP2:
        LD A,C
        CP 00H
        JR Z,DUMP4
        LD C,A
DUMP3:
        LD A,(HL)
        CALL PRINT_HEX
        INC HL
        LD A,C
        DEC A
        LD C,A
        LD A,SPACE
        CALL PRINT_CHAR
        JR DUMP2
DUMP4:
        CALL DUMP_ASCII
        LD A,B
        CP 00H
        JR Z,DUMP_EXIT
        DEC A
        LD B,A
        LD C,010H
        LD A,CR
        CALL PRINT_CHAR
        LD A,LF
        CALL PRINT_CHAR
        LD A,SPACE
        CALL PRINT_CHAR
        LD A,'|'
        CALL PRINT_CHAR
        CALL DUMP_ADDR
        LD A,SPACE
        CALL PRINT_CHAR
        CALL PRINT_CHAR
        JR DUMP2
DUMP_ASCII:
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        LD A,SPACE
        CALL PRINT_CHAR
        CALL PRINT_CHAR
        LD DE,0010H
        SBC HL,DE
        LD B,010H
DUMP_ASCII2:
        LD A,B
        CP 00H
        JR Z,DUMP_ASCII3
        DEC A
        LD B,A
        LD A,(HL)
        CALL DUMP_ASCII_CONVERT
        CALL PRINT_CHAR
        INC HL
        JR DUMP_ASCII2
DUMP_ASCII3:
        LD A,'|'
        CALL PRINT_CHAR
        POP HL
        POP DE
        POP BC
        POP AF
        RET
DUMP_ASCII_CONVERT:
        CP 07FH
        JP P,DUMP_ASCII_CONVERT2
        CP 0FFH
        JR Z,DUMP_ASCII_CONVERT2
        AND 07FH
        CP 020H
        JP M,DUMP_ASCII_CONVERT2
        JR DUMP_ASCII_CONVERT3
DUMP_ASCII_CONVERT2:
        LD A,'.'
DUMP_ASCII_CONVERT3:
        RET
DUMP_ADDR:
        LD A,H
        CALL PRINT_HEX
        LD A,L
        CALL PRINT_HEX
        RET
;DUMP_ADDR_MODMEM:
;        LD A,H
;        CALL PRINT_HEX
;        LD A,L
;        CALL PRINT_HEX
;        LD A, " "
;        CALL PRINT_CHAR
;        LD A,(HL)
;        CALL PRINT_HEX
;        RET
DUMP_EXIT:
        LD HL,DUMP_FOOTER_MSG
        CALL PRINT_STRING
        CALL BUF_CLR
        LD A,CR
        CALL PRINT_CHAR
        LD A,LF
        CALL PRINT_CHAR
        CALL PRINT_PROMPT
        RET
DUMP_NEXT_BUF:
        INC HL
        LD A,(HL)
        CALL PRINT_CHAR
        RET
;--------------------------

HELP:
        LD HL,HELP_MSG
        CALL PRINT_STRING
        CALL PRINT_PROMPT
        RET

IN_CMD:
        LD HL,IN_MSG
        CALL PRINT_STRING
        LD A,(BUF_BOT+3)          ;GET THE BYTES, CONVERT TO BINARY ADDRESS
        LD D,A
        LD A,(BUF_BOT+4)
        LD E,A
        CALL ASCIIHEX_TO_BYTE
        LD C,A
        IN A,(C)
        CALL PRINT_HEX
        LD A,'h'
        CALL PRINT_CHAR
        CALL BUF_CLR
        CALL PRINT_PROMPT
        RET

MODMEM:
        LD HL,MODMEM_MSG
        CALL PRINT_STRING
        LD A,(BUF_BOT+7)          ;GET THE BYTES, CONVERT TO BINARY ADDRESS
        LD D,A
        LD A,(BUF_BOT+8)
        LD E,A
        CALL ASCIIHEX_TO_BYTE
        LD H,A                  ;PLACE UPPER BYTE IN H
        LD A,(BUF_BOT+9)
        LD D,A
        LD A,(BUF_BOT+10)        ;FOR NICE ROUND-NUMBER DUMP.
        LD E,A
        CALL ASCIIHEX_TO_BYTE
        LD L,A                  ;PLACE LOWER BYTE IN L
        CALL MODMEM_DUMP_ADDR
        LD A,'>'
        CALL PRINT_CHAR
MODMEM2:
        CALL MODMEM_GET
        CP 'X'
        JR Z,MODMEM_EXIT
        CP 'x'
        JR Z,MODMEM_EXIT
        LD D,A
        CALL MODMEM_GET
        CP 'X'
        JR Z,MODMEM_EXIT
        CP 'x'
        JR Z,MODMEM_EXIT
        LD E,A
MODMEM3:
        CALL ASCIIHEX_TO_BYTE
        LD (HL),A
        INC HL
        LD A,CR
        CALL PRINT_CHAR
        LD A,LF
        CALL PRINT_CHAR
        CALL MODMEM_DUMP_ADDR
        LD A,'>'
        CALL PRINT_CHAR
        JR MODMEM2
MODMEM_GET:
        LD A,00H                ;SETUP THE STATUS REGISTER
        OUT (SIOA_C),A
        IN A,(SIOA_C)           ;LOAD THE STATUS BYTE
        LD C,01H                ;LOAD BYTE TO COMPARE THE BIT, AND COMPARE
        AND C
        SUB C
        JR NZ,MODMEM_GET
        IN A,(SIOA_D)
        CALL PRINT_CHAR         ;ECHO
        RET
MODMEM_DUMP_ADDR:
        LD A,H
        CALL PRINT_HEX
        LD A,L
        CALL PRINT_HEX
        LD A, " "
        CALL PRINT_CHAR
        LD A,(HL)
        CALL PRINT_HEX
        RET
MODMEM_EXIT:
        CALL BUF_CLR
        CALL PRINT_PROMPT
        RET

OUT_CMD:
        LD A,(BUF_BOT+4)
        LD D,A
        LD A,(BUF_BOT+5)
        LD E,A
        CALL ASCIIHEX_TO_BYTE
        LD C,A
        LD A,(BUF_BOT+7)
        LD D,A
        LD A,(BUF_BOT+8)
        LD E,A
        CALL ASCIIHEX_TO_BYTE
        OUT (C),A
        CALL BUF_CLR
        CALL PRINT_PROMPT
        RET

RESTART:
        JP BOOT

HEXLOAD:
        CALL IH_LOAD
        CALL PRINT_PROMPT
        RET
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
;///////////////////////////////////////////////////////////////////////////////
;-------------------------------------------------------------------------------
; THIS IS A ROUTINE FOR LOADING AN INTEL HEX FILE INTO MEMORY FROM SERIAL.
;   THE SOURCE FROM THIS WAS TAKEN FROM: http://www.vaxman.de/projects/tiny_z80/
;
; According to Bernd Ulmann, the author of the site listed above, he took this
; routine from Andrew Lynch's boot loader program.  While aware of who Andrew
; is, I have not had any conversations with him concerning this program, and
; I have not laid eyes on the code.  Bernd has modified this code to work with
; his own computer, a z80 machine with IDE support. I have further modified it
; to work with my own system, although those modifications were minor.  I did
; include several of Bernd's system calls, as they were different enough in
; nature from my own that it would wreak havoc, and cause me to either rewrite
; essentially the same code, or to modify the flow of the rest of my monitor
; program in order to make it work. However, I also recreated several of his
; calls to better suit my needs, but have credit him by placing them within
; this block of code.  To see the original source, please visit the site listed
; above.
;
;
;   The end of Bernd's and Andrews code will be clearly noted in my source.
;-------------------------------------------------------------------------------
;


IH_LOAD:
        PUSH AF
        PUSH DE
        PUSH HL
        LD HL,IH_LOAD_MSG_1
        CALL PRINT_STRING
IH_LOAD_LOOP:
        CALL GETC                       ;GET A CHARACTER
        CP CR                           ;DONT CARE ABOUT CR
        JR Z,IH_LOAD_LOOP
        CP LF                           ;...OR LF
        JR Z,IH_LOAD_LOOP
        CP SPACE                        ;...OR A SPACE
        JR Z,IH_LOAD_LOOP
        CALL TO_UPPER                   ;CONVERT TO UPPER CASE
        CALL PUTC                       ;ECHO CHARACTER
        CP ':'                          ; IS IT A COLON?
        JR NZ,IH_LOAD_ERROR
        CALL GET_BYTE                   ;GET RECORD LENGTH INTO A
        LD D,A                          ;LENGTH IS NOW IN D
        LD E,00H                        ;CLEAR CHECKSUM
        CALL IH_LOAD_CHK                ;COMPUTE CHECKSUM
        CALL GET_WORD                   ;GET LOAD ADDRESS INTO HL
        LD A,H                          ;UPDATE CHECKSUM BY THIS ADDRESS
        CALL IH_LOAD_CHK
        LD A,L
        CALL IH_LOAD_CHK

        ;THINK I NEED THE ADDRESS ADJUSTER HERE
        PUSH DE
        LD DE,08000H
        ADD HL,DE
        CALL IH_ADDR_TST
        POP DE
        ;END OF ADDRESS ADJUST

        CALL GET_BYTE                   ;GET THE RECORD TYPE
        CALL IH_LOAD_CHK                ;UPDATE CHECKSUM
        CP 01H                          ;HAVE WE READED EOF MARKER?
        JR NZ,IH_LOAD_DATA              ;NO - GET SOME DATA
        CALL GET_BYTE                   ;YES - EOF,READ CHECKSUM DATA
        CALL IH_LOAD_CHK                ;UPDATE OUR OWN CHECKSUM
        LD A,E
        AND A                           ;IS OUR CHECKSUM ZERO?
        JR Z,IH_LOAD_EXIT               ;YES - EXIT THIS ROUTINE

IH_LOAD_CHK_ERR:
        LD HL,IH_LOAD_MSG_3
        CALL PRINT_STRING               ;NO - PRINT AN ERROR MESSAGE
        JR IH_LOAD_EXIT                 ; AND EXIT

IH_LOAD_DATA:
        LD A,D                          ;RECORD LENGTH IS NOW IN A
        AND A                           ;DID WE PROCESS ALL BYTES?
        JR Z,IH_LOAD_EOL                ;YES - PROCESS END OF LINE
        CALL GET_BYTE                   ;READ TWO HEX DIGITS INTO A
        CALL IH_LOAD_CHK                ;UPDATE CHECKSUM
        LD (HL),A                       ;STORE BYTE INTO MEMORY
        INC HL                          ;INCREMENT POINTER
        DEC D                           ;DECREMENT REMAINING RECORD LENGTH
        JR IH_LOAD_DATA                 ;GET NEXT BYTE

IH_LOAD_EOL:
        CALL GET_BYTE                   ;READ THE LAST BYTE IN THE LINE
        CALL IH_LOAD_CHK                ;UPDATE CHECKSUM
        LD A,E
        AND A                           ;IS THE CHECKSUM ZERO?
        JR NZ,IH_LOAD_CHK_ERR
        CALL CRLF
        JR IH_LOAD_LOOP                 ;YES - READ NEXT LINE

IH_LOAD_ERROR:
        LD HL,IH_LOAD_MSG_2
        CALL PRINT_STRING               ;PRINT ERROR MESSAGE

IH_LOAD_EXIT:
        CALL CRLF
        POP HL                          ;RESTORE REGISTERS
        POP DE
        POP AF
        RET                             ;RETURN FROM HEX LOADER

IH_LOAD_CHK:
        LD C,A                          ;ALL IN ALL COMPUTE E=E-A
        LD A,E
        SUB C
        LD E,A
        LD A,C
        RET

IH_LOAD_MSG_1:
        DB "INTEL HEX LOAD: ",00H
IH_LOAD_MSG_2:
        DB " SYNTAX ERROR!",00H
IH_LOAD_MSG_3:
        DB " CHECKSUM ERROR!",00H
IH_LOAD_MSG_CRLF:
        DB CR,LF,00H
IH_LOAD_MSG_OUTSPC:
        DB CR,LF,LF,"OUT OF MEMORY.",CR,LF,00H

;--------------
;PUTC
;SENDS THE CHARACTER CODE IN REG-A TO THE SERIAL LINE
;----------------
; DESTROYS A & C.
;----------------
PUTC:
        PUSH AF
        PUSH BC
PUTC2
        LD A,00H
        OUT (SIOA_C),A          ;SELECT REGISTER 0
        IN A,(SIOA_C)           ;READ REGISTER 0
        RRC A
        RRC A
        LD C,01H                ;ROTATE, AND, THEN SUB
        AND C
        SUB C                   ;TRANMIT READY?
        JR NZ,PUTC2             ;NO - TRY AGAIN
        POP BC                  ;YES - RESTORE
        POP AF
PUTC3:
        OUT (SIOA_D),A          ;SEND CHARACTER CODE
        RET

;----------------
; CRLF
; SENDS A CR/LF TO THE SERIAL LINE
;-----------------
CRLF:
        PUSH HL                 ;SAVE THE POINTER
        LD HL,IH_LOAD_MSG_CRLF  ;LOAD NEW POINTER
        CALL PRINT_STRING       ;PRINT IT
        POP HL                  ;RESTORE OLD POINTER
        RET
;----------------
;TO_UPPER
;CONVERTS ASCII CODE IN REG-A INTO UPPER CASE, RETURNS IN REG-A
;----------------
TO_UPPER:
        CP 61H
        RET C
        CP 7BH
        RET NC
        AND 5FH
        RET
;----------------
;GETC
;READS A CHARACTER CODE FROM SERIAL INTO REG-A
;----------------
GETC:
        PUSH AF
        PUSH BC
GETC2:
        LD A,00H                ;SETUP THE STATUS REGISTER
        OUT (SIOA_C),A
        IN A,(SIOA_C)           ;LOAD THE STATUS BYTE
        LD C,01H                ;LOAD BYTE TO COMPARE THE BIT, AND COMPARE
        AND C
        SUB C
        JR NZ,GETC2
        POP BC
        POP AF
GETC3:
        IN A,(SIOA_D)
        RET

;---------------
; GET_BYTE
; Get a byte in hexadecimal notation. The result is returned in A. Since
; the routine get_nibble is used only valid characters are accepted - the
; input routine only accepts characters 0-9a-f.
;---------------
GET_BYTE:
        PUSH BC                         ;SAVE THE REGISTERS
        CALL GET_NIBBLE                 ;GET UPPER NIBBLE
        RLC A
        RLC A
        RLC A                           ;ROTATE RIGHT
        RLC A
        LD B,A                          ;SAVE UPPER NIBBLE
        CALL GET_NIBBLE                 ;GET LOWER NIBBLE
        OR B                            ;COMBINE
        POP BC                          ;RESTORE OLD REGISTERS
        RET
;----------------
; GET_NIBBLE
; Get a hexadecimal digit from the serial line. This routine blocks until
; a valid character (0-9a-f) has been entered. A valid digit will be echoed
; to the serial line interface. The lower 4 bits of A contain the value of
; that particular digit.
;----------------
GET_NIBBLE:
        CALL GETC                       ;READ A CHARACTER
        CALL TO_UPPER                   ;CONVERT TO UPPER CASE
        CALL IS_HEX                     ;WAS IT A HEX DIGIT
        JR NC,GET_NIBBLE                ;NO, GET ANOTHER CHARACTER
        CALL NIBBLE2VAL                 ;CONVERT NIBBLE TO VALUE
        CALL PRINT_NIBBLE
        RET
;-----------------
; IS_HEX
; is_hex checks a character stored in A for being a valid hexadecimal digit.
; A valid hexadecimal digit is denoted by a set C flag.
;-----------------
IS_HEX:
        CP 47H                          ;GREATER THAN 'F' ?
        RET NC                          ;YES - RETURN
        CP 30H                          ;LESS THAN '0'
        JR NC,IS_HEX_1                  ;NO - CONTINUE
        CCF                             ; COMPLIMENT CARRY - I.E. CLEAR IT
        RET
IS_HEX_1:
        CP 3AH                          ;LESS OR EQUAL TO '9'?
        RET C                           ;YES - RETURN
        CP 41H                          ;LESS THAN 'A'?
        JR NC,IS_HEX_2                  ;NO - CONTINUE
        CCF                             ;YES - CLEAR CARRY AND RETURN
        RET
IS_HEX_2:
        SCF                             ;SET CARRY AND RETURN
        RET
;------------------
; NIBBLE2VAL
; nibble2val expects a hexadecimal digit (upper case!) in A and returns the
; corresponding value in A.
;
NIBBLE2VAL:
        CP 3Ah                          ;IS IT A DIGIT?
        JR C,NIBBLE2VAL1                ;YES
        SUB 7                           ;ADJUST FOR A-F
NIBBLE2VAL1:
        SUB 30H                         ;FOLD BACK TO 0..15
        AND 0FH
        RET

;------------------
; PRINT_NIBBLE
; print_nibble prints a single hex nibble which is contained in the lower
; four bits of A:
;------------------
PRINT_NIBBLE:
        PUSH AF                         ;SAVE REGISTERS
        AND 0FH                         ;JUST IN CASE...
        ADD A,30h                       ;IF DIGIT, WE ARE DONE
        CP 3AH                          ;IS RESULT > 9?
        JR C,PRINT_NIBBLE1
        ADD A,07H                       ;TAKE CARE OF A-F ('A'-'0'-0AH)
PRINT_NIBBLE1:
        CALL PUTC                       ;PRINT THE NIBBLE
        POP AF                          ;POP AF
        RET
;----------------
; GETS
;  Read a string from STDIN - HL contains the buffer start address,
; B contains the buffer length.
;----------------
; NOT SURE IF THIS WILL WORK OR NOT...
GETS:
        PUSH AF
        PUSH BC
        PUSH HL
GETS_LOOP:
        CALL GETC                               ;GET A CHARACTER
        CP CR                                   ;SKIP CR
        JR Z,GETS_LOOP                          ;LF WILL TERMINATE INPUT
        CALL TO_UPPER
        CALL PUTC                               ;ECHO CHARACTER
        CP LF                                   ;TERMINATE STRING AT LF
        JR Z,GETS_EXIT                          ;  OR COPY TO BUFFER
        LD (HL),A
        INC HL
        DJNZ GETS_LOOP
GETS_EXIT:
        LD (HL),00H                             ;INSERT TERMINATION BYTE
        POP HL
        POP BC
        POP AF
        RET
;------------------
; GET_WORD
; Get a word (16 bit) in hexadecimal notation. The result is returned in HL.
; Since the routines get_byte and therefore get_nibble are called, only valid
; characters (0-9a-f) are accepted.
;------------------
; PROBABLY NEED TO ADJUST FOR RAM ADDRESS TO LOAD INTO..
GET_WORD:
        PUSH AF                         ;SAVE THE REGISTERS
        CALL GET_BYTE                   ;GET THE UPPER BYTE
        LD H,A
        CALL GET_BYTE                   ;GET THE LOWER BYTE
        LD L,A
        POP AF                          ;RESTORE THE REGISTERS
        RET

        ;END OF BERND'S AND ANDREW'S CODE - NOTHING ELSE FOLLOWS


IH_OUTSPC:
        LD HL,IH_LOAD_MSG_OUTSPC
        CALL PRINT_STRING
        JP IH_LOAD_EXIT
IH_ADDR_TST:
        PUSH AF
        LD A,0FBH
        SUB H
        JR Z,IH_ADDR_TST2
        POP AF
        RET
IH_ADDR_TST2:
        CALL DELAY                      ;BURN TIME TO LET THE TRANSFER
        CALL DELAY                      ; FINISH
        CALL DELAY
        CALL DELAY
        CALL GETC                       ;GET RID OF CHARACTER STILL IN BUFFER
        CALL GETC
        POP AF                          ;RESTORE REGISTERS
        POP DE
        JR IH_OUTSPC                    ;PRINT MEMORY MSG AND EXIT

;-------------------------------------------------------------------------------
;///////////////////////////////////////////////////////////////////////////////
;-------------------------------------------------------------------------------

