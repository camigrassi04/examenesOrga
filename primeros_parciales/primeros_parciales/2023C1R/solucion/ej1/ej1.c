#include "ej1.h"

uint32_t* acumuladoPorCliente(uint8_t cantidadDePagos, pago_t* arr_pagos){
    uint32_t* pagos_aprobados_por_cliente = calloc(10, sizeof(uint32_t));
    for (int i = 0; i < cantidadDePagos; i++){
        pago_t pago = arr_pagos[i];
        if (pago.aprobado){
            uint8_t cliente = pago.cliente;
            pagos_aprobados_por_cliente[cliente] += pago.monto;
        }
    }
    return pagos_aprobados_por_cliente;
}

uint8_t en_blacklist(char* comercio, char** lista_comercios, uint8_t n){
    for (int i = 0; i < n; i++){
        char* comercio1 = lista_comercios[i];
        if (strcmp(comercio1, comercio) == 0){
            return 1;
        }
    }
    return 0;
}

pago_t** blacklistComercios(uint8_t cantidad_pagos, pago_t* arr_pagos, char** arr_comercios, uint8_t size_comercios){
    // primero vemos la cantidad de pagos tal que su comercio se encuentra blacklisteado
    uint8_t cant_pagos_res = 0;
    for (int i = 0; i < cantidad_pagos; i++){
        pago_t pago = arr_pagos[i];
        char* comercio = pago.comercio;
        if (en_blacklist(comercio, arr_comercios, size_comercios)){
            cant_pagos_res++;
        }
    }
    // ahora armo el array de punteros a los pagos y agrego los pagos
    pago_t** pagos_res = malloc(cant_pagos_res*24);
    uint8_t ultimo_agregado = 0;
    for (int i = 0; i < cantidad_pagos; i++){
        pago_t pago = arr_pagos[i];
        char* comercio = pago.comercio;
        if (en_blacklist(comercio, arr_comercios, size_comercios)){
            pagos_res[ultimo_agregado] = &arr_pagos[i];
            ultimo_agregado++;
        }
    }
    return pagos_res;
}


