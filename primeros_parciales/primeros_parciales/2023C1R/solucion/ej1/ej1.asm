global acumuladoPorCliente_asm
global en_blacklist_asm
global blacklistComercios_asm

%define CANTIDAD_DE_CLIENTES 10
%define SIZE_OF_UINT32 4 
;son 32 bits, es decir, 4 bytes.

;########### SECCION DE TEXTO (PROGRAMA)
section .text

; cantidadDePagos -> dl
; arr_pagos -> rsi
acumuladoPorCliente_asm:
	;prólogo
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14

	;guardo dl y rsi en r12 y r13 así los preservo
	xor r12, r12
	mov r12b, dl
	mov r13, rsi

	;ahora, queremos hacer un call a calloc, preparamos los registros
	mov rdi, CANTIDAD_DE_CLIENTES
	mov rsi, SIZE_OF_UINT32
	call calloc ;en rax se guarda el puntero al array clientes

	mov r14, rax ;ahora en r14 tenemos el puntero al array

	.ciclo:
	;si ya terminamos de recorrer el arreglo que nos pasaron, saltamos a fin
	cmp r12b, 0
	je .fin

	

	jmp ciclo


	.fin:
	;epílogo
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

en_blacklist_asm:
	ret

blacklistComercios_asm:
	ret
