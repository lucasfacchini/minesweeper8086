.data  
bombs	DB 25 DUP(0)
qty_bombs DB ?

.code

#make_BIN#
               
MOV qty_bombs, 15
               
CALL start_bombs
;JMP show_table

start_bombs PROC
    MOV CX, 15
    
    PUSH CX
	MOV AH, 2CH
    INT 21H
    POP CX 
    
    MOV AL, DL    	
	; Eq congruente (ant*2+1) mod 25
	loop_bombs:
    	MOV BX, 2
    	MUL BX
    	ADD AX, 1
    	MOV BX, 25
    	MOV AH, 0
    	DIV BX
    	MOV AL, DL
    	CBW
    	MOV SI, AX
    	MOV [bombs + SI], 1
    LOOP loop_bombs
start_bombs ENDP


show_table:
	MOV dh, 0
	l1:
	MOV dl, 0
		l2:
		mov  bh, 0    ;Display page
		mov  ah, 02h  ;SetCursorPosition
		int  10h
		
		mov  al, 'x'
		mov  bl, 0Ch  ;Color is red
		mov  bh, 0    ;Display page
		mov  ah, 0Eh  ;Teletype
		int  10h

		INC dl
		CMP dl, 5
		JL l2
	INC dh
	CMP dh, 5
	JL l1

HLT 