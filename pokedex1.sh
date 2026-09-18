#!/bin/bash

# Verificar si se proporcionó un argumento
if [ -z "$1" ]; then
  echo "Uso: $0 <nombre_pokemon>"
  exit 1
fi

# Convertir el nombre a minúsculas para la API
nombre=$(echo "$1" | tr 'A-Z' 'a-z')
url="https://pokeapi.co/api/v2/pokemon/$nombre"

# Consultar la API capturando la respuesta y el código HTTP
# -s: silencioso, -w: escribe el código http al final, -L: sigue redirecciones
respuesta=$(curl -s -L -w "\n%{http_code}" "$url")
codigo=$(echo "$respuesta" | tail -n 1)
json=$(echo "$respuesta" | sed '$d')

# Manejo de error 404
if [ "$codigo" != "200" ]; then
  echo "No encontrado: $nombre (HTTP $codigo)"
  exit 1
fi

# Extraer el id y el nombre usando jq
id=$(echo "$json" | jq -r '.id')
nombre_poke=$(echo "$json" | jq -r '.name')

# Extraer el primer tipo del Pokémon
tipo=$(echo "$json" | jq -r '.types[0].type.name')

# Base de datos interna de tipos (Fortalezas y Debilidades)
# Según la tabla de tipos (simplificada para el primer tipo)
case "$tipo" in
  "normal")
    fuerte="Ninguno"
    debil="Lucha"
    ;;
  "fire")
    fuerte="Bicho, Acero, Planta, Hielo"
    debil="Roca, Fuego, Agua, Dragón"
    ;;
  "water")
    fuerte="Tierra, Roca, Fuego"
    debil="Agua, Planta, Dragón"
    ;;
  "grass")
    fuerte="Tierra, Roca, Agua"
    debil="Volador, Veneno, Bicho, Acero, Fuego, Planta, Dragón"
    ;;
  "electric")
    fuerte="Volador, Agua"
    debil="Planta, Eléctrico, Dragón"
    ;;
  "ice")
    fuerte="Volador, Tierra, Planta, Dragón"
    debil="Acero, Fuego, Agua, Hielo"
    ;;
  "fighting")
    fuerte="Normal, Roca, Acero, Hielo, Siniestro"
    debil="Volador, Veneno, Bicho, Psíquico, Hada"
    ;;
  "poison")
    fuerte="Planta, Hada"
    debil="Veneno, Tierra, Roca, Fantasma"
    ;;
  "ground")
    fuerte="Veneno, Roca, Acero, Fuego, Eléctrico"
    debil="Bicho, Planta"
    ;;
  "flying")
    fuerte="Lucha, Bicho, Planta"
    debil="Roca, Acero, Eléctrico"
    ;;
  "psychic")
    fuerte="Lucha, Veneno"
    debil="Acero, Psíquico"
    ;;
  "bug")
    fuerte="Planta, Psíquico, Siniestro"
    debil="Lucha, Volador, Veneno, Fantasma, Acero, Fuego, Hada"
    ;;
  "rock")
    fuerte="Volador, Bicho, Fuego, Hielo"
    debil="Lucha, Tierra, Acero"
    ;;
  "ghost")
    fuerte="Fantasma, Psíquico"
    debil="Siniestro"
    ;;
  "dragon")
    fuerte="Dragón"
    debil="Acero"
    ;;
  "dark")
    fuerte="Fantasma, Psíquico"
    debil="Lucha, Siniestro, Hada"
    ;;
  "steel")
    fuerte="Roca, Hielo, Hada"
    debil="Acero, Fuego, Agua, Eléctrico"
    ;;
  "fairy")
    fuerte="Lucha, Dragón, Siniestro"
    debil="Veneno, Acero, Fuego"
    ;;
  *)
    fuerte="Desconocido"
    debil="Desconocido"
    ;;
esac

# Traducir el tipo al español para la salida
case "$tipo" in
  "normal") tipo_es="normal" ;;
  "fire") tipo_es="fuego" ;;
  "water") tipo_es="agua" ;;
  "grass") tipo_es="planta" ;;
  "electric") tipo_es="eléctrico" ;;
  "ice") tipo_es="hielo" ;;
  "fighting") tipo_es="lucha" ;;
  "poison") tipo_es="veneno" ;;
  "ground") tipo_es="tierra" ;;
  "flying") tipo_es="volador" ;;
  "psychic") tipo_es="psíquico" ;;
  "bug") tipo_es="bicho" ;;
  "rock") tipo_es="roca" ;;
  "ghost") tipo_es="fantasma" ;;
  "dragon") tipo_es="dragón" ;;
  "dark") tipo_es="siniestro" ;;
  "steel") tipo_es="acero" ;;
  "fairy") tipo_es="hada" ;;
  *) tipo_es="$tipo" ;;
esac

# Imprimir la salida en el formato solicitado
echo "id:$id"
echo "name:\"$nombre_poke\""
echo "tipo:\"$tipo_es\""
echo "debil contra:\"$debil\""
echo "fuerte contra:\"$fuerte\""
