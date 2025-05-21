#include <stdlib.h>
#include "lista.h"

/**
 * Dada una lista enlazada de proyectos devuelve el `sum` más grande de ésta.
 *
 * - El `sum` más grande de la lista vacía (`NULL`) es 0.
 */
uint32_t proyecto_mas_dificil(lista_t* lista) {
	if (lista == NULL){
		return 0;
	}
	uint32_t puntos = 0;
	while (lista != NULL){
		if (lista->sum > puntos){
			puntos = lista->sum;
		}
		lista = lista->next;
	}
	return puntos;
}

/**
 * Dada una lista enlazada de proyectos y un índice en ésta setea la i-ésima
 * tarea en cero.
 *
 * - La implementación debe "saltearse" a los proyectos sin tareas
 * - Se puede asumir que el índice siempre es válido
 * - Se debe actualizar el `sum` del nodo actualizado de la lista
 */
void marcar_tarea_completada(lista_t* lista, size_t index) {
	size_t ultimo_size = 0;
	while (lista != NULL){
		size_t size_real = ultimo_size+lista->size;
		if (index < size_real){ // index se encuentra dentro del array en el que estamos parados (ni en el anterior, ni en el siguiente)
			size_t index_local = index - ultimo_size;
			uint32_t elem_actual = lista->array[index_local];
			lista->array[index_local] = 0; // limpio el elemento
			lista->sum = lista->sum - elem_actual;// actualizo la suma
			return; // cortamos para no seguir recorriendo las listas
		}
		ultimo_size = size_real;
		lista = lista->next;
	}
	return;
}

/**
 * Dada una lista enlazada devuelve su longitud.
 *
 * - La longitud de `NULL` es 0
 */
uint64_t lista_len(lista_t* lista) {
	uint64_t len = 0;
	while (lista != NULL){
		len++;
		lista = lista->next;
	}
	return len;
}

/**
 * Dado un array de `size` enteros de 32 bits sin signo devuelve la cantidad de
 * ceros en ese array.
 *
 * - Un array de tamaño 0 tiene 0 ceros.
 */
uint64_t tareas_completadas(uint32_t* array, size_t size) {
	uint64_t contador = 0;
	for (size_t i = 0; i < size; i++){
		if (array[i] == 0){
			contador++;
		}
	}
	return contador;
}

/**
 * Dada una lista enlazada de proyectos se devuelve un array que cuenta
 * cuántas tareas completadas tiene cada uno de ellos.
 *
 * - Si se provee a la lista vacía como parámetro (`NULL`) la respuesta puede
 *   ser `NULL` o el resultado de `malloc(0)`
 * - Los proyectos sin tareas tienen cero tareas completadas
 * - Los proyectos sin tareas deben aparecer en el array resultante
 * - Se provee una implementación esqueleto en C si se desea seguir el
 *   esquema implementativo recomendado
 */
uint64_t* tareas_completadas_por_proyecto(lista_t* lista) {
	size_t length = lista_len(lista);
	uint64_t* results = malloc(length * sizeof(uint64_t));
	for (size_t i = 0; i < length; i++) {
		results[i] = tareas_completadas(lista->array, lista->size);
		lista = lista->next;
	}
	return results;
}
