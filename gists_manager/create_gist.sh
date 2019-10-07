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
path="/tmp/$database"

# Funciones
function main {
	if [ -d $path ]; then
		exportCollection
	else
		mkdir $path
		exportCollection
	fi
}

function exportCollection {
	mongoexport --db $database --collection $collection --out "$path/gist_manager.json" &>/dev/null
	if [ $? = 0 ]; then
		echo "Collection exportada satisfactoriamente"
		JSON
	else
		rm -rf $path
		echo "Error al exportar la Collection." 1>&2
		exit 1
	fi
}

function JSON {
	if [ -f $path/final.json ]; then
		rm -rf $path/final.json
		updateJSON
	else
		updateJSON
	fi
}

function updateJSON {
	touch $path/final.json
	sed -e 's/"/\\"/g' -e 's/0}/0}\\n/g' $path/gist_manager.json > $path/final.json
	if [ $? = 0 ]; then
		echo "Collection convertida a String satisfactioriamente."
		createJSON
	else
		echo "Error al convertir la Collection a String." 1>&2
		exit 1
	fi
}

function createJSON {
	touch $path/wena.json
	cat > $path/wena.json << EOF
{
  "description": "Descripción",
  "public": true,
  "files": {
    "wena.json": {
      "content": "content_json"
    }
  }
}
EOF
	modificarJSON
}

function modificarJSON {
	touch $path/nose.json
	var="ho al osjofjas dfosjd aosdjf osadifj sdifjsd fisdjf "
	content=`cat $path/final.json`
	con=$(cat $path/final.json)
	sed -e "s/content_json/$(sed -e 's/[\&/]/\\&/g' -e 's/$/\\n/' $path/final.json | tr -d '\n')/g" $path/wena.json > $path/nose.json
	#sed -e "s/content_json/$(cat /tmp/mmands/final.json)/g" $path/wena.json
	if [ $? = 0 ]; then
		echo "Collection convertida a String satisfactioriamente."
		subirGist
	else
		echo "Error al convertir la Collection a String." 1>&2
		exit 1
	fi
}

function subirGist {
	touch $path/resultado.json
	curl --user "$user:$password" --data @$path/nose.json https://api.github.com/gists > $path/resultado.json
	if [ $? = 0 ]; then
		echo "Gist subido satisfactioriamente."
		touch $path/id.json
		grep -Eo '["][a-z,A-Z,0-9]{32}["]' $path/resultado.json > $path/id.json
		hola=$(grep -Eo '[a-z,A-Z,0-9]{32}' $path/id.json)
		mongo mongodb://localhost/$database <<EOF
db.gists.insert({
	id: "$hola"
})
EOF
	else
		echo "Error al subir el Gist." 1>&2
		exit 1
	fi
}

function isEmptyCollectionBackUp {
    mongo $database --eval "db.gists.find().count()" > /dev/null
    if [ $? = 0 ]; then
		echo "Gist subido satisfactioriamente."
        let count=`mongo $database --eval "db.gists.find().count()" --quiet` 
        if [ $count = 0 ]; then
            echo "0 colec"
        else
            echo "1 o mas"
        fi
	else
		echo "Error al subir el Gist." 1>&2
		exit 1
	fi

}

# Main 
if [ $# -eq 4 ]; then
    #main
	isEmptyCollectionBackUp
else
	echo "Error, debes introducir cuatro parametros" 1>&2
	exit 1
fi