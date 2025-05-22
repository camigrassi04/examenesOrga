section .text

global inicializar_OT_asm
global calcular_z_asm
global ordenar_display_list_asm

extern malloc
extern free
extern calloc

OFFSET_PRIMITIVA EQU 0
OFFSET_X EQU 8
OFFSET_Y EQU 9
OFFSET_Z EQU 10
OFFSET_SIGUIENTE_DL EQU 16
OFFSET_DISPLAY_LIST_SIZE EQU 24 

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

    movzx r12, dil ; r12 = table_size

    mov rdi, OFFSET_OT_SIZE
    call malloc ; rax = OT
    mov r13, rax ; r13 = OT

    mov [r13 + OFFSET_TABLE_SIZE], r12b

    xor rax, rax
    cmp r12, 0
    jne .no_vacia

    mov qword [r13 + OFFSET_TABLE], 0
    jmp .fin

    .no_vacia:
    mov rdi, r12
    mov rsi, OFFSET_SIZE
    call calloc ; rax = table
    mov [r13 + OFFSET_TABLE], rax

    .fin:
    mov rax, r13
    pop r13
    pop r12
    pop rbp
    ret

; void* calcular_z(nodo_display_list_t* display_list) ;
calcular_z_asm:
; rdi = nodo
; sil = z_size
    push rbp
    mov rbp, rsp

    push r12
    push r13
    push r14
    push r15

    mov r12, rdi ; r12 = nodo
    movzx r13, sil ; r13 = z_size

    cmp r12, 0
    je .fin

    mov r14, [r12 + OFFSET_PRIMITIVA]
    mov dil, [r12 + OFFSET_X]
    mov sil, [r12 + OFFSET_Y]
    mov dl, r13b ; dl = z_size

    call r14 ; rax = z
    mov byte [r12 + OFFSET_Z], al

    .fin: 
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
    sub rsp, 8

    mov r12, rdi ; r12 = ot
    mov r13, rsi ; r13 = display_list

    cmp byte [r12 + OFFSET_TABLE_SIZE], 0 ; ot->table_size == 0
    je .fin

    .while:
    cmp r13, 0
    je .fin

    mov rdi, r13
    mov sil, byte [r12 + OFFSET_TABLE_SIZE]
    call calcular_z_asm

    movzx r14, byte [r13 + OFFSET_Z] ; i = display_list->z

    mov rdi, OFFSET_OT_SIZE
    call malloc ; rax = nodo

    mov [rax + OFFSET_DISPLAY_ELEMENT], r13 ; nodo->display_element = display_list
    mov qword [rax + OFFSET_SIGUIENTE], 0 ; nodo->siguiente = NULL

    mov r8, [r12 + OFFSET_TABLE] ; ot->table
    shl r14, 3 ; i * 8
    cmp qword [r8 + r14], 0
    jne .agregar_ultimo

    mov [r8 + r14], rax ; ot->table[i] = nodo
    jmp .siguiente_nodo

    .agregar_ultimo:
    mov r15, [r8 + r14] ; ultimo = ot->table[i]
    .buscar_ultimo:
    cmp qword [r15 + OFFSET_SIGUIENTE], 0
    je .asignar_nodo

    mov r15, [r15 + OFFSET_SIGUIENTE] ; ultimo = ultimo->siguiente
    jmp .buscar_ultimo

    .asignar_nodo:
    mov [r15 + OFFSET_SIGUIENTE], rax ; ultimo->siguiente = nodo

    .siguiente_nodo:
    mov r13, [r13 + OFFSET_SIGUIENTE_DL] ; display_list = display_list->siguiente
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
