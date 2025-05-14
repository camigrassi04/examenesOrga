#include "ej1.h"

string_proc_list* string_proc_list_create(void){
	// inicializo una lista doble enlazada con first y last en null
	string_proc_list* lista = malloc(sizeof(string_proc_list));
	lista->first = NULL;
	lista->last = NULL;
	return lista;
}

string_proc_node* string_proc_node_create(uint8_t type, char* hash){
	// creo el nodo
	string_proc_node* nodo = malloc(sizeof(string_proc_node));
	// cuando hago malloc me está reservando espacio para toda la estructura, por lo que puedo establecer los valores sin necesidad de pedir espacio*
	nodo->type = type; // duda: hace falta pedir espacio para este byte antes de escribirlo?
	nodo->hash = hash; // importante: nos pidieron que no sea una copia. entonces solo asigno la referencia que me pasaron
	nodo->next = NULL;
	nodo->previous = NULL;
	return nodo;
}

// * pero si, por ejemplo, una de los valores que pongo es un puntero, ahí sí tengo que hacer espacio para guardar la cosa a la que apunta ese puntero
void string_proc_list_add_node(string_proc_list* list, uint8_t type, char* hash){
	// creo nodo
	string_proc_node* nodo = string_proc_node_create(type, hash);
	if (list->first == NULL){ // el nodo que agregamos es el primero
		list->first = nodo;
		list->last = nodo;
	} else {
        nodo->previous = list->last;
        list->last->next = nodo;
        list->last = nodo;
	}
}

char* string_proc_list_concat(string_proc_list* list, uint8_t type , char* hash){
}


/** AUX FUNCTIONS **/

void string_proc_list_destroy(string_proc_list* list){

	/* borro los nodos: */
	string_proc_node* current_node	= list->first;
	string_proc_node* next_node		= NULL;
	while(current_node != NULL){
		next_node = current_node->next;
		string_proc_node_destroy(current_node);
		current_node	= next_node;
	}
	/*borro la lista:*/
	list->first = NULL;
	list->last  = NULL;
	free(list);
}
void string_proc_node_destroy(string_proc_node* node){
	node->next      = NULL;
	node->previous	= NULL;
	node->hash		= NULL;
	node->type      = 0;			
	free(node);
}


char* str_concat(char* a, char* b) {
	int len1 = strlen(a);
    int len2 = strlen(b);
	int totalLength = len1 + len2;
    char *result = (char *)malloc(totalLength + 1); 
    strcpy(result, a);
    strcat(result, b);
    return result;  
}

void string_proc_list_print(string_proc_list* list, FILE* file){
        uint32_t length = 0;
        string_proc_node* current_node  = list->first;
        while(current_node != NULL){
                length++;
                current_node = current_node->next;
        }
        fprintf( file, "List length: %d\n", length );
		current_node    = list->first;
        while(current_node != NULL){
                fprintf(file, "\tnode hash: %s | type: %d\n", current_node->hash, current_node->type);
                current_node = current_node->next;
        }
}