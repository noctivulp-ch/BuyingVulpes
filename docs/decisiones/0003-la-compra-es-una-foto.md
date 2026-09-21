# 0003 — La línea de compra copia tienda, producto, precio y medida

**Estado:** Aceptada · **Fecha:** 2026-09-21

## Contexto

"Esa factura se guarda en un calendario … con todos los datos para
comparar." Comparar exige que el desglose de marzo diga lo que costó en
marzo, aunque el producto haya cambiado de precio o de nombre en junio.

## Decisión

`linea_compra` lleva copiados `tienda_nombre`, `producto_nombre`, `precio` y
`medida`. `producto_id` queda como referencia blanda, nullable. Nada que
edite el catálogo toca una compra finalizada, y hay una prueba que lo exige
(`compra_en_curso_test.dart`).

## Por qué

Es la misma regla que `precio_aplicado` en VulpTiketing: un registro de lo
que pasó es una foto, no una referencia viva. La alternativa —un JOIN al
producto en el momento de leer— reescribe la historia cada vez que se
corrige el catálogo.

## Consecuencias

- Archivar un producto o una tienda no rompe ningún desglose.
- El PDF y el detalle se construyen solo con `linea_compra`.
- Comparar precios de un producto en el tiempo es consultar sus líneas por
  `producto_id` — está en el `TODO.md`.
