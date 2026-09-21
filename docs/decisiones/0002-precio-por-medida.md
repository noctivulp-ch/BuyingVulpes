# 0002 — El precio es por medida; subtotal = precio × cantidad

**Estado:** Aceptada · **Fecha:** 2026-09-21

## Contexto

El pedido: "al crear un producto uno tiene que colocar el precio y la
cantidad además de la medida". Cabían dos lecturas: el precio del paquete
(un bulto de 2 kg cuesta ₡2.500) o el precio por unidad de medida (₡1.250 el
kilo, y se llevan 2).

## Decisión

El precio es **por la medida** (`Medida`: unidad, kilogramo, gramo, litro,
mililitro, paquete, docena) y la cantidad va en esa medida. La línea vale
`precio × cantidad`. El producto guarda la **cantidad habitual** como punto
de partida; la línea la cambia sin tocar el producto.

## Por qué

- Es la convención de las apps de referencia (SoftList, Shopping List
  Calculator) y la de la góndola: el precio por kilo está en la etiqueta.
- Cambiar la cantidad recalcula solo. Con precio por paquete, "llevo tres"
  habría exigido un segundo concepto de cantidad.
- Un paquete cerrado se modela igual: medida `paquete` o `unidad`, precio
  del paquete, cantidad 1.

## Consecuencias

- La medida es un enum cerrado, guardado por nombre. Un campo libre deja
  "kg", "Kg" y "kilos" en el mismo catálogo.
- Los subtotales pueden tener decimales (1,5 kg × ₡800): el formato los
  muestra solo cuando existen.
