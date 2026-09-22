# Historial y desglose en PDF

## De dónde salen

De los **libros**: un archivo por año ([0007](../decisiones/0007-libros-rodantes-la-maquina-de-escribir.md)).
El año en curso está adjunto; un año anterior se abre solo para leer cuando
el calendario lo pide, y se cierra. No hay "restaurar" para mirar atrás.

## Calendario

Un mes por pantalla, como el de VulpTiketing: los días con compras llevan el
número en negrita y un punto; el de hoy, un borde. Tocar un día filtra la
lista de abajo a ese día; tocarlo de nuevo la suelta. No se puede avanzar
más allá del mes actual.

Debajo, las compras del mes (o del día): fecha y hora, cuántos artículos se
compraron de los anotados, las tiendas, y el total comprado.

## Detalle

Fecha completa, un pozo con las cuentas (comprado, anotado, sin comprar,
presupuesto y sobró/se pasó) y un pozo por tienda con cada línea: ✓ si se
compró, — si no, cantidad, nota y subtotal.

## PDF

El botón de archivo de la barra superior lo genera (si ya existe, lo
regenera igual —es determinista— y lo abre con el visor del sistema). Lleva:

- Fecha y hora, cuántos artículos en cuántas tiendas, cuántos comprados.
- Una tabla por tienda: ✓/–, producto, cantidad con medida, precio por
  medida, subtotal, notas; y el total de la tienda con lo comprado.
- Totales: lista, comprado, sin comprar, presupuesto, sobró/se pasó.

Se guarda en `<documentos>/BuyingVulpes/compras/compra_AAAA-MM-DD_HHMM.pdf`.
En Android esa carpeta es privada de la app; llevarlo a Descargas por
MediaStore, como hace VulpTiketing, está en el `TODO.md`.

Las fuentes son Noto Sans recortadas (las mismas de VulpTiketing): las de
fábrica del generador no tienen el ₡.
