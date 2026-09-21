# La compra

Hay **una compra en curso** como máximo. No existe hasta que se anota la
primera línea, y vive en la base: una lista se arma en días, y cerrar la app
no puede perderla.

## Anotar

Desde el panel de tiendas se marcan productos y se anotan. Cada línea copia
del producto su nombre, la tienda, el precio por medida, la cantidad habitual
y la medida ([0003](../decisiones/0003-la-compra-es-una-foto.md)).

## La lista

Dos secciones, cada una agrupada **por tienda**:

- **Por comprar**: lo anotado que todavía no cayó al carrito.
- **En el carrito**: lo marcado.

La casilla de cada línea la mueve de una a otra. Tocar el subtotal abre la
línea para cambiar **cantidad**, **precio de hoy** y **nota**, o quitarla.

Si el precio cambia, el interruptor "Guardar este precio en el producto"
—encendido de fábrica— actualiza el catálogo
([0004](../decisiones/0004-la-linea-ensena-al-catalogo.md)). Es la forma de
mantener los precios al día sin ir a editar productos aparte: se corrige en
la góndola y queda.

## El pie

Tres cifras y un botón:

| Cifra | Qué es | En rojo cuando |
|---|---|---|
| Lista | Σ subtotales de TODO lo anotado | supera el presupuesto |
| Carrito | Σ de lo marcado | supera el presupuesto |
| Queda / Pasado | presupuesto − carrito | es negativo |

Sin presupuesto, la tercera dice "—". El presupuesto se pone desde la
etiqueta de la barra superior; vacío lo quita.

Avisar de que **la lista** excede el presupuesto, aunque el carrito todavía
no, es deliberado: conviene saberlo en el pasillo, no en la caja.

## Finalizar

"Finalizar compra · N/M" (marcados/anotados). Pide confirmación y, si hay
líneas sin marcar, lo dice: quedan en el desglose como **no compradas**, que
es información —lo que no se consiguió o no alcanzó.

Al finalizar: se cierra la compra (`finalizada_en`), se genera el PDF, se
abre el detalle, y la próxima línea que se anote abre una compra nueva.
