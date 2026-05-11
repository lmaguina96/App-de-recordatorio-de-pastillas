import 'package:hive/hive.dart';
import '../models/medicine.dart';

class HiveService {
  static const String _boxName = 'medicamentos';
  static const String _historialBox = 'historial';

  static List<Medicine> getMedicamentos() {
    final box = Hive.box<Medicine>(_boxName);
    return box.values.toList();
  }

  static Future<void> guardarMedicamento(Medicine med, {int? index}) async {
    final box = Hive.box<Medicine>(_boxName);
    if (index != null) {
      await box.putAt(index, med);
    } else {
      await box.add(med);
    }
  }

  static Future<void> eliminar(int index) async {
    final box = Hive.box<Medicine>(_boxName);
    await box.deleteAt(index);
  }

  // ✅ Eliminar medicamento del historial también
  static Future<void> eliminarDelHistorial(String nombreMedicamento) async {
    final box = Hive.box(_historialBox);
    final keysAEliminar = <String>[];

    for (var key in box.keys) {
      final entrada = box.get(key);
      if (entrada['nombre'] == nombreMedicamento) {
        keysAEliminar.add(key as String);
      }
    }

    for (var key in keysAEliminar) {
      await box.delete(key);
    }
  }

  static Future<void> guardarEntradaHistorial({
    required String fecha,
    required String nombreMedicamento,
    required int dosisTotal,
    required int dosisTomadas,
  }) async {
    final box = Hive.box(_historialBox);
    final key = '$fecha|$nombreMedicamento';

    final entradaAnterior = box.get(key);

    int dosisFinal = dosisTomadas;
    if (entradaAnterior != null) {
      final dosisAnteriores = entradaAnterior['dosisTomadas'] as int? ?? 0;
      dosisFinal = dosisTomadas > dosisAnteriores ? dosisTomadas : dosisAnteriores;
    }

    await box.put(key, {
      'fecha': fecha,
      'nombre': nombreMedicamento,
      'dosisTotal': dosisTotal,
      'dosisTomadas': dosisFinal,
    });
  }

  static Map<String, Map<String, dynamic>> getHistorial() {
    final box = Hive.box(_historialBox);
    final Map<String, Map<String, dynamic>> result = {};
    for (var key in box.keys) {
      result[key as String] = Map<String, dynamic>.from(box.get(key));
    }
    return result;
  }

  static Future<void> limpiarHistorial() async {
    await Hive.box(_historialBox).clear();
  }

  // ✅ Calcular estadísticas
  static Map<String, dynamic> calcularEstadisticas() {
    final box = Hive.box(_historialBox);
    final Map<String, dynamic> stats = {
      'cumplimientoSemanal': 0.0,
      'cumplimientoMensual': 0.0,
      'medicamentosCumplidos': <String>[],
      'medicamentosIncumplidos': <String>[],
      'totalDosis': 0,
      'dosisTomadas': 0,
    };

    if (box.isEmpty) return stats;

    int totalDosis = 0;
    int dosisTomadas = 0;
    final medicamentos = <String, Map<String, int>>{};

    final ahora = DateTime.now();
    final hace7Dias = ahora.subtract(const Duration(days: 7));
    final hace30Dias = ahora.subtract(const Duration(days: 30));

    for (var key in box.keys) {
      final entrada = box.get(key);
      final fecha = DateTime.parse(entrada['fecha'] as String);
      final nombre = entrada['nombre'] as String;
      final total = entrada['dosisTotal'] as int;
      final tomadas = entrada['dosisTomadas'] as int;

      if (!medicamentos.containsKey(nombre)) {
        medicamentos[nombre] = {'total': 0, 'tomadas': 0};
      }
      medicamentos[nombre]!['total'] = medicamentos[nombre]!['total']! + total;
      medicamentos[nombre]!['tomadas'] = medicamentos[nombre]!['tomadas']! + tomadas;

      totalDosis += total;
      dosisTomadas += tomadas;
    }

    stats['totalDosis'] = totalDosis;
    stats['dosisTomadas'] = dosisTomadas;

    // Calcular cumplimiento semanal y mensual
    int dosisSemana = 0;
    int dosisSemanaT = 0;
    int dosisMes = 0;
    int dosisMesT = 0;

    for (var key in box.keys) {
      final entrada = box.get(key);
      final fecha = DateTime.parse(entrada['fecha'] as String);
      final total = entrada['dosisTotal'] as int;
      final tomadas = entrada['dosisTomadas'] as int;

      if (fecha.isAfter(hace7Dias)) {
        dosisSemana += total;
        dosisSemanaT += tomadas;
      }
      if (fecha.isAfter(hace30Dias)) {
        dosisMes += total;
        dosisMesT += tomadas;
      }
    }

    stats['cumplimientoSemanal'] = dosisSemana > 0 ? (dosisSemanaT / dosisSemana * 100).toStringAsFixed(1) : '0';
    stats['cumplimientoMensual'] = dosisMes > 0 ? (dosisMesT / dosisMes * 100).toStringAsFixed(1) : '0';

    // Medicamentos cumplidos e incumplidos
    for (var med in medicamentos.entries) {
      final porcentaje = med.value['total']! > 0
          ? (med.value['tomadas']! / med.value['total']! * 100)
          : 0;

      if (porcentaje == 100) {
        stats['medicamentosCumplidos'].add(med.key);
      } else if (porcentaje == 0) {
        stats['medicamentosIncumplidos'].add(med.key);
      }
    }

    return stats;
  }
}