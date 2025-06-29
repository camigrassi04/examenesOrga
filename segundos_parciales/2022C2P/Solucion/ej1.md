# ESTO ESTÁ MAL
Nos piden definir una *syscall*.
Para eso, debemos agregar una entrada a la IDT. 
En `idt.c`:
```C
void idt_init(){
    ...
    IDT_ENTRY3(100);
}
```
Será una entrada de tipo 3 ya que cualquier tarea de nivel de usuario debe poder llamarla. 

Luego, la declaramos en `idt.h`:
```h
void _isr100();
```

b) Ahora, escribimos la rutina de atención de interrupción en `isr.asm`:

*Asumo que los parámetros le llegan de la siguiente forma:*
*- edi → virt*
*- esi → phy*
*- dx → task_sel*
```nasm
global _isr100
_isr100:
    pushad

    push edi
    push esi
    push dx
    push esp ; le pasamos el esp de nivel 0 (ya que el de la tss no está actualizado)
    call XXXX ; handler en C
    add esp, 14 ; restauro stack

    popad
    iret
```

```C
void XXXX(uint32_t esp, uint16_t task_sel, uint32_t phy, uint32_t virt) {
    // realizamos los mapeos
    uint32_t cr3_tarea_actual = rcr3();
    uint32_t cr3_tarea_parametro = obtener_cr3(task_sel);
    mmu_map_page(cr3_tarea_actual, virt, phy, MMU_P | MMU_U); // mapeo tarea actual
    mmu_map_page(cr3_tarea_parametro, virt, phy, MMU_P | MMU_U); // mapeo tarea pasada por parámetro

    // modificamos campos de la tarea pasada por parámetro para que cuando se ejecute retome en virt
    modificar_eip_tss(task_sel, virt); // modificamos el valor de eip en la tss para que luego la tarea retome de ahi
    
    // modificamos valor del eip en el stack de la tarea para que luego de la interrupción se retome desde virt
    modificar_eip_pila(esp, virt);
}
```

```C
uint32_t obtener_cr3(uint16_t task_sel) {
    tss_t* tss = obtener_tss(task_sel);
    return tss->cr3; 
}
```

```C
tss_t* obtener_tss(uint16_t task_sel){
    uint16_t idx = task_sel >> 3;
    return gdt[idx].base;
}
```

```C
void modificar_eip_tss(uint16_t task_sel, uint32_t virt) {
    tss_t* tss = obtener_tss(task_sel);
    tss->eip = virt;
}
```

```C
void modificar_eip_pila(uint32_t esp, uint32_t virt) { 
    esp[9] = virt; // pila[9] = eip_3
}
```
---
Conclusiones del ejercicio:
- *¿cuál es el eip que busca el scheduler para saber la instrucción desde la cual retoma la tarea?* 
    - Si la tarea no está en ejecución, el eip que nos interesa es el de la tss (ya que es la siguiente instrucción que iba a ejecutarse, pero antes se hizo el jmp far).
    - Si la tarea está en ejecución, el eip que nos interesa es el que se encuentra en la pila (el que se restaura con iret), ya que es la dirección que se guardó al arrancar la interrupción. 

- El esp de la tss de la tarea actual no va a estar actualizado, por eso tenemos que pasar el esp como parámetro en el handler. 

>⚠️ En la primer versión que hicimos, hacíamos esto:
> ```C
> void modificar_eip_tss(uint16_t task_sel, uint32_t virt) {
>    tss_t* tss = obtener_tss(task_sel);
>    tss->eip = virt;
>}
>```
>
> Eso está incompleto, porque sólo estamos cambiando el puntero a la próxima instrucción, pero no estamos teniendo en cuenta que tenemos que resetear las pilas (la base del stack nivel 0 y nivel 3) y los selectores de segmento. 

#### Si quiero cambiar el EIP de una tarea que no está en ejecución, cómo tengo que hacerlo?
