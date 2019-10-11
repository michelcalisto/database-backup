#!/bin/bash
#
# Title		: create_gist.sh
# Description	: Script para la creación de gists.
# Author	: Michel Calisto
# Version	: 0.1

# Variables
user=$1
password=$2
database=$3
collection=$4
description=$5
file_name=$6
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
	line=$(wc -l < $path/gist_manager.json)
    num=$(($line-1))
    sed -e 's/"/\\"/g' -e 's/0}/0},\\n/g' $path/gist_manager.json | head -n $num > $path/string_json.json
    sed -e 's/"/\\"/g' $path/gist_manager.json | tail -1 >> $path/string_json.json
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
    "$file_name.json": {
      "content": "[content_json]"
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
	curl --user "$user:$password" --data @$path/complete_json.json -X POST https://api.github.com/gists > $path/upload.json
	if [ $? = 0 ]; then
		echo "Gist agregado a GitHub satisfactioriamente."
        id=$(grep -Eo '["][a-z,A-Z,0-9]{32}["]' $path/upload.json | grep -Eo '[a-z,A-Z,0-9]{32}')
		raw=`grep -Eo "(https:\/\/gist\.githubusercontent\.com\/)$user[\/]{1}[a-z,A-Z,0-9]{32}[\/]{1}(raw)[\/]{1}[a-z,A-Z,0-9]{40}[\/]{1}($file_name.json)" $path/upload.json`
		mongo mongodb://localhost/$database <<EOF
db.gists.insert(
{
	id: "$id",
    description: "$description",
    name: "$file_name",
	raw: "$raw"
})
EOF
        if [ $? = 0 ]; then
            echo "Gist agregado a la base de datos satisfactioriamente."
			echo "Raw URL: "$raw
			rm -rf $path
        else
            echo "Error!!! al agregar el Gist a la base de datos." 1>&2
            exit 1
        fi
	else
		echo "Error!!! al agregar el Gist a GitHub." 1>&2
		exit 1
	fi
}

# Main 
if [ $# -eq 6 ]; then
	isEmptyCollection
else
	echo "Error!!! debes introducir seis parametros." 1>&2
	exit 1
fi