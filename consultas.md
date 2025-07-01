# Preguntas para hacer en la clase de consultas:

## Inspiradas en el ejercicio 2022C2P:
[Ejercicio](segundos_parciales/2022C2P/Solucion/ejercicio_orga.md)
1) Si tenemos una tarea fuera de ejecución y nos piden que cambiemos el lugar desde el que se retoma, qué cosas deberíamos modificar además del EIP?   
Hay dos formas de modificar desde dónde se retoma la tarea:   
    1. *Agarrar la TSS, agarrar la pila y buscar el eip desde la pila*
    2. *Modificar el EIP desde la TSS y modificar el code segment a nivel 3. lo mismo con el stack segment.* 


2) Por qué es necesario reiniciar el stack de nivel 3 luego de cambiar la dirección en la que se resume la tarea?   
Básicamente porque le quedan valores basura del viejo contexto de ejecución que en el nuevo no nos interesan.
4) > *"La tarea que pasan por parametro esta frenada en la interrupcion de reloj, es decir, que el CS es de nivel 0. En la interrupcion de reloj el unico lugar donde las tareas quedan desalojadas y para poder forzar la ejecucion del codigo que me pasan por parametro tengo que hacer cs:eip, sino hago esto estaria haciendo cs0:eip y esta mal"*  

    ¿Qué significa esto?    
    Básicamente es la misma consideración que el punto 2 del 1). Es decir, no podemos saltar a la tarea teniendo el cs en 0.
5) Si tenemos una tarea que fue interrumpida por el reloj y luego dentro de la interrupción de reloj saltamos a otra tarea, cuando el scheduler retome la tarea, dónde la retoma? desde `.fin` de la interrupción de reloj o desde su propio código?   
Retoma desde el `.fin`.
6) > *IMPORTANTE: Desde nivel 0 NO podemos usar la pila de nivel 3 para guardar el estado de retorno y variables locales. Por lo tanto, se debe intercambiar la base de la pila. La nueva base de la pila se toma desde los campos SS0:ESP0 en la TSS. El estado de la pila de nivel 3 se guarda en la pila de nivel 0.*   
    
    Qué significa?   
    

## Inspiradas en el ejercicio 2023C1R:
Resolución: segundo cuatri 2023

[Ejercicio](segundos_parciales/2023C1R/Solucion/ej1.md)
1) Por qué en el siguiente punto:   

*¿Cómo modificarías el punto anterior para que exit (además de lo que hace normalmente) guarde el ID de quién la llamó en el EAX de próxima tarea a ejecutar? Mostrar código*   

Tiene que modificar el eax desde la pila y no el de la tss? Qué consideraciones/asunciones se hacen? (por ejemplo, que la tarea se ejecutó por lo menos 1 vez)

*Lo que suponemos: Teníamos entendido que modificando el tss, cuando se haga el jmp far, se va a cargar con los últimos valores (es decir, el modificado). Después con el popad se van a pisar los valores y esos van a ser los que quedan.*
