Para definir las syscalls `lock` y `release` debemos agregar dos nuevas entradas a la idt.
Para eso, definimos en `idt.c`:
```c
void idt_init(){
    ...
    IDT_ENTRY3(80);
    IDT_ENTRY3(81); 
}
```
Serán `IDT_ENTRY3` ya que tienen que poder ser llamadas desde nivel de usuario. 
Luego, declaramos en `isr.h`:
```h
void _isr80();
void _isr81();
```

Ahora implementaremos las rutinas de atención en `isr.asm`:
*Asumo, tanto para `lock` como para `release`, que la dirección virtual de la página compartida viene en edi*

```nasm
global _isr80
_isr80:
    pushad

    str cx ; obtengo el selector de la tarea actual
    push cx ; lo paso como parámetro
    push edi ; paso como parámetro la página compartida

    call puede_acceder_a_memoria_compartida ; devuelve 1 si puede, 0 si no (y de paso marca que quiere el lock)

    add esp, 6 ; restauro tope de la pila 

    cmp ax, 1
    je .get_lock

    ; si estamos acá, es que debemos pasar a la siguiente tarea
    call sched_next_task
    mov word [sched_task_selector], ax
    jmp far [sched_task_offset]
    
    .get_lock:
    push edi
    call get_lock
    add esp, 4

    .fin:
    popad
    iret
```

Antes de pasar a las funciones definidas en el scheduler, amplío la información que tiene de cada tarea:
```c
typedef struct {
  int16_t selector;
  task_state_t state;
  uint8_t wants_lock;
} sched_entry_t;
```
Al agregar una nueva tarea, `wants_lock` se inicializa siempre en 0.

Defino la función auxiliar:
```c
uint16_t puede_acceder_a_memoria_compartida(vaddr_t shared_page, uint16_t selector){
    if (task_with_lock != current_task() || task_with_lock != -1){
        // si el lock lo tiene una tarea distinta a la actual y marca que quiere el lock
        sched_tasks[current_task].wants_lock = 1;
        return 0;
    }
    // si la tarea que tiene el lock es la actual, o el lock está libre, es válido
    return 1;
}
```
> **IMPORTANTE:** Con la implementación que tenemos ahora, una tarea que quiere el lock al ser retomada podría tomarlo, ya que no se hace nunca el chequeo de si el lock está libre.

Entonces, podríamos modificar el `sched_next_task` para que evite esta situación, haciendo que nunca tome una tarea que quiere el lock mientras el lock no está disponible (*no tiene sentido que elija a una tarea que quiere el lock, porque solo va a buscar el lock y hasta que no esté disponible la tarea no puede hacer nada más que esperarlo*).

*Es un asquete este código pero básicamente chequea si el lock está libre: si está libre, actúa como un scheduler común y corriente, si no, elige una tarea que no quiere el lock.*

```c
uint16_t sched_next_task(void) {
    if (task_with_lock == -1){
        // Buscamos la próxima tarea viva (comenzando en la actual)
        int8_t i;
        for (i = (current_task + 1); (i % MAX_TASKS) != current_task; i++) {
            // Si esta tarea está disponible la ejecutamos
            if (sched_tasks[i % MAX_TASKS].state == TASK_RUNNABLE) {
            break;
            }
        }

        // Ajustamos i para que esté entre 0 y MAX_TASKS-1
        i = i % MAX_TASKS;

        // Si la tarea que encontramos es ejecutable entonces vamos a correrla.
        if (sched_tasks[i].state == TASK_RUNNABLE) {
            current_task = i;
            return sched_tasks[i].selector;
        }

        // En el peor de los casos no hay ninguna tarea viva. Usemos la idle como
        // selector.
        return GDT_IDX_TASK_IDLE << 3;
    } else {
        // Buscamos la próxima tarea viva y que no quiera el lock(comenzando en la actual)
        int8_t i;
        for (i = (current_task + 1); (i % MAX_TASKS) != current_task; i++) {
            // Si esta tarea está disponible la ejecutamos
            if (sched_tasks[i % MAX_TASKS].state == TASK_RUNNABLE && sched_tasks[i % MAX_TASKS].wants_lock == 0) {
            break;
            }
        }

        // Ajustamos i para que esté entre 0 y MAX_TASKS-1
        i = i % MAX_TASKS;

        // Si la tarea que encontramos es ejecutable entonces vamos a correrla.
        if (sched_tasks[i].state == TASK_RUNNABLE && sched_tasks[i].wants_lock == 0) {
            current_task = i;
            return sched_tasks[i].selector;
        }

        // En el peor de los casos no hay ninguna tarea viva. Usemos la idle como
        // selector.
        return GDT_IDX_TASK_IDLE << 3;
    }
}
```


```nasm
global _isr81
_isr81:
    pushad

    push edi
    call free_lock
    add esp, 4

    popad
    iret
```
Y defino la función `free_lock`
```c
void free_lock(vaddr_t shared_page){
    task_with_lock = -1;
    sched_tasks[current_task].wants_lock = 0;
}
```
Nos piden, además, que si una tarea quiere leer la página compartida y el lock no está activo, que pueda hacerlo sin tener que pedir el lock. 
- Si es una lectura y nadie tiene el lock, permitimos
- Si es escritura o lectura y alguien tiene el lock, no lo permitimos. 

Modificamos entonces la rutina de excepción de Page Fault.
```nasm
global _isr14
_isr14:
    pushad
    mov edi, cr2             ; Dirección virtual que causó el page fault
    pop eax                  ; Código de error (lo pushea la CPU antes de saltar a la ISR)

    shr edi, 12              ; Redondeo a base de página
    shl edi, 12

    cmp edi, TASK_LOCKABLE_PAGE_VIRT
    jne .normal              ; Si no es la página compartida, salgo por la rutina normal

    ; Llegamos acá => hubo acceso a la página compartida

    and eax, 2               ; Bit 1 del código de error indica si fue escritura (1) o lectura (0)
    cmp eax, 1
    je .fin                  ; Si fue escritura, NO hacemos nada

    ; Si fue lectura, verifico si el lock está libre
    call lock_disponible
    cmp ax, 0
    je .fin                  ; Si no está disponible, no dejo pasar

    ; Si está disponible el lock, mapeo la página como solo lectura
    mov eax, cr3
    mov ecx, [TASK_LOCKABLE_PAGE_PHY]
    mov edi, [TASK_LOCKABLE_PAGE_VIRT]
    mov edx, [READ_ONLY_USER_ATTRIBUTES]
    push edx
    push edi
    push ecx
    push eax
    call mmu_map_page
    add esp, 16
    jmp .fin

.normal:
    ; Para cualquier otro page fault, sigo con el handler original
    push edi
    call page_fault_handler
    add esp, 4
    cmp al, 1
    je .fin

.ring0_exception:
    call kernel_exception
    jmp $

.fin:
    popad
    add esp, 4               ; Código de error
    iret
```

Explicación por partes:

*Leemos la dirección que provocó el page fault (cr2) y le sacamos el offset, para conseguir solo la base de la página. la idea es poder compararla con TASK_LOCKABLE_PAGE_VIRT, que es la dirección virtual compartida*
```nasm
mov edi, cr2
shr edi, 12
shl edi, 12
```

*Si no es la página compartida, salta a .normal*. Es decir, trataremos con un page fault normal (ya que no es un acceso que nos interesa en el contexto de este ejercicio)

*Si es página compartida, chequeamos si fue de escritura:*
```nasm
pop eax        ; error code
and eax, 2     ; Bit de escritura
cmp eax, 1
```
*Si es de escritura, salta a .fin (se trata como error). Si es de lectura, seguimos*

*Chequeamos si hay alguien con el lock*
```nasm
call lock_disponible
cmp ax, 0
je .fin
```
*Si está disponible, haremos un mapeo `readonly` para esa tarea*. 

*Mapeamos la página en modo lectura para usuario:*
```nasm
mov eax, cr3
mov ecx, [TASK_LOCKABLE_PAGE_PHY]
mov edi, [TASK_LOCKABLE_PAGE_VIRT]
mov edx, [READ_ONLY_USER_ATTRIBUTES]
push edx
push edi
push ecx 
push eax
call mmu_map_page
add esp, 16
```

Con esto, entonces, permitimos que **todas las tareas puedan leer la página compartida, sin necesidad de pedir el lock, siempre y cuando este esté libre**. 
---

Notas: 
Notar que en este inciso a), una tarea podría conseguir el lock o bien la primera vez que usa get_lock o bien porque quería el lock y fue esperando hasta que fue liberado, de manera tal que luego del jmp far, cuando se retoma, es correcto que pida el lock de vuelta. 

---
b) Nos piden que:
- si una tarea quiere acceder a memoria compartida y no posee el lock, debe comportarse como si la tarea lo hubiera solicitado
- el lock adquirido se liberará automáticamente luego de 5 desalojos de la tarea que lo obtuvo

> Quieren que la tarea no tenga que llamar a la syscall. Es decir, que si escribe sin tener el lock, el kernel automáticamente le dé el lock (como si hubiera hecho la syscall), de manera transparente para el usuario.
>
> Y que, luego de 5 desalojos (5 veces que el scheduler le quite la CPU), se libera el lock automáticamente.

Con el punto anterior (*page_fault*) ya atendemos los accesos inválidos de escritura/lectura a la página compartida. 

- Si fue una escritura sin lock, reutilizamos la lógica de `get_lock`, pero lo hacemos mediante la rutina de `page fault`. Es decir, va a pasar que el usuario accede, ocurre un page_fault, el kernel automáticamente le da el lock y remapea, y la instrucción continúa.

Además, necesitaremos **contar cuántas veces se desaloja la tarea con lock**. Por lo que declaramos una variable global, por ejemplo:
```c
int desalojos_tarea_con_lock = 0;
```
Y cada vez que la tarea que tiene el lock deja de ser la actual, sumamos 1 a esa variable. 

Cuando otra tarea recibe el lock, seteamos esa variable en 0. 