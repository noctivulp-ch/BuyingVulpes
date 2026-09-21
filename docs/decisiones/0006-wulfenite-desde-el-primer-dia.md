# 0006 — La app nace con `wulf_flutter`, acento jade

**Estado:** Aceptada · **Fecha:** 2026-09-21

## Contexto

Wulfenite-UI se extrajo de VulpTiketing y DurdrawGUI justamente "para las
apps que vienen". Esta es la primera.

## Decisión

Dependencia por ruta a `#Libs/wulfenite_ui/flutter`. Se usan `WulfBandeja`
(por el tema), `WulfPozo`, `WulfDialogo`/`WulfAcciones`, `WulfRail`,
`WulfIcono`, `WulfFalla`, `mostrarAviso`, tokens de espaciado y radio.
Acento **jade**.

## Por qué

- Identidad de la casa sin reescribir nada; las reglas (dónde va Cancelar,
  cómo se ve el foco) vienen dentro de los widgets.
- Jade y no oro: en el mismo teléfono que VulpTiketing tienen que
  distinguirse de un vistazo, y el gris peltre no opina.

## Consecuencias

- Lo que la librería no trae (barra de navegación inferior, casillas de
  lista, calendario) se hace con Material temado por el `ColorScheme` de
  Wulfenite. Si alguna pieza se repite en otra app, se sube a la librería.
- El paquete se resuelve por ruta relativa; el repo de BuyingVulpes no es
  autosuficiente sin `#Libs`. Es lo mismo que pasa con VulpTiketing y está
  asumido en el workspace.
