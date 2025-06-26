# ¿Dónde debería definir cada cosa al momento de hacer una nueva función?

- `tasks.c`:   
Acá se define la *gestión de las tareas*, su *creación*, *destrucción* y cualquier operación que las manipule directamente.   
En el TP tenemos definidas las siguientes (más importantes):   
    - `create_task`: crea una nueva tarea
    - `tasks_init`: inicializa el sistema de tareas. 

- `sched.c`:   
Gestión del *scheduler*, se encarga de decidir qué tarea debe ejecutarse a continuación, gestionando su tiempo y los cambios de contexto entre tareas.    
En el TP tenemos definidas:   
    - Estructuras importantes, como:   
        - `task_state_t`: free, runnable, paused. 
        - `sched_entry_t`: selector y estado de cada tarea
        - `sched_tasks[MAX_TASKS]`: arreglo de tareas
        - `current_task`: tarea actualmente en ejecución
    - `sched_add_task`: agrega una tarea al primer slot libre (lo agrega al arreglo de tareas)
    - `sched_disable_task`: deshabilita una tarea en el scheduler (la marca como paused)
    - `sched_enable_task`: habilita una tarea en el scheduler (la marca como runnable)
    - `sched_init`: inicializa el scheduler
    - `sched_next_task`: obtiene la siguiente tarea disponible con una política round robin. Si no hay tareas disponibles, salta a la Idle. 

- `mmu.c`:
Funciones relacionadas con la **gestión de memoria y paginación**, necesarias para implementar el sistema de memoria virtual en modo protegido con paginación. 
En el TP tenemos definidas:   
    - `zero_page`: limpia el contenido de una página
    - `mmu_next_free_kernel_page`: devuelve la dir física de la próxima página de kernel disponible
    - `mmu_next_free_user_page`: devuelve la dir física de la próxima página de usuario disponible
    - `mmu_init_kernel_dir`: inicializa las estructuras de paginación vinculadas al kernel y realiza el identity mapping
    - `mmu_map_page`: agrega las entradas necesarias a las estructuras de paginación de modo de que la dirección virtual virt se traduzca en la dirección física phy con los atributos definidos en attrs
    - `mmu_unmap_page`: elimina la entrada vinculada a la dirección virt en la tabla de páginas correspondiente
    - `copy_page`: copia el contenido de la página física localizada en la dirección src_addr a la página física ubicada en dst_addr
    - `mmu_init_task_dir`: inicializa las estructuras de paginación vinculadas a una tarea cuyo código se encuentra en la dirección phy_start
    - `page_fault_handler`: true si se atendió el page fault y puede continuar la ejecución y false si no se pudo atender