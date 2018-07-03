ORG 100h

.model small
.stack 2048
.data
    MSG_ASK_LEVEL DB 'Utilize as setas para selecionar a dificuldade:', 10, 13, 10, 13
                  DB '      X Facil   (05 bombas)', 10, 13
                  DB '        Dificil (15 bombas)$'

    bombs    DB 25 DUP(0)
    qty_bombs DW ?
    last_pos DB 0
    current_pos DB 0

.code

JMP main

clear_screen PROC
    MOV AL, 03h
    MOV AH, 0
    INT 10h

    RET
clear_screen ENDP

ask_level_events PROC
    ;qty of bombs selected, firt is easy (5 bombs)
    MOV AX, 5
    ;BX is next value to alter on key pressed
    MOV BX, 15
    PUSHA

    loop_ask_level_event:
        MOV AH, 00h
        INT 16h
        CMP AH, 72
        JE ev_ask_level_top_bottom
        CMP AH, 80
        JE ev_ask_level_top_bottom
        CMP AH, 28
        JE ev_ask_level_enter
        JMP loop_ask_level_event
        ev_ask_level_top_bottom:
            ;set cursor position at easy option
            MOV DH, 2
            MOV DL, 6
            MOV BH, 0
            MOV AH, 2h
            INT 10h

            ;unmark easy option
            MOV AL, ' '
            MOV CX, 1
            MOV Ah, 0Ah
            INT 10h

            ;save unmark command
            PUSHA
            ;set cursor position at hard option
            MOV DH, 3
            MOV DL, 6
            MOV AH, 2h
            INT 10h
            POPA

            ;unmark easy hard option
            INT 10h

            POPA
            ;alter 5 to 15 or 15 to 5
            MOV CX, AX
            MOV AX, BX
            MOV BX, CX
            CMP AX, 5
            PUSHA

            ;mark option selected
            JE mark_easy_level
            MOV DH, 3
            JMP mark_level ;will mark as hard
            mark_easy_level:
                MOV DH, 2
            mark_level:
                MOV DL, 6
                MOV BH, 0
                MOV AH, 2h
                INT 10h

                MOV AL, 'X'
                MOV CX, 1
                MOV Ah, 0Ah
                INT 10h
                JMP loop_ask_level_event
        ev_ask_level_enter:
            POPA

    RET
ask_level_events ENDP

ask_level PROC
    MOV DX, OFFSET MSG_ASK_LEVEL
    MOV AH, 9
    INT 21h

    CALL ask_level_events
    MOV qty_bombs, AX

    RET
ask_level ENDP

start_bombs PROC
    MOV CX, qty_bombs

    PUSH CX
    MOV AH, 2ch
    INT 21h
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
    RET
start_bombs ENDP

show_table PROC
    MOV DH, 0
    MOV CL, 0
    l1:
    MOV DL, 0
    mov BH, 0    ;Display page
    mov AH, 02h  ;SetCursorPosition
    INT 10h
        l2:
        
        MOV  AL, 'x'
        ;mov  bl, 0Ch  ;Color is red
        ;mov  bh, 0    ;Display page
        MOV  AH, 0Eh  ;Teletype
        INT  10h

        INC DL
        INC CL
        CMP DL, 5
        JL l2
    INC DH
    CMP DH, 5
    JL l1

    RET
show_table ENDP

update_main_events PROC
    MOV BL, current_pos
    MOV last_pos, BL
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
    CMP AH, 28
    JE ev_enter
    JMP ev_end
    ev_left:
        DEC current_pos
        CALL update_table
        JMP ev_end
    ev_right:
        INC current_pos 
        CALL update_table
        JMP ev_end
    ev_top:
        SUB current_pos, 5
        CALL update_table
        JMP ev_end
    ev_bottom:
        ADD current_pos, 5
        CALL update_table
        JMP ev_end
    ev_enter:
        CALL open_cell 
    ev_end:
    RET
update_main_events ENDP

update_table PROC
    MOV AH, 0    
    MOV AL, last_pos
    MOV BX, 5
    DIV BL       
    MOV CX, AX  
    
    MOV AH, 0    
    MOV AL, current_pos
    DIV BL 
    
    MOV DH, AL
    MOV DL, AH 
    mov AH, 02h 
    INT 10h ; setar posicao na tela
       
    MOV AL, 'X'
    MOV AH, 0Eh 
    INT  10h ; escrever na tela
        
    MOV DH, CL
    MOV DL, CH     
    MOV AH, 02h 
    INT 10h ; setar posicao na tela
    MOV AL, 'x'
    MOV AH, 0Eh 
    INT  10h ; escrever na tela
    RET
update_table ENDP

open_cell PROC
    RET    
open_cell ENDP

main:
    CALL ask_level
    CALL start_bombs
    CALL clear_screen
    CALL show_table
main_loop:
    CALL update_main_events
    JMP main_loop