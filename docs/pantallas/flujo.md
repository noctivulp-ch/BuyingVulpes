# Pantallas y flujo

```
┌────────────────────────────────────────────────┐
│  [≡] Compra                         [🏷 presup] │  ← Ventana 1: la lista
│                                                │
│  Por comprar                                   │
│  ┌ Walmart ────────────────────────────────┐   │
│  │ ☐ Leche      1 u × ₡950          ₡950   │   │
│  └─────────────────────────────────────────┘   │
│  En el carrito                                 │
│  ┌ Walmart ────────────────────────────────┐   │
│  │ ☑ Arroz      2 kg × ₡1.200     ₡2.400   │   │
│  └─────────────────────────────────────────┘   │
│  ┌ Feria ──────────────────────────────────┐   │
│  │ ☑ Tomate   1,5 kg × ₡800       ₡1.200   │   │
│  └─────────────────────────────────────────┘   │
│                                                │
│  ┌ Lista ₡4.550 │ Carrito ₡3.600 │ Queda ₡400 ┐│  ← pie de cuentas
│  │        [ Finalizar compra · 2/3 ]          ││
│  └────────────────────────────────────────────┘│
│  ( Compra )        ( Historial )               │  ← barra en teléfono; rail en tablet
└────────────────────────────────────────────────┘
```

**[≡]** abre el panel de tiendas, que ocupa toda la pantalla:

```
┌────────────────────────────────────────────────┐
│  [←] Tiendas                        [+ Tienda] │
│  ┌ ▾ Walmart · 3 productos · 1 marcado   [+] ┐ │
│  │  ☑ Arroz        ₡1.200 / kg         [✎]   │ │
│  │  ☐ Leche        ₡950 / u · ya en la lista │ │
│  │  ☐ Pan          ₡1.100 / u          [✎]   │ │
│  └───────────────────────────────────────────┘ │
│  ┌ ▸ Feria · 5 productos                 [+] ┐ │
│  └───────────────────────────────────────────┘ │
│                                                │
│            [ Anotar 1 en la lista ]            │
└────────────────────────────────────────────────┘
```

- Toque en la fila de la tienda: despliega. Pulsación larga: editar tienda.
- `[+]` de la fila: nuevo producto en esa tienda (queda marcado al crearlo).
- Casilla: marcar para anotar. `[✎]`: editar producto.
- El botón del pie aparece con el primer marcado y anota todos.

**Historial**: sin scroll de página. El calendario llena el alto que le toca
(seis semanas siempre, repartidas con `Expanded`) y la lista de compras del
mes o del día se desplaza en su propia parte: de pie, calendario arriba y
lista abajo; con ancho, lado a lado. Tocar una compra → detalle → PDF.

**Ajustes** (tercera ventana): tema (claro/oscuro/sistema), acento (oro/jade/
peltre) y Optimización (los efectos pesados de Wulfenite, hoy el relieve
grabado). Se guardan en `shared_preferences`, no en la base: no son datos.

## Diálogos

Todos con `WulfDialogo`: Cancelar a la izquierda, la acción que confirma a
la derecha. Producto, tienda, línea, presupuesto y confirmación de finalizar.
