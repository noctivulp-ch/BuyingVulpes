#!/usr/bin/env bash
# Regenera las tres capturas del README (docs/capturas/*.png): la lista de
# compra en oscuro con oro, en claro con jade, y un corte diagonal entre claro
# y oscuro con peltre.
#
#   tools/capturas/capturas.sh
#
# Compila el release de Linux, siembra una base de demostración con los DAO de
# la app (sembrar_test.dart) y abre el binario dentro de Xvfb con un HOME
# temporal, una vez por tema: no abre ventanas en el escritorio ni toca los
# datos de quien lo ejecuta. Necesita flutter, xvfb-run, ImageMagick (import) y
# Python con Pillow y NumPy.
set -euo pipefail
cd "$(dirname "$0")/../.."

aislado="$(mktemp -d)"
trap 'rm -rf "$aislado"' EXIT
datos="$aislado/share/com.vulpes.buying_vulpes"
mkdir -p "$datos" "$aislado/crudas" docs/capturas

flutter build linux --release
CAPTURAS_BASE="$datos" flutter test tools/capturas/sembrar_test.dart

capturar() {  # nombre modo acento
  printf '{"flutter.modo_tema":"%s","flutter.acento":"%s"}' "$2" "$3" > "$datos/shared_preferences.json"
  HOME="$aislado" XDG_DATA_HOME="$aislado/share" XDG_CONFIG_HOME="$aislado/config" \
  GDK_BACKEND=x11 xvfb-run -a -s "-screen 0 1280x720x24" bash -c '
    build/linux/x64/release/bundle/buying_vulpes & app=$!
    sleep 6
    import -window root "$0"
    kill $app' "$aislado/crudas/$1.png"
}

capturar compra-oscuro-oro oscuro oro
capturar compra-claro-jade claro jade
capturar _claro-peltre claro peltre
capturar _oscuro-peltre oscuro peltre

cp "$aislado"/crudas/compra-*.png docs/capturas/
python3 tools/capturas/corte_diagonal.py \
  "$aislado/crudas/_claro-peltre.png" "$aislado/crudas/_oscuro-peltre.png" \
  docs/capturas/compra-claro-oscuro.png
ls -1 docs/capturas
