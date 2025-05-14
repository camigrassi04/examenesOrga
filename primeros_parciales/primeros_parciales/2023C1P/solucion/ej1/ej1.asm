extern malloc
global templosClasicos
global cuantosTemplosClasicos



;########### SECCION DE TEXTO (PROGRAMA)
section .text
COLUM_LARGO_OFFSET EQU 0
NOMBRE_OFFSET EQU 8
COLUM_CORTO EQU 16
TEMPLO_SIZE EQU 24

templosClasicos:
; rdi -> temploArr
; rsi -> temploArr_len

push rbp
mov rbp, rsp

push r12
push r13
push r14
push r15

mov r12, rdi ; r12 = temploArr
mov r13, rsi ; r13 = temploArr_len

call cuantosTemplosClasicos ; rax = cant_templos_clasicos
mov rdi, rax
imul rdi, 24
call malloc ; rax = templos_clasicos

xor r14, r14 ; i = 0
xor r15, r15 ; indice_siguiente = 0

.for:
    cmp r14, r13
    je .fin

    mov r8, r14 ; r9 = i
    imul r8, 24 ; i * 24
    movzx r9, byte [r12 + r8 + COLUM_LARGO_OFFSET] ; temploArr[i].colum_largo

    movzx r10, byte [r12 + r8 + COLUM_CORTO] ; temploArr[i].colum_largo
    shl r10, 1
    inc r10

    cmp r9, r10
    jne .avanzar

    mov r11, r15 ; r11 = indice_siguiente
    imul r11, 24 ; indice_siguiente*24

    ; como un templo tiene tamaño de 24 bytes y los registros tienen tamaño de 8 bytes, lo tenemos que copiar en 3 partes
    
    mov r9, [r12 + r8]; guardo temploArr[i] parte 1
    mov [rax + r11], r9 ; templos_clasicos[indice_siguiente] = temploArr[i]

    mov r9, [r12 + r8 + 8] ; guardo temploArr[i] parte 2
    mov [rax + r11 + 8], r9

    mov r9, [r12 + r8 + 16] ; guardo temploArr[i] parte 3
    mov [rax + r11 + 16], r9

    inc r15

.avanzar:
    inc r14
    jmp .for

.fin:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

cuantosTemplosClasicos:
; rdi -> temploArr
; rsi -> temploArr_len

push rbp
mov rbp, rsp

xor rax, rax ; rax = res
xor r8, r8 ; r8 = i = 0

.for:
    cmp r8, rsi
    je .fin

    mov r9, r8 ; r9 = i
    imul r9, 24 ; i * 24

    movzx r10, byte [rdi + r9] ; temploArr[i].colum_largo

    movzx r11, byte [rdi + r9 + COLUM_CORTO] ; temploArr[i].colum_largo
    shl r11, 1
    inc r11

    cmp r10, r11
    jne .avanzar

    inc rax

.avanzar:
    inc r8
    jmp .for

.fin:
    pop rbp
    ret

; importante de este:
; cuando accedemos a temploArr[i] YA ESTAMOS PARADOS EN temploArr[i].colum_largo, no necesitamos desreferenciar de vuelta.
; mismo si nos queremos mover a colum_corto, le sumamos el desplazamiento a temploArr[i] y luego desreferenciamos para acceder al valor final
; esto funciona porque si estamos parados en temploArr[0] ya accedemos a todos los contenidos del struct, solo tenemos que movernos sin pasarnos del tamanio de un templo. 

; otra: no nos iba a dejar hacer mov r9, [rdi + r8*24] porque no le gusta el *24, entonces hay que calcularlo a manopla y luego sumarlo.

;       temploArr                      
;   ┌────────────────┐                 
;   │ colum_largo    │                 
;   │                │|                
;   │ nombre         │|-> temploArr[0] 
;   │                │|                
;   │ colum_corto    │                 
;   ┼────────────────┤                 
;   │                │                 
;   │                │                 
;   │                │                 
;   │                │                 
;   │                │                 
;   │                │                 
;   │                │                 
;   └────────────────┘                 