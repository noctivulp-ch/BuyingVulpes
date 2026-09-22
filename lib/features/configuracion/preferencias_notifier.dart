import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wulf_flutter/wulf_flutter.dart';

enum ModoTema {
  claro,
  oscuro,
  sistema;

  ThemeMode get themeMode => switch (this) {
    ModoTema.claro => ThemeMode.light,
    ModoTema.oscuro => ThemeMode.dark,
    ModoTema.sistema => ThemeMode.system,
  };
}

/// Lo que la persona eligió sobre cómo se ve la app. Nada de negocio.
class Preferencias {
  const Preferencias({
    this.modoTema = ModoTema.sistema,
    this.acento = WulfAcento.jade,
    this.efectosApagados = const {},
  });

  final ModoTema modoTema;
  final WulfAcento acento;
  final Set<WulfEfectoPesado> efectosApagados;

  Preferencias copyWith({
    ModoTema? modoTema,
    WulfAcento? acento,
    Set<WulfEfectoPesado>? efectosApagados,
  }) => Preferencias(
    modoTema: modoTema ?? this.modoTema,
    acento: acento ?? this.acento,
    efectosApagados: efectosApagados ?? this.efectosApagados,
  );
}

const _kModoTema = 'modo_tema';
const _kAcento = 'acento';
const _kEfectosApagados = 'efectos_apagados';

/// Las preferencias, guardadas en el almacén de claves del sistema (no en
/// SQLite: no son datos, no viajan en un respaldo, y se leen antes de abrir
/// la base para que el primer cuadro ya salga con el tema elegido).
class PreferenciasNotifier extends AsyncNotifier<Preferencias> {
  @override
  Future<Preferencias> build() async {
    final prefs = await SharedPreferences.getInstance();
    return Preferencias(
      modoTema: _enumDe(ModoTema.values, prefs.getString(_kModoTema)) ?? ModoTema.sistema,
      acento: _enumDe(WulfAcento.values, prefs.getString(_kAcento)) ?? WulfAcento.jade,
      efectosApagados: {
        for (final n in prefs.getStringList(_kEfectosApagados) ?? const <String>[])
          ?_enumDe(WulfEfectoPesado.values, n),
      },
    );
  }

  /// Por nombre y no por índice: reordenar un enum no puede cambiar lo elegido.
  static T? _enumDe<T extends Enum>(List<T> valores, String? nombre) =>
      valores.where((v) => v.name == nombre).firstOrNull;

  Future<void> cambiarModoTema(ModoTema modo) async {
    (await SharedPreferences.getInstance()).setString(_kModoTema, modo.name);
    state = AsyncData((state.valueOrNull ?? const Preferencias()).copyWith(modoTema: modo));
  }

  Future<void> cambiarAcento(WulfAcento acento) async {
    (await SharedPreferences.getInstance()).setString(_kAcento, acento.name);
    state = AsyncData((state.valueOrNull ?? const Preferencias()).copyWith(acento: acento));
  }

  Future<void> alternarEfecto(WulfEfectoPesado efecto, {required bool apagado}) async {
    final actual = state.valueOrNull ?? const Preferencias();
    final nuevos = {...actual.efectosApagados};
    apagado ? nuevos.add(efecto) : nuevos.remove(efecto);
    (await SharedPreferences.getInstance()).setStringList(_kEfectosApagados, [for (final e in nuevos) e.name]);
    state = AsyncData(actual.copyWith(efectosApagados: nuevos));
  }
}

final preferenciasProvider = AsyncNotifierProvider<PreferenciasNotifier, Preferencias>(
  PreferenciasNotifier.new,
);
