.data  
bombs	DB 25 DUP(0)
qty_bombs DW ?
selected_pos DB ?

.code

#make_BIN#
               
MOV qty_bombs, 5  

JMP main_loop

start_bombs PROC
    MOV CX, qty_bombs
    
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


show_table PROC
	MOV dh, 0
	MOV CL, 0
	l1:
	MOV dl, 0
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h
		l2:
        CMP selected_pos, CL
        JE selected_char 
        JNE normal_char        
		selected_char:
		    mov  al, 'X'
		    JMP char_end
		normal_char:
            mov  al, 'x'
            JMP char_end
        char_end:           		
		;mov  bl, 0Ch  ;Color is red
		;mov  bh, 0    ;Display page
		mov  ah, 0Eh  ;Teletype
		int  10h

		INC dl
		INC CL
		CMP dl, 5
		JL l2   	
	INC dh
	CMP dh, 5	    
	JL l1
	
    RET
show_table ENDP    

update_events PROC
    MOV AH, 00h
    INT 16h             
    CMP AH, 75
    JE ev_left
    CMP AH, 77
    JE ev_right
    CMP AH, 72
    JE ev_top
    CMP AH, 80
    JE ev_bottom
    ev_left:
        DEC selected_pos 
        JMP ev_end
    ev_right:           
        INC selected_pos
        JMP ev_end
    ev_top:
        SUB selected_pos, 5 
        JMP ev_end
    ev_bottom:
        ADD selected_pos, 5 
        JMP ev_end
    ev_end:
    RET
update_events ENDP

main_loop:
    CALL show_table
    CALL update_events
    JMP main_loop