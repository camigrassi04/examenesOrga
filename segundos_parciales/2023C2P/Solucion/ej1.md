Sistema: 
- 5 tareas independientes. 
- Utilizan el registro `ecx` como reservado. Contendrá un número de ticks de reloj denominado UTC el cual será actualizado por el sistema, incrementándolo cada vez que la tarea vuelva a ser ejecutada luego de una interrupción de reloj.
- servicio `fuiLlamadaMasVeces` que permite que una tarea pregunte si el UTC de otra tarea es menor que el suyo. Espera en `edi` el ID de la tarea por la que se está preguntando y devuelve el resultado en `eax`. Es 0 si la llamadora tiene UTC menor o igual y 1 en caso contrario. 

a) 
> Es importante la GDT en paginación ya que, para que una tarea corra código o acceda a datos, necesita tener cargados los registros de segmento (CS, DS, SS, etc)   
> Cada uno de esos registros contiene un selector que apunta a una entrada de la GDT. Los descriptores de la GDT determinarán     
> Asimismo, también contendrá un descriptor para la TSS. 

Es importante en la GDT tener definidas las siguientes entradas:
- `GDT_IDX_NULL_DESC` -> este descriptor siempre estará definido.
- `GDT_IDX_CODE_0` -> segmento para código de nivel 0 ejecución/lectura (kernel)
- `GDT_IDX_CODE_3` -> segmento para código de nivel 3 ejecución/lectura 
- `GDT_IDX_DATA_0` -> segmento para datos de nivel 0 escritura/lectura
- `GDT_IDX_DATA_3` -> segmento para datos de nivel 3 escritura/lectura
- Entrada para el TSS descriptor (sistema)

Los campos relevantes serán los siguientes:
- `.s`: Tipo del segmento (0 si es descriptor de sistema* y 1 si es de código/datos)
- `.type`: dependiendo del bit `s` cómo interpretamos este campo. Nos dice qué operaciones están permitidas. 
- `.dpl`: nos indica el nivel de privilegio del segmento. Máximo privilegio = 0 (kernel) y menor privilegio = 3 (usuario)
- `dirección base` (son cachitos de bits dispersos por el segmento): nos dice dónde arranca el comienzo de nuestro segmento. 
- `.p`: nos indica si el segmento está presente en memoria o no. 

* *si es de sistema, entonces se puede tratar de un TSS o IDT gates.*
Ya que cada tarea tendrá su `CS` (code segment), `DS` (data segment), `SS` (stack segment), etc.

b) Primero, cuando agregamos una tarea al sistema, (`create_task`), debemos inicializar el registro `ecx` en cero, para que no contenga basura.   
Luego, sabemos que una tarea será ejecutada cuando es la "seleccionada" en la interrupción de reloj como la tarea que se ejecutará, ya que luego se hace un jmp far a ella.    
Propongo entonces una modificación a la interrupción de reloj:
```nasm
global _isr32
_isr32:
    pushad
    ; 1. Le decimos al PIC que vamos a atender la interrupción
    call pic_finish1
    call next_clock

    ; 2. Realizamos el cambio de tareas en caso de ser necesario
    call sched_next_task

    cmp ax, 0
    je .fin

    str bx
    cmp ax, bx
    je .fin

    ; 3. Actualizamos ecx de la próxima tarea a ejecutar
    push eax ; le pasa el id de la tarea a la función
    call incrementar_ecx ; función de C que incrementa el ecx de la tarea, ya que vuelve a ser ejecutada
    add esp, 4 ; restauro tope pila

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
void incrementar_ecx(int8_t id_tarea) {
    // encontramos la tss de la tarea
    tss_t* tss = obtener_tss(sched_tasks[id_tarea].selector);
    // obtenemos la pila de la tarea (que contiene los valores actualizados de la tarea, es decir, sus valores cuando cayó la interrupción), esto es asumiendo que la tarea "cortó su ejecución" por una interrupción de reloj, como pasa en el tp
    uint32_t* esp = tss->esp;
    esp[6] = esp[6] + 1; // incremento el ecx
}
```

Definimos la función auxiliar `obtener_tss`:
```c
tss_t* obtener_TSS(uint16_t selector){
    uint16_t idx = selector >> 3;
    return gdt[idx].base // en realidad acá es un abuso de anotación, ya que se guarda en partes en la GDT entry
}
```

c) Para que una tarea pueda comparar el valor de su `ecx` con el de otra tarea, o bien puede hacerlo a través de un acceso a memoria compartida (es decir, se podría tener guardado en ese espacio de memoria un arreglo con los ecx de cada tarea de manera que cada una puede acceder a los ecx de las otras).   
Otra forma es definir una syscall. De esa forma, la tarea puede delegar la responsabilidad de buscar el ecx de la otra tarea al kernel. 

Voy a seguir la segunda forma. 

Para definir la syscall, vamos a tener que agregar una entrada a la IDT.
```c
void idt_init() {
    ...
    IDT_ENTRY3(80);
}
```
Lo declaramos en `isr.h` y luego definimos la rutina de atención de interrupción.

d) *Nos dicen que en EDI nos pasan el ID de la tarea por la que se está preguntando*
```c
global _isr80
_isr80:
    pushad

    push edi
    push ecx ; le paso mi utc
    call fui_llamada_mas_veces ; en eax nos devuelve 1 si sí, 0 si no
    add esp, 8

    ; debemos escribir el resultado directamente en la pila para que no se pise el valor del registro con el popad

    mov [esp + 28], eax

    popad
    iret
```

```c
uint32_t fui_llamada_mas_veces(uint32 utc, int8_t id_tarea) {
    tss_t* tss_otra = obtener_tss(sched_tasks[id_tarea].selector);
    uint32_t ucx_otra = obtener_UCX(tss_otra);
    return ucx > ucx_otra;
}
```

```c
uint32_t obtener_UCX(tss_t* tss) {
    uint32_t* esp = tss->esp;
    return esp[6];
}
```
e) No, no tiene sentido. Ya que justamente por ser un registro de propósito general, su valor puede ser modificado en cada llamado de función a C, entre otras cosas, y hay que estar teniendo cuidado con eso. Una forma que se me ocurre de solucionarlo es que el kernel mantenga la información en un arreglo que contenga los ecx de cada tarea. 

