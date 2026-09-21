# Stack

| Capa | Elección | Por qué |
|---|---|---|
| UI | Flutter 3.44, Material 3 | Mismo stack que VulpTiketing: una sola forma de hacer las cosas en la casa |
| Diseño | `wulf_flutter` (`#Libs/wulfenite_ui/flutter`) | La librería de diseño de la casa: laca, pozos, retícula, rail, diálogo con sus reglas. Esta es la primera app que nace ya con ella |
| Acento | Jade | Otra app de la misma familia; en el mismo teléfono que VulpTiketing (oro) tiene que distinguirse de un vistazo |
| Estado | Riverpod 2 | Un Notifier por entidad, providers derivados para presentación — ver [gestión de estado](gestion-estado.md) |
| Datos | SQLite (`sqflite`, `sqflite_common_ffi` en escritorio) | Local, sin cuenta, sin red. Una lista de compras no necesita servidor |
| PDF | `pdf` + Noto Sans recortada | Las fuentes de fábrica no tienen ₡. Se reutilizan las de VulpTiketing (42 KB) |
| Fotos | `image_picker` | Galería o cámara; se copian reducidas a la carpeta de la app |
| Abrir PDF | `open_filex` | Funciona en Linux y Android sin más plugins |
| Plataformas | Android, Linux, Windows | Las mismas que VulpTiketing. Sin iOS/macOS por ahora |

## Estructura

```
lib/
├── main.dart                 tema, idioma, arranque
├── app_shell.dart            las dos ventanas y el rail / barra
├── core/
│   ├── db/                   esquema, apertura, provider de la conexión
│   ├── dinero.dart           formato de montos y cantidades
│   └── medida.dart           el enum cerrado de medidas
└── features/
    ├── tienda/               modelo, DAO, Notifier, formulario
    ├── producto/             modelo, DAO, Notifier, formulario, fotos
    ├── compra/               modelo, resumen (puro), DAO, Notifier, pantalla, panel
    └── historial/            providers de lectura, calendario, detalle, PDF
```

Cada `features/<x>` es autosuficiente: modelo → DAO → Notifier → UI. Ver
las reglas en el `CLAUDE.md` de la raíz.
