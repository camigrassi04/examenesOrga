# Índice:
- [Resumen consigna](#resumen-consigna)
- [Definición del array](#definición-del-array)
- [Syscall malloco](#syscall-malloco)
- [Mecanismo lazy allocation](#mecanismo-lazy-allocation)
- [Syscall chau](#syscall-chau)
- [CORRECCIONES](#correcciones)

# Resumen consigna:
Sistema donde:
- cada tarea puede pedir memoria de forma dinámica y liberarla en caso de que no la necesite
- mecanismo de asignación de memoria: *lazy allocation* (kernel solo reserva memoria cuando se la accede)

Syscalls:
- `malloco` que permite a las tareas reservar memoria.
    - *parámetro*: cantidad de memoria a reservar en bytes
    - *retorna*: dirección virtual a partir de la cual se reservó la memoria   
    *nota: si no hay suficiente memoria disponible, la syscall deberá devolver `NULL`*   
    Condiciones de asignación de memoria: 
        - Como máximo, una tarea puede tener asignados hasta 4MB de memoria. Si intenta reservar más, la syscall deberá devolver `NULL`
        - Área de memoria reservable empieza en `0xA10C0000`
        - Cada tarea puede pedir varias veces memoria pero no reservar más de 4MB en total
        - `malloco` asigna direcciones posteriores al último bloque reservado por la tarea. Si no encuentra memoria virtual suficiente, devuelve `NULL`

- `chau` permite a las tareas liberar memoria reservada:
    - *parámetro*: dirección virtual más baja de la memoria reservada
    - marca la memoria reservada como en desuso. Luego, una tarea de nivel 0 se encarga de liberar todos los bloques de memoria marcados en desuso. Se ejecuta cada 100 ticks de reloj.

Además, el sistema mantiene un **array alojado estáticamente en la memoria del kernel donde cada elemento representa una reserva**. 

***Lazy Allocation:***
- No se asigna memoria física hasta que la tarea quiera acceder. 
- Si la dirección virtual corresponde a las reservadas por la tarea, el kernel le asigna memoria física a esa dire virtual. Se asigna sólamente una única página física por cada acceso a la memoria reservada. 
- Si el acceso es incorrecto, el kernel debe remover la tarea del scheduler, marcar la memoria reservada por la misma para que sea liberada y saltar a la próxima tarea.
- Las páginas de memoria física son obtenidas del área libre de tareas.
- La memoria asignada por este mecanismo debe ser inicializada a cero.

# Definición del array:
Como el array deberá llevar el registro de reservas y liberaciones de memoria, se me ocurre que los elementos del array podrían ser así:
```c
typedef struct {
  vaddr_t vaddr_base; // dirección base desde donde se reservó memoria
  uint32_t bytes_reservados; // cantidad de bytes que se reservaron
  int8_t id_tarea_reserva; // id de la tarea que reservó
  bool en_uso; // booleano que determina si la memoria se encuentra en uso (1) o liberada (0)
} reserva_t;
```

Luego, al hacerse una reserva se agregará un elemento del tipo `reserva_t` al array y al liberarse se buscará en el arreglo la reserva correspondiente y se apagará el bit `en_uso`. 

# Syscall `malloco`:
Para definir la syscall `malloco` primero hay que agregar una entrada a la IDT. 
```c
void idt_init() {
    ...
    IDT_ENTRY3(80);
}
```
Será `IDT_ENTRY3` ya que todas las tareas de nivel 3 deben poder llamar a la syscall.

Luego declaramos la interrupción en `isr.h`:
```h
void _isr80();
```

Y definimos la rutina de interrupción en `isr.asm`:
*Asumo que la cantidad de bytes a reservar me la pasan por edi*
```nasm
extern malloco
...
global _isr80
_isr80:
    pushad

    push edi
    call malloco ; handler en C, retorna en eax la dirección virtual desde la cual se reservó memoria
    add esp, 4

    mov [esp + 28], eax ; escribo en la pila el valor de eax para que con el popad quede actualizado

    popad
    iret
```
Luego definimos la función en C `malloco`:
```c
// defino variable global idx_ult_reserva, que mantendrá el índice de la última reserva. Arranca en -1 porque al iniciar el sistema no hay ninguna reserva hecha
uint32_t idx_ult_reserva = -1;
#define VADDR_TAREAS_RESERVABLE 0xA10C0000
#define VADDR_LIMITE_RESERVA 0xA14C0000 // VADDR_TAREAS_RESERVABLE + 4MB 
#define MEM_START_PHYSICAL 0x400000
...

vaddr_t malloco(uint32_t cant_bytes) {
    // chequeo si la tarea se pasa de la reserva de 4MB
    if (reserva_menos_de_4mb){
        void* dir_base = siguiente_direccion_a_reservar(cant_bytes);
        if (dir_base != NULL){ // si vamos a reservar, lo agregamos al array para registrar la reserva
            idx_ult_reserva++; // actualizo índice de la reserva
            arr[idx_ult_reserva].vaddr_base = dir_base;
            arr[idx_ult_reserva].bytes_reservados = cant_bytes;
            arr[idx_ult_reserva].id_tarea_reserva = current_task;
            arr[idx_ult_reserva].en_uso = true;
        }
        return dir_base;
    }
}
```
Función auxiliar `reserva_menos_de_4mb` que determina si, con la reserva que se piensa actuar, la tarea se encuentra dentro del límite de los 4MB que puede reservar:
```c
bool reserva_menos_de_4mb(uint32_t cant_bytes) {
    uint32_t acum = cant_bytes;
    for (int i = 0; i <= idx_ult_reserva; i++){
        if (arr[i].id_tarea_reserva == current_task){
            if (arr[i].en_uso == true){
                acum += arr[i].bytes_reservados; // solo nos importan las reservas activas
            }
        }
    }
    return acum < 4000000;
}
```

> Nota: ¿Cuántas páginas entran en 4MB?   
> 1 MB = 1024 KB   
> Tamaño de una página = 4KB    
> 4096 KB / 4 KB = 1024 páginas     
> 1 página = 4096 bytes

Función auxiliar `siguiente_direccion_a_reservar` que busca a partir de qué dirección debe hacer la reserva. Si la reserva se pasa de las 
```c
void* siguiente_direccion_a_reservar(uint32_t cant_bytes) {
    void* dir_base = VADDR_TAREAS_RESERVABLE;
    // buscamos la última reserva
    uint32_t idx_ultima = -1;
    for (int i = 0; i <= idx_ult_reserva; i++ ) {
        if (arr[i].id_tarea_reserva == current_task){
            idx_ultima = i;
        }
    }
    if (arr[idx_ultima].vaddr_base + arr[idx_ultima].bytes_reservados + cant_bytes > VADDR_LIMITE_RESERVA){ // no tiene más espacio para reservar
        return NULL;
    }
    return (arr[idx_ultima].vaddr_base + arr[idx_ultima].bytes_reservados); // si no, devolvemos la dirección en la que puede empezar a reservar
}
```

# Mecanismo *lazy allocation*:
Para lograr este mecanismo de *lazy allocation* el kernel podrá valerse de una `page_fault`. Ya que, cuando una tarea intente acceder a una posición de memoria, saltará esta excepción lanzada por el procesador y de ahí se decidirá cómo proseguir según el caso.    
Para adaptarlo a la consigna, vamos a modificar el `page_fault` que ya tenemos definido en el tp. 
```nasm
; Rutina de atención de Page Fault
global _isr14

_isr14:
	; Estamos en un page fault.
	pushad
    ; COMPLETAR: llamar rutina de atención de page fault, pasandole la dirección que se intentó acceder
    mov ecx, cr2
    push ecx
    call page_fault_handler
    pop ecx

    cmp al, 0 ; si se hizo dentro del area on demand
    je .fin
    
    cmp al, 1
    je .ring0_exception
    
	; Si estamos aca es que cometimos un page fault fuera de lo que la tarea reservó
    mov ecx, cr2

    call castigar_tarea

    .ring0_exception:
    push eax ; preservamos el selector
    
    call kernel_exception

    add esp, 4

    ; saltamos a la siguiente tarea
    mov word [sched_task_selector], ax
    jmp far [sched_task_offset]

    .fin:
	popad
	add esp, 4 ; error code
	iret
```

> 0 = memoria ondemand   
> 1 = memoria reservada por la tarea (y fuera de la ondemand)   
> 2 = memoria no reservada por la tarea (y fuera de la ondemand)

```c
int8_t page_fault_handler(vaddr_t virt) {
  print("Atendiendo page fault...", 0, 0, C_FG_WHITE | C_BG_BLACK);
  // Chequeemos si el acceso fue dentro de la memoria virtual que tenía reservada (no contemplo el caso donde quiere acceder a la memoria liberada que reservó antes porque la consigna no aclara como se debe manejar)
  vaddr_t tope = siguiente_direccion_a_reservar(0);
  if(!(virt >= ON_DEMAND_MEM_START_VIRTUAL && virt < ON_DEMAND_MEM_END_VIRTUAL)){
    if(!(virt >= VADDR_TAREAS_RESERVABLE && virt < tope)){
        return 2;
    }
    // En caso de que si, mapear la pagina
    uint32_t cr3 = rcr3();
    uint32_t bytes_reservados = calcular_bytes_reservados(virt);
    uint32_t task_code_pages = bytes_reservados/4096; 
    for (uint32_t i = 0; i < task_code_pages; i++){ // mapeamos todas las páginas correspondientes
        paddr_t dir_phy = MEM_START_PHYSICAL + i*PAGE_SIZE; // calculo dirección física página nro i
        vaddr_t dir_virt = virt + i*PAGE_SIZE; 
        zero_page(dir_phy); // limpia el contenido de la página
        mmu_map_page(cr3, dir_virt, dir_phy, (MMU_P | MMU_U | MMU_W));
    }
    return 1;
  }  
  // si estamos acá, estamos tratando con un page fault convencional
  uint32_t cr3 = rcr3();
  mmu_map_page(cr3, virt, ON_DEMAND_MEM_START_PHYSICAL, (MMU_P | MMU_U | MMU_W));
  return 0;
}
```
*Entonces lo que hago es, a partir de la dirección virtual base, según la cantidad de bytes pedidos, mapeo una página a cada dirección virtual que corresponde. Es decir, por ejemplo, si pedí 8192 bytes (dos páginas) tendría que mapear la dirección virtual base a una página y luego dirección virtual base + 4096 a otra página.*

```c
uint32_t calcular_bytes_reservados(vaddr_t virt) {
    for (int i = 0; i <= idx_ult_reserva; i++ ) {
        if (arr[i].vaddr_base == virt) {
            return arr[i].bytes_reservados;
        }
    }
    return 0;
}
```
```c
uint16_t castigar_tarea() {
    for (int i = 0; i <= idx_ult_reserva; i++ ) {
        if (arr[i].id_tarea_reserva == current_task){
            chau(arr[i].vaddr_base);
        }
    }
    // remover la tarea del scheduler = pausarla ?
    sched_disable_task(tarea);
    return sched_next_task(); // retorno el selector de la siguiente tarea para hacer el jmp far
}
```
# Syscall `chau`:
Para definir la syscall `chau` primero hay que agregar una entrada a la IDT. 
```c
void idt_init() {
    ...
    IDT_ENTRY3(81);
}
```
Será `IDT_ENTRY3` ya que todas las tareas de nivel 3 deben poder llamar a la syscall.

Luego declaramos la interrupción en `isr.h`:
```h
void _isr81();
```

Y definimos la rutina de interrupción en `isr.asm`:
*Asumo que la dirección virtual más baja de la memoria reservada se pasa por edi*

```nasm
extern chau
global _isr81
_isr81:
    pushad

    push edi
    call chau
    add esp, 4

    popad
    iret
```

```c
void chau(vaddr_t dir_virt) {
    for (uint32_t i = 0; i <= idx_ult_reserva; i++){
        if (arr[i].vaddr_base == dir_virt) {
            if (arr[i].id_tarea_reserva == current_task){
                arr[i].en_uso = 0;
            }
        }
    }
}
```

Luego, definimos en la interrupción de reloj una rutina que libere los bloques de memoria marcados en desuso
```nasm
_isr32:
    pushad
    ; 1. Le decimos al PIC que vamos a atender la interrupción
    call pic_finish1
    call next_clock

    ; 2. Chequeamos si estamos en un tick de reloj múltiplo de 100
    mov eax, [isrNumber]
    mov edi, 100
    div edi ; ahora en eax tenemos el resultado de la división

    cmp edi, 0 
    jne .continuar ; si no estamos en un tick múltiplo de 100, la interrupción de reloj sigue como siempre

    ; si estamos acá es porque es un tick múltiplo de 100, por lo que tendremos que liberar los bloques en desuso
    call liberar_bloques

    .continuar:

    ; 3. Realizamos el cambio de tareas en caso de ser necesario
    call sched_next_task

    cmp ax, 0
    je .fin

    str bx
    cmp ax, bx
    je .fin

    mov word [sched_task_selector], ax

    jmp far [sched_task_offset]

    .fin:
    ; 4. Actualizamos las estructuras compartidas ante el tick del reloj
    call tasks_tick


    ; 5. Actualizamos la "interfaz" del sistema en pantalla
    call tasks_screen_update


    popad

    iret
```
```c
void liberar_bloques() {
    for (uint32_t i = 0; i <= idx_ult_reserva; i++){
        if (arr[i].en_uso == 0) {
            uint32_t cr3 = obtener_cr3(arr[i].id_tarea_reserva);
            uint32_t bytes_reservados = calcular_bytes_reservados(virt);
            uint32_t task_code_pages = bytes_reservados/4096; 
            for (uint32_t i = 0; i < task_code_pages; i++){
                vaddr_t dir_virt = virt + i*PAGE_SIZE; 
                mmu_unmap_page(cr3, arr[i].vaddr_base);
            }
        }
    }
}
```
```c
uint32_t obtener_cr3(int8_t id_tarea) {
    uint32_t idx = sched_tasks[id_tarea].selector >> 3;
    tss_t* tss = gdt[idx].base; // abuso de notación
    return tss->cr3;
}
```
---
# Correcciones:
## 1. Syscall `malloco` tiene que devolver algo a la tarea
Es decir, tendríamos que pisar el valor de eax desde la pila, de manera tal que cuando se haga `popad` se pise el valor del registro y le quede guardado a la tarea el puntero a la dirección reservada.
## 2. Cuando nos piden definir una tarea de nivel 0, hay que definirla posta
Es decir, tendríamos que crear una entrada en la GDT para su TSS, darle sus páginas correspondientes...   
Es importante que la tarea sea un loop infinito para que corra continuamente en los sucesivos turnos. 
## 3. Zero page funciona solo para direcciones físicas en el área kernel (por identity mapping)
Entonces para setear en cero una dirección física del área libre de tareas, primero hay que mapearla a una dirección virtual libre del área kernel (está definido en el tp con un define) y luego usar `kmemset`. 