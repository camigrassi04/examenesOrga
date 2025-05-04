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
  ordering_table_t* res = malloc(sizeof(ordering_table_t));
  res->table_size = table_size;
  if(table_size != 0){
    nodo_ot_t** table = calloc(table_size, sizeof(nodo_ot_t*));
    res->table = table;
  }
  else{
    res->table = NULL;
  }
  return res;
}

void calcular_z(nodo_display_list_t* nodo, uint8_t z_size) {
  while(nodo != NULL){
    uint8_t new_z_value = nodo->primitiva(nodo->x, nodo->y, z_size);
    nodo->z = new_z_value;
    nodo = nodo->siguiente;
  }
  return;
}

void ordenar_display_list(ordering_table_t* ot, nodo_display_list_t* display_list) {
  uint8_t table_size = ot->table_size;
  calcular_z(display_list, table_size);
  for(uint8_t i=0; i<table_size; i++){
    nodo_ot_t* ultimo_nodo = NULL;
    nodo_display_list_t* iterador = display_list;
    while(iterador != NULL){
      if(iterador->z == i){
        nodo_ot_t* nuevo_nodo = malloc(sizeof(nodo_ot_t));
        nuevo_nodo->display_element = iterador;
        nuevo_nodo->siguiente = NULL;
        if(ultimo_nodo != NULL){
          ultimo_nodo->siguiente = nuevo_nodo;
        }
        else{
          ot->table[i] = nuevo_nodo;
        }
        ultimo_nodo = nuevo_nodo;
      }

      iterador = iterador->siguiente;
    }
  }
  return;
}
