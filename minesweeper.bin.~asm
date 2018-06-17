.data
game	DB 25 DUP(0)

.code

#make_BIN#

JMP show_table

start_matrix:
	MOV dh, 0
	sm_l1:
	MOV dl, 0
		sm_l2:
		MOV [game], dl
		INC dl
		CMP dl, 5
		JL sm_l2
	INC dh
	CMP dh, 5
	JL sm_l1


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