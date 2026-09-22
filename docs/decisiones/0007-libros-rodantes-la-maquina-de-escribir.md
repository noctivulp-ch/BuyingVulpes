# 0007 — Libros de compras rodantes: la "máquina de escribir"

**Estado:** Aceptada · **Fecha:** 2026-09-21

## Contexto

El dueño, al ver la primera versión: *"con máquina de escribir me refería a
[…] lo que deja un archivo atrás cuando llega a cierto punto de uso para no
tener tablas infinitas de datos […] aunque el flujo no sea masivo es
importante, porque le da longevidad a la app"*.

La primera versión tenía `compra` y `linea_compra` en la base principal, con
el argumento de que cien filas al año no justificaban la complejidad. El
argumento era de rendimiento; el del dueño es de **longevidad**: una tabla
que solo crece es una deuda que se cobra en cinco años, y entonces migrar
datos vivos es lo caro. Se paga ahora, que no hay nada que mover.

## Decisión

Las compras viven en **libros**: archivos SQLite (`compras-2026.db`) con las
tablas `compra` y `linea_compra`, **uno por año calendario**. La base
principal guarda el catálogo y el índice `libro_compras`. El libro del año
se adjunta al abrir (`ATTACH … AS libro`); como las tablas no existen en la
principal, `SELECT * FROM compra` resuelve contra el adjunto y el DAO no
cambió una línea.

- **Rota al abrir una compra**, no al finalizarla: `prepararPara(fecha)` cierra
  el libro si el año cambió y abre el nuevo antes de insertar. Una compra
  nunca queda con sus líneas en un libro y su cierre en otro.
- **Cerrar es dejar de escribir.** Nada se mueve ni se borra: el archivo queda
  con su nombre y el índice lo marca cerrado con su `fecha_fin`.
- **Los cerrados se leen sin restaurar**: el historial pregunta al índice qué
  libro cubre el mes, y si está cerrado abre el archivo en modo lectura,
  consulta y lo cierra. Mirar 2024 desde 2029 es abrir un archivo.
- **El esquema del libro se pone al día al adjuntarlo o abrirlo**, preguntando
  `PRAGMA table_info` (hoy no hay columnas nuevas; el mecanismo ya está).
- **Migración v1 → v2** copia las compras al libro del año de la primera,
  comprueba que las cuentas cuadran y solo entonces borra las tablas viejas.
  Probada sobre una base v1 real y sobre la base del dueño (una compra).

## Por qué un año calendario y no "365 días con actividad"

VulpTiketing cuenta días con ventas para que un cierre largo no gaste el
libro. Acá el criterio es el año porque:

- El historial se mira **por mes**, y "qué libro tiene marzo de 2026" es una
  consulta al índice por año, sin recorrer fechas.
- El archivo se llama como la gente piensa: `compras-2026.db`.
- Con dos compras por semana, 365 días con actividad son tres años y medio
  en un archivo; el año es el corte natural.

El mecanismo (índice, ATTACH, rotación al escribir, lectura de cerrados) es
el mismo; solo cambia la regla de cuándo se pasa de hoja.

## Consecuencias

- `CompraDao` sigue igual. `CompraEnCursoNotifier` llama a `prepararPara` al
  abrir una compra y a `recontarDias` al finalizarla.
- `compraDetalladaProvider` se indexa por `(id, mes)`: sin el mes habría que
  abrir todos los libros cerrados para encontrar una compra.
- Un respaldo futuro tiene que llevar la base principal **y** los libros; un
  sync futuro, elegir libro (mismo pendiente que en VulpTiketing).
- Las pruebas adjuntan libros de verdad en una carpeta temporal a la base en
  memoria: rotación, lectura de cerrados y migración se prueban tal cual.
