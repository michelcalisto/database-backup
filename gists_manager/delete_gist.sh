#!/bin/bash
#
# Title		: delete_gist.sh
# Description	: Script para la eliminación de gists.
# Author	: Michel Calisto
# Version	: 0.1

# Variables
user=$1
password=$2
database=$3
id=$4

# Functions
function isEmptyCollection {
    mongo $database --eval "db.gists.find().count()" > /dev/null
    if [ $? = 0 ]; then
        let count=`mongo $database --eval "db.gists.find().count()" --quiet` 
        if [ $count = 0 ]; then
            echo "Error!!! la colección se encuentra vacía." 1>&2
		    exit 1
        else
            deleteGist
        fi
	else
		echo "Error!!! en la conexión con la base de datos." 1>&2
		exit 1
	fi
}

function deleteGist {
    curl --user "$user:$password" -X DELETE https://api.github.com/gists/$id
    if [ $? = 0 ]; then
		echo "Gist eliminado de GitHub satisfactioriamente."
		mongo mongodb://localhost/$database <<EOF
db.gists.remove(
{
    id: "$id"    
})
EOF
        if [ $? = 0 ]; then
            echo "Gist de la base de datos eliminado satisfactioriamente."
            rm -rf $path
        else
            echo "Error!!! al eliminar el Gist de la base de datos." 1>&2
            exit 1
        fi
	else
		echo "Error!!! al eliminar el Gist de GitHub." 1>&2
		exit 1
	fi
}

# Main 
if [ $# -eq 4 ]; then
	isEmptyCollection
else
	echo "Error!!! debes introducir cuatro parametros." 1>&2
	exit 1
fi