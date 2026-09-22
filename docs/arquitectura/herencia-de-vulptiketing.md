# Qué se heredó de VulpTiketing, y qué no

El dueño preguntó, al ver la primera versión, si el "estilo de base de datos
de máquina de escribir" y lo demás pulido en VulpTiketing estaba acá. Esta es
la respuesta, concepto por concepto. Los conceptos están escritos como notas
reutilizables en el vault (`Obsidia/AppCreator/conceptos/`, empezar por
`arrancar-una-app-de-la-casa`).

| Concepto | Acá | Cómo, o por qué no |
|---|---|---|
| **Libro inmutable** — la línea es una foto; el registro cerrado no se edita | ✅ | `linea_compra` copia tienda, producto, precio y medida (ADR 0003). Una compra finalizada no tiene ninguna operación de escritura. Prueba: "la compra cerrada sobrevive a que el producto se archive" |
| **JSON solo para lo que vive con su fila** | ✅ (por omisión) | No hay JSON en el esquema: nada lo pedía. La regla se aplica cuando aparezca |
| *Revertir/anular* un registro cerrado | ❌ | Nadie pidió deshacer una compra finalizada. Si hace falta, es `anulada_en` + motivo, no `DELETE` |
| **Tablas sincronizables** — UUID, `updated_at`, `deleted_at` | ✅ la forma | Tienda y producto llevan las tres; compra y línea, `updated_at`. Sync no hay: un solo aparato hoy. El esquema no cambia cuando lo haya |
| **Notifier por entidad, sin CRUD genérico, DAO por llamada** | ✅ | `TiendaNotifier`, `ProductoNotifier`, `CompraEnCursoNotifier`, `PreferenciasNotifier`; `ResumenCompra` puro. Reglas en `CLAUDE.md` |
| **Migraciones probadas sobre base vieja** | ✅ | v1 → v2 (`migrarComprasALibro`) probada sobre una base v1 real y aplicada a la base del dueño |
| **Versión única** (`pubspec` ↔ `version.dart` con prueba) | ❌ todavía | No hay pantalla "Acerca de" ni versión visible. Se agrega con el primer release |
| **`versiones.md`** | ❌ todavía | Hasta la primera instalación con datos |
| **Respaldo cifrado + catálogo compartible** | ❌ | En `TODO.md`. Antes del primer release con datos reales |
| **Exportar a Descargas por MediaStore** | ❌ | En `TODO.md`. Hoy el PDF va a documentos de la app |
| **Fuentes Noto con ₡ en el PDF** | ✅ | Copiadas de tiketing (`assets/fonts/`) |
| **Libros rodantes (SQLite adjuntable)** — la "máquina de escribir" | ✅ | Un libro por año, ADR 0007. Primero se dejó fuera por volumen; el dueño lo corrigió: es longevidad, no rendimiento. Y acá los cerrados se leen sin restaurar, que en tiketing quedó pendiente |
| **Harness flutter_driver + MCP** | ❌ | Cuando haya aparato real |
| **Wulfenite-UI** (laca, pozos, retícula, rail, diálogo, iconos, foco) | ✅ | `wulf_flutter` por ruta, acento jade. Es la primera app que nace con la librería |
| **Ajustes**: tema, acento, efectos apagables | ✅ | `shared_preferences`, no SQLite |
| **Docs locales + Gherkin + `TODO.md` + vault** | ✅ | Desde el primer commit |
| **Pruebas de pantalla con SQLite real** | ✅ | `runAsync` y cuadros con tiempo real (`test/pantallas_test.dart`); nació acá |

## Lo que se hizo distinto, y por qué

- **La compra en curso vive en la base**, no en memoria como el carrito de
  tiketing: una lista se arma en días (ADR 0005).
- **Las líneas del borrador se borran de verdad** al quitarlas: no son
  historial hasta finalizar. En tiketing el carrito ni siquiera toca la base.
- **Sin roles**: una lista de compras es de una persona.
