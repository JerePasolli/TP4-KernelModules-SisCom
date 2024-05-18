# TP4 - Kernel Modules - Sistemas de Computación 2024

## Desafío 1 

- ¿Qué es checkinstall y para qué sirve?
- ¿Se animan a usarlo para empaquetar un hello world ? 
- Revisar la bibliografía para impulsar acciones que permitan mejorar la seguridad del kernel, concretamente: evitando cargar módulos que no estén firmados.

## Desafío 2

Debe tener respuestas precisas a las siguientes preguntas y sentencias:
- ¿ Cómo empiezan y terminan unos y otros ?

```
Un programa generalmente comienza con la funcion `main()`, esto depende del lenguaje y de la implementacion, luego ejecuta una serie de instrucciones y termina despues de completarlas.
```

```
Un modulo siempre comienza con la funcion `module_init` o una funcion designada por la llamada `module_init`. Esta funcion notifica al kernel sobre las funcionalidades del modulo, preparandolo para que pueda llamarse al modulo cuando se lo requiera. Los modulos concluyen invocando `cleanup_module` o una funcion especifica a travez de la llamada `module_exit` con lo cual se desregistran las funcionalidades, por lo cual la funcion de entrada y de salida es obligatoria para un modulo.

module_init(hello_init); 
module_exit(hello_exit); 
```

- ¿Qué funciones tiene disponible un programa y un módulo?
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
- Espacio de usuario y Espacio del kernel:
```
El kernel gestiona principalmente el acceso a los recursos, ya sea una tarjeta de video, un disco duro o la memoria. Los programas frecuentemente compiten por los mismos recursos. El kernel tiene como objetivo mantener el orden, asegurando que distintos programas no accedan a los recursos de manera indiscriminada.

 Unix, utiliza solo dos anillos o niveles: el anillo más alto (anillo 0, también conocido como "modo supervisor", donde todas las acciones son permisibles) y el anillo más bajo, referido como "modo usuario".

Para verlo mas claro por ejemplo las función de biblioteca llama a una o más llamadas al sistema, y estas llamadas al sistema se ejecutan en nombre de la función de biblioteca, pero lo hacen en “supervisor mode” ya que son parte del propio kernel. Una vez que la llamada al sistema completa su tarea, regresa y la ejecución se transfiere de nuevo al “user mode”.
```

- Espacio de datos.
- Drivers. Investigar contenido de /dev.


## ¿Qué es checkinstall y para qué sirve?
checkinstall  is  a program that monitors an installation procedure (such as make install, install.sh ), and creates a standard package for your distribution (currently deb, rpm and tgz packages are sup‐
       ported) that you can install through your distribution's package management system (dpkg, rpm or installpkg).
```
```
asdasd
adas
'''