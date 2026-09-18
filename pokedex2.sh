#!/usr/bin/env bash
# pokedex2.sh - Muestra el tipo o los tipos de un Pokémon usando PokéAPI.
# Uso:    ./pokedex2.sh nombre
# Salida: una sola línea, por ejemplo -> charizard: fire, flying
# Código de salida: 0 si todo salió bien, 1 si hubo cualquier error.

# Con el locale "C", [a-z] significa solo letras de la a a la z (sin acentos).
LC_ALL=C

# ---------- Configuración ----------
# Carpeta donde está este script (así funciona aunque se ejecute desde otra carpeta)
DIR_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_CACHE="$DIR_SCRIPT/data"
URL_BASE="https://pokeapi.co/api/v2/pokemon"
TIEMPO_CONEXION=5   # segundos máximos para conectarse
TIEMPO_TOTAL=10     # segundos máximos por consulta

# Archivo temporal: se borra siempre al terminar el script
TEMPORAL=""
trap 'rm -f "$TEMPORAL"' EXIT

# ---------- Funciones ----------
mostrar_uso() {
  echo "Uso: ./pokedex2.sh nombre" >&2
}

# Error de uso: explica el problema, muestra el uso y termina con código 1
error_uso() {
  echo "Error: $1" >&2
  mostrar_uso
  exit 1
}

# Error general: muestra el mensaje en stderr y termina con código 1
error() {
  echo "Error: $1" >&2
  exit 1
}

# Comprueba que un archivo JSON tenga los campos necesarios
json_valido() {
  jq -e '
    (.name | type == "string")
    and (.types | type == "array" and length > 0)
    and all(.types[]; (.slot | type == "number") and (.type.name | type == "string"))
  ' "$1" >/dev/null 2>&1
}

# Consulta la API (máximo 2 intentos) y guarda la respuesta válida en la caché
descargar_pokemon() {
  local url="$URL_BASE/$nombre/"
  local intento codigo estado mensaje=""

  mkdir -p "$DIR_CACHE" || error "no se pudo crear la carpeta $DIR_CACHE"
  TEMPORAL="$(mktemp "$DIR_CACHE/.tmp.XXXXXX")" || error "no se pudo crear un archivo temporal"

  for intento in 1 2; do
    # Guarda el cuerpo en el archivo temporal y devuelve solo el código HTTP
    codigo="$(curl -sS --connect-timeout "$TIEMPO_CONEXION" --max-time "$TIEMPO_TOTAL" \
      -o "$TEMPORAL" -w '%{http_code}' "$url" 2>/dev/null)"
    estado=$?

    if [ "$estado" -ne 0 ]; then
      # curl falló antes de recibir respuesta: conexión o tiempo de espera
      if [ "$estado" -eq 28 ]; then
        mensaje="se agotó el tiempo de espera al consultar PokéAPI."
      else
        mensaje="no se pudo conectar con PokéAPI (revisa tu conexión a internet)."
      fi
    else
      case "$codigo" in
        200)
          if json_valido "$TEMPORAL"; then
            mv "$TEMPORAL" "$ARCHIVO" || error "no se pudo guardar la caché en $ARCHIVO"
            chmod 644 "$ARCHIVO"
            return 0
          fi
          error "la respuesta de PokéAPI no tiene el formato esperado."
          ;;
        404)
          echo "Pokémon no encontrado" >&2
          exit 1
          ;;
        429|5??)
          mensaje="PokéAPI tuvo un error temporal (HTTP $codigo)."
          ;;
        *)
          error "PokéAPI respondió con un error inesperado (HTTP $codigo)."
          ;;
      esac
    fi

    # Si fue el primer intento, espera un segundo y vuelve a intentar
    if [ "$intento" -eq 1 ]; then
      sleep 1
    fi
  done

  error "$mensaje (se intentó 2 veces)"
}

# ---------- 1. Validar la entrada ----------
if [ "$#" -ne 1 ]; then
  error_uso "se necesita exactamente un argumento: el nombre del Pokémon."
fi

nombre="${1,,}"   # convierte a minúsculas

if [ -z "$nombre" ]; then
  error_uso "el nombre no puede estar vacío."
fi

if [[ ! "$nombre" =~ ^[a-z0-9-]+$ ]]; then
  error_uso "el nombre solo puede contener letras, números o guiones."
fi

# ---------- 2. Comprobar que curl y jq estén instalados ----------
faltan=0
for programa in curl jq; do
  if ! command -v "$programa" >/dev/null 2>&1; then
    echo "Error: no está instalado '$programa'. Instálalo con: sudo apt install $programa" >&2
    faltan=1
  fi
done
if [ "$faltan" -eq 1 ]; then
  exit 1
fi

# ---------- 3. Usar la caché o consultar la API ----------
ARCHIVO="$DIR_CACHE/$nombre.json"

if [ ! -f "$ARCHIVO" ] || ! json_valido "$ARCHIVO"; then
  descargar_pokemon
fi

# ---------- 4. Mostrar el resultado ----------
# Ordena los tipos por slot y los une con ", "
if ! resultado="$(jq -r '.name + ": " + ([.types | sort_by(.slot) | .[] | .type.name] | join(", "))' "$ARCHIVO")"; then
  error "no se pudo leer el archivo JSON."
fi

echo "$resultado"
exit 0
