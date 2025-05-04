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
    ; dil table_size

    ; prólogo
    push rbp
    mov rbp, rsp

    push r12
    push r13
    push r14
    push r15
    push rbx

    mov r12b, dil

    mov rdi, 16

    sub rsp, 8
    call malloc ; rax =  ordering_table_t* OT

    mov r13, rax

    mov byte [r13 + OFFSET_TABLE_SIZE], r12b ;  OT->table_size = table_size

    cmp r12b, 0
    je .null_case

    movzx rdi, r12b
    mov rsi, 8

    call calloc ; rax = nodo_ot_t** table

    mov [r13 + OFFSET_TABLE], rax ; OT->table = table

    jmp .fin
.null_case:
    mov qword [r13 + OFFSET_TABLE], 0 ; OT->table = NULL
.fin:
    ; epilogo
    mov rax, r13
    add rsp, 8
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; void* calcular_z(nodo_display_list_t* display_list) ;
calcular_z_asm:

; void* ordenar_display_list(ordering_table_t* ot, nodo_display_list_t* display_list) ;
ordenar_display_list_asm:

