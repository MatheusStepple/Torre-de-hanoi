; =============================================
; SEÇÃO DE DADOS
; =============================================
section .data
    ; mensagem para entrada do utilizador.
    msg_input db 'Digite o numero de discos: ', 0

    ; caractere de nova linha.
    msg_newline db 10, 0

    ; modelo da mensagem para movimentos de disco: "disc: N Orig -> Dest".
    msg db "disc: "
    disco db " "
    db "   "
    torre_saida db " "
    db " -> "
    torre_ida db " "
    db 0xa
    lenght equ $-msg

; =============================================
; SEÇÃO BSS
; =============================================
section .bss
    ; buffer para armazenar a entrada do utilizador (até 2 dígitos + newline).
    buffer resb 3

; =============================================
; SEÇÃO DE TEXTO
; =============================================
section .text
    ; ponto de entrada do programa.
    global _start

; =============================================
; PROGRAMA PRINCIPAL
; =============================================
_start:
    ; imprime a mensagem de entrada.
    mov edx, 26               ; tamanho da mensagem.
    mov ecx, msg_input        ; endereço da mensagem.
    mov ebx, 1                ; stdout.
    mov eax, 4                ; sys_write.
    int 0x80

    ; lê a entrada do utilizador.
    mov eax, 3                ; sys_read.
    mov ebx, 0                ; stdin.
    mov ecx, buffer           ; buffer de destino.
    mov edx, 3                ; bytes a ler.
    int 0x80

    ; converte entrada ASCII para número.
    xor eax, eax              ; zera EAX (acumulador).
    mov edi, buffer           ; EDI aponta para o buffer.

loop_conversao:
    mov bl, [edi]             ; carrega caractere.
    cmp bl, 10                ; verifica newline.
    je finalizar_conversao
    ; assume-se que a entrada é um dígito válido.
    sub bl, '0'               ; converte ASCII para numérico.
    imul eax, 10              ; multiplica acumulador por 10.
    add eax, ebx              ; adiciona novo dígito.
    inc edi                   ; próximo caractere.
    jmp loop_conversao

finalizar_conversao:
    ; não há validação de intervalo (1 a 99).

    ; configura e chama a função de Hanoi.
    push dword 2              ; torre auxiliar.
    push dword 3              ; torre de destino.
    push dword 1              ; torre de origem.
    push eax                  ; número de discos.
    call torre_de_hanoi

    ; imprime nova linha no final.
    mov edx, 1
    mov ecx, msg_newline
    mov ebx, 1
    mov eax, 4                ; sys_write.
    int 0x80

    ; encerra programa com sucesso.
    mov eax, 1                ; sys_exit.
    mov ebx, 0                ; código de saída 0.
    int 0x80

; =============================================
; FUNÇÃO HANOI (Recursiva)
; =============================================
torre_de_hanoi:
    push ebp                  ; salva EBP.
    mov ebp, esp              ; configura novo EBP.

    mov eax, [ebp+8]          ; carrega num_discos (n).
    cmp eax, 0                ; caso base: se n é 0, retorna.
    je liberar

    ; 1ª chamada recursiva: move n-1 discos da origem para a auxiliar.
    push dword [ebp+16]       ; nova auxiliar (antiga destino).
    push dword [ebp+20]       ; novo destino (antiga auxiliar).
    push dword [ebp+12]       ; nova origem (antiga origem).
    dec eax                   ; n-1 discos.
    push dword eax
    call torre_de_hanoi
    add esp, 16               ; limpa parâmetros da pilha.

    ; imprime o movimento do disco atual.
    push dword [ebp+20]       ; torre destino.
    push dword [ebp+12]       ; torre origem.
    push dword [ebp+8]        ; número do disco.
    call printar
    add esp, 12               ; limpa parâmetros da pilha.

    ; 2ª chamada recursiva: move n-1 discos da auxiliar para o destino.
    push dword [ebp+12]       ; nova auxiliar (antiga origem).
    push dword [ebp+16]       ; novo destino (antiga destino).
    push dword [ebp+20]       ; nova origem (antiga auxiliar).
    mov eax, [ebp+8]          ; recarrega num_discos (n).
    dec eax
    push dword eax
    call torre_de_hanoi

liberar:
    mov esp, ebp              ; restaura ESP.
    pop ebp                   ; restaura EBP.
    ret                       ; retorna da função.

; =============================================
; FUNÇÃO PRINT
; =============================================
printar:
    push ebp                  ; salva EBP.
    mov ebp, esp              ; configura novo EBP.

    ; prepara número do disco (ASCII).
    mov eax, [ebp + 8]
    add al, 48                ; converte para ASCII ('0').
    mov [disco], al

    ; prepara torre de origem (letra A, B, C).
    mov eax, [ebp + 12]
    add al, 64                ; converte para letra ('A'-1).
    mov [torre_saida], al

    ; prepara torre de destino (letra A, B, C).
    mov eax, [ebp + 16]
    add al, 64                ; converte para letra ('A'-1).
    mov [torre_ida], al

    ; imprime a mensagem completa.
    mov edx, lenght
    mov ecx, msg
    mov ebx, 1
    mov eax, 4                ; sys_write.
    int 0x80

    mov esp, ebp              ; restaura ESP.
    pop ebp                   ; restaura EBP.
    ret                       ; retorna da função.
