# BuyingVulpes — Documentación

Listas de compras por tienda. Se anota lo que hace falta eligiendo productos
de cada tienda, se marca lo que va cayendo al carrito, se mira cuánto va y
cuánto queda del presupuesto, y al finalizar la compra queda un desglose en
PDF archivado en un calendario para comparar después.

## Cómo navegar

| Carpeta | Qué hay |
|---|---|
| [arquitectura/](arquitectura/) | Stack, [datos](arquitectura/datos.md), [gestión de estado](arquitectura/gestion-estado.md) |
| [funciones/](funciones/) | [Catálogo](funciones/catalogo.md), [la compra](funciones/compra.md), [historial y PDF](funciones/historial.md) |
| [decisiones/](decisiones/index.md) | ADRs numerados: qué se decidió y por qué |
| [pantallas/](pantallas/flujo.md) | Las tres ventanas (Compra, Historial, Ajustes) y cómo se pasa de una a otra |
| [referencias/](referencias/apps-de-referencia.md) | Las apps que se miraron antes de diseñar |
| `../features/*.feature` | La verdad funcional cerrada, en Gherkin |

## El pedido original

Lo dijo el dueño el 2026-09-21, con estas palabras, y es contra lo que se
mide todo lo que hay:

- Lista de productos **por tienda**; crear tiendas y productos sin fricción;
  se arranca sin ninguna.
- Un producto lleva **precio, cantidad y medida** (unidades, kilogramos…),
  foto, nombre y notas.
- Para armar la lista se elige la tienda y se van seleccionando o creando los
  productos; cada artículo con una **casilla** que al marcarla lo pasa a una
  lista inferior, **el carrito**; abajo el **total de la lista y el del
  carrito**, con opción de **presupuesto**.
- **Finalizar compra** guarda la lista, con un **desglose en PDF** bien
  formateado para comparar, archivado en un **calendario mensual** como el de
  VulpTiketing. Lo editado o creado durante la compra queda en su tienda.
- Se pueden elegir productos de **varias tiendas**, ordenados por tienda.
- Las tiendas con sus artículos van en una **ventana lateral izquierda
  abatible que ocupa la pantalla completa**, con **selección múltiple**.
