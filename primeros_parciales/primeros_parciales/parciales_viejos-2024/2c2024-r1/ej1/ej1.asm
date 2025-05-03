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
	; sil  = uint8_t          x
	; dil  = uint8_t          y
	; rcx = void*            fun_modificar(attackunit_t*)

	; prologo
	push rbp
	mov rbp, rsp

	push r12
	push r13
	push r14
	push r15
	push rbx

	mov r12, rdi ; mapa
	movzx r13, sil ; x
	movzx r14, dil ; y
	mov r15, rcx ; fun_modificar

	;mov r8, [r12]
	;cmp r8, 0
	;je .fin
	
	mov r8, r13 ; copio r13 en un registro auxiliar
	imul r8, COLUMNAS ; x * COLUMNAS

	mov r9, r14 ; r9 = y
	add r9, r8

	imul r9, 8 ; 8*(255*x + y)
	add r12, r9

	cmp [r12], 0
	je .fin ; mapa[x][y] == null?

	mov r8, [rbx + ATTACKUNIT_REFERENCES] ; mapa[x][y]->references
	cmp r8, 1
	je .funcion

	dec r8
	mov rdi, ATTACKUNIT_SIZE

	sub rsp, 8
	call malloc ; rax = puntero a nueva_unidad
	add rsp, 8

	mov [rax], [r12] ; *nueva_unidad = *unidad;
	mov [rax + ATTACKUNIT_REFERENCES], BYTE 1 ; nueva_unidad->references = 1
	mov [r12], rax ; mapa[x][y] = nueva_unidad

.funcion:
	mov rdi, rbx
	sub rsp, 8
	call r15
	add rsp, 8

.fin:
	; epilogo
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
                                                                   