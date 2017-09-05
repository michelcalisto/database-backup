#!/bin/bash
#
# Title		: backup-db.sh
# Description	: Script para el respaldo de bases de datos.
# Author	: laloinsane
# Version	: 0.1

fechaformato1=`date +%d-%m-%Y_%H-%M-%S`
fechaformato2=`date +%d/%m/%Y`
horaformato2=`date +%T`
archivo="backupdb_$fechaformato1"
ruta=$1
carpeta=$2

function comprobarMysqlDump {
	if [ $? != 0 ]
	then
		echo "$fechaformato2 a las $horaformato2, ocurrió un error con mysqldump durante el proceso de respaldo de base de datos." >> "registro.txt"
		rm -rf $archivo.sql
		exit 1
	fi
}

function comprobarGzip {
	if [ $? = 0 ]
	then
		echo "$fechaformato2 a las $horaformato2, respaldo de base de datos realizado satisfactoriamente." >> "registro.txt"
	else
		echo "$fechaformato2 a las $horaformato2, ocurrió un error con gzip durante el proceso de respaldo de base de datos." >> "registro.txt"
		exit 1
	fi
}

function respaldar {
	mysqldump --user=xxx --password=xxx xxx > "$archivo.sql" 2>/dev/null
	comprobarMysqlDump
	gzip -q "$archivo.sql" 2>/dev/null
	comprobarGzip
}

if [ $# -eq 2 ]
then
	if [ -d "$ruta" ]
	then
		cd $ruta
		if [ -d $carpeta ]
		then
			cd $carpeta
			respaldar
		else
			mkdir $carpeta
			cd $carpeta
			respaldar
		fi
	else
		echo "No existe la ruta señalada" 1>&2
		exit 1
	fi
else
	echo "Error, debes introducir dos parametros" 1>&2
	exit 1
fi
