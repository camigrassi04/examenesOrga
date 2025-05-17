section .text

global inicializar_OT_asm
global calcular_z_asm
global ordenar_display_list_asm

extern malloc
extern free
extern calloc

OFFSET_TABLE_SIZE EQU 0
OFFSET_TABLE EQU 8
OFFSET_OT_SIZE EQU 16

; nodo_ot_t
OFFSET_DISPLAY_ELEMENT EQU 0
OFFSET_SIGUIENTE EQU 8
OFFSET_SIZE EQU 16
;########### SECCION DE TEXTO (PROGRAMA)

; ordering_table_t* inicializar_OT(uint8_t table_size);
inicializar_OT_asm:
    ; dil = table_size
    push rbp
    mov rbp, rsp

    push r12
    push r13

    xor r12, r12
    mov r12b, dil
    mov rdi, OFFSET_OT_SIZE
    call malloc ; rax = OT
    mov r13, rax

    mov byte [r13 + OFFSET_TABLE_SIZE], r12b ; OT->table_size = table_size

    cmp byte r12b, 0
    je .crear_tabla_null

    movzx rdi, r12b
    mov rsi, 8
    call calloc ; rax = table 
    mov [r13 + OFFSET_TABLE], rax
    jmp .fin
    .crear_tabla_null:
    mov qword [r13 + OFFSET_TABLE], 0

    .fin:
    mov rax, r13
    pop r13
    pop r12
    pop rbp
    ret
; void* calcular_z(nodo_display_list_t* display_list) ;
calcular_z_asm:
    ; rdi nodo
    ; sil z_size

    push rbp
    mov rbp, rsp

    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp, 8

    xor r13, r13
    mov r12, rdi ; r12 = nodo
    mov r13b, sil ; r13b = z_size

    .while:
    cmp r12, 0
    je .fin

    mov rbx, [r12] ; rbx = primitiva
    mov dil, byte [r12 + 8] ; dil = nodo->x
    mov sil, byte [r12 + 9] ; sil = nodo->y
    mov dl, r13b ; dl = z_size
    call rbx ; rax = z
    mov byte [r12 + 10], al
    
    mov r12, [r12 + 16] ; nodo = nodo->siguiente

    jmp .while

    .fin:
    add rsp, 8
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret
; void* ordenar_display_list(ordering_table_t* ot, nodo_display_list_t* display_list) ;
ordenar_display_list_asm:
    ; rdi = ot
    ; rsi = display_list

    push rbp
    mov rbp, rsp

    push r12
    push r13
    push r14
    push r15
    push rbx

    mov r12, rdi ; r12 = ot
    mov r13, rsi ; r13 = display_list

    ; calculo z para todos los nodos
    mov rdi, r13
    movzx rsi, byte [r12 + OFFSET_TABLE_SIZE]
    call calcular_z_asm

    .while:
    cmp r13, 0
    je .fin

    mov rdi, OFFSET_SIZE
    call malloc
    mov r14, rax ; r14 = nuevo_nodo

    mov [r14 + OFFSET_DISPLAY_ELEMENT], r13 ; nuevo_nodo->display_element = display_list
    mov qword [r14 + OFFSET_SIGUIENTE], 0 ; nuevo_nodo->siguiente = NULL

    mov r15, [r12 + OFFSET_TABLE] ; r15 = ot->table
    movzx rbx, byte [r13 + 10] ; rbx = display_list->z
    imul rbx, 8 ; multiplico por el tamaño del dato de la table
    add r15, rbx ; r15 = &ot->table[z]

    cmp qword [r15], 0 ; ot->table[display_list->z] == NULL ?
    jne .encontrar_ultimo

    mov [r15], r14 ; ot->table[display_list->z] = nuevo_nodo
    jmp .avanzar

    .encontrar_ultimo:
    mov rbx, [r15] ; rbx = ultimo
    .loop:
    cmp qword [rbx + OFFSET_SIGUIENTE], 0 ; ultimo->siguiente == NULL ?
    je .insertar_nodo
    mov rbx, [rbx + OFFSET_SIGUIENTE] ; ultimo = ultimo->siguiente
    jmp .loop

    .insertar_nodo:
    mov [rbx + OFFSET_SIGUIENTE], r14 ; ultimo->siguiente = nuevo_nodo

    .avanzar:
    mov r13, [r13 + 16] ; display_list = display_list->siguiente
    jmp .while

    .fin:
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret
