#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ej1.h"

/**
 * Marca el ejercicio 1A como hecho (`true`) o pendiente (`false`).
 *
 * Funciones a implementar:
 *   - es_indice_ordenado
 */
bool EJERCICIO_1A_HECHO = true;

/**
 * Marca el ejercicio 1B como hecho (`true`) o pendiente (`false`).
 *
 * Funciones a implementar:
 *   - indice_a_inventario
 */
bool EJERCICIO_1B_HECHO = true;

/**
 * OPCIONAL: implementar en C
 */
bool es_indice_ordenado(item_t** inventario, uint16_t* indice, uint16_t tamanio, comparador_t comparador) {
	//idea es recorrer índices uno a uno y comparar con el siguiente si están ordenados según el comparador hasta terminar de recorrer el inventario
	for (uint8_t i = 1; i < tamanio; i++){
		if (!comparador(inventario[indice[i-1]], inventario[indice[i]])){
			return false;
		}	
	}
	return true;
}

/**
 * OPCIONAL: implementar en C
 */
item_t** indice_a_inventario(item_t** inventario, uint16_t* indice, uint16_t tamanio) {
	item_t** resultado = malloc(tamanio*8);
	for (int i = 0; i < tamanio; i++){
		resultado[i] = inventario[indice[i]];
	}
	return resultado;
}
