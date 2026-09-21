# 0004 — Corregir el precio en la línea actualiza el producto, de fábrica

**Estado:** Aceptada · **Fecha:** 2026-09-21

## Contexto

"Los artículos editados o creados se guardan en su respectiva lista por
supermercado." El precio se descubre en la góndola, con la lista abierta. Si
corregirlo obligara a ir al catálogo, no se corregiría, y el catálogo
envejecería.

## Decisión

Al editar una línea, si el precio cambió, aparece el interruptor "Guardar
este precio en el producto", **encendido**. Cantidad y nota son siempre solo
de la línea.

## Por qué

- Lo normal es que el precio nuevo sea el precio de ahora en adelante.
- Encendido y visible, no automático y oculto: hay ofertas de un día que no
  hay que recordar, y apagarlo es un toque.

## Consecuencias

- `CompraEnCursoNotifier.editarLinea(actualizarProducto:)` es el único punto
  donde una operación de compra toca el catálogo, y lo hace a través de
  `ProductoNotifier`, no del DAO.
- Solo el precio viaja. Cambiar la medida o el nombre sí es editar el producto.
