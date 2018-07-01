ORG 100h

.model small
.stack 2048
.data
    MSG_ASK_LEVEL DB 'Utilize as setas para selecionar a dificuldade:', 10, 13, 10, 13
                  DB '      X Facil   (05 bombas)', 10, 13
                  DB '        Dificil (15 bombas)$'

    bombs    DB 25 DUP(0)
    qty_bombs DW ?
    selected_pos DB ?

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
            MOV BH, 0
            MOV CX, 1
            MOV Ah, 0Ah
            INT 10h

            ;save unmark command
            PUSHA
            ;set cursor position at hard option
            MOV DH, 3
            MOV DL, 6
            MOV BH, 0
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
                MOV BH, 0
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
start_bombs ENDP

show_table PROC
    CALL clear_screen

    MOV DH, 0
    MOV CL, 0
    l1:
    MOV DL, 0
    mov BH, 0    ;Display page
    mov AH, 02h  ;SetCursorPosition
    INT 10h
        l2:
        CMP selected_pos, CL
        JE selected_char
        JNE normal_char
        selected_char:
            MOV  AL, 'X'
            JMP char_end
        normal_char:
            MOV  AL, 'x'
            JMP char_end
        char_end:
        ;mov  bl, 0Ch  ;Color is red
        ;mov  bh, 0    ;Display page
        MOV  AH, 0Eh  ;Teletype
        INT  10h

        INC dl
        INC CL
        CMP dl, 5
        JL l2
    INC dh
    CMP dh, 5
    JL l1

    RET
show_table ENDP

update_main_events PROC
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
update_main_events ENDP

main:
    CALL ask_level
    CALL start_bombs
main_loop:
    CALL show_table
    CALL update_main_events
    JMP main_loop