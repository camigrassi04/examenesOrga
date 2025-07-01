a) Tendremos el mismo esquema que el del taller, pero agregando la *memoria virtual de video*:   
Memoria virtual de video: `0x08004000`-`0x08005FFF` (dos páginas **nivel 3, read-write**).   
Estará mapeada o bien en la *memoria física de video **real*** (`0xB8000-0xB9FFF`), o bien en la *dummy* (`0x1E000-0x1FFFF`), que pertenecen al primer mega de memoria (kernel).

b) En este nuevo sistema tenemos que tener en cuenta que:
- Hay una única tarea con acceso a la memoria física de video. El resto podrán escribir sólo en la dummy. (Por lo tanto, hay que determinar la primer tarea que tiene acceso a esta memoria).
- Cada vez que se suelte la tecla `TAB` hay que cambiar la tarea que tiene acceso a la pantalla verdadera.

Definimos macros:
```c
#define MEM_VIRT_VIDEO 0x08004000
#define MEM_VIRT_VIDEO_2 0x08005000 // 1 página más
#define MEM_PHY_VIDEO 0xB8000
#define MEM_PHY_VIDEO_2 0xB9000
#define MEM_PHY_VIDEO_DUMMY 0x1E000
#define MEM_PHY_VIDEO_DUMMY_2 0x1F000
```

En `mmu_init_task_dir` agregamos el mapeo a la memoria dummy:
```c
paddr_t mmu_init_task_dir(paddr_t phy_start) {
    ...
    // mapeamos las dos páginas virtuales de video a la pantalla dummy.
    mmu_map_page(cr3, MEM_VIRT_VIDEO, MEM_PHY_VIDEO_DUMMY, (MMU_P | MMU_W | MMU_U));
    mmu_map_page(cr3, MEM_VIRT_VIDEO_2, MEM_PHY_VIDEO_DUMMY_2, (MMU_P | MMU_W | MMU_U));

    return (paddr_t) directorio;
}
```
c) Definimos una variable global que nos indica quién tiene actualmente el acceso a la pantalla:
```C
uint8_t id_tarea_video = -1; // arranca en -1 porque no representa el índice de ninguna tarea
```
Esta variable se actualizará cada vez que haya un cambio de pantalla (cada vez que se suelta el `TAB`).

d) Cambios necesarios para hacer el cambio de pantalla al soltar la tecla `TAB`:
Veamos la rutina de interrupción de teclado:
```nasm
global _isr33

; COMPLETAR: Implementar la rutina
_isr33:
    pushad

    ; 1. Le decimos al PIC que vamos a atender la interrupción
    call pic_finish1

    ; 2. Leemos la tecla desde el teclado y la procesamos
    in al, 0x60

    ; 3. Chequeamos si la tecla corresponde a soltar el TAB 
    push eax ; preservamos el valor de la tecla

    cmp al, 0x8F
    jne .fin ; no es soltar TAB

    call cambio_de_pantalla ; función en C que se encarga de realizar el cambio de pantalla

.fin:
    call tasks_input_process

    add esp, 4

    popad

    iret
```

`cambio de pantalla` debe desmapear la tarea que accede a la pantalla de video y mapearla a la dummy, agarrar la tarea i+1 y mapearla a la pantalla de video, y actualizar la variable global que indica quién tiene la pantalla de video posta. No nos interesa si esta tarea se encuentra inhabilitada o pausada. 

```c
void cambio_de_pantalla() {
    // desmapeamos y mapeamos tarea actual
    uint32_t cr3 = obtener_cr3(id_tarea_video);

    mmu_unmap_page(cr3, MEM_VIRT_VIDEO);
    mmu_unmap_page(cr3, MEM_VIRT_VIDEO_2);

    mmu_map_page(cr3, MEM_VIRT_VIDEO, MEM_PHY_VIDEO_DUMMY, MMU_P | MMU_W | MMU_U);
    mmu_map_page(cr3, MEM_VIRT_VIDEO_2, MEM_PHY_VIDEO_DUMMY_2, MMU_P | MMU_W | MMU_U);

    // mapeamos la pantalla de video a la siguiente tarea (según el índice)
    if (id_tarea_video == MAX_TASKS - 1){ // estamos en la última tarea, tenemos que volver a la primera, actualizamos var global
        uint8_t id_tarea_video = 0;    
    } else {
        uint8_t id_tarea_video = id_tarea_video + 1;
    }

    uint32_t cr3 = obtener_cr3(id_tarea_video);

    mmu_unmap_page(cr3, MEM_VIRT_VIDEO);
    mmu_unmap_page(cr3, MEM_VIRT_VIDEO_2);

    mmu_map_page(cr3, MEM_VIRT_VIDEO, MEM_PHY_VIDEO, MMU_P | MMU_W | MMU_U);
    mmu_map_page(cr3, MEM_VIRT_VIDEO_2, MEM_PHY_VIDEO_2, MMU_P | MMU_W | MMU_U);
}
```

Función auxiliar `obtener_cr3`:
```C
uint32_t obtener_cr3(uint8_t id_tarea) {
    uint16_t seg_sel = sched_tasks[id_tarea].selector;
    uint16_t idx = seg_sel >> 3; 
    tss_t* tss = gdt[idx].base;
    return tss->cr3;
}
```

> Pregunta: Es necesario hacer mmu_unmap_page o usamos directamente mmu_map_page con otra dirección?

e) Idea: Definir una syscall que una tarea puede llamar para saber si actualmente tiene o no la pantalla real. La idea sería que la rutina de atención de la interrupción llame a una función de C que retorne *current_task == id_tarea_video.*

f) Idea: que el kernel mantenga dos páginas para cada tarea donde guarda la copia de las páginas que modificó durante su tiempo teniendo la pantalla de video. Luego, agregamos a la función `cambio_de_pantalla` que los contenidos de las páginas de video se copien a esas páginas "backup" (con `copy_page`) y luego cuando cambiamos de pantalla, el kernel (con `copy_page`) copia el contenido de las páginas backup a la pantalla de video.