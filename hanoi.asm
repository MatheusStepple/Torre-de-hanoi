; =============================================
; SEÇÃO DE DADOS - Onde armazenamos mensagens e variáveis
; =============================================
section .data
    ; Mensagem solicitando entrada do usuário
    msg_input db 'Digite o numero de discos (1 a 99): ', 0

    ; Mensagem de erro para entrada inválida
    msg_invalid db 'Numero invalido! Use um valor entre 1 e 99.', 10, 0

    ; Caractere de nova linha
    msg_newline db 10, 0

    ; Modelo de mensagem para exibir movimentos dos discos
    msg db "disc: "       ; Início da mensagem
    disco db " "          ; Irá conter o número do disco
    db "   "              ; Alguns espaços
    torre_saida db " "    ; Irá conter a torre de origem
    db " -> "             ; Seta
    torre_ida db " "      ; Irá conter a torre de destino
    db 0xa                ; Nova linha no final
    lenght equ $-msg      ; Calcula o tamanho total da mensagem

; =============================================
; SEÇÃO BSS - Onde reservamos espaço para variáveis
; =============================================
section .bss
    buffer resb 3         ; Reserva 3 bytes para o buffer de entrada do usuário

; =============================================
; SEÇÃO DE TEXTO - Onde o código do programa está
; =============================================
section .text
    global _start         ; Indica ao linker onde o programa começa

; =============================================
; PROGRAMA PRINCIPAL
; =============================================
_start:
    ; Configura a pilha
    push ebp
    mov ebp, esp

    ; Imprime a mensagem de entrada
    mov edx, 35           ; Tamanho da mensagem
    mov ecx, msg_input    ; Mensagem a ser impressa
    mov ebx, 1            ; Descritor de arquivo (1 = stdout)
    mov eax, 4            ; Número da syscall (4 = write)
    int 128               ; Chama o kernel para imprimir

    ; Lê a entrada do usuário
    mov eax, 3            ; Número da syscall (3 = read)
    mov ebx, 0            ; Descritor de arquivo (0 = stdin)
    mov ecx, buffer       ; Onde armazenar a entrada
    mov edx, 3            ; Máximo de bytes para ler
    int 128               ; Chama o kernel para ler

    ; Converte entrada ASCII para número
    xor eax, eax          ; Limpa eax (zera)
    mov edi, buffer       ; Aponta para o buffer de entrada

; Loop para converter cada caractere em dígito
loop_conversao:
    mov bl, [edi]         ; Pega o próximo caractere
    cmp bl, 10            ; Verifica se é newline (fim da entrada)
    je finalizar_conversao ; Se for newline, finaliza
    cmp bl, '0'           ; Verifica se caractere é menor que '0'
    jl input_errado       ; Se for, entrada inválida
    cmp bl, '9'           ; Verifica se caractere é maior que '9'
    jg input_errado       ; Se for, entrada inválida
    sub bl, '0'           ; Converte ASCII para número (subtrai '0')
    imul eax, 10          ; Multiplica o total atual por 10
    add eax, ebx          ; Adiciona novo dígito
    inc edi               ; Vai para o próximo caractere
    jmp loop_conversao    ; Repete

; Após conversão, valida se número está entre 1-99
finalizar_conversao:
    cmp eax, 1            ; Verifica se é menor que 1
    jl input_errado
    cmp eax, 99           ; Verifica se é maior que 99
    jg input_errado

    ; Configura parâmetros para função de Hanoi:
    ; Parâmetros são empilhados em ordem reversa:
    ; 1. Torre de destino (3)
    ; 2. Torre auxiliar (2)
    ; 3. Torre de origem (1)
    ; 4. Número de discos (entrada do usuário)
    push dword 2          ; Torre auxiliar
    push dword 3          ; Torre de destino
    push dword 1          ; Torre de origem
    push eax              ; Número de discos
    call torre_de_hanoi   ; Chama a função de Hanoi

    ; Imprime nova linha ao final
    mov edx, 1            ; Tamanho (1 byte)
    mov ecx, msg_newline  ; Caractere de nova linha
    mov ebx, 1            ; stdout
    mov eax, 4            ; syscall write
    int 128               ; Chama o kernel

    ; Encerra programa com sucesso
    mov eax, 1            ; syscall exit
    mov ebx, 0            ; código de saída 0
    int 128               ; Chama o kernel

; =============================================
; TRATAMENTO DE ERRO - Quando a entrada é inválida
; =============================================
input_errado:
    ; Imprime mensagem de entrada inválida
    mov edx, 47           ; Tamanho da mensagem
    mov ecx, msg_invalid  ; Mensagem a ser impressa
    mov ebx, 1            ; stdout
    mov eax, 4            ; syscall write
    int 128               ; Chama o kernel

    ; Encerra com código de erro 1
    mov eax, 1            ; syscall exit
    mov ebx, 1            ; código de saída 1
    int 128               ; Chama o kernel

; =============================================
; FUNÇÃO HANOI - Solucionador recursivo das Torres de Hanoi
; =============================================
torre_de_hanoi:
    push ebp              ; Salva o ponteiro base antigo
    mov ebp, esp          ; Define novo ponteiro base
    mov eax, [ebp+8]      ; Pega parâmetro do número de discos
    cmp eax, 0            ; Se 0 discos, já terminou
    je liberar            ; Pula para limpeza

    ; Primeira chamada recursiva: move n-1 discos da origem para a auxiliar
    push dword [ebp+16]   ; Atual auxiliar vira destino
    push dword [ebp+20]   ; Atual destino vira auxiliar
    push dword [ebp+12]   ; Origem permanece origem
    dec eax               ; Decrementa número de discos
    push dword eax        ; Empilha n-1 como novo valor
    call torre_de_hanoi   ; Chamada recursiva
    add esp, 16           ; Limpa pilha após chamada

    ; Imprime o movimento atual
    push dword [ebp+16]   ; Torre destino
    push dword [ebp+12]   ; Torre origem
    push dword [ebp+8]    ; Número do disco
    call printar          ; Chama função de impressão
    add esp, 12           ; Limpa pilha

    ; Segunda chamada recursiva: move n-1 discos da auxiliar para o destino
    push dword [ebp+12]   ; Origem atual vira auxiliar
    push dword [ebp+16]   ; Auxiliar atual vira origem
    push dword [ebp+20]   ; Destino permanece destino
    mov eax, [ebp+8]      ; Pega número de discos
    dec eax               ; Decrementa
    push dword eax        ; Empilha n-1 como novo valor
    call torre_de_hanoi   ; Chamada recursiva

; Limpeza e retorno
liberar:
    mov esp, ebp          ; Restaura ponteiro da pilha
    pop ebp               ; Restaura ponteiro base
    ret                   ; Retorna da função

; =============================================
; FUNÇÃO PRINT - Exibe cada movimento
; =============================================
printar:
    push ebp              ; Salva ponteiro base antigo
    mov ebp, esp          ; Define novo ponteiro base

    ; Prepara número do disco para exibir
    mov eax, [ebp + 8]    ; Pega parâmetro do número do disco
    add al, 48            ; Converte para ASCII (48 = '0')
    mov [disco], al       ; Armazena na mensagem

    ; Prepara torre de origem para exibir
    mov eax, [ebp + 12]   ; Pega parâmetro da torre de origem
    add al, 64            ; Converte para letra (65 = 'A')
    mov [torre_saida], al ; Armazena na mensagem

    ; Prepara torre de destino para exibir
    mov eax, [ebp + 16]   ; Pega parâmetro da torre de destino
    add al, 64            ; Converte para letra
    mov [torre_ida], al   ; Armazena na mensagem

    ; Imprime a mensagem completa do movimento
    mov edx, lenght       ; Tamanho da mensagem
    mov ecx, msg          ; Mensagem a imprimir
    mov ebx, 1            ; stdout
    mov eax, 4            ; syscall write
    int 128               ; Chama o kernel

    ; Limpeza e retorno
    mov esp, ebp          ; Restaura ponteiro da pilha
    pop ebp               ; Restaura ponteiro base
    ret                   ; Retorna da função
