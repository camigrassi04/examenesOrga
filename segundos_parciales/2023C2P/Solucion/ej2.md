a) Va a saltar la **General Protection Fault**, ya que una tarea con nivel de privilegio de usuario está intentando ejecutar instrucciones privilegiadas y su nivel de privilegio no es 0. [Volumen 3A, sección 6.14 - General Protection Fault (#GP)](https://cpu.fyi/d/575e52). (página 231)

b) Cuando ocurre una excepción, el procesador guarda el valor de los registros `CS` y `EIP` que apuntan directamente a la instrucción que generó la excepción (ya que no llega a ejecutarse). Entonces, el S.O puede leer el byte en la dirección `CS:EIP` para determinar cuál es la instrucción que se quiso ejecutar.    
Para determinar si la instruccion que se trato de ejecutar fue halt lo que tenemos que hacer es leer si la instruccion a la que apunta el eip de la pila es igual al opcode de HLT, que es 0xF4.

c) Para finalizar el proceso lo que se tiene que hacer es llamar a una funcion en sched.c que pause la tarea que se estaba corriendo actualmente que fue la que hizo el halt.

d) continuar