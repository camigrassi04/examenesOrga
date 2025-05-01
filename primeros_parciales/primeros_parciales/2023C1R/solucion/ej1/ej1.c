#include "ej1.h"

uint32_t* acumuladoPorCliente(uint8_t cantidadDePagos, pago_t* arr_pagos){
    //creo el arreglo de 10 posiciones e inicializo en 0
    uint32_t *clientes = calloc(10, sizeof(uint32_t));
    for (int i= 0; i < cantidadDePagos; i++){
        //nos vamos a fijar en el monto, en el cliente y en aprobado. si está aprobado el pago, buscamos el cliente y en ese indice en el arreglo que nos construimos vamos a sumarle el monto
        if (arr_pagos[i].aprobado == 1){
            uint8_t cliente = arr_pagos[i].cliente;
            uint8_t monto = arr_pagos[i].monto;
            clientes[cliente] += monto;
        }
    }
    return clientes;
}

uint8_t en_blacklist(char* comercio, char** lista_comercios, uint8_t n){
}

pago_t** blacklistComercios(uint8_t cantidad_pagos, pago_t* arr_pagos, char** arr_comercios, uint8_t size_comercios){
}


