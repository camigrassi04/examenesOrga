#include <stdio.h>    //encabezado de funciones de entrada y salida fopen, fclose, fgetc, printf, fprintf ...
#include <stdlib.h>   //biblioteca estándar, atoi, atof, rand, srand, abort, exit, system, NULL, malloc, calloc, realloc...
#include <stdint.h>   //contiene la definición de tipos enteros ligados a tamaños int8_t, int16_t, uint8_t,...
#include <ctype.h>    //contiene funciones relacionadas a caracteres, isdigit, islower, tolower...
#include <string.h>   //contiene las funciones relacionadas a strings, memcmp, strcat, memset, memmove, strlen,strstr...
#include <math.h>   //define funciones matemáticas como cos, sin, abs, sqrt, log...
#include <stdbool.h>  //contiene las definiciones de datos booleanos, true (1), false (0)
#include <unistd.h>   //define constantes y tipos standard, NULL, R_OK, F_OK, STDIN_FILENO, STDOUT_FILENO, STDERR_FILENO...
#include <assert.h>   //provee la macro assert que evalúa una condición, y si no se cumple provee información diagnóstica y aborta la ejecución

//*************************************
//Declaración de estructuras
//*****
#define USE_ASM_IMPL 1

//cada atributo de un struct esta alineado a su propio tamaño y el struct está alineado al tamaño de su dato más grande
typedef struct pago {
  uint8_t monto; //offset: 0
  char* comercio; //offset: 8 (7 bytes de padding para que esté alineado a 8 porque es el tamaño del dato)
  uint8_t cliente; //offset: 16 
  uint8_t aprobado; //offset: 17 (tanto este como el anterior, como son bytes están alineados a cualquier posición de memoria)
} pago_t; // offset: 24 (porque 18 no es múltiplo de 8, entonces mete padding)

// función toma un arreglo de los pagos que se hicieron y su longitud. Queremos devolver un arreglo con todos los clientes, computando los pagos de ser necesario.
uint32_t* acumuladoPorCliente(uint8_t cantidadDePagos, pago_t* arr_pagos);
uint32_t* acumuladoPorCliente_asm(uint8_t cantidadDePagos, pago_t* arr_pagos);

uint8_t en_blacklist(char* comercio, char** lista_comercios, uint8_t n);
uint8_t en_blacklist_asm(char* comercio, char** lista_comercios, uint8_t n);
pago_t** blacklistComercios(uint8_t cantidad_pagos, pago_t* arr_pagos, char** arr_comercios, uint8_t size_comercios);
pago_t** blacklistComercios_asm(uint8_t cantidad_pagos, pago_t* arr_pagos, char** arr_comercios, uint8_t size_comercios);
