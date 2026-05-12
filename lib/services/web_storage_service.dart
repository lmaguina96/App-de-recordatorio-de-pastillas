import 'dart:async';
import 'dart:html' as html;
import 'dart:convert' as convert;

class WebStorageService {
  static const String _medicamentosKey = 'medicamentos_web';
  static const String _historialKey = 'historial_web';

  static Future<void> guardarMedicamento(
      Map<String, dynamic> med, {
        int? index,
      }) async {
    final medicamentos = _obtenerMedicamentos();

    if (index != null) {
      medicamentos[index] = med;
    } else {
      medicamentos.add(med);
    }

    _guardarEnLocal(_medicamentosKey, medicamentos);
  }

  static List<Map<String, dynamic>> _obtenerMedicamentos() {
    final data = html.window.localStorage[_medicamentosKey];

    if (data == null) return [];

    try {
      final List<dynamic> decoded =
      convert.jsonDecode(data) as List<dynamic>;

      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<void> eliminarMedicamento(int index) async {
    final medicamentos = _obtenerMedicamentos();

    if (index < medicamentos.length) {
      medicamentos.removeAt(index);
      _guardarEnLocal(_medicamentosKey, medicamentos);
    }
  }

  static Future<void> guardarEntradaHistorial(
      Map<String, dynamic> entrada,
      ) async {
    final historial = _obtenerHistorial();

    final key =
        '${entrada['fecha']}|${entrada['nombreMedicamento']}';

    historial[key] = entrada;

    _guardarEnLocal(_historialKey, historial);
  }

  static Map<String, dynamic> _obtenerHistorial() {
    final data = html.window.localStorage[_historialKey];

    if (data == null) return {};

    try {
      return convert.jsonDecode(data)
      as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  static Future<void> limpiarHistorial() async {
    html.window.localStorage.remove(_historialKey);
  }

  static void _guardarEnLocal(
      String key,
      dynamic data,
      ) {
    html.window.localStorage[key] =
        convert.jsonEncode(data);
  }
}