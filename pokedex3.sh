#!/bin/bash

# Validar que el usuario ingrese un argumento
if [ -z "$1" ]; then
  echo "Uso: $0 <nombre_pokemon>"
  exit 1
fi

# Convertir el texto a minúsculas porque la API es sensible a mayúsculas
nombre=$(echo "$1" | tr 'A-Z' 'a-z')
url="https://pokeapi.co/api/v2/pokemon/$nombre"

# Descargar el JSON y pegar el código HTTP al final de la respuesta
respuesta=$(curl -s -w '\n%{http_code}' "$url")
codigo=$(echo "$respuesta" | tail -n 1)
json=$(echo "$respuesta" | sed '$d')

# Manejo del error 404 cuando el Pokémon no existe
if [ "$codigo" != "200" ]; then
  echo "No encontrado"
  exit 1
fi

# Filtrado y formato de salida con jq
echo "$json" | jq -r '
  "ID:     #\(.id)",
  "Nombre: \(.name)",
  "Altura: \(.height / 10) m",
  "Peso:   \(.weight / 10) kg",
  "Estadísticas:", (.stats[] | "  - \(.stat.name): \(.base_stat)")
'
