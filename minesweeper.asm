ORG 100h

.model small
.stack 2048
.data
    ; mensagens usadas durante o jogo
    MSG_ASK_LEVEL DB 'Utilize as teclas direcionais cima/baixo para selecionar a dificuldade', 10, 13
                  DB 'Pressione enter para confirmar:', 10, 13, 10, 13
                  DB '      X Facil   (05 bombas)', 10, 13
                  DB '        Dificil (15 bombas)$'

    MSG_INFO DB 'As teclas direcionais cima/baixo/esquerda/direita navegam pelo campo', 10, 13
             DB 'Precione ENTER para abrir a posicao selecionada', 10, 13
             DB 'Boa sorte soldado!', 10, 13, 10, 13
             DB 'Carregando, aguarde...$'

    MSG_READY DB 'Pronto para jogar, precione ENTER$'

    START_TABLE DB 'Xxxxx', 10, 13
                DB 'xxxxx', 10, 13
                DB 'xxxxx', 10, 13
                DB 'xxxxx', 10, 13
                DB 'xxxxx$'
                    
    MSG_WINNER DB 'PARABENS!$'

    MSG_LOSER DB 'PERDEU!', 10, 13
              DB 'Infelizmente achamos o mapa quando voce pisou na bomba:$', 10, 13 
    ; caracteres usados na visualizacao do campo
    CELL_CLOSED DB 'x'
    CELL_CLOSED_SELECTED DB 'X'
    CELL_OPENED DB 'o'
    CELL_OPENED_SELECTED DB 'O'
    
    qty_bombs DW ? ; quantidade de bombas a serem geradas (dificuldade)
    
    ; vetores
    bombs DB 25 DUP(0) ; vetor das bombas geradas
    visible_map DB 25 DUP(0) ; vetor do campo, armazena quais posicoes estao abertas ou fechadas
    
    ; variaveis de controle de selecao
    qty_cell_to_open DW 25
    last_pos DB 0 ; posicao anterior selecionada
    current_pos DB 0 ; posicao atual selecionada
    status_game DB 0 ; status do jogo para controle de vitoria ou derrota
                     ; 0 = em andamento | 1 = derrota | 2 = vitoria 

.code

JMP main

; limpa tela
clear_screen PROC
    MOV AL, 03h
    MOV AH, 0
    INT 10h

    RET
clear_screen ENDP

; selecao de dificuldade
ask_level_events PROC
    MOV AX, 5
    MOV BX, 15
    PUSHA

    loop_ask_level_event:
        MOV AH, 00h
        INT 16h
        CMP AH, 72 ; tecla UP
        JE ev_ask_level_top_bottom
        CMP AH, 80 ; tecla DOWN
        JE ev_ask_level_top_bottom
        CMP AH, 28 ; tecla ENTER
        JE ev_ask_level_enter
        JMP loop_ask_level_event
        ev_ask_level_top_bottom:
            ; seta cursor na posicao facil
            MOV DH, 3
            MOV DL, 6
            MOV BH, 0
            MOV AH, 2h
            INT 10h

            ; desmarca posicao facil
            MOV AL, ' '
            MOV CX, 1
            MOV Ah, 0Ah
            INT 10h

            ;save unmark command
            PUSHA
            ; seta cursor na posicao dificil
            MOV DH, 4
            MOV DL, 6
            MOV AH, 2h
            INT 10h
            POPA

            ; desmarca posicao dificil
            INT 10h

            POPA
            ; altera 5 para 15 ou 15 para 5
            MOV CX, AX
            MOV AX, BX
            MOV BX, CX
            CMP AX, 5
            PUSHA

            ; marca posicao selecionada
            JE mark_easy_level
            MOV DH, 4
            JMP mark_level ; marca dificil
            mark_easy_level:
                MOV DH, 3
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

; mostra mensagem para escolha de dificuldade
ask_level PROC
    MOV DX, OFFSET MSG_ASK_LEVEL
    MOV AH, 9
    INT 21h

    CALL ask_level_events
    MOV qty_bombs, AX
    SUB qty_cell_to_open, AX

    RET
ask_level ENDP

; inicializa vetor de bombas, gerando posicoes aleatorias
start_bombs PROC
    MOV CX, qty_bombs
    
    ; obtem relogio para primeiro valor
    PUSH CX
    MOV AH, 2ch
    INT 21h
    POP CX

    MOV AL, DL
    ; calculo da equacao linear congruente (ant*2+1) mod 25
    loop_bombs:
        MOV BX, 2
        MUL BX ; ant * 2
        ADD AX, 1 ; ant * 2 + 1
        MOV BX, 25
        MOV AH, 0
        DIV BX ; mod 25  
        MOV AL, DL
        CBW
        MOV SI, AX
        ; teste se ja foi gerado a mesma posicao
        MOV AH, [bombs + SI]
        CMP AH, 1
        JNE store_bomb
        INC AL ; incrementar caso ja gerado
        JMP loop_bombs ; recalcular novo valor        
        store_bomb:        
        MOV [bombs + SI], 1 ; marca bomba na posicao do vetor de bombas
        
    LOOP loop_bombs
    RET
start_bombs ENDP

; mostra mensagem de pronto para jogar 
info_events PROC
    MOV DH, 4
    MOV DL, 0
    MOV AH, 2h
    INT 10h

    MOV DX, OFFSET MSG_READY
    MOV AH, 9
    INT 21h

    loop_info_event:
        MOV AH, 00h
        INT 16h
        CMP AH, 28
        JNE loop_info_event

    RET
info_events ENDP

; mostra o mapa com as bombas reveladas em caso de vitoria ou derrota
show_map PROC
    MOV DH, 2
    MOV SI, 0
    l1:
        MOV DL, 0
        MOV BH, 0
        MOV AH, 02h
        INT 10h ; seta posicao do cursor na tela
        l2:
            CMP [bombs + SI], 1
            JE bomb_char
                ;Marca celula sem bomba
                MOV AL, 'o'
                JMP char_end
            bomb_char:
                ;Marca celula com bomba
                MOV AL, '1'
            char_end:
                MOV  AH, 0Eh
                INT 10h ; escreve na tela

                INC SI
                INC DL
                CMP DL, 5
                JL l2
                INC DH
                CMP DH, 7
                JL l1

    RET
show_map ENDP

; mostra mensagem de derrota ou vitoria e o mapa
show_results PROC
    CALL clear_screen
    CMP status_game, 2
    JE write_winner

    ; mostra mensagem de derrota
    MOV DX, OFFSET MSG_LOSER
    MOV AH, 9
    INT 21h
    JMP end_show_result
    
    ; mostra mensagem de vitoria
    write_winner:
        MOV DX, OFFSET MSG_WINNER
        MOV AH, 9
        INT 21h

    end_show_result:
    CALL show_map ; mostra o mapa com as bombas reveladas
    MOV DL, 0
    MOV DH, 8
    MOV BH, 0
    MOV AH, 02h
    INT 10h 
    RET
show_results ENDP
              
; mostra instrucoes de jogabilidade              
show_info PROC
    CALL clear_screen
    MOV DX, OFFSET MSG_INFO
    MOV AH, 9
    INT 21h

    RET
show_info ENDP

; mostra o campo com todas posicoes fechadas no inicio do jogo
show_table PROC
    CALL clear_screen
    MOV DX, OFFSET START_TABLE
    MOV AH, 9
    INT 21h

    RET
show_table ENDP

; gerenciamento de eventos usados durante o jogo 
update_main_events PROC
    MOV BL, current_pos
    MOV last_pos, BL
    MOV AH, 00h
    INT 16h ; captura de tecla pressionda
    CMP AH, 75 ; tecla LEFT
    JE ev_left
    CMP AH, 77 ; tecla RIGHT
    JE ev_right
    CMP AH, 72 ; tecla UP
    JE ev_top 
    CMP AH, 80 ; tecla DOWN
    JE ev_bottom
    CMP AH, 28 ; tecla ENTER
    JE ev_enter
    JMP ev_end
    ; eventos de movimentacao de selecao
    ev_left:
        DEC current_pos
        CMP current_pos, -1
        JE reset_current
        CALL update_table
        JMP ev_end
    ev_right:
        INC current_pos
        CMP current_pos, 25
        JE reset_current
        CALL update_table
        JMP ev_end
    ev_top:
        SUB current_pos, 5
        CMP current_pos, -1
        JLE reset_current
        CALL update_table
        JMP ev_end
    ev_bottom:
        ADD current_pos, 5
        CMP current_pos, 25
        JGE reset_current
        CALL update_table
        JMP ev_end
    ; evento para abrir posicao        
    ev_enter:
        CALL open_cell
        JMP ev_end
    reset_current:
        MOV AL, last_pos
        MOV current_pos, AL
    ev_end:

    RET
update_main_events ENDP

; atualiza tabela conforme evento de selecao
update_table PROC
    ; calcula posicao (col, row) na tabela
    MOV AH, 0
    MOV AL, last_pos
    MOV BX, 5
    DIV BL
    MOV CX, AX

    MOV AH, 0
    MOV AL, current_pos
    DIV BL
    
    ; atualizar selecionado (current_pos)
    MOV DH, AL
    MOV DL, AH
    MOV AH, 02h
    INT 10h ; setar posicao na tela             
    MOV AH, 0             
    MOV AL, current_pos
    MOV SI, AX
    CMP [visible_map + SI], 1
    JE update_opened
    MOV AL, CELL_CLOSED_SELECTED
    JMP write_current                    
    update_opened:
        MOV AL, CELL_OPENED_SELECTED    
    write_current:
        MOV AH, 0Eh
        INT 10h ; escrever na tela

    ; atualizar anterior (last_pos)
    MOV DH, CL
    MOV DL, CH
    MOV AH, 02h
    INT 10h ; setar posicao na tela
    
    MOV AH, 0             
    MOV AL, last_pos
    MOV SI, AX
    CMP [visible_map + SI], 1
    JE update_opened_last
    MOV AL, CELL_CLOSED
    JMP write_last                    
    update_opened_last:
        MOV AL, CELL_OPENED
    write_last:
        MOV AH, 0Eh
        INT 10h ; escrever na tela
    RET
update_table ENDP

; abre posicao do campo ao apertar ENTER
open_cell PROC
    ;Verifica se posicao ja foi aberta, SI armazenara o valor do deslocamento para o procedimento
    MOV AH, 0
    MOV AL, current_pos
    MOV SI, AX
    CMP [visible_map + SI], 1 ; verifica se a posicao ja esta aberta
    JE end_open_cell

    ; verifica se posicao tem bomba
    CMP [bombs + SI], 0
    JE open_cell_no_bomb
    ; escreve perdedor, caso seja bomba
    MOV status_game, 1
    JMP end_open_cell
                      
    ; abre posicao sem bomba                      
    open_cell_no_bomb:
        MOV [visible_map + SI], 1 ; marca posicao como aberta
        ; atualiza tela
        MOV BX, 5
        DIV BL
        
        MOV DH, AL
        MOV DL, AH
        MOV AH, 02h
        INT 10h ; setar posicao na tela
    
        MOV AL, 'O'
        MOV AH, 0Eh
        INT 10h ; escrever na tela         

        ; muda status do jogo para 2 (vitoria) caso todas posicoes sem bomba foram abertas
        DEC qty_cell_to_open
        CMP qty_cell_to_open, 0
        JNE end_open_cell
        MOV status_game, 2

    end_open_cell:
    RET
open_cell ENDP

main: ; inicio do jogo
    CALL ask_level ; selecao de dificuldade
    CALL show_info ; mostra instrucoes
    CALL start_bombs ; inicia vetor de bombas
    CALL info_events ; mostra mensagem de pronto para jogar  
    CALL show_table ; mostra campo todo fechado
main_loop: ; loop principal do jogo
    CALL update_main_events ; gerencia eventos de selecao
    ; verifica se jogo ainda esta em andamento 
    CMP status_game, 0
    JNE end_game ; sai do loop, se vitoria ou derrota
    JMP main_loop ; reinicia loop, jogo em andamento 
end_game: ; fim de jogo
    CALL show_results ; mostra vitoria ou derrota e bombas reveladas
    MOV AH, 0 ; finaliza programa
    INT 21h