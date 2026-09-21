# Datos

Esquema v1. Cuatro tablas; las dos primeras son el catálogo, las dos últimas
la compra.

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
  crea al anotar la primera línea, no al abrir la app.
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
| Base | carpeta de soporte de la app: Linux `~/.local/share/com.vulpes.buying_vulpes/buying_vulpes.db` |
| Fotos | `<soporte>/imagenes/<uuid>.<ext>`; el producto guarda solo el nombre |
| PDF | `<documentos>/BuyingVulpes/compras/compra_AAAA-MM-DD_HHMM.pdf` |
