import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// La conexión, una para toda la app. Las pruebas la reemplazan con una base
/// en memoria.
final databaseProvider = FutureProvider<Database>((ref) => AppDatabase.abrir());
