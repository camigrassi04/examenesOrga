; /** defines bool y puntero **/
%define NULL 0
%define TRUE 1
%define FALSE 0

section .data

section .text

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

; FUNCIONES auxiliares que pueden llegar a necesitar:
extern malloc
extern free
extern str_concat
extern strlen
extern strcpy
extern strcat

; FIJATE SI ES ALGO QUE TENÉS QUE HACER: 
; CHEQUEAR QUE MALLOC NO NOS HAYA DADO UN PUNTERO A NULL, PORQUE EN ESE CASO CUANDO ACCEDEMOS A LOS ELEMENTOS DEL STRUCT ESTAMOS ACCEDIENDO MAL.

string_proc_list_create_asm:
; no tiene entradas
    push rbp
    mov rbp, rsp

    mov rdi, 16 ; sizeof(string_proc_list) = 16
    call malloc ; rax = lista
    mov qword [rax], 0
    mov qword [rax + 8], 0

    pop rbp
    ret

string_proc_node_create_asm:
; dil = type
; rsi = hash
    push rbp
    mov rbp, rsp

    push r12
    push r13

    xor r12, r12
    mov r12b, dil
    mov r13, rsi

    mov rdi, 32
    call malloc ; rax = nodo
    mov byte [rax + 16], r12b ; nodo->type = type
    mov qword [rax + 24], r13 ; nodo->hash = hash
    mov qword [rax], 0 ; nodo->next = NULL
    mov qword [rax + 8], 0 ; nodo->previous = NULL

    pop r13
    pop r12
    pop rbp
    ret

string_proc_list_add_node_asm:
; rdi = list
; sil = type
; rdx = hash
    push rbp
    mov rbp, rsp

    push r12
    push r13
    push r14
    sub rsp, 8

    mov r12, rdi
    movzx r13, sil
    mov r14, rdx

    xor rdi, rdi
    mov dil, r13b
    mov rsi, r14
    call string_proc_node_create_asm ; rax = nodo

    cmp qword [r12], 0 ; list->first == NULL ?
    je .agregar_primer_nodo

    mov r8, [r12 + 8] ; list->last
    mov [rax + 8], r8 ; nodo->previous = list->last
    mov [r8], rax ; list->last->next = nodo
    mov [r12 + 8], rax ; list->last = nodo
    jmp .fin

    .agregar_primer_nodo:
    mov [r12], rax ; list->first = nodo
    mov [r12 + 8], rax ; list->last = nodo

    .fin:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

string_proc_list_concat_asm:
; rdi = list 
; sil = type
; rdx = hash
    push rbp
    mov rbp, rsp

    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp, 8

    mov r12, rdi ; r12 = list
    movzx r13, sil ; r13 = type
    mov r14, rdx ; r14 = hash

    cmp r12, 0
    je .unica_copia

    xor r15, r15
    mov rdi, r14
    call strlen ; rax = strlen(hash)
    mov r15, rax ; r15 = total_hashes

    ; uso el registro rbx para guardar el nodo (aunque al final lo quiero usar para devolver nuevo_hash)
    mov rbx, [r12] ; node = list->first
    .while1:
    cmp qword rbx, 0 ; node == NULL ?
    je .armar_hash

    cmp byte [rbx + 16], r13b
    jne .avanzar

    mov rdi, [rbx + 24]
    call strlen 
    add r15, rax 

    .avanzar:
    mov rbx, [rbx]
    jmp .while1

    .armar_hash:
    mov rdi, r15 ; rdi = total_hashes
    inc rdi
    call malloc ; rax = malloc(total_hashes +1)
    mov rbx, rax ; rbx = nuevo_hash

    mov byte [rbx], 0 ; nuevo_hash[0] = '\0'
    mov rdi, rbx
    mov rsi, r14
    call strcat ; strcat(nuevo_hash, hash)
    mov r12, [r12] ; ahora r12 = node

    .while:
    cmp qword r12, 0 ; node != NULL
    je .fin

    cmp byte [r12 + 16], r13b ; node->type == type ?
    jne .siguiente_nodo

    mov rdi, rbx
    mov rsi, [r12 + 24] 
    call strcat ; strcat(nuevo_hash, node->hash)

    .siguiente_nodo:
    mov r12, [r12]
    jmp .while

    .unica_copia:
    mov rdi, r14
    call strlen ; rax = strlen(hash)
    inc rax
    mov rdi, rax
    call malloc ; rax = copia_original
    mov rbx, rax ; rbx = copia_original
    cmp qword rbx, 0 ; copia_original != NULL ?
    je .fin

    mov rdi, rbx
    mov rsi, r14
    call strcpy ; strcpy(copia_original, hash)

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