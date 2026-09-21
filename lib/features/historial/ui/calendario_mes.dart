import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wulf_flutter/wulf_flutter.dart';

/// Un mes con los días que tienen compras marcados. Solo dibuja y avisa: qué
/// días llevan marca y qué pasa al tocar uno lo decide quien lo usa.
class CalendarioMes extends StatelessWidget {
  const CalendarioMes({
    super.key,
    required this.mes,
    required this.hoy,
    required this.diasConCompras,
    required this.seleccionado,
    required this.onMes,
    required this.onDia,
  });

  /// Primer día del mes que se muestra.
  final DateTime mes;
  final DateTime hoy;
  final Set<int> diasConCompras;
  final DateTime? seleccionado;
  final ValueChanged<DateTime> onMes;
  final ValueChanged<DateTime> onDia;

  static const _semana = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final laca = lacaDe(context);
    final diasDelMes = DateTime(mes.year, mes.month + 1, 0).day;
    final huecos = mes.weekday - 1;
    final esteMes = DateTime(hoy.year, hoy.month);
    final puedeAvanzar = mes.isBefore(esteMes);
    final titulo = DateFormat('MMMM y', 'es').format(mes);

    return WulfPozo(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Mes anterior',
                onPressed: () => onMes(DateTime(mes.year, mes.month - 1)),
                icon: const WulfIcono('chevron-izquierda', descripcion: null),
              ),
              Expanded(
                child: Text(
                  titulo[0].toUpperCase() + titulo.substring(1),
                  textAlign: TextAlign.center,
                  style: tema.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Mes siguiente',
                onPressed: puedeAvanzar ? () => onMes(DateTime(mes.year, mes.month + 1)) : null,
                icon: const WulfIcono('chevron-derecha', descripcion: null),
              ),
            ],
          ),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final d in _semana)
                Center(child: Text(d, style: tema.textTheme.labelSmall)),
              for (var i = 0; i < huecos; i++) const SizedBox.shrink(),
              for (var dia = 1; dia <= diasDelMes; dia++)
                _Dia(
                  numero: dia,
                  conCompras: diasConCompras.contains(dia),
                  esHoy: hoy.year == mes.year && hoy.month == mes.month && hoy.day == dia,
                  elegido: seleccionado != null &&
                      seleccionado!.year == mes.year &&
                      seleccionado!.month == mes.month &&
                      seleccionado!.day == dia,
                  acento: tema.colorScheme.primary,
                  sobreAcento: tema.colorScheme.onPrimary,
                  textoApagado: laca.textoAtenuadoEnBandeja,
                  onTap: () => onDia(DateTime(mes.year, mes.month, dia)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({
    required this.numero,
    required this.conCompras,
    required this.esHoy,
    required this.elegido,
    required this.acento,
    required this.sobreAcento,
    required this.textoApagado,
    required this.onTap,
  });

  final int numero;
  final bool conCompras;
  final bool esHoy;
  final bool elegido;
  final Color acento;
  final Color sobreAcento;
  final Color textoApagado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WulfRadius.pozo),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: elegido ? acento : null,
          borderRadius: BorderRadius.circular(WulfRadius.pozo),
          border: esHoy && !elegido ? Border.all(color: acento) : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$numero',
              style: tema.textTheme.bodyMedium?.copyWith(
                color: elegido ? sobreAcento : (conCompras ? null : textoApagado),
                fontWeight: conCompras ? FontWeight.w600 : null,
              ),
            ),
            // El punto es la marca de "acá hubo compra": se ve sin leer.
            if (conCompras)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: elegido ? sobreAcento : acento,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
