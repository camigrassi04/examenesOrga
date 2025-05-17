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
  
  //creo una tabla con table_size elementos, donde cada uno representa un puntero, por lo que les asigno espacio de 8 bytes.
  //calloc inicializa en 0
  if (table_size != 0){
    nodo_ot_t** table = calloc(table_size, 8);
    OT->table = table;
  } else {
    OT->table = NULL;
  }
  return OT;
}

void calcular_z(nodo_display_list_t* nodo, uint8_t z_size) {
  while(nodo != NULL){
    uint8_t z = nodo->primitiva(nodo->x, nodo->y, z_size);
    nodo->z = z;
    nodo = nodo->siguiente;
  }
  return;
}

void ordenar_display_list(ordering_table_t* ot, nodo_display_list_t* display_list) {
  /*
  ¿qué hace el algoritmo?
    - recorre los nodos de la display list
    - va calculando su z. 
    - su z indica a qué parte de la ot va a parar. la ot está organizada por los z de los nodos de la display list,
    - sin embargo, la ot, para el índice z, apunta a una lista enlazada, que tendrá un primer elemento (un nodo_ot_t) y un último
    - entonces cuando agregamos un nodo de la display list tenemos que, según el z, ver en qué índice de la tabla deberíamos ubicarlo (es decir, en qué lista enlazada) y dónde
  */
  calcular_z(display_list, ot->table_size); //calculamos el z de todos los nodos
  while(display_list != NULL){ //recorremos la lista de nodos display list
    nodo_ot_t* nuevo_nodo = malloc(sizeof(nodo_ot_t)); // pido espacio para un nuevo nodo
    nuevo_nodo->display_element = display_list; 
    nuevo_nodo->siguiente = NULL; // actualizo los campos del nuevo nodo
    // con ot->table[display_list->z] accedemos al valor de la posición z en la tabla
    if (ot->table[display_list->z] == NULL){ //no hay primer elemento
      ot->table[display_list->z] = nuevo_nodo; // como es el primer nodo de la lista enlazada, table[z] deberá apuntar a él.
    } else {
      nodo_ot_t* ultimo = ot->table[display_list->z]; 
      while(ultimo->siguiente != NULL){
        ultimo = ultimo->siguiente; // me posiciono en el último elemento actual (cuyo siguiente es NULL)
      }
      ultimo->siguiente = nuevo_nodo; // actualizo el puntero del nodo anterior al que ahora es el último
    }
    display_list = display_list->siguiente; // avanzo de nodo
  }
  return;
}
