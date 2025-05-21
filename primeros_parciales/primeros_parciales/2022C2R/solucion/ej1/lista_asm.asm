extern malloc

%define OFFSET_NEXT  0
%define OFFSET_SUM   8
%define OFFSET_SIZE  16
%define OFFSET_ARRAY 24
%define OFFSET_LISTAT_SIZE 32

BITS 64

section .text


; uint32_t proyecto_mas_dificil(lista_t*)
;
; Dada una lista enlazada de proyectos devuelve el `sum` más grande de ésta.
;
; - El `sum` más grande de la lista vacía (`NULL`) es 0.
;
global proyecto_mas_dificil
proyecto_mas_dificil:
; rdi = lista
	push rbp
	mov rbp, rsp

	xor rax, rax ; puntos = 0
	
	cmp rdi, 0 ; lista == NULL ?
	je .fin

	.while:
	cmp rdi, 0 ; lista == NULL ?
	je .fin

	cmp dword [rdi + OFFSET_SUM], eax
	jle .avanzar

	mov rax, [rdi + OFFSET_SUM]
	
	.avanzar:
	mov rdi, [rdi + OFFSET_NEXT]
	jmp .while

	.fin:
	pop rbp
	ret

; void tarea_completada(lista_t*, size_t)
;
; Dada una lista enlazada de proyectos y un índice en ésta setea la i-ésima
; tarea en cero.
;
; - La implementación debe "saltearse" a los proyectos sin tareas
; - Se puede asumir que el índice siempre es válido
; - Se debe actualizar el `sum` del nodo actualizado de la lista
;
global marcar_tarea_completada
marcar_tarea_completada:
; rdi = lista
; rsi = index

	push rbp
	mov rbp, rsp

	xor r8, r8 ; r8 = ultimo_size
	xor r9, r9 ; r9 = size_real 
	.while:
	cmp rdi, 0
	je .fin

	add r9, [rdi + OFFSET_SIZE]
	cmp rsi, r9 ; index == size_real ?
	jge .avanzar

	; calculo index local
	mov r10, rsi
	sub r10, r8
	shl r10, 2 ; index_local * 4
	mov r11, [rdi + OFFSET_ARRAY] ; &array[0]
	add r11, r10 ; &array[index_local]

	mov r10d, dword [r11] ; elem_actual
	mov ecx, dword [rdi + OFFSET_SUM]
	sub ecx, r10d
	mov dword [rdi + OFFSET_SUM], ecx ; lista->sum = lista->sum - elem_actual;
	mov dword [r11], 0 ; lista->array[index_local] = 0

	jmp .fin

	.avanzar:
	mov r8, r9
	mov rdi, [rdi + OFFSET_NEXT]
	jmp .while
	
	.fin:
	pop rbp
	ret

; uint64_t* tareas_completadas_por_proyecto(lista_t*)
;
; Dada una lista enlazada de proyectos se devuelve un array que cuenta
; cuántas tareas completadas tiene cada uno de ellos.
;
; - Si se provee a la lista vacía como parámetro (`NULL`) la respuesta puede
;   ser `NULL` o el resultado de `malloc(0)`
; - Los proyectos sin tareas tienen cero tareas completadas
; - Los proyectos sin tareas deben aparecer en el array resultante
; - Se provee una implementación esqueleto en C si se desea seguir el
;   esquema implementativo recomendado
;
global tareas_completadas_por_proyecto
tareas_completadas_por_proyecto:
; rdi = lista
	push rbp
	mov rbp, rsp

	push r12
	push r13
	push r14
	push r15

	mov r12, rdi ; r12 = lista

	call lista_len ; rax = length
	mov r13, rax ; r13 = length

	mov rdi, r13
	shl rdi, 3 ; length * sizeof(uint64_t)
	call malloc ; rax = results
	mov r14, rax ; r14 = results

	xor r15, r15 ; i = 0
	.for:
	cmp r15, r13
	je .fin

	mov rdi, [r12 + OFFSET_ARRAY] ; rdi = lista->array
	mov rsi, [r12 + OFFSET_SIZE]
	call tareas_completadas
	
	mov r8, r15
	shl r8, 3
	mov [r14 + r8], rax ; results[i] = tareas_completadas(lista->array, lista->size)
	mov r12, [r12 + OFFSET_NEXT]
	inc r15
	jmp .for

	.fin:
	mov rax, r14
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

; uint64_t lista_len(lista_t* lista)
;
; Dada una lista enlazada devuelve su longitud.
;
; - La longitud de `NULL` es 0
;
lista_len:
; rdi = lista
	push rbp
	mov rbp, rsp

	xor rax, rax
	.while:
	cmp rdi, 0
	je .fin

	inc rax
	mov rdi, [rdi + OFFSET_NEXT]
	jmp .while

	.fin:
	pop rbp
	ret

; uint64_t tareas_completadas(uint32_t* array, size_t size) {
;
; Dado un array de `size` enteros de 32 bits sin signo devuelve la cantidad de
; ceros en ese array.
;
; - Un array de tamaño 0 tiene 0 ceros.
tareas_completadas:
; rdi = array
; rsi = size
	push rbp
	mov rbp, rsp

	xor rax, rax
	xor r8, r8 ; i = 0
	.for:
	cmp r8, rsi
	je .fin

	mov r9, r8
	shl r9, 2 ; i * 4
	mov r9d, [rdi + r9] ; array[i]
	cmp r9d, 0
	jne .avanzar

	inc rax ; contador++
	.avanzar:
	inc r8
	jmp .for

	.fin:
	pop rbp
	ret
