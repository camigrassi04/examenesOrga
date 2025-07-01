> 1 página = 4KB   
> 1MB = 1000KB   
> 1000KB / 4KB = 250 páginas   
> (Estos son cálculos con mb y kb)

a) Al esquema de memoria virtual del tp le agregamos, debajo de la sección de memoria compartida, 1 mega para los datos de la tarea, esto será 256 páginas. Arranca en la `0x08004000` y termina en la `0x08104000`.   
Esto se encontrará mapeado a las direcciones físicas de `0x400000` a `0x2FFFFFF`, que se corresponde a la memoria de las tareas donde almacenar datos y pila. 

b) Definimos una syscall que permita a la tarea maliciosa copiar alguna página de la tarea deseada. 
Para eso, definimos una entrada en la IDT:
```c
void idt_init() {
    ...
    IDT_ENTRY3(80);
}
```
La declaramos en `isr.h`.   
Definimos la rutina de atención de la interrupción en `isr.asm`:   
*Nos pasan los parámetros por EDI (ID tarea) y en ESI la dirección de la memoria virtual*
```nasm
global _isr80
_isr80:
    pushad

    push edi
    push esi
    call copiar_pagina
    add esp, 8

    popad
    iret
```

*Asumimos que la dirección física en la que la tarea maliciosa debe copiar la página se define en un `PADDR_COPY_HERE`, que será establecido al crearse la tarea (`create_task`).*
```c
void copiar_pagina(vaddr_t dir_virt, uint8_t id_tarea) {
    if (current_task == 1){ // es la tarea maliciosa, copia    
        paddr_t dir_fisica = obtener_dir_fisica(dir_virt, id_tarea); // obtenemos la dirección física correspondiente a la dirección virtual que queremos copiar 
        if (dir_fisica == 0) return; // si no tiene dirección física mapeada, no podemos hacer nada
        copy_page(PADDR_COPY_HERE, dir_fisica); // copiamos el contenido de dir_fisica a PADDR_COPY_HERE
        mmu_map_page(rcr3(), dir_virt, PADDR_COPY_HERE, (MMU_P | MMU_W | MMU_U)); // mapeamos la dirección virtual `dir_virt` a PADDR_COPY_HERE
    }
}
```
Definimos la función auxiliar `obtener_dir_fisica`:
```c
paddr_t obtener_dir_fisica(vaddr_t dir_virt, uint8_t id_tarea) {
    tss_t* tss = gdt[sched_tasks[id_tarea].segmento >> 3].base;
    uint32_t cr3 = tss->cr3;
    pd_entry_t* pd = (pd_entry_t*)CR3_TO_PAGE_DIR(cr3); // Directorio de páginas
    int pdi = VIRT_PAGE_DIR(virt); // Índice del directorio de páginas
    if (!(pd[pdi].attrs & MMU_P)) { // Si la página no está mapeada, devolvemos 0
        return 0;
    }

    pt_entry_t* pt = (pt_entry_t*)MMU_ENTRY_PADDR(pd[pdi].pt); // Tabla de páginas
    int pti = VIRT_PAGE_TABLE(virt); // Índice de la tabla de páginas
    if (!(pt[pti].attrs & MMU_P)) { // Si la página no está mapeada, devolvemos 0
        return 0;
    }

    paddr_t direccion_fisica = MMU_ENTRY_PADDR(pt[pti].page); // Dirección física de la base de la página
    // Devolvemos la dirección base de la página (sin el offset)
    return direccion_fisica;
}
```

c) No, no debemos modificar la interrupción de reloj ya que el servicio en ese sentido es igual al tp. Todas las tareas se ejecutan con normalidad y, si la tarea maliciosa (con id = 1) decide robar información a otras tareas, deberá ella misma llamar a una syscall y la misma interrupción se encargará de hacer la copia. 