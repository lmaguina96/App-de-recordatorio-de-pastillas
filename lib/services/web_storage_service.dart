import 'dart:convert';
import 'dart:html' as html;

class WebStorageService {
  static const String medicamentosKey = 'medicamentos_web';

  static List<Map<String, dynamic>> obtenerMedicamentos() {
    final data =
    html.window.localStorage[medicamentosKey];

    if (data == null) {
      return [];
    }

    try {
      final decoded = jsonDecode(data);

      return List<Map<String, dynamic>>.from(decoded);
    } catch (e) {
      return [];
    }
  }

  static Future<void> guardarMedicamento(
      Map<String, dynamic> medicamento, {
        int? index,
      }) async {
    final medicamentos = obtenerMedicamentos();

    if (index != null &&
        index >= 0 &&
        index < medicamentos.length) {
      medicamentos[index] = medicamento;
    } else {
      medicamentos.add(medicamento);
    }

    html.window.localStorage[medicamentosKey] =
        jsonEncode(medicamentos);
  }

  static Future<void> eliminarMedicamento(
      int index) async {
    final medicamentos = obtenerMedicamentos();

    if (index >= 0 &&
        index < medicamentos.length) {
      medicamentos.removeAt(index);

      html.window.localStorage[medicamentosKey] =
          jsonEncode(medicamentos);
    }
  }

  static Future<void> guardarEntradaHistorial(
      Map<String, dynamic> historial) async {}

  static Future<void> limpiarHistorial() async {}
}