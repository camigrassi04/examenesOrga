#include "ej1.h"

nodo_display_list_t* inicializar_nodo(
  uint8_t (*primitiva)(uint8_t x, uint8_t y, uint8_t z_size),
  uint8_t x, uint8_t y, nodo_display_list_t* siguiente) {
    nodo_display_list_t* nodo = malloc(sizeof(nodo_display_list_t));
    nodo->primitiva = primitiva;
    nodo->x = x;
    nodo->y = y;
    nodo->z = 255;
    nodo->siguiente = siguiente;
    return nodo;
}

ordering_table_t* inicializar_OT(uint8_t table_size) {
  ordering_table_t* OT = malloc(sizeof(ordering_table_t));
  OT->table_size = table_size;
  if (table_size == 0){
    OT->table = NULL;
  } else {
    nodo_ot_t** table = calloc(table_size, sizeof(nodo_ot_t*));
    OT->table = table;
  }
  return OT;
}

void calcular_z(nodo_display_list_t* nodo, uint8_t z_size) {
  if (nodo == NULL){
    return;
  }
  uint8_t z = nodo->primitiva(nodo->x, nodo->y, z_size);
  nodo->z = z;
  return;
}

void ordenar_display_list(ordering_table_t* ot, nodo_display_list_t* display_list) {
  if (ot->table_size == 0) return;
  while(display_list != NULL){ // recorro la lista de nodos
    calcular_z(display_list, ot->table_size); // calculo z del nodo
    // ot es un array de punteros a nodo_ot_t
    uint8_t i = display_list->z; 
    nodo_ot_t* nodo = malloc(sizeof(nodo_ot_t));
    nodo->display_element = display_list;
    nodo->siguiente = NULL;
    if (ot->table[i] == NULL){ // no hay primer nodo
      ot->table[i] = nodo; // table[i] apunta a un nodo_ot_t
    } else {
      nodo_ot_t* ultimo = ot->table[i];
      while (ultimo->siguiente != NULL){ // busco el último actual
        ultimo = ultimo->siguiente;
      }
      ultimo->siguiente = nodo;
    } 
    display_list = display_list->siguiente;
  }
  return;
}
