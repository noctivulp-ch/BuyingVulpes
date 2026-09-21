# Gestión de estado — Riverpod, un Notifier por entidad

Misma disciplina que VulpTiketing (allí, decisiones 0009 y 0014): **sin
CRUD genérico**. Cada entidad tiene exactamente las operaciones que su vida
real permite, y ninguna comparte una clase base con otra.

## Notifiers (escriben)

| Notifier | Entidad | Operaciones | Lo que NO tiene, y por qué |
|---|---|---|---|
| `TiendaNotifier` | Tienda | crear, actualizar, archivar | borrar físico y restaurar: nadie lo pidió; una tienda con historial no puede borrarse |
| `ProductoNotifier` | Producto | crear, actualizar, archivar | idem; "mover de tienda": el mismo producto en otra tienda es otro producto (0001) |
| `CompraEnCursoNotifier` | la compra abierta y sus líneas | agregarProductos, marcar, editarLinea (opcionalmente actualiza el producto, 0004), quitarLinea, ponerPresupuesto, finalizar | editar una compra cerrada: es una foto (0003); borrar una compra: es historial |

Los tres construyen el DAO **en cada llamada** (`Future<Dao> get _dao`) y
nunca lo guardan en un campo: en VulpTiketing, un DAO cacheado en `build()`
apuntaba a una conexión cerrada tras restaurar un backup y fallaba una vez de
cada dos.

## Providers derivados (solo leen)

| Provider | Qué da |
|---|---|
| `tiendasActivasProvider` | las tiendas sin `deleted_at` |
| `productosPorTiendaProvider` | `Map<tiendaId, List<Producto>>` de los activos |
| `comprasDelMesProvider(Mes)` | las finalizadas de un mes; lo invalida `finalizar()` |
| `compraDetalladaProvider(id)` | una compra cerrada con sus líneas y su `ResumenCompra` |

Quién ve qué es presentación: la lista base de cada Notifier trae todo,
archivados incluidos.

## Servicios (una cosa externa cada uno)

| Servicio | Responsabilidad |
|---|---|
| `FacturaPdfService` | construir y guardar el PDF de una `CompraDetallada`. No sabe de Riverpod |
| `ImagenProductoService` | elegir una foto y copiarla reducida a la carpeta de la app |

## Lo puro

`ResumenCompra` y `GrupoPorTienda` no importan Flutter ni la base. Toda
cuenta nueva va ahí, con su prueba en `test/resumen_compra_test.dart`.
