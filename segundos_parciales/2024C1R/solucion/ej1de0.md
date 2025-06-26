Nos piden:
- Comprobar si la dire virtual `shared_page` corresponde a la página compartida. En caso contrario no debe hacer nada.
- Modificar un flag, accesible por el kernel en todos los contextos que indique que la memoria compartida está bloqueada por la tarea invocante (este flag tiene que identificar a la tarea que posee el lock)
- Desmapear la página compartida de todas las tareas que no posean el lock

Antes de definir la función, debemos modificar una estructura del scheduler.
En `sched.c` agregamos una variable global:
```c
  uint8_t task_with_lock = -1; // determina qué tarea posee acceso único a la memoria compartida, inicializada en -1 ya que no corresponde al índice de ninguna tarea
```
```c
void get_lock(vaddr_t shared_page){
    if (shared_page == SHARED_MEM_PTR){ // chequea si la shared page corresponde a la página compartida
        task_with_lock = current_task; // establezco que el lock lo posee la tarea actual (seteo flag)

        // esto no lo dice la consigna pero si no, cómo es que la tarea tiene mapeado ya la página compartida si en algún momento quizás la desmapearon porque otra tuvo el lock?

        // entonces la mapeo porlas

        mmu_map_page(rcr3(), SHARED_MEM_PTR, SHARED_MEM, (MMU_P | MMU_U));

        for (uint8_t i = 0; i < MAX_TASKS; i++){
            if (i != current_task){
                uint32_t cr3_tarea = obtener_cr3(sched_tasks[i].selector);
                mmu_unmap_page(cr3_tarea, SHARED_MEM_PTR);
            }
        }
    }
}
```

Defino la función auxiliar:
```c
uint32_t obtener_cr3(uint16_t selector){
    uint16_t idx = selector >> 3; 
    tss_t* tss = gdt[idx].base;
    return tss_task->cr3;
}
```