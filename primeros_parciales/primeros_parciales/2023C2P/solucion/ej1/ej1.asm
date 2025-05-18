section .text

global contar_pagos_aprobados_asm
global contar_pagos_rechazados_asm

global split_pagos_usuario_asm

extern malloc
extern free
extern strcmp

PAGO_T_MONTO EQU 0
PAGO_T_APROBADO EQU 1
PAGO_T_PAGADOR EQU 8
PAGO_T_COBRADOR EQU 16
PAGO_T_SIZE EQU 24

PAGO_SPLITTED_T_CANT_APROBADOS EQU 0
PAGO_SPLITTED_T_CANT_RECHAZADOS EQU 1
PAGO_SPLITTED_T_APROBADOS EQU 8
PAGO_SPLITTED_T_RECHAZADOS EQU 16
PAGO_SPLITTED_T_SIZE EQU 24

LISTELEM_T_DATA EQU 0
LISTELEM_T_NEXT EQU 8
LISTELEM_T_PREV EQU 16
LISTELEM_T_SIZE EQU 24

LIST_T_FIRST EQU 0
LIST_T_LAST EQU 8

;########### SECCION DE TEXTO (PROGRAMA)

; uint8_t contar_pagos_aprobados_asm(list_t* pList, char* usuario);
contar_pagos_aprobados_asm:
; rdi = pList
; rsi = usuario
    push rbp
    mov rbp, rsp

    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp, 8

    mov r12, rdi ; r12 = pList
    mov r13, rsi ; r13 = usuario

    xor rbx, rbx ; res = 0
    cmp qword r12, 0  ; pList != NULL ?
    je .fin

    mov r14, [r12 + LIST_T_FIRST] ; r14 = nodo
    .while:
    cmp qword r14, 0 ; nodo == NULL
    je .fin

    mov rdi, [r14 + LISTELEM_T_DATA]
    mov rdi, [rdi + PAGO_T_COBRADOR] ; nodo->data->cobrador
    mov rsi, r13
    call strcmp ; strcmp(nodo->data->cobrador, usuario)
    cmp qword rax, 0 ; strcmp(nodo->data->cobrador, usuario) == 0 ?
    jne .avanzar

    mov r8, [r14 + LISTELEM_T_DATA]
    movzx r8, byte [r8 + PAGO_T_APROBADO]
    cmp qword r8, 1
    jne .avanzar

    inc rbx

    .avanzar:
    mov r14, [r14 + LISTELEM_T_NEXT]
    jmp .while
    .fin:
    xor rax, rax
    mov al, bl
    add rsp, 8
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret
; uint8_t contar_pagos_rechazados_asm(list_t* pList, char* usuario);
contar_pagos_rechazados_asm:
; rdi = pList
; rsi = usuario
    push rbp
    mov rbp, rsp

    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp, 8

    mov r12, rdi ; r12 = pList
    mov r13, rsi ; r13 = usuario

    xor rbx, rbx ; res = 0
    cmp qword r12, 0  ; pList != NULL ?
    je .fin

    mov r14, [r12 + LIST_T_FIRST] ; r14 = nodo
    .while:
    cmp qword r14, 0 ; nodo == NULL
    je .fin

    mov rdi, [r14 + LISTELEM_T_DATA]
    mov rdi, [rdi + PAGO_T_COBRADOR] ; nodo->data->cobrador
    mov rsi, r13
    call strcmp ; strcmp(nodo->data->cobrador, usuario)
    cmp qword rax, 0 ; strcmp(nodo->data->cobrador, usuario) == 0 ?
    jne .avanzar

    mov r8, [r14 + LISTELEM_T_DATA]
    movzx r8, byte [r8 + PAGO_T_APROBADO]
    cmp qword r8, 0
    jne .avanzar

    inc rbx
    
    .avanzar:
    mov r14, [r14 + LISTELEM_T_NEXT]
    jmp .while
    .fin:
    xor rax, rax
    mov al, bl
    add rsp, 8
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret
; pagoSplitted_t* split_pagos_usuario_asm(list_t* pList, char* usuario);
split_pagos_usuario_asm:
; rdi = pList
; rsi = usuario
    push rbp
    mov rbp, rsp

    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp, 8

    mov r12, rdi ; r12 = pList
    mov r13, rsi ; r13 = usuario

    mov rdi, PAGO_SPLITTED_T_SIZE
    call malloc ; rax = res
    mov rbx, rax 

    mov rdi, r12
    mov rsi, r13
    call contar_pagos_aprobados_asm ; al = cant_aprobados
    mov byte [rbx + PAGO_SPLITTED_T_CANT_APROBADOS], al ; res->cant_aprobados = contar_pagos_aprobados(pList, usuario)
    mov rdi, r12
    mov rsi, r13
    call contar_pagos_rechazados_asm
    mov byte [rbx + PAGO_SPLITTED_T_CANT_RECHAZADOS], al

    movzx rdi, byte [rbx + PAGO_SPLITTED_T_CANT_APROBADOS]
    shl rdi, 3
    call malloc ; rax = res->aprobados = malloc((res->cant_aprobados)*8)
    mov [rbx + PAGO_SPLITTED_T_APROBADOS], rax

    movzx rdi, byte [rbx + PAGO_SPLITTED_T_CANT_RECHAZADOS]
    shl rdi, 3
    call malloc ; rax = res->rechazados = malloc((res->cant_rechazados)*8)
    mov [rbx + PAGO_SPLITTED_T_RECHAZADOS], rax

    cmp r12, 0 ; pList == NULL ?
    je .fin

    mov r12, [r12 + LIST_T_FIRST] ; listElem_t* nodo = pList->first
    xor r14, r14 ; ultimo_aprobado = 0
    xor r15, r15 ; ultimo_rechazado = 0

    .loop:
    cmp r12, 0
    je .fin

    mov rdi, [r12 + LISTELEM_T_DATA] ; rdi = nodo->data
    mov rdi, [rdi + PAGO_T_COBRADOR] ; rdi = nodo->data->cobrador
    mov rsi, r13
    call strcmp ; rax = strcmp(nodo->data->cobrador, usuario)
    cmp qword rax, 0
    jne .avanzar

    mov qword r8, [r12 + LISTELEM_T_DATA]
    movzx r8, byte [r8 + PAGO_T_APROBADO]
    cmp r8, 1
    je .agregar_aprobado

    mov r9, r15 ; r9 = ultimo_rechazado 
    shl r9, 3
    mov r8, [rbx + PAGO_SPLITTED_T_RECHAZADOS]
    mov [r8 + r9], r12 ; res->aprobados[ultimo_rechazado] = nodo
    inc r15
    jmp .avanzar

    .agregar_aprobado:
    mov r9, r14 ; r9 = ultimo_aprobado 
    shl r9, 3
    mov r8, [rbx + PAGO_SPLITTED_T_APROBADOS]
    mov [r8 + r9], r12 ; res->aprobados[ultimo_aprobado] = nodo
    inc r14

    .avanzar:
    mov r12, [r12 + LISTELEM_T_NEXT] ; nodo = nodo->next
    jmp .loop

    .fin:
    mov rax, rbx 
    add rsp, 8
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret