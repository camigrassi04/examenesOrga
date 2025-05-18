#include "ej1.h"

list_t* listNew(){
  list_t* l = (list_t*) malloc(sizeof(list_t));
  l->first=NULL;
  l->last=NULL;
  return l;
}

void listAddLast(list_t* pList, pago_t* data){
    listElem_t* new_elem= (listElem_t*) malloc(sizeof(listElem_t));
    new_elem->data=data;
    new_elem->next=NULL;
    new_elem->prev=NULL;
    if(pList->first==NULL){
        pList->first=new_elem;
        pList->last=new_elem;
    } else {
        pList->last->next=new_elem;
        new_elem->prev=pList->last;
        pList->last=new_elem;
    }
}


void listDelete(list_t* pList){
    listElem_t* actual= (pList->first);
    listElem_t* next;
    while(actual != NULL){
        next=actual->next;
        free(actual);
        actual=next;
    }
    free(pList);
}

uint8_t contar_pagos_aprobados(list_t* pList, char* usuario){
    uint8_t res = 0;
    if (pList != NULL){
        listElem_t* nodo = pList->first;
        while (nodo != NULL){
            if (strcmp(nodo->data->cobrador, usuario) == 0 && nodo->data->aprobado == 1){
                res++;
            }
            nodo = nodo->next;
        }
    }
    return res;
}

uint8_t contar_pagos_rechazados(list_t* pList, char* usuario){
    uint8_t res = 0;
    if (pList != NULL){
        listElem_t* nodo = pList->first;
        while (nodo != NULL){
            if (strcmp(nodo->data->cobrador, usuario) == 0 && nodo->data->aprobado == 0){
                res++;
            }
            nodo = nodo->next;
        }
    }
    return res;
}

pagoSplitted_t* split_pagos_usuario(list_t* pList, char* usuario){
    pagoSplitted_t* res = malloc(sizeof(pagoSplitted_t));
    res->cant_aprobados = contar_pagos_aprobados(pList, usuario);
    res->cant_rechazados = contar_pagos_rechazados(pList, usuario);
    res->aprobados = malloc((res->cant_aprobados)*8); 
    res->rechazados = malloc((res->cant_rechazados)*8); 

    if (pList != NULL){
        listElem_t* nodo = pList->first;
        uint8_t ultimo_aprobado = 0;
        uint8_t ultimo_rechazado = 0;
        while (nodo != NULL){
            if (strcmp(nodo->data->cobrador, usuario) == 0){
                if (nodo->data->aprobado == 1){
                    res->aprobados[ultimo_aprobado] = nodo;
                    ultimo_aprobado++;
                }
                if (nodo->data->aprobado == 0){
                    res->rechazados[ultimo_rechazado] = nodo;
                    ultimo_rechazado++;
                }
            }
            nodo = nodo->next;
        }
    }
    return res;
}