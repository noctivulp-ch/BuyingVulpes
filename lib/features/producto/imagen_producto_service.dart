import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Las fotos de los productos: se copian a la carpeta de la app y el producto
/// guarda solo el NOMBRE del archivo. Guardar la ruta completa se rompe al
/// cambiar de aparato o de sistema, porque la carpeta de datos cambia.
class ImagenProductoService {
  ImagenProductoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  static const _uuid = Uuid();

  Future<Directory> carpeta() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'imagenes'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> archivoDe(String nombre) async => File(p.join((await carpeta()).path, nombre));

  /// Abre la galería o la cámara y devuelve el nombre del archivo copiado, o
  /// nulo si se canceló. Se reduce al elegir: una foto de 12 MP para un
  /// cuadro de 72 px es memoria tirada en cada lista.
  Future<String?> elegir({required bool camara}) async {
    final elegida = await _picker.pickImage(
      source: camara ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (elegida == null) return null;
    final nombre = '${_uuid.v4()}${p.extension(elegida.path).toLowerCase()}';
    await File(elegida.path).copy((await archivoDe(nombre)).path);
    return nombre;
  }
}
