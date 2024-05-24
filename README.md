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

Un programa generalmente comienza con la funcion `main()`, esto depende del lenguaje y de la implementacion, luego ejecuta una serie de instrucciones y termina despues de completarlas.

Un modulo siempre comienza con la funcion `module_init` o una funcion designada por la llamada `module_init`. Esta funcion notifica al kernel sobre las funcionalidades del modulo, preparandolo para que pueda llamarse al modulo cuando se lo requiera. Los modulos concluyen invocando `cleanup_module` o una funcion especifica a travez de la llamada `module_exit` con lo cual se desregistran las funcionalidades, por lo cual la funcion de entrada y de salida es obligatoria para un modulo.

module_init(hello_init); 
module_exit(hello_exit); 


### ¿Qué funciones tiene disponible un programa y un módulo?

El kernel de Linux es modular:  permite insertar y eliminar código bajo demanda con el fin de añadir o quitar una funcionalidad. 

Los modulos son esenciales porque proporcionan la flexibilidad necesaria para extender las capacidades del sistema operativo sin necesidad de recompilar todo el kernel. 

  * Funcionalidades que podemos añadir con módulos:
    * Drivers privativos de hardware para gráficos / tarjetas de red.
    * Registrar temperaturas de componentes del ordenador y gestion del hardware.
    * Optimizacion del hardware.

  * Funcionalidades que tiene disponible un programa:
    * Gestión de Archivos/Procesos/Memoria.
    * Interacción con el Hardware.
    * Redes, establecimiento de conexiones, envío/recepción de paquetes.
    * Interfaz de Usuario.
    * etc.

#### Observaciones a cerca de las funcionalidades:

  Los programas normalmente invocan funciones en donde muchas de sus definiciones no entran en el programa hasta la etapa de enlazado ej: `printf()` lo cual asegura que la funcion este disponile y apunta la llamada a la biblioteca estandar de C.

  Los módulos del kernel son diferentes en este aspecto. los módulos son archivos de objeto cuyos símbolos se resuelven al ejecutar insmod o modprobe. La definición de los símbolos proviene del propio kernel; las únicas funciones externas que se pueden usar son las proporcionadas por el kernel. Los símbolos exportados por el kernel se encuentan en /proc/kallsyms

  Incluso se pueden escribir módulos para reemplazar las llamadas al sistema del kernel, como hacer que el kernel escriba "¡Ja ja, eso hace cosquillas!" cada vez que alguien intente eliminar un archivo del sistema sin los permisos adecuados.


### Espacio de usuario y Espacio del kernel:

El kernel gestiona principalmente el acceso a los recursos, ya sea una tarjeta de video, un disco duro o la memoria. Los programas frecuentemente compiten por los mismos recursos. El kernel tiene como objetivo mantener el orden, asegurando que distintos programas no accedan a los recursos de manera indiscriminada.

 Unix utiliza solo dos anillos o niveles: el anillo más alto (anillo 0, también conocido como "modo supervisor", donde todas las acciones son permisibles) y el anillo más bajo, referido como "modo usuario".

Para verlo mas claro, pongamos un ejemplo. Una función de una biblioteca realiza una o más llamadas al sistema, y estas llamadas al sistema se ejecutan en nombre de la función de biblioteca, pero lo hacen en “supervisor mode” ya que son parte del propio kernel. Una vez que la llamada al sistema completa su tarea, regresa y la ejecución se transfiere de nuevo al “user mode”.

### Espacio de datos

El "espacio de datos" hace referencia a la manera en que el sistema gestiona, organiza y almacena datos, tanto en memoria como en disco (almacenamiento secundario).

#### Memoria Virtual y Física

El SO mantiene un esquema de memoria virtual para gestionar cómo los procesos acceden a la memoria física. Cada proceso se ejecuta en su propio espacio de direcciones virtuales, lo que significa que cada proceso piensa que tiene acceso a toda la memoria del sistema, aunque en realidad comparte la memoria física con otros procesos.

#### Segmentación de Memoria

El espacio de datos de un proceso se segmenta en varias regiones principales:

- Código (text segment): Contiene el código ejecutable del programa.
- Datos estáticos (data segment): Contiene variables globales y estáticas que se inicializan.
- Datos no inicializados (BSS segment): Contiene variables globales y estáticas que no se inicializan.
- Heap: Área de memoria dinámica que se utiliza para la asignación dinámica durante la ejecución del programa (usando malloc, por ejemplo).
- Stack: Utilizado para la ejecución de llamadas a funciones y almacenamiento de variables locales.

#### Sistema de Archivos

El espacio de datos en disco se gestiona a través del sistema de archivos del SO. Para el caso de GNU/Linux, el sistema de archivos más comun es ext4.

- Inodos: Cada archivo tiene un inodo que contiene metadatos sobre el archivo (permisos, propietario, tamaño, etc.).
- Bloques: Los datos de los archivos se almacenan en bloques en el disco.
- Directorio: Los archivos se organizan en una estructura jerárquica de directorios.

#### Gestión de Memoria

El kernel gestiona la memoria mediante varias técnicas:

- Paginación (paging): La memoria se divide en páginas de tamaño fijo (típicamente 4 KB). El sistema puede intercambiar páginas entre la RAM y el espacio de intercambio (swap) en el disco.
- Segmentación: Aunque menos común en sistemas modernos, se puede segmentar la memoria para distintos propósitos y procesos, a diferencia de la paginación, la segmentación permite dividir la memoria en segmentos de tamaño variable.
- Caché y Buffers: El SO utiliza el caché y los buffers para mejorar el rendimiento del acceso a disco.

#### Intercambio de Datos y Comunicación Inter-procesos (IPC)

Para la comunicación entre procesos y la transferencia de datos, Linux ofrece varias técnicas de IPC:

- Tuberías (pipes) y Tuberías con nombre (named pipes): Para la comunicación de datos en una sola dirección.
- Colas de mensajes: Permiten que los procesos envíen y reciban mensajes.
- Memoria compartida: Permite que varios procesos accedan a una misma región de memoria.
- Semáforos: Para la sincronización entre procesos.

#### Seguridad y Permisos

El espacio de datos en Linux está protegido mediante un sistema de permisos y políticas de seguridad:

- Permisos de archivos: Lectura, escritura y ejecución pueden ser configurados para el propietario, grupo y otros usuarios.
- Control de acceso obligatorio (MAC): Sistemas como SELinux implementan políticas de seguridad estrictas sobre qué procesos pueden acceder a qué recursos.

### Drivers. Investigar contenido de /dev.

Un driver o controlador es un programa que actúa como intermediario entre el sistema operativo y un dispositivo de hardware. Los drivers traducen las instrucciones del sistema operativo a un formato que el hardware puede entender y viceversa.

#### Tipos de Drivers en Linux

En Linux, los drivers se clasifican principalmente según el tipo de hardware que controlan:

- Drivers de dispositivos de bloque: Para dispositivos que leen y escriben datos en bloques, como discos duros y unidades SSD.
- Drivers de dispositivos de caracter: Para dispositivos que manejan datos en forma de flujo de caracteres, como puertos seriales y teclados.
- Drivers de red: Para interfaces de red, como tarjetas Ethernet y WiFi.
- Drivers gráficos: Para tarjetas de video y otros dispositivos de visualización.
- Drivers de sonido: Para tarjetas de sonido y otros dispositivos de audio.
- Drivers de dispositivos USB y periféricos: Para una amplia variedad de dispositivos conectados a través de USB.

Otra clasificación de los drivers es la siguiente:

- Repositorio de Kernel: Los drivers abiertos se incluyen en el repositorio principal del kernel y están disponibles para todas las distribuciones.
- Drivers Privativos: Algunos fabricantes proporcionan drivers binarios que no están incluidos en el kernel principal. Estos pueden ser descargados directamente desde el sitio web del fabricante o a través de gestores de paquetes de la distribución.

#### Gestión de Drivers en Linux

El manejo de drivers en Linux incluye la instalación, carga, descarga y configuración. Aquí están las herramientas y métodos más comunes:

- `lsmod`: Muestra los módulos del kernel actualmente cargados.
modprobe: Carga módulos del kernel y sus dependencias.
- `insmod`: Inserta un módulo en el kernel.
- `rmmod`: Elimina un módulo del kernel.

### Contenido del directorio /dev

El directorio /dev contiene archivos que representan dispositivos físicos y virtuales en el sistema. Estos archivos de dispositivos permiten a los programas interactuar con el hardware mediante operaciones de lectura y escritura, similar a como interactuarían con archivos regulares.

#### Tipos de Dispositivos en /dev

En /dev, los archivos de dispositivos se clasifican en dos categorías principales:

#### Dispositivos de Bloque (Block Devices):

Descripción: Estos dispositivos manejan datos en bloques, que son unidades de datos de tamaño fijo.
Ejemplos: Discos duros, unidades SSD, y particiones.
Identificación: Generalmente tienen nombres como sda, sda1, sdb, etc.
Uso: Estos dispositivos son utilizados para operaciones de entrada/salida de gran volumen y permiten el acceso aleatorio a los datos.

#### Dispositivos de Carácter (Character Devices):

Descripción: Estos dispositivos manejan datos en flujos de caracteres.
Ejemplos: Teclados, ratones, puertos serie, y consolas.
Identificación: Generalmente tienen nombres como tty0, ttyS0, random, null, etc.
Uso: Estos dispositivos son utilizados para operaciones de entrada/salida de baja latencia y permiten el acceso secuencial a los datos.

Podemos saber si un dispositivo es de cada tipo ejecutando el comando `ls -l`, y observando la primera letra de cada dispositivo listado: 
- c -> character
- b -> block

![Listado de dispositivos en /dev](./img/img13.png)
![Listado de dispositivos en /dev](./img/img14.png)

#### Dispositivos Comunes en /dev

- /dev/null: Un dispositivo especial que descarta cualquier dato escrito en él. Leer desde /dev/null siempre devuelve un EOF (End Of File).
- /dev/zero: Un dispositivo especial que proporciona un flujo de ceros. Es útil para inicializar datos.
- /dev/random y /dev/urandom: Dispositivos que generan números aleatorios. /dev/random puede bloquearse si no hay suficiente entropía, mientras que /dev/urandom no se bloquea y es menos seguro.
- /dev/sda, /dev/sdb, etc.: Representan discos duros y dispositivos de almacenamiento.
- /dev/tty, /dev/tty0, /dev/ttyS0, etc.: Representan terminales y puertos serie.
- /dev/loop0, /dev/loop1, etc.: Dispositivos de loopback que permiten montar archivos como si fueran discos.
- /dev/cdrom, /dev/dvd: Representan unidades de CD/DVD.

## Preguntas finales

Ejecutamos el paso a paso para cargar y descargar el módulo de ejemplo del repositorio en el kernel, de la siguiente manera:

```bash
$ cd part1/module
$ make
$ sudo insmod mimodulo.ko
$ sudo dmesg
$ lsmod | grep mod
$ sudo rmmod mimodulo
$ sudo dmesg
$ lsmod | grep mod
$ modinfo mimodulo.ko
$ modinfo /lib/modules/$(uname -r)/kernel/crypto/des_generic.ko
```
En las siguientes imágenes se observan los resultados de los comandos:

![Resultado del comando insmod](./img/img15.png)

Extracto del comando `sudo dmesg`:

![Resultado del comando dmesg luego de cargar el módulo](./img/img16.png)
![Resultado del comando lsmod luego de cargar el módulo](./img/img17.png)

Extracto del comando `sudo dmesg` luego de remover el módulo:

![Resultado del comando dmesg luego de remover el módulo](./img/img18.png)

Y los respectivos comandos `modinfo`:

![Resultado del comando modinfo](./img/img19.png)
![Resultado del comando modinfo](./img/img20.png)

### ¿Qué diferencias se pueden observar entre los dos modinfo?

El módulo des_generic.ko proporciona una implementación del algoritmo DES (Data Encryption Standard) para ser utilizado dentro del kernel de Linux. Esto permite que el cifrado DES sea utilizado por otras partes del kernel, como el subsistema de criptografía (Crypto API) y puede ser aprovechado por aplicaciones que necesitan realizar operaciones criptográficas a nivel del kernel. Por otro lado, mimodulo.ko es un simple ejemplo que escribe un mensaje indicando si fue cargado/descargado del kernel.

En primer lugar notamos que el módulo "des_generic.ko" posee varios alias asociados, lo que nos da distintas formas de accederlo en caso de necesitarlo. Además, contiene como dependencia la librería "libdes".

La otra gran diferencia es que este módulo propio del kernel esta firmado, por lo que se puede considerar seguro, mientras que nuestro ejemplo no lo está. De igual manera, siguiendo el procedimiento ya mencionado se puede firmar de manera similar.

### ¿Qué divers/modulos estan cargados en sus propias pc?

