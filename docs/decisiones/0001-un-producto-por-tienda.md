# 0001 — Un producto pertenece a una tienda

**Estado:** Aceptada · **Fecha:** 2026-09-21

## Contexto

"Lista de productos por tienda" fue la primera frase del pedido. Había dos
formas de modelarlo: un catálogo global de productos con una tabla de precios
por tienda, o productos que viven dentro de cada tienda.

## Decisión

`producto.tienda_id NOT NULL`. El arroz de Walmart y el arroz de la Feria son
dos productos, cada uno con su precio, su foto y sus notas.

## Por qué

- Es como se piensa al hacer la lista: "en Walmart llevo esto, en la feria
  aquello". La tienda es el contexto, no un atributo.
- Comparar precios entre tiendas se hace igual —el historial guarda la
  tienda en cada línea— sin obligar a decidir de antemano qué es "el mismo"
  producto. Emparejar "Arroz Tío Pelón 2 kg" con "Arroz 2kg Tio Pelon" es
  un problema que no vale la pena resolver en la primera versión.
- Un catálogo global con precios por tienda es la forma correcta cuando hay
  cientos de tiendas y un producto normalizado (código de barras). Acá hay
  cuatro tiendas y lo que la persona escribió.

## Consecuencias

- No hay "mover producto de tienda": se crea en la otra.
- Si más adelante se quiere "el mismo producto en varias tiendas", el camino
  es un `grupo_id` opcional en producto que los emparente, sin tocar esto.
