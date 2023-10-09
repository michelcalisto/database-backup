# Database backup script

### Descripción

Script para el respaldo y compresión de bases de datos.

### Construcción / Modificación

Antes de utilizar el script, diríjase al directorio donde se descargo el repositorio, ábralo con su editor de texto favorito 
y remplaze los textos ```"xxx"``` de la function respaldar, en el siguiente orden: usuario de mysql, password de mysql y finalmente el nombre de la base de datos que se desea respaldar. Por último asígnele permisos de ejecución al script.

``` bash
# dar permisos de ejecución al script
sudo chmod 775 backup.sh
```

### Utilización

Para utilizar el script, diríjase al directorio donde se descargo el repositorio, luego con la ayuda de la 
consola ejecute ```./backup.sh "ruta" "carpeta"``` siendo carpeta, el directorio donde se alojarán los respaldos, 
mientras que ruta es donde se ubicará carpeta.