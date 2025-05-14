extern malloc

section .rodata
; Acá se pueden poner todas las máscaras y datos que necesiten para el ejercicio

section .text
; Marca un ejercicio como aún no completado (esto hace que no corran sus tests)
FALSE EQU 0
; Marca un ejercicio como hecho
TRUE  EQU 1

; Marca el ejercicio 1A como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - es_indice_ordenado
global EJERCICIO_1A_HECHO
EJERCICIO_1A_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 1B como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - indice_a_inventario
global EJERCICIO_1B_HECHO
EJERCICIO_1B_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

;########### ESTOS SON LOS OFFSETS Y TAMAÑO DE LOS STRUCTS
; Completar las definiciones (serán revisadas por ABI enforcer):
ITEM_NOMBRE EQU 0
ITEM_FUERZA EQU 20
ITEM_DURABILIDAD EQU 24
ITEM_SIZE EQU 28

;; La funcion debe verificar si una vista del inventario está correctamente 
;; ordenada de acuerdo a un criterio (comparador)

;; bool es_indice_ordenado(item_t** inventario, uint16_t* indice, uint16_t tamanio, comparador_t comparador);

;; Dónde:
;; - `inventario`: Un array de punteros a ítems que representa el inventario a
;;   procesar.
;; - `indice`: El arreglo de índices en el inventario que representa la vista.
;; - `tamanio`: El tamaño del inventario (y de la vista).
;; - `comparador`: La función de comparación que a utilizar para verificar el
;;   orden.
;; 
;; Tenga en consideración:
;; - `tamanio` es un valor de 16 bits. La parte alta del registro en dónde viene
;;   como parámetro podría tener basura.
;; - `comparador` es una dirección de memoria a la que se debe saltar (vía `jmp` o
;;   `call`) para comenzar la ejecución de la subrutina en cuestión.
;; - Los tamaños de los arrays `inventario` e `indice` son ambos `tamanio`.
;; - `false` es el valor `0` y `true` es todo valor distinto de `0`.
;; - Importa que los ítems estén ordenados según el comparador. No hay necesidad
;;   de verificar que el orden sea estable.

global es_indice_ordenado
es_indice_ordenado:
	;prólogo
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15
	push rbx
	;preservamos los registros

	mov r12, rdi ;r12 = puntero a inventario
	mov r13, rsi ;r13 = puntero a indice
	mov r14, rcx ;r14 = comparador

	movzx r15, dx ;extendemos tamanio a 64 bits (zero extend)

	mov rbx, 1

.loop:
	cmp rbx, r15
	je .true ;i = tamanio?

	;preparamos los registros rdi y rsi para llamar al comparador
	mov r8, rbx ; r8 = i
	dec r8 ; r8 = i-1
	shl r8, 1 ; r8 = (i-1) * 2bytes (tamaño de datos de indice)
	movzx r9, word [r13 + r8] ;valor de indice[i-1] (tenemos que desreferenciarlo porque si no nos estariamos refiriendo al puntero)
	mov rdi, [r12 + r9 * 8] ;puntero a inventario[indice[i-1]]

	mov r8, rbx
	shl r8, 1 ; r8 = i * 2
	movzx r9, word [r13 + r8]
	mov rsi, [r12 + r9 * 8]

	sub rsp, 8          ;alineamos stack a 16 bytes
	call r14
	add rsp, 8

	cmp rax, 0
	je .false

	inc rbx ; i++
	jmp .loop

.false:
	xor rax, rax        ; return false
	jmp .fin

.true:
	mov rax, 1          ; return true

.fin:
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

;; Dado un inventario y una vista, crear un nuevo inventario que mantenga el
;; orden descrito por la misma.

;; La memoria a solicitar para el nuevo inventario debe poder ser liberada
;; utilizando `free(ptr)`.

;; item_t** indice_a_inventario(item_t** inventario, uint16_t* indice, uint16_t tamanio);

;; Donde:
;; - `inventario` un array de punteros a ítems que representa el inventario a
;;   procesar.
;; - `indice` es el arreglo de índices en el inventario que representa la vista
;;   que vamos a usar para reorganizar el inventario.
;; - `tamanio` es el tamaño del inventario.
;; 
;; Tenga en consideración:
;; - Tanto los elementos de `inventario` como los del resultado son punteros a
;;   `ítems`. Se pide *copiar* estos punteros, **no se deben crear ni clonar
;;   ítems**

global indice_a_inventario
indice_a_inventario:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits o 8 bits.
	;
	; rdi = item_t**  inventario
	; rsi = uint16_t* indice
	; dx = uint16_t  tamanio

	;prólogo
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15
	push rbx

	mov r12, rdi ;inventario
	mov r13, rsi ;indice
	movzx r14, dx ;tamanio

	mov rdi, r14
	shl rdi, 3

	sub rsp, 8
	call malloc ;rax = puntero a resultado
	add rsp, 8

	mov r8, rax

	xor r15, r15
.loop:
	cmp r15, r14
	je .fin

	movzx r9, word [r13]
	mov r9, [r12 + r9*8]

	mov [r8 + r15*8], r9

	add r13, 2 ;movemos el puntero al siguiente dato de indice
	inc r15
	jmp .loop
	
.fin:
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret
