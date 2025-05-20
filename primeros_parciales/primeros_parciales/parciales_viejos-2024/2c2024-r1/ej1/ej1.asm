extern malloc
extern free

section .rodata
; Acá se pueden poner todas las máscaras y datos que necesiten para el ejercicio

section .text
; Marca un ejercicio como aún no completado (esto hace que no corran sus tests)
FALSE EQU 0
; Marca un ejercicio como hecho
TRUE  EQU 1

FILAS EQU 255

COLUMNAS EQU 255

; Marca el ejercicio 1A como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - optimizar
global EJERCICIO_1A_HECHO
EJERCICIO_1A_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 1B como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - contarCombustibleAsignado
global EJERCICIO_1B_HECHO
EJERCICIO_1B_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 1C como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - modificarUnidad
global EJERCICIO_1C_HECHO
EJERCICIO_1C_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

;########### ESTOS SON LOS OFFSETS Y TAMAÑO DE LOS STRUCTS
; Completar las definiciones (serán revisadas por ABI enforcer):
ATTACKUNIT_CLASE EQU 0
ATTACKUNIT_COMBUSTIBLE EQU 12
ATTACKUNIT_REFERENCES EQU 14
ATTACKUNIT_SIZE EQU 16

global optimizar
optimizar:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits o 8 bits.
	;
	; rdi = mapa_t           mapa
	; rsi = attackunit_t*    compartida
	; rdx = uint32_t*        fun_hash(attackunit_t*)

	; prólogo
	push rbp
	mov rbp, rsp

	; preservo registros no volátiles
	push r12
	push r13
	push r14
	push r15
	push rbx

	; preservo parámetros de la función
	mov r12, rdi ; mapa_t
	; en rdi voy a tener mapa_t[0][0]
	mov r13, rsi ; compartida
	mov r14, rdx ; funhash

	mov rdi, r13
	sub rsp, 8
	call r14 ; eax = hash_compartida

	mov r15d, eax ; preservo hash_compartida en un registro no volatil

	xor rbx, rbx ; i = 0

.loop:
	cmp rbx, FILAS * COLUMNAS
	je .fin

	mov rdi, [r12] ;attackunit_t* (mapa[i][j])

	cmp rdi, 0 ; rdi == null pointer?
	je .next_iteration

	cmp rdi, r13
	je .next_iteration

	call r14 ; eax = fun_hash(mapa[i][j])

	cmp r15d, eax ; hash_actual == hash_compartida?
	jne .next_iteration

	mov rdi, [r12]
	dec BYTE [rdi + ATTACKUNIT_REFERENCES] ; mapa[i][j]->references--
	inc BYTE [r13 + ATTACKUNIT_REFERENCES] ; compartida->references++
	mov [r12], r13 ; mapa[i][j] = compartida

	cmp BYTE [rdi + ATTACKUNIT_REFERENCES], 0
	jne .next_iteration

	call free

.next_iteration:
	inc rbx
	add r12, 8
	jmp .loop

.fin:
	; epílogo
	add rsp, 8
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

global contarCombustibleAsignado
contarCombustibleAsignado:
	; rdi = mapa_t           mapa
	; rsi = uint16_t*        fun_combustible(char*)

	; prologo
	push rbp
	mov rbp, rsp

	push r12
	push r13
	push r14
	push r15
	push rbx

	mov r12, rdi
	mov r13, rsi

	xor rbx, rbx ; i
	xor r15, r15 ; acum (r15d)

.loop:
	cmp rbx, FILAS * COLUMNAS
	je .fin

	mov rdi, [r12] ; mapa[i][j]
	cmp rdi, 0
	je .next_iteration ; mapa[i][j] == 0 -> continue

	sub rsp, 8
	call r13 ; ax = comb_designado
	add rsp, 8

	movzx r8d, ax ; (uint32_t) comb_designado
	mov rdi, [r12]
	movzx r9d, WORD [rdi + ATTACKUNIT_COMBUSTIBLE] ; mapa[i][j]->combustible
	sub r9d, r8d
	add r15d, r9d


.next_iteration:
	inc rbx
	add r12, 8
	jmp .loop

.fin:
	; epilogo
	mov eax, r15d
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

global modificarUnidad
modificarUnidad:
	; rdi = mapa_t           mapa
	; sil  = uint8_t         x
	; dl  = uint8_t          y
	; rcx = void*            fun_modificar(attackunit_t*)

	; prologo
	push rbp
	mov rbp, rsp

	push r12
	push r13
	push r14
	push r15
	push rbx
	sub rsp, 8

	mov r12, rdi ; r12 = mapa es un array de arrays de punteros a attackunits
	movzx r13, sil ; r13 = x
	movzx r14, dl ; r14 = y
	mov r15, rcx ; r15 = fun_modificar

	mov r8, r13 ; r8 = x
	imul r8, 255 ; multiplico el x por la # columnas
	add r8, r14 ; 255x + y
	shl r8, 3 ; 8*(255x + y) (multiplico por el tamaño del dato de la celda)

	add r8, r12
	mov rbx, r8 ; &mapa[x][y]

	cmp rbx, 0
	je .fin

	mov r9, [rbx]
	movzx r8, byte [r9 + ATTACKUNIT_REFERENCES]
	cmp r8, 1 ; unidad->references == 1 ?
	jle .fin

	dec byte [r9 + ATTACKUNIT_REFERENCES] ; unidad->references--
	
	mov rdi, ATTACKUNIT_SIZE
	call malloc ; rax = nueva_unidad

	mov r9, [rbx] ; mapa[x][y]
	mov r8, [r9] ; r8 = primeros 8 bytes de attackunit
	mov r10, [r9 + 8] ; r10 = segundos 8 bytes de attackunit 
	mov [rax], r8 ; *nueva_unidad = *unidad
	mov [rax + 8], r10
	mov byte [rax + ATTACKUNIT_REFERENCES], 1 ; nueva_unidad->references = 1
	mov [rbx], rax ; mapa[x][y] = nueva_unidad

.fin:
	mov rdi, [rbx]
	call r15 

	; epilogo
	add rsp, 8
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

                                                                   
;          mapa_t : attackunit_t**                                   
;    ┌──────────────────────────────┐                                
;    │x x x x x x ................. ┼─► 255 columnas                 
;    │                              │   tamaño de c/celda: 8 bytes   
;    │                              │                                
;    └──────────────────────────────┘                                
;    ej: mapa[2][3]                                                  
;    para ubicarnos en toda la tercera fila y luego                  
;    irnos a la 4ta columna, tendríamos que multiplicar x            
;    por 255 (#columnas). después le sumamos el y                    
;    (desplazamiento en la fila) y multiplicamos todo por            
;    el tamaño del dato de las celdas.                               
                                                                   
;    nos queda: dirección_base + 8*(255*x + y)                       
                                                                   