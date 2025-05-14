#include "ej1.h"

uint32_t cuantosTemplosClasicos_c(templo *temploArr, size_t temploArr_len){
    uint32_t res = 0;
    for (int i = 0; i < temploArr_len; i++){
        if (temploArr[i].colum_largo == 2*temploArr[i].colum_corto + 1){
            res+=1;
        }
    }
    return res;
}
  
templo* templosClasicos_c(templo *temploArr, size_t temploArr_len){
    uint32_t cant_templos_clasicos = cuantosTemplosClasicos(temploArr, temploArr_len);
    templo* templos_clasicos = malloc(cant_templos_clasicos*24);

    uint32_t indice_siguiente = 0;
    for (int i = 0; i < temploArr_len; i++){
        if (temploArr[i].colum_largo == 2*temploArr[i].colum_corto + 1){
            templos_clasicos[indice_siguiente] = temploArr[i];
            indice_siguiente+=1; 
        }
    }
    return templos_clasicos;
}
