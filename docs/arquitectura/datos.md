# Datos

Esquema **v2**. La base principal tiene el catálogo y el índice de libros;
las compras viven en **libros rodantes**, un archivo SQLite por año
([decisión 0007](../decisiones/0007-libros-rodantes-la-maquina-de-escribir.md)).

```
<soporte>/
├── buying_vulpes.db      tienda · producto · libro_compras
├── compras-2026.db       compra · linea_compra   (adjunto como `libro` mientras es el año en curso)
└── compras-2027.db       … el siguiente, cuando llegue
```

## Base principal

```sql
CREATE TABLE tienda (
  id          TEXT PRIMARY KEY,     -- UUID v4
  nombre      TEXT NOT NULL,
  notas       TEXT,
  updated_at  TEXT NOT NULL,        -- ISO 8601
  deleted_at  TEXT                  -- NULL = activa; puesto = archivada
);

CREATE TABLE producto (
  id          TEXT PRIMARY KEY,
  tienda_id   TEXT NOT NULL,        -- de UNA tienda (decisión 0001)
  nombre      TEXT NOT NULL,
  precio      REAL NOT NULL,        -- POR la medida (decisión 0002)
  cantidad    REAL NOT NULL DEFAULT 1,   -- la habitual; la línea la copia
  medida      TEXT NOT NULL DEFAULT 'unidad',  -- nombre del enum Medida
  imagen      TEXT,                 -- nombre de archivo en la carpeta de imágenes
  notas       TEXT,
  updated_at  TEXT NOT NULL,
  deleted_at  TEXT
);

CREATE TABLE libro_compras (
  id                TEXT PRIMARY KEY,
  archivo           TEXT NOT NULL,    -- compras-2026.db; el índice manda, no el nombre
  anio              INTEGER NOT NULL, -- criterio de rotación y de búsqueda por mes
  fecha_inicio      TEXT NOT NULL,
  fecha_fin         TEXT,             -- solo cerrados
  dias_con_compras  INTEGER NOT NULL DEFAULT 0,
  cerrado           INTEGER NOT NULL DEFAULT 0
);
```

## Libro (`compras-AAAA.db`)

Mismo esquema en todos; se aplica al crear cada uno (`esquemaLibro`).

```sql
CREATE TABLE compra (
  id             TEXT PRIMARY KEY,
  iniciada_en    TEXT NOT NULL,
  finalizada_en  TEXT,              -- NULL = en curso; hay UNA en curso como máximo
  presupuesto    REAL,              -- NULL = sin presupuesto
  notas          TEXT,
  updated_at     TEXT NOT NULL
);

CREATE TABLE linea_compra (
  id               TEXT PRIMARY KEY,
  compra_id        TEXT NOT NULL,
  producto_id      TEXT,            -- de dónde salió; puede quedar huérfano
  tienda_id        TEXT NOT NULL,
  tienda_nombre    TEXT NOT NULL,   -- FOTO (decisión 0003)
  producto_nombre  TEXT NOT NULL,   -- FOTO
  precio           REAL NOT NULL,   -- FOTO, por medida
  cantidad         REAL NOT NULL,
  medida           TEXT NOT NULL,   -- FOTO
  en_carrito       INTEGER NOT NULL DEFAULT 0,  -- la casilla
  notas            TEXT,
  updated_at       TEXT NOT NULL
);
```

## Reglas

- **Borrado lógico** en tienda y producto: `deleted_at`. El historial los
  nombra, así que no pueden desaparecer. Las líneas de una compra en curso sí
  se borran de verdad al quitarlas: no son historial todavía.
- **Sin `REFERENCES`.** SQLite no las exige salvo con `PRAGMA foreign_keys`,
  y una línea tiene que poder leerse aunque su producto se haya archivado.
  La integridad la sostiene la app: la línea lleva copiado todo lo que
  necesita para valer sola.
- **Una compra en curso.** `finalizada_en IS NULL` identifica la abierta. Se
  crea al anotar la primera línea, no al abrir la app — y ANTES de crearla se
  deja adjunto el libro del año, rotando si cambió.
- **Los libros cerrados se leen abriendo el archivo aparte** (solo lectura),
  nunca adjuntándolo: el alias `libro` es del año en curso.
- **Fechas** en ISO 8601 como texto, hora local. El calendario agrupa por
  `finalizada_en`.
- **Medida** se guarda por el nombre del enum (`kilogramo`), no por índice:
  reordenar el enum no puede cambiar el significado de una fila.

## Derivados que NO se guardan

`subtotal = precio × cantidad`, los totales por tienda, el total de la lista,
el del carrito y lo que queda del presupuesto. Todos salen de
`ResumenCompra` (`features/compra/resumen_compra.dart`), puro y probado.

## Dónde viven los archivos

| Qué | Dónde |
|---|---|
| Base principal | carpeta de soporte de la app: Linux `~/.local/share/com.vulpes.buying_vulpes/buying_vulpes.db` |
| Libros | misma carpeta, `compras-AAAA.db` |
| Fotos | `<soporte>/imagenes/<uuid>.<ext>`; el producto guarda solo el nombre |
| PDF | `<documentos>/BuyingVulpes/compras/compra_AAAA-MM-DD_HHMM.pdf` |
