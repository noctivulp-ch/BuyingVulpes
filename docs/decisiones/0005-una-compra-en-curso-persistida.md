# 0005 — Una sola compra en curso, guardada en la base

**Estado:** Aceptada · **Fecha:** 2026-09-21

## Contexto

VulpTiketing lleva el carrito de una venta en memoria: dura un minuto. Una
lista de compras se arma a lo largo de la semana, se abre en el
supermercado, se cierra la app a mitad y se retoma.

## Decisión

La compra en curso es una fila de `compra` con `finalizada_en IS NULL`, sus
líneas en `linea_compra`, y hay **una** como máximo. Se crea al anotar la
primera línea, no al abrir la app.

## Por qué

- Cerrar la app no puede perder la lista.
- Una sola: dos listas a la vez es un concepto que nadie pidió, y complica
  cada pantalla ("¿a cuál anoto?"). Si hace falta, el esquema ya lo permite
  —solo habría que quitar el límite y elegir.

## Consecuencias

- `CompraEnCursoNotifier` lee siempre de la base después de escribir; no
  hay estado en memoria que pueda divergir.
- Finalizar deja `null` en curso; la próxima línea abre otra.
