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

; FIJATE SI ES ALGO QUE TENÉS QUE HACER: 
; CHEQUEAR QUE MALLOC NO NOS HAYA DADO UN PUNTERO A NULL, PORQUE EN ESE CASO CUANDO ACCEDEMOS A LOS ELEMENTOS DEL STRUCT ESTAMOS ACCEDIENDO MAL.

string_proc_list_create_asm:
; no tiene entradas
push rbp
mov rbp, rsp

mov qword rdi, 16 ; string_proc_list_size
call malloc ; rax = lista

mov qword [rax], 0 ; lista->first = NULL
mov qword [rax + 8], 0 ; lista->last = NULL

pop rbp
ret

string_proc_node_create_asm:
; dil = type
; rsi = hash
push rbp
mov rbp, rsp

push r12
push r13

mov r12b, dil ; r12b = type
mov r13, rsi ; r13 = hash

mov rdi, 32 ; sizeof(string_proc_node)
call malloc ; rax = nodo

mov byte [rax + 16], dil ; nodo->type = type
mov qword [rax + 24], rsi ; nodo->hash = hash
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

mov r12, rdi ; r12 = list
mov r13b, sil ; r13b = type
mov r14, rdx ; r14 = hash

mov dil, r13b
mov rsi, r14
call string_proc_node_create_asm ; rax = nodo

mov r8, [r12] ; list->first
cmp r8, 0 ; list->first == NULL ?
je .primer_nodo

mov r9, [r12 + 8]
mov [rax + 8], r9 ; nodo->previous = list->last
mov r10, [r12 + 8] ; list->last
mov [r10], rax ; list->last->next = nodo
mov [r12 + 8], rax ; list->last = nodo
jmp .fin

.primer_nodo:
    mov [r12], rax
    mov [r12 + 8], rax
    jmp .fin

.fin:
    add rsp, 8
    pop rbp
    ret

string_proc_list_concat_asm:
