## Organización del archivo:
- [Preliminares](#entendiendo-el-ejercicio-1)
- [Ejercicio](#ejercicio)
- [Cosas que aprendí del ejercicio](#cosas-interesantes-que-me-quedaron-del-ejercicio)
- [Recomendaciones](#recomendaciones)
- [Anexo](#anexo-cómo-debería-ser-la-función-obtener_cr3uint16_t-segsel)

### Entendiendo el ejercicio 1:
#### ¿Qué nos pide?
Queremos implementar una syscall llamada `get_lock` que permite a una tarea *pedir acceso exclusivo a una página compartida*. El lock garantiza que solo **una tarea a la vez puede acceder a esa página**

Varias cuestiones del ejercicio:
1. *¿Dónde está definido get_lock?*    
Debería estar definido en `sched.c` ya que es código kernel. 
2. *¿Dónde tenemos que definir la variable lock (el flag que nos indica quién es el dueño actual del lock)?*   
Por lo que vemos en la consigna, el lock tiene que estar definido **claramente en algún lugar del kernel**. Probablemente sea en *sched.c* ya que es el que tiene acceso a las tareas y sabe cuál es la que se está ejecutando actualmente. 

***Aclaración:*** *La función `get_lock` **NO** es la syscall, si no que es una función del kernel que será llamada por la syscall.*

---
### Ejercicio

En `defines.h` defino:

```h
#define TASK_LOCKABLE_PAGE_VIRT 0x08003000
#define TASK_LOCKABLE_PAGE_PHY 0x0001D000
```

> ¿De dónde salen estas constantes?
> En el archivo `shared.h` tenemos definido lo siguiente:
> ```h 
> #ifdef ORGA2__TAREA__
>	/**
>	 * Para las tareas de usuario la direccion de memoria es esta
>	 */
>	#define SHARED_MEM_PTR 0x08003000
>	/**
>	 * Para las tareas de usuario la pagina compartida es de solo lectura
>	 */
>	#define CONSTNESS const
>#else
>	/**
>	 * Para el kernel la direccion fisica es esta
>	 */
>	#define SHARED_MEM_PTR 0x1D000
>	/**
>	 * Para el kernel la pagina compartida admite escrituras
>	 */
>	#define CONSTNESS
>#endif
>```

En `sched.c` defino la variable global:

```c
static int task_with_lock = -1 // pongo -1 porque no es un índice válido (es decir, está disponible)
// cuando una tarea tenga el lock, el valor de esta variable va a ser su índice de la tarea en el arreglo sched_tasks (arreglo global de tareas del kernel). 
```

```C
void get_lock(vaddr_t shared_page){
    if (shared_page == TASK_LOCKABLE_PAGE_VIRT){ //chequeamos si shared_page corresponde a la página compartida
        if (task_with_lock == -1){
            task_with_lock = current_task; // el lock ahora pertenece a la tarea actual (la que hizo la syscall). current_task está definido en sched.c
            for (int i = 0; i < MAX_TASKS; i++){ // desmapeo la página compartida de todas las páginas que no posean el lock
                if (current_task != i){
                    pd_entry_t* cr3 = obtener_cr3(sched_tasks[i].selector);; // obtengo el cr3 de la tarea i
                    mmu_unmap_page((uint32_t) cr3, TASK_LOCKABLE_PAGE_VIRT); // desmapeo la tarea i con la dirección virtual de la página compartida (esto asegura que ninguna tarea que no sea la que tiene el lock pueda acceder a la página compartida)
                }
            }
        }
    }
}
```

*MAX_TASKS está definido en task_defines.h*

### Cosas interesantes que me quedaron del ejercicio:
- Las tareas las pensamos como índices. Si queremos acceder a la tarea en sí, la buscamos en el **arreglo global de índices**, definido en `sched.c`:
```c
/**
 * Estructura usada por el scheduler para guardar la información pertinente de
 * cada tarea.
 */
typedef struct {
  int16_t selector;
  task_state_t state;
} sched_entry_t;

static sched_entry_t sched_tasks[MAX_TASKS] = {0};
```

### Recomendaciones:
1. Escribir bien qué pide la consigna y dividirlo en pasitos.
2. Pensar en *dónde debería ubicarse cada cosa* según las características o para qué se usa.
3. Fijarte en el TP las definiciones de las estructuras.   
Por ejemplo, en este ejercicio, sacamos la dirección física y virtual de la página compartida en base al archivo del tp llamado `shared.h`. También, `MAX_TASKS` lo sacamos del archivo `task_defines.h`.

## Anexo: ¿Cómo debería ser la función `obtener_cr3(uint16_t segsel)`?
>Dado el el selector de segmento de la tarea i, devuelve su CR3 correspondiente.

*En el ejercicio no usamos `rcr3()` para esto ya que eso solo nos da el CR3 de la tarea que se está ejecutando*.

```c
pd_entry_t* obtener_cr3(uint16_t segsel){
    uint16_t idx = segsel >> 3;
    gdt_entry_t seg_descriptor = gdt[idx];

    uint32_t base = seg_descriptor.base_15_0
                    | seg_descriptor.base_23_16 << 16
                    | seg_descriptor.base_31_24 << 24;
    
    tss_t* tss_pointer = (tss_t*) base;
    return tss_pointer->cr3; // recordar que en tss tenemos el valor de cr3, entre otros
}
```