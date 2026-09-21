# Catálogo: tiendas y productos

## Tienda

Nombre y notas. Se crea desde el panel lateral con el botón "Tienda", y se
edita con una pulsación larga sobre su fila. Archivar una tienda no está en la
UI todavía (el Notifier lo tiene); una tienda con compras en el historial se
sigue nombrando allí aunque se archive.

## Producto

Pertenece a **una** tienda ([decisión 0001](../decisiones/0001-un-producto-por-tienda.md)).
Campos:

| Campo | Qué es |
|---|---|
| Nombre | Obligatorio |
| Precio | **Por la medida**: el kilo, el litro, la unidad ([0002](../decisiones/0002-precio-por-medida.md)). Cero permitido (regalo, muestra) |
| Por (medida) | Enum cerrado: unidad, kilogramo, gramo, litro, mililitro, paquete, docena |
| Cantidad habitual | Lo que se suele llevar. La línea la copia al anotar y se cambia ahí sin tocar el producto |
| Foto | Galería o cámara (cámara solo en móvil). Se copia reducida a 800 px y el producto guarda el nombre del archivo |
| Notas | Texto libre: marca preferida, "el de la góndola del fondo", lo que sea |

Se crea desde la fila de su tienda en el panel (el `+` a la derecha). **Lo
recién creado queda marcado**: si se creó desde el panel es porque se va a
anotar. Se edita con el lápiz de su fila. "Quitar" en el formulario lo
archiva (borrado lógico).

## El panel lateral

Es un cajón (`Drawer`) que **ocupa todo el ancho**: abierto, es la ventana.
Lista las tiendas como pozos desplegables; dentro, cada producto con su
casilla, precio por medida y, si ya está anotado, "· ya en la lista".

Se pueden marcar productos de **varias tiendas** y el botón del pie anota
todos de una vez. Un producto ya anotado no se duplica; el aviso lo dice.
