; Matheus Stepple - Sistemas de Informação 2024.2
; projeto feito em dupla com Matheus Henrique

; projeto funcionando em: https://www.tutorialspoint.com/compilers/online-assembly-compiler.htm

; =============================================
; SEÇÃO DE DADOS
; Usada para armazenar dados inicializados do programa, por exemplo uma variável global

; =============================================

section .data
    ; Mensagem para solicitar a entrada do usuário.
    msg_input db 'Digite o numero de discos: ', 0

    ; Caractere de nova linha.
    msg_newline db 10, 0

    ; Modelo da mensagem para movimentos de disco: "disc: N Orig -> Dest".
    msg db "disc: "
    disco db " "
    db "   "
    torre_saida db " "
    db " -> "
    torre_ida db " ", 0xa ; 0xa para quebrar linha
    lenght equ $-msg

; =============================================

; SEÇÃO BSS
; Usada para armazenar dados não inicializados do programa, como buffers.

; =============================================

section .bss
    ; buffer para armazenar a entrada do usuário (até 2 dígitos + newline).
    buffer resb 3

; =============================================
; SEÇÃO DE TEXTO
; usado para armazenar o código executável do nosso programa.
; =============================================

section .text
    ; ponto de entrada do programa.
    global _start

; =============================================
; PROGRAMA PRINCIPAL
; =============================================

_start:
    ; imprime a mensagem de entrada para o usuário.
    mov edx, 26             ; tamanho da mensagen.
    mov ecx, msg_input      ; endereço da mensagem.
    mov ebx, 1              ; descritor de arquivo para stdout (saída padrão).
    mov eax, 4              ; chamada de sistema sys_write.
    int 0x80                ; interrupção para o kernel (Linux).

    ; Lê a entrada do usuário.
    mov eax, 3              ; chamada de sistema sys_read.
    mov ebx, 0              ; descritor de arquivo para stdin (entrada padrão).
    mov ecx, buffer         ; buffer de destino para a entrada.
    mov edx, 3              ; número de bytes a ler (2 dígitos + newline).
    int 0x80                ; interrupção para o kernel.

    ; Converte a entrada ASCII (string) para um número inteiro.
    xor eax, eax            ; zera EAX (usado como acumulador para o número).
    mov edi, buffer         ; EDI aponta para o início do buffer.

loop_conversao:
    mov bl, [edi]           ; carrega o caractere atual do buffer.
    cmp bl, 10              ; compara com o caractere de nova linha (ASCII 10).
    je finalizar_conversao  ; se for newline, finaliza a conversão.
    
    sub bl, '0'             ; converte o caractere ASCII para seu valor numérico.
    imul eax, 10            ; multiplica o acumulador atual por 10 (prepara para o próximo dígito).
    add eax, ebx            ; adiciona o valor numérico do dígito atual ao acumulador.
    inc edi                 ; avança para o próximo caractere no buffer.
    jmp loop_conversao      ; continua o loop.

finalizar_conversao:
    ; valor final do número de discos está em EAX.
    
    ; configura e chama a função recursiva da Torre de Hanoi.
    push dword 2            ; empilha a torre auxiliar (identificador 2).
    push dword 3            ; empilha a torre de destino (identificador 3).
    push dword 1            ; empilha a torre de origem (identificador 1).
    push eax                ; empilha o número de discos (obtido do usuário).
    call torre_de_hanoi     ; Chama a função principal da torre de Hanoi dnv.

    ; imprime uma nova linha no final da execução.
    mov edx, 1              ; tamanho da mensagem (1 byte para o newline).
    mov ecx, msg_newline    ; endereço do caractere de nova linha.
    mov ebx, 1              ; stdout.
    mov eax, 4              ; sys_write.
    int 0x80                ; interrupção para o kernel.

    ; encerra o programa com sucesso.
    mov eax, 1              ; chamada de sistema sys_exit.
    mov ebx, 0              ; código de saída 0 (sucesso).
    int 0x80                ; interrupção para o kernel.

; =============================================
; FUNÇÃO HANOI (Recursiva)
; parâmetros na pilha (do topo para a base):
; [ebp+8]: número de discos (n)
; [ebp+12]: torre de origem
; [ebp+16]: torre auxiliar
; [ebp+20]: torre de destino
; =============================================

torre_de_hanoi:
    push ebp                ; salva o EBP do chamador na pilha.
    mov ebp, esp            ; configura o EBP para o topo da pilha atual, criando o novo frame.

    mov eax, [ebp+8]        ; carrega o número de discos (n) para EAX.
    cmp eax, 0              ; compara n com 0.
    je liberar              ; se n é 0 (caso base), pula para liberar e retornar.

    ; 1ª chamada recursiva: move n-1 discos da torre de origem para a torre auxiliar.
    ; Parâmetros para a próxima chamada: (n-1, origem, destino, auxiliar)
    ; (n-1, [ebp+12] (origem), [ebp+16] (auxiliar), [ebp+20] (destino))
    ; obrigado python!!
    
    push dword [ebp+16]     ; empilha a nova torre auxiliar (que era a torre de destino na chamada atual).
    push dword [ebp+20]     ; empilha o novo destino (que era a torre auxiliar na chamada atual).
    push dword [ebp+12]     ; empilha a nova origem (que era a torre de origem na chamada atual).
    dec eax                 ; decrementa o número de discos (n-1).
    push dword eax          ; empilha o novo número de discos (n-1).
    call torre_de_hanoi     ; chama recursivamente torre_de_hanoi.
    add esp, 16             ; limpa os 4 parâmetros (4 * 4 bytes = 16 bytes) da pilha após o retorno.

    ; imprime o movimento do disco atual (o maior disco da pilha atual).
    ; parâmetros para printar: (disco, origem, destino)
    ; ([ebp+8] (disco atual), [ebp+12] (origem), [ebp+20] (destino))
    push dword [ebp+20]     ; empilha a torre de destino.
    push dword [ebp+12]     ; empilha a torre de origem.
    push dword [ebp+8]      ; empilha o número do disco (n).
    call printar            ; chama a função para imprimir o movimento.
    add esp, 12             ; limpa os 3 parâmetros (3 * 4 bytes = 12 bytes) da pilha após o retorno.

    ; 2ª chamada recursiva: move n-1 discos da torre auxiliar para a torre de destino.
    ; parâmetros para a próxima chamada: (n-1, auxiliar, origem, destino)
    ; (n-1, [ebp+20] (auxiliar), [ebp+12] (origem), [ebp+16] (destino))
    
    push dword [ebp+12]     ; Empilha a nova torre auxiliar (que era a torre de origem na chamada atual).
    push dword [ebp+16]     ; Empilha o novo destino (que era a torre de destino na chamada atual).
    push dword [ebp+20]     ; Empilha a nova origem (que era a torre auxiliar na chamada atual).
    mov eax, [ebp+8]        ; Recarrega o número de discos (n) para EAX (pois EAX foi modificado na 1ª chamada).
    dec eax                 ; Decrementa o número de discos (n-1).
    push dword eax          ; Empilha o novo número de discos (n-1).
    call torre_de_hanoi     ; Chama recursivamente torre_de_hanoi.

liberar:
    mov esp, ebp            ; Restaura o ESP para o valor de EBP (libera o frame atual).
    pop ebp                 ; Restaura o EBP do chamador.
    ret                     ; Retorna da função (usa o endereço de retorno salvo na pilha pelo CALL).

; =============================================
; FUNÇÃO PRINT
; parâmetros na pilha (do topo para a base do frame):
; [ebp+8]: número do disco
; [ebp+12]: torre de origem
; [ebp+16]: torre de destino
; =============================================

printar:
    push ebp                ; salva o EBP do chamador.
    mov ebp, esp            ; configura o EBP para o topo da pilha atual.

    ; Prepara o número do disco para impressão (converte para ASCII).
    mov eax, [ebp + 8]      ; carrega o número do disco.
    add al, 48              ; adiciona 48 (ASCII de '0') para converter para o caractere numérico.
    mov [disco], al         ; armazena o caractere no local 'disco' na seção .data.

    ; Prepara a torre de origem para impressão (converte para letra A, B, C).
    mov eax, [ebp + 12]     ; carrega o identificador da torre de origem.
    add al, 64              ; adiciona 64 (ASCII de 'A'-1) para converter para a letra correspondente ('A', 'B', 'C').
    mov [torre_saida], al   ; armazena o caractere no local 'torre_saida' na seção .data.

    ; prepara a torre de destino para impressão (converte para letra A, B, C).
    mov eax, [ebp + 16]     ; carrega o identificador da torre de destino.
    add al, 64              ; adiciona 64 (ASCII de 'A'-1) para converter para a letra correspondente.
    mov [torre_ida], al     ; armazena o caractere no local 'torre_ida' na seção .data.

    ; Imprime a mensagem completa formatada.
    mov edx, lenght         ; tamanho da mensagem a ser impressa.
    mov ecx, msg            ; endereço da mensagem formatada.
    mov ebx, 1              ; stdout.
    mov eax, 4              ; sys_write.
    int 0x80                ; interrupção para o kernel.

    mov esp, ebp            
    pop ebp                
    ret                     ; cabosse
