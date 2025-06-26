A) Primero hacemos los defines al inicio de `defines.h`
```h
#define BUFFER_PADDR 0xF151C000
#define DMA_VADDR 0xBABAB000
```

Y en `mmu.c` agregamos esas constantes como externs. 

```c
void buffer_dma(pd_entry_t* pd){
    uint32_t cr3 = (uint32_t) pd;
    mmu_map_page(cr3, DMA_VADDR, BUFFER_PADDR, MMU_U | MMU_P); // recordar que los attr MMU se refieren a permisos del mapeo virtual-físico (en este caso de la tabla de páginas, por lo que hace la función mmu_map_page)
    // esto entonces es lectura, modo usuario
}
```
B) 
```c
void buffer_copy(pd_entry_t* pd, paddr_t phys){
    uint32_t cr3 = (uint32_t) pd;
    copy_page(phys, BUFFER_PADDR); // copia el buffer a la dirección pasada por parámetro (no se encuentra mapeada a ninguna dirección virtual)
    mmu_map_page(cr3, DMA_VADDR, phys, MMU_U | MMU_P); // mapeo la dirección física phys a una dirección virtual
}
```

Es importante **mapear la dirección física con la virtual** ya que a través de la dirección física es como el **proceso puede acceder a esa dirección física**. Esta relación va a estar definida en el *page directory* y *page table*.


> La entrada i del page directory sirve para traducir las direcciones virtuales entre i*4MB e (i+1)*4MB
> 
> La page table, por otro lado, contiene entradas que apuntan a páginas físicas individuales. Cada entrada de una pt traduce un bloque de 4KB de memoria virtual a memoria física. También contiene flags (presente, lectura/escritura, usuario/kernel, etc)

