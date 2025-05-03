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
 *   - contarCombustibleAsignado
 */
bool EJERCICIO_1B_HECHO = true;

/**
 * Marca el ejercicio 1B como hecho (`true`) o pendiente (`false`).
 *
 * Funciones a implementar:
 *   - modificarUnidad
 */
bool EJERCICIO_1C_HECHO = true;

/**
 * OPCIONAL: implementar en C
 * 
 *                                                                                    
                                                                                   
            mapa_t                     mapa[i][j]                                  
     ┌──────────────┌──┐            ┌──────────────┐           ┌────────────┐      
     │              │ ─┼──────────► │ attackunit_t*├────────►  │attackunit_t│      
     │              │  │            │              │           │            │      
     ┌──────────────└──┘            └──────────────┘           └────────────┘      
     │                 │                      ▲                                    
     │                 │                      │                                    
     ┌─────────────────┐                      │                                    
     │                 │                      │                                    
     │                 │                      │                                    
     ┌─────────────────┐     ┌────────────┐   │                                    
     │                 │     │            │   │                                    
     │               ──┼───► │ mapa_t[i]  ┼───┘                                    
     └─────────────────┘     └────────────┘                                        
                             attackunit_t**                                        
        ;esta flecha no es un puntero, es lo que es.                                                                
                                                                                   
                                                                                   
 */
void optimizar(mapa_t mapa, attackunit_t* compartida, uint32_t (*fun_hash)(attackunit_t*)) {
    //idea: recorrer todas las posiciones del mapa y buscar que unidades tienen el mismo hash
    //luego, modificar la referencia para que apunte a la compartida, disminuir de la unidad vieja en uno la referencia y aumentar en uno la referencia de la compartida

    uint32_t hash_compartida = fun_hash(compartida);

    for (int i = 0; i < 255; i++){
        for (int j = 0; j < 255; j++){
            //casos borde: si mapa[i][j] == compartida entonces no hago nada
            if (mapa[i][j] == compartida){
                continue;
            }
            //si mapa[i][j] no tiene un puntero a un attackunit
            if (mapa[i][j] == 0){
                continue;
            }

            uint32_t hash_particular = fun_hash(mapa[i][j]);
            if (hash_particular != hash_compartida){
                continue;
            }
            mapa[i][j]->references--;
            if (mapa[i][j]->references == 0){
                free(mapa[i][j]); //importante, podemos liberar solo cuando referencias está en 0
            }
            mapa[i][j] = compartida;
            compartida->references++;
        }
    }
}

/**
 * OPCIONAL: implementar en C
 */
uint32_t contarCombustibleAsignado(mapa_t mapa, uint16_t (*fun_combustible)(char*)) {
    uint32_t acum = 0;
    for (int i = 0; i < 255; i++){
        for (int j = 0; j < 255; j++){
            if (mapa[i][j] == 0){
                continue;
            }
            uint32_t comb_designado = (uint32_t) fun_combustible(mapa[i][j]->clase);
            uint32_t dif = (mapa[i][j]->combustible) - comb_designado;
            acum += dif;
        }   
    }
    return acum;
}

/**
 * OPCIONAL: implementar en C
 */
void modificarUnidad(mapa_t mapa, uint8_t x, uint8_t y, void (*fun_modificar)(attackunit_t*)) {
    attackunit_t* unidad = mapa[x][y];
    if (unidad == NULL){
        return;
    }
    //si la unidad tiene una referencia, la modificamos directamente
    if (unidad->references > 1){
        unidad->references--;
        attackunit_t* nueva_unidad = malloc(sizeof(attackunit_t));
        *nueva_unidad = *unidad;
        nueva_unidad->references = 1;
        mapa[x][y] = nueva_unidad;
    } 
    
    fun_modificar(mapa[x][y]);
}
