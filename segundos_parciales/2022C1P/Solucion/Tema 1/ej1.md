*Nos piden: ampliar el sistema para que una tarea pueda modificar el valor del registro `edx` de la tarea próxima*.

1. 
Primero, debemos definir la syscall.

Para eso, agregamos una entrada a la IDT de la siguiente manera:
```c
void idt_init(){
    ...
    IDT_ENTRY3(80);
}
```
Y luego la declaramos en `isr.h`:
```h
void _isr80();
```

Definimos el número 80 como número de la syscall ya que es un número mayor a 32 (menores a 32 son los reservados por Intel) y no interfiere con los de hardware. 

Asimismo, es una `IDT_ENTRY3` ya que debe poder ser llamada por cualquier tarea de nivel 3. 

2. 
Asumo que el parámetro se le pasa a la syscall por el registro `edi`. 

```nasm
global _isr80
_isr80:
    pushad

    push edi
    call modify_next_task_edx ; llamo al handler en C
    add esp, 4

    popad
    iret
```

Mi idea de implementación es tener una variable global que indique el valor al que tiene que modificarse `edx` y que luego la interrupción de clock pueda acceder a ese valor para encargarse de modificarlo.

Entonces, agregamos variables globales en `sched.c`:
```c
uint32_t next_edx_value = 0;
bool modificar_edx_value = false;
```
En `next_edx_value` guardamos el valor al que tendremos que modificar el edx, no importa el valor con el que se inicializa. Por otro lado, `modificar_edx_value` es una flag que básicamente determina si la otra variable es válida o no. Se inicializa en false ya que, hasta que no haya alguna tarea que quiera modificar el valor de edx, no nos interesa la variable global y deberíamos ignorarla. 

```c
void modify_next_task_edx(uint32_t edx_value){
    next_edx_value = edx_value;
    modificar_edx_value = true;
}
```

3. Modificamos la rutina de interrupción de reloj de manera tal que se fije en esa variable global. 
Para ello, debemos declarar al inicio de `isr.asm` la variable como extern para que pueda accederla:
```nasm
extern next_edx_value
extern modificar_edx_value
```

Luego, modificamos la rutina:
```nasm
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

    ; función que modifica el registro edx directamente en la tss de la próxima tarea
    
    push ax ; paso como parámetro el selector de la tarea actual
    call modify_edx
    pop ax
    mov word [sched_task_selector], ax
    jmp far [sched_task_offset]

    .fin:
    ; 3. Actualizamos las estructuras compartidas ante el tick del reloj
    call tasks_tick
    ; 4. Actualizamos la "interfaz" del sistema en pantalla
    call tasks_screen_update
    popad
    iret
```

En `sched.c` defino la función:
```c
void modify_edx(uint16_t segsel){
    if (modificar_edx_value == true){
        tss_t* tss_base = gdt[selector >> 3].base;
        tss_base.edx = next_edx_value;
        modificar_edx_value = false;
    }
}
```

¿Por qué modificando la TSS de la tarea a la que vamos a saltar nos aseguramos que el edx quede modificado? Porque cuando hacemos el jmp far, la CPU automáticamente carga el contexto de la TSS en los registros del CPU, incluyendo los registros generales. Entonces, cuando empiece a ejecutar la tarea, tendrá ese valor modificado cargado en `edx`. 