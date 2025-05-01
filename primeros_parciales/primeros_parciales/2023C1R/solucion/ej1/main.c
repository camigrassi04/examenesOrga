#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>

#include "ej1.h"

int main (void){
    //caso: 4 personas pagaron, dos están desaprobados
    pago_t *arr_pagos = malloc(sizeof(pago_t)*4);
    arr_pagos[0].monto = 10;
    arr_pagos[0].cliente = 1;
    arr_pagos[0].aprobado = 1;

    arr_pagos[1].monto = 10;
    arr_pagos[1].cliente = 0;
    arr_pagos[1].aprobado = 0;

    arr_pagos[2].monto = 20;
    arr_pagos[2].cliente = 9;
    arr_pagos[2].aprobado = 1;

    arr_pagos[3].monto = 5;
    arr_pagos[3].cliente = 1;
    arr_pagos[3].aprobado = 1;

    uint32_t* res = acumuladoPorCliente(4, arr_pagos);

    //printeo resultado
    for (int i = 0; i<10; i++){
        printf("cliente: %d\nmonto: %d\n\n", i, res[i]);
    }

    //debería retornar todos los clientes en 0, menos: 
    //cliente: 1 monto: 15
    //cliente: 9 monto: 20

    free(arr_pagos);
    free(res);
    return 0;
}


