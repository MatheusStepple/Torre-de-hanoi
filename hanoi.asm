; Matheus Stepple - Sistemas de Informação 2024.2
; Projeto feito em dupla com Matheus Henrique

; o programa está funcionando em
; https://www.tutorialspoint.com/compilers/online-assembly-compiler.htm

; ---
; SEÇÃO DE DADOS (.data)
; ---
section .data
    msg_input db 'Digite o numero de discos: ', 0 ; mensagem para pedir entrada.
    msg_newline db 10, 0                          ; caractere de nova linha.

    msg db "Mova o disco "      ; parte 1 da mensagem de movimento.
    disco db " "                 ; placeholder para o número do disco.
    db " da torre "              ; parte 2 da mensagem.
    torre_saida db " "           ; placeholder para a torre de origem.
    db " para a torre "          ; parte 3 da mensagem.
    torre_ida db " ", 0xa        ; placeholder para a torre de destino, com nova linha.
    lenght equ $-msg             ; calcula o comprimento da mensagem 'msg'.

    msg_concluido db 'Concluido!', 0xa   ; mensagem de conclusão.
    len_concluido equ $-msg_concluido    ; calcula o comprimento da mensagem de conclusão.

; ---
; SEÇÃO BSS (.bss)
; ---
section .bss
    buffer resb 3 ; buffer para entrada do usuário (até 2 dígitos + newline).

; ---
; SEÇÃO DE TEXTO (.text)
; ---
section .text
    global _start ; define o ponto de entrada do programa.

; ---
; PROGRAMA PRINCIPAL (_start)
; ---
_start:
    ; imprime a mensagem de entrada
    mov edx, 26             ; tamanho da mensagem.
    mov ecx, msg_input      ; endereço da mensagem.
    mov ebx, 1              ; saída padrão (stdout).
    mov eax, 4              ; chamada de sistema (sys_write).
    int 0x80                ; executa a chamada.

    ; lê a entrada do usuário
    mov eax, 3              ; chamada de sistema (sys_read).
    mov ebx, 0              ; entrada padrão (stdin).
    mov ecx, buffer         ; buffer para armazenar entrada.
    mov edx, 3              ; número de bytes a ler.
    int 0x80                ; executa a chamada.

    ; converte a entrada ASCII para número
    xor eax, eax            ; zera EAX (acumulador).
    mov edi, buffer         ; edi aponta para o buffer.

loop_conversao:
    mov bl, [edi]           ; carrega caractere.
    cmp bl, 10              ; compara com newline.
    je finalizar_conversao  ; se for newline, finaliza.

    sub bl, '0'             ; converte ASCII para numérico.
    imul eax, 10            ; multiplica acumulador por 10.
    add eax, ebx            ; adiciona novo dígito.
    inc edi                 ; próximo caractere.
    jmp loop_conversao      ; repete o loop.

finalizar_conversao:
    ; o número de discos está em EAX.

    ; configura e chama a função de Hanoi
    push dword 2            ; empilha torre auxiliar (2).
    push dword 3            ; empilha torre de destino (3).
    push dword 1            ; empilha torre de origem (1).
    push eax                ; empilha número de discos.
    call torre_de_hanoi     ; chama a função.

    ; imprime a mensagem de conclusão
    mov edx, len_concluido  ; tamanho da mensagem.
    mov ecx, msg_concluido  ; endereço da mensagem.
    mov ebx, 1              ; saída padrão (stdout).
    mov eax, 4              ; chamada de sistema (sys_write).
    int 0x80                ; executa a chamada.

    ; encerra programa
    mov eax, 1              ; chamada de sistema (sys_exit).
    mov ebx, 0              ; código de saída 0 (sucesso).
    int 0x80                ; executa a chamada.

; ---
; FUNÇÃO HANOI (torre_de_hanoi) - Recursiva
; ---------------------------------------------
; implementa o algoritmo recursivo da Torre de Hanói.
; parâmetros na pilha (do topo da pilha para baixo, ou do EBP+offset):
; [ebp+20]: torre_auxiliar (identificador numérico da torre auxiliar)
; [ebp+16]: torre_destino  (identificador numérico da torre de destino)
; [ebp+12]: torre_origem   (identificador numérico da torre de origem)
; [ebp+8]:  qtd_discos     (número de discos a serem movidos)
; =============================================

torre_de_hanoi:
    push ebp                ; salva ebp.
    mov ebp, esp            ; configura novo ebp.

    mov eax, [ebp+8]        ; carrega qtd_discos (n).
    cmp eax, 1              ; checa caso base (n=1).
    jne else_branch         ; se n não é 1, vai para 'else'.

    ; caso base: move o disco 1
    push dword [ebp+16]     ; empilha torre destino.
    push dword [ebp+12]     ; empilha torre origem.
    push dword 1            ; empilha número do disco (1).
    call print              ; chama a função 'print'.
    add esp, 12             ; limpa argumentos da pilha.
    jmp liberar             ; pula para o final da função.

else_branch:
    ; passo 1: move n-1 discos da origem para o auxiliar
    push dword [ebp+16]     ; novo auxiliar (destino antigo).
    push dword [ebp+20]     ; novo destino (auxiliar antigo).
    push dword [ebp+12]     ; nova origem (origem antiga).
    mov eax, [ebp+8]        ; recarrega n discos.
    dec eax                 ; n-1 discos.
    push dword eax          ; empilha n-1.
    call torre_de_hanoi     ; chamada recursiva.
    add esp, 16             ; limpa argumentos da pilha.

    ; passo 2: move o disco atual da origem para o destino
    push dword [ebp+16]     ; empilha torre destino.
    push dword [ebp+12]     ; empilha torre origem.
    push dword [ebp+8]      ; empilha disco atual (n).
    call print              ; chama a função 'print'.
    add esp, 12             ; limpa argumentos da pilha.

    ; passo 3: move n-1 discos do auxiliar para o destino
    push dword [ebp+12]     ; novo auxiliar (origem antiga).
    push dword [ebp+16]     ; novo destino (destino antigo).
    push dword [ebp+20]     ; nova origem (auxiliar antiga).
    mov eax, [ebp+8]        ; recarrega n discos.
    dec eax                 ; n-1 discos.
    push dword eax          ; empilha n-1.
    call torre_de_hanoi     ; chamada recursiva.

liberar:
    mov esp, ebp            ; restaura esp.
    pop ebp                 ; restaura ebp.
    ret                     ; retorna da função.

; ---
; FUNÇÃO PRINT (print)
; ---------------------------------------------
; prepara e exibe uma mensagem de movimento de disco no formato:
; "Mova o disco N da torre Orig para a torre Dest"
; parâmetros na pilha (do topo da pilha para baixo, ou do EBP+offset):
; [ebp+16]: id_torre_destino (identificador numérico da torre de destino)
; [ebp+12]: id_torre_origem  (identificador numérico da torre de origem)
; [ebp+8]:  num_disco        (número do disco a ser movido)
; =============================================

print:
    push ebp                ; salva ebp.
    mov ebp, esp            ; configura novo ebp.

    mov eax, [ebp + 8]      ; carrega número do disco.
    add al, 48              ; converte para ascii.
    mov [disco], al         ; armazena no placeholder.

    mov eax, [ebp + 12]     ; carrega torre de origem.
    add al, 64              ; converte para letra ('a'-1).
    mov [torre_saida], al   ; armazena no placeholder.

    mov eax, [ebp + 16]     ; carrega torre de destino.
    add al, 64              ; converte para letra ('a'-1).
    mov [torre_ida], al     ; armazena no placeholder.

    mov edx, lenght         ; tamanho da mensagem.
    mov ecx, msg            ; endereço da mensagem.
    mov ebx, 1              ; saída padrão (stdout).
    mov eax, 4              ; chamada de sistema (sys_write).
    int 0x80                ; executa a chamada.

    mov esp, ebp            ; restaura esp.
    pop ebp                 ; restaura ebp.
    ret                     ; retorna da função.
