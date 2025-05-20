global acumuladoPorCliente_asm
global en_blacklist_asm
global blacklistComercios_asm

extern malloc
extern calloc
extern strcmp

%define CANTIDAD_DE_CLIENTES 10
%define SIZE_OF_UINT32 4 
;son 32 bits, es decir, 4 bytes.

;########### SECCION DE TEXTO (PROGRAMA)
section .text

PAGO_T_MONTO EQU 0
PAGO_T_COMERCIO EQU 8
PAGO_T_CLIENTE EQU 16
PAGO_T_APROBADO EQU 17
PAGO_T_SIZE EQU 24

; cantidadDePagos -> dil
; arr_pagos -> rsi
acumuladoPorCliente_asm:
	push rbp
	mov rbp, rsp
	push r12
	push r13

	movzx r12, dil ; cantidadDePagos
	mov r13, rsi ; arr_pagos
	
	mov rdi, 10
	mov rsi, 4
	call calloc ; array de 10 posiciones de 4 bytes c/u (estructura ocupa 40 bytes)

	xor r8, r8 ; i = 0

	.for:
	cmp r8, r12 ; i == cantidadDePagos ?
	je .fin

	mov r9, r8 ; r9 = i
	imul r9, PAGO_T_SIZE ; i * 24
	add r9, r13 ; r9 = &arr_pagos[i]

	cmp byte [r9 + PAGO_T_APROBADO], 0
	je .incrementar

	movzx r10, byte [r9 + PAGO_T_CLIENTE] ; uint8_t cliente = pago.cliente
	shl r10, 2 ; cliente * 4 (tamanio dato de pagos_aprobados_por_cliente)
	add r10, rax ; r10 = &pagos_aprobados_por_cliente[cliente]
	
	movzx r11, byte [r9 + PAGO_T_MONTO] ; pago.monto
	add dword [r10], r11d ; pagos_aprobados_por_cliente[cliente] += pago.monto (necesario el dword porque el tamaño del dato del arreglo es de 32 bits, 4 bytes)

	.incrementar:
	inc r8
	jmp .for


	.fin:
	pop r13
	pop r12
	pop rbp
	ret

en_blacklist_asm:
; rdi = comercio
; rsi = lista_comercios
; dl = n
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15
	push rbx
	sub rsp, 8

	mov r12, rdi ; r12 = comercio
	mov r13, rsi ; r13 = lista_comercios
	movzx r14, dl ; r14 = n

	xor r15, r15 ; i = 0

	.for:
	cmp r15, r14
	je .no_esta_en_blacklist

	mov r9, r15 ; r9 = i
	imul r9, 8 ; i * 8
	add r9, r13 ; &lista_comercios[i]
	mov rdi, [r9] ; rdi = lista_comercios[i]

	mov rsi, r12 ; rsi = comercio
	call strcmp
	cmp rax, 0
	jne .avanzar

	jmp .esta_en_blacklist

	.esta_en_blacklist:
	mov rax, 1
	jmp .fin

	.avanzar:
	inc r15
	jmp .for

	.no_esta_en_blacklist:
	xor rax, rax
	.fin:
	add rsp, 8
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

blacklistComercios_asm:
; dil = cantidad_pagos
; rsi = arr_pagos
; rdx = arr_comercios
; cl = size_comercios
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15
	push rbx
	sub rsp, 8

	movzx r12, dil ; r12 = cantidad_pagos
	mov r13, rsi ; r13 = arr_pagos
	mov r14, rdx ; r14 = arr_comercios
	movzx r15, cl ; r15 = size_comercios

	; primera parte: contar #comercios en blacklist

	xor rbx, rbx ; rbx = cant_pagos_res
	xor r9, r9 ; i = 0
	.for:
	cmp r9, r12 ; i == cantidad_pagos ?
	je .armar_array_pagos

	mov r8, r9 ; r8 = i
	imul r8, 24 ; i * 24
	add r8, r13 ; &arr_pagos[i]
	mov r8, [r8 + 8] ; arr_pagos[i].comercio

	mov rdi, r8 ; rdi = comercio
	mov rsi, r14 ; rsi = arr_comercios
	mov dl, r15b ; dl = size_comercios
	push r9
	call en_blacklist_asm
	pop r9

	cmp al, 0
	je .incrementar_i

	inc rbx ; cant_pagos_res++

	.incrementar_i:
	inc r9
	jmp .for

	.armar_array_pagos:
	; segunda parte: armar el array que devolveremos
	
	mov rdi, rbx ; rdi = cant_pagos_res
	shl rdi, 3
	call malloc ; rax = pagos_res
	mov rbx, rax
	
	xor r9, r9 ; r9 = ultimo_agregado

	xor r8, r8 ; r8 = i
	
	.for2:
	cmp r8, r12 ; i == cantidad_pagos ?
	je .fin

	mov r10, r8 ; r10 = i
	imul r10, 24 ; i * 24
	add r10, r13 ; &arr_pagos[i]
	mov rdi, [r10 + 8] ; arr_pagos[i].comercio

	mov rsi, r14
	mov dl, r15b
	push r8 ; preservo i antes de llamar a función
	push r9
	call en_blacklist_asm
	pop r9
	pop r8
	cmp al, 0
	je .avanzar_i

	mov r10, r8
	imul r10, 24
	add r10, r13 ; &arr_pagos[i]

	mov r11, r9
	shl r11, 3 ; ultimo_agregado * 8
	mov [rbx + r11], r10 ; pagos_res[ultimo_agregado] = &arr_pagos[i]

	inc r9 ; ultimo_agregado++

	.avanzar_i:
	inc r8
	jmp .for2
	
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
