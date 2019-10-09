#!/bin/bash
#
# Title		: update_gist.sh
# Description	: Script para la actualización de gists.
# Author	: Michel Calisto
# Version	: 0.1

# Variables
user=$1
password=$2
database=$3
collection=$4
description=$5
file_name=$6
id=$7
file_name_old=$8
path="/tmp/$database"

# Functions
function isEmptyCollection {
    mongo $database --eval "db.$collection.find().count()" > /dev/null
    if [ $? = 0 ]; then
        let count=`mongo $database --eval "db.$collection.find().count()" --quiet` 
        if [ $count = 0 ]; then
            echo "Error!!! la colección se encuentra vacía." 1>&2
		    exit 1
        else
            createEnviroment
        fi
	else
		echo "Error!!! en la conexión con la base de datos." 1>&2
		exit 1
	fi
}

function createEnviroment {
    if [ -d $path ]; then
        rm -rf $path
        mkdir $path
		exportCollection
	else
		mkdir $path
		exportCollection
	fi
}

function exportCollection {
	mongoexport --db $database --collection $collection --out "$path/gist_manager.json" &>/dev/null
	if [ $? = 0 ]; then
		echo "Colección exportada satisfactoriamente."
		convertStringJSON
	else
		echo "Error!!! al exportar la colección." 1>&2
		exit 1
	fi
}

function convertStringJSON {
    touch $path/string_json.json
	sed -e 's/"/\\"/g' -e 's/0}/0}\\n/g' $path/gist_manager.json > $path/string_json.json
	if [ $? = 0 ]; then
		echo "Colección convertida a string satisfactioriamente."
		createDefaultJSON
	else
		echo "Error!!! al convertir la colección a string." 1>&2
		exit 1
	fi
}


function createDefaultJSON {
	touch $path/default.json
	cat > $path/default.json << EOF
{
  "description": "$description",
  "public": true,
  "files": {
    "$file_name_old.json": null,
    "$file_name.json": {
      "content": "content_json"
    }
  }
}
EOF
	updateJSON
}

function updateJSON {
	touch $path/complete_json.json
	sed -e "s/content_json/$(sed -e 's/[\&/]/\\&/g' -e 's/$/\\n/' $path/string_json.json | tr -d '\n')/g" $path/default.json > $path/complete_json.json
	if [ $? = 0 ]; then
		echo "Colección convertida a string satisfactioriamente."
		uploadGist
	else
		echo "Error!!! al convertir la colección a string." 1>&2
		exit 1
	fi
}


function uploadGist {
	touch $path/upload.json
	curl --user "$user:$password" --data @$path/complete_json.json -X PATCH https://api.github.com/gists/$id
	if [ $? = 0 ]; then
		echo "Gist de GitHub actualizado satisfactioriamente."
        		mongo mongodb://localhost/$database <<EOF
db.gists.update(
{
    id: "$id"    
},
{
	id: "$id",
    description: "$description",
    name: "$file_name"
})
EOF
        if [ $? = 0 ]; then
            echo "Gist de la base de datos actualizado satisfactioriamente."
            rm -rf $path
        else
            echo "Error!!! al actualizar el Gist de la base de datos." 1>&2
            exit 1
        fi
	else
		echo "Error!!! al actualizar el Gist de Github." 1>&2
		exit 1
	fi
}

# Main
if [ $# -eq 8 ]; then
	isEmptyCollection
else
	echo "Error!!! debes introducir ocho parametros." 1>&2
	exit 1
fi