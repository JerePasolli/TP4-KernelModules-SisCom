# TP4 - Kernel Modules - Sistemas de Computación 2024

## Desafío 1 

### ¿Qué es checkinstall y para qué sirve?

Checkinstall es un programa que monitorea un procedimiento de instalación (como make install, install.sh, etc) y crea un paquete estándar para una distribución de Linux (actualmente se soportan paquetes deb, rpm y tgz) que se puede instalar a través del sistema de gestión de paquetes de la distribución en cuestión (dpkg, rpm o installpkg).

El principal beneficio de CheckInstall contra simplemente ejecutar make install es la habilidad de instalar y desinstalar el paquete del sistema usando el sistema de gestión de paquetes de la distribución de  Linux, además de poder instalar el paquete resultante en varias computadoras fácilmente.

### ¿Se animan a usarlo para empaquetar un hello world? 

Para probar la utilidad de checkinstall creamos un sencillo "Hello world" en C:

```c
#include <stdio.h>

int main() 
{
    printf("Hello, World!\n");
    return 0;
}
```

Luego procedimos a crear el Makefile correspondiente, generando dentro de este la instrucción "install", que luego utilizará Checkinstall para generar el paquete a través del Makefile:

```makefile
TARGET = hello_world
SRCS = hello_world.c
CC = gcc
CFLAGS = -Wall -Werror

all: $(TARGET)

$(TARGET): $(SRCS)
    $(CC) $(CFLAGS) -o $(TARGET) $(SRCS)

install: $(TARGET)
    install -m 0755 $(TARGET) /usr/local/bin/

clean:
    rm -f $(TARGET)
```
Una vez creado el makefile, simplemente resta ejecutar Checkinstall para generar el paquete. En vez de utilizar ```make install``` como haríamos usualmente, ejecutamos ```checkinstall```. Esto utilizará la instrucción "install" dentro del Makefile para generar el paquete (.deb en este caso).
Una vez ejecutado este comando, se nos permite modificar diferentes atributos del paquete a crear, tales como su nombre, descripción, versión, autor, etc, de la siguiente manera:

![Ejecución de checkinstall](./img/img1.png)
![Ejecución de checkinstall](./img/img2.png)

Una vez terminado este proceso, obtenemos el paquete .deb de nuestro programa:

![Paquete .deb obtenido](./img/img3.png)

Y al abrirlo podremos instalarlo a través del sistema de gestión de paquetes (interfaz gráfica):

![Instalación del paquete .deb mediante interfaz gráfica](./img/img4.png)

O bien podemos instalarlo mediante la terminal con el comando ```sudo dpkg -i tp4-kernelmodules_1.0-1_amd64.deb```

### Revisar la bibliografía para impulsar acciones que permitan mejorar la seguridad del kernel, concretamente: evitando cargar módulos que no estén firmados

En primer lugar, para evitar la carga de módulos no firmados en el kernel se debe habilitar el arranque seguro (secure boot) desde la BIOS o UEFI:

![Activación de arranque seguro](./img/img5.webp)

De esta manera al intentar cargar un módulo que no esté firmado el SO nos lo impedirá:

![Impedimento del SO de cargar módulo no firmado](./img/img6.png)

Para poder firmar el módulo y que sea posible utilizarlo en la PC se debe hacer lo siguiente:

1) Crear ekl archivo de condfiguración con parámetros para la generación de claves (claves ssh, una pública y otra privada):

![Archivo de configuración para crear claves ssh](./img/img7.png)

2) Crear el par de claves (pública y privada) con los siguientes comandos:


```bash
$ openssl req -x509 -new -nodes -utf8 -sha256 -days 36500 \
$ -batch -config configuration_file.config -outform DER \
$ -out my_signing_key_pub.der \
$ -keyout my_signing_key.priv
```

![Creación de claves ssh](./img/img8.png)

3) Para corroborar que se realizó correctamente el proceso, se puede chequear la validez de las claves, de la siguiente manera:

```bash
$ openssl x509 -inform der -text -noout -in my_signing_key_pub.der
```

![Verificación de validez de claves](./img/img9.png)

4) Agregamos la clave pública al sistema utilizando mokutil:

```bash
$ mokutil --import my_signing_key_pub.der
```

![Adición de clave al sistema utilizando mokutil](./img/img10.png)

5) Debemos permitir que se agregue la llave pública con la herramienta MOK, que se ejecutará cuando reiniciemos el sistema:

![Adición de clave al sistema luego del reinicio](./img/img11.jpg)

6) Finalmente, con el siguiente comando firmamos el módulo:

```bash
$ sudo /usr/src/kernels/$(uname -r)/scripts/sign-file sha256 my_signing_key.priv my_signing_key_pub.der part1/module/mimodulo.ko
```

Una vez hechos estos pasos, ya es posible cargar el módulo firmado:

![Carga de módulo firmado](./img/img12.png)


## Desafío 2

Debe tener respuestas precisas a las siguientes preguntas y sentencias:

### ¿ Cómo empiezan y terminan unos y otros (programas y módulos) ?

```
Un programa generalmente comienza con la funcion `main()`, esto depende del lenguaje y de la implementacion, luego ejecuta una serie de instrucciones y termina despues de completarlas.
```

```
Un modulo siempre comienza con la funcion `module_init` o una funcion designada por la llamada `module_init`. Esta funcion notifica al kernel sobre las funcionalidades del modulo, preparandolo para que pueda llamarse al modulo cuando se lo requiera. Los modulos concluyen invocando `cleanup_module` o una funcion especifica a travez de la llamada `module_exit` con lo cual se desregistran las funcionalidades, por lo cual la funcion de entrada y de salida es obligatoria para un modulo.

module_init(hello_init); 
module_exit(hello_exit); 
```

### ¿Qué funciones tiene disponible un programa y un módulo?
```
El kernel de Linux es modular:  permite insertar y eliminar código bajo demanda con el fin de añadir o quitar una funcionalidad. 

Los modulos son esenciales porque proporcionan la flexibilidad necesaria para extender las capacidades del sistema operativo sin necesidad de recompilar todo el kernel. 
```
  * Funcionalidades que podemos añadir con módulos:
    * Drivers privativos de hardware para gráficos / tarjetas de red.
    * Registrar temperaturas de componentes del ordenador y gestion del hardware.
    * Optimizacion del hardware.

  * Funcionalidades que tiene disponible un programa:
    * Gestión de Archivos/Procesos/Memoria.
    * Interacción con el Hardware.
    * Redes, establecimiento de conexiones, envio/recepcion..
    * Interfaz de Usuario.
    * etc.
  * Observaciones a cerca de las funcionalidades:

  ```
  Los programas normalmente invocan funciones en donde muchas de sus definiciones no entran en el programa hasta la etapa de enlazado ej: `printf()` lo cual asegura que la funcion este disponile y apunta la llamada a la biblioteca estandar de C.

  Los módulos del kernel son diferentes en este aspecto. los módulos son archivos de objeto cuyos símbolos se resuelven al ejecutar insmod o modprobe. La definición de los símbolos proviene del propio kernel; las únicas funciones externas que puedes usar son las proporcionadas por el kernel. Los símbolos han sido exportados por tu kernel se encuentan en /proc/kallsyms

  Incluso puedes escribir módulos para reemplazar las llamadas al sistema del kernel, como hacer que el kernel escriba "¡Ja ja, eso hace cosquillas!" cada vez que alguien intente eliminar un archivo en tu sistema.
  ```

### Espacio de usuario y Espacio del kernel:

```
El kernel gestiona principalmente el acceso a los recursos, ya sea una tarjeta de video, un disco duro o la memoria. Los programas frecuentemente compiten por los mismos recursos. El kernel tiene como objetivo mantener el orden, asegurando que distintos programas no accedan a los recursos de manera indiscriminada.

 Unix, utiliza solo dos anillos o niveles: el anillo más alto (anillo 0, también conocido como "modo supervisor", donde todas las acciones son permisibles) y el anillo más bajo, referido como "modo usuario".

Para verlo mas claro por ejemplo las función de biblioteca llama a una o más llamadas al sistema, y estas llamadas al sistema se ejecutan en nombre de la función de biblioteca, pero lo hacen en “supervisor mode” ya que son parte del propio kernel. Una vez que la llamada al sistema completa su tarea, regresa y la ejecución se transfiere de nuevo al “user mode”.
```

### Espacio de datos.
### Drivers. Investigar contenido de /dev.
