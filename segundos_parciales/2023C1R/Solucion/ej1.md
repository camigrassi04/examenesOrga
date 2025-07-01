a) *Implementar Syscall exit que al ser llamada por una tarea, la inactiva y pone a correr la siguiente (según indique el sistema de prioridad utilizado)*

Definimos una IDT entry para la syscall:
```C
void idt_init() {
    ...
    IDT_ENTRY3(100);
}
```
Definimos la rutina de atención:
```nasm
global _isr100
_isr100:
    pushad

    call disable_current_task ; pausamos la tarea actual

    ; ponemos a correr a la siguiente tarea
    call sched_next_task

    str bx
    cmp ax, bx
    je .fin

    mov word [sched_task_selector], ax

    jmp far [sched_task_offset]

    .fin:
    popad
    iret
```
En `sched.c`:
```C
void disable_current_task() {
    sched_disable_task(current_task);
}
```
b) *¿Cómo modificarías el punto anterior para que exit guarde también el ID de quien llamó en el EAX de próxima tarea a ejecutar?*

```nasm
_isr100:
    pushad

    call disable_current_task ; pausamos la tarea actual

    ; ponemos a correr a la siguiente tarea
    call sched_next_task

    str bx
    cmp ax, bx
    je .fin

    push eax
    call setear_eax ; setea en el registro eax (de la próxima tarea a ejecutar) el id de la tarea actual
    pop eax

    mov word [sched_task_selector], ax

    jmp far [sched_task_offset]

    .fin:
    popad
    iret
```

```C
void setear_eax(uint16_t next_task_seg) {
    // idea: modificar el eax de la tss, de manera que cuando se cargue al hacer el jmp far quede modificado
    tss_t* tss_task = obtener_tss(next_task_seg);
    tss_task->eax = (uint32_t) current_task;
}
```

c) *Y si la que modifica el EAX de nivel 3 de la tarea que va a ser ejecutada luego de la llamada a la syscall si no la interrupción de reloj? Cómo deberíamos modificar el código de la interrupción de reloj?*

d) *¿?*

