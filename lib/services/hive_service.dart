import 'package:hive_flutter/hive_flutter.dart';
import '../models/medicine.dart';

class HiveService {
  static late Box<Medicine> _medicineBox;
  static late Box _historyBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MedicineAdapter());
    }

    _medicineBox = await Hive.openBox<Medicine>('medicines');
    _historyBox = await Hive.openBox('history');
  }

  // =========================
  // MEDICINAS
  // =========================

  static List<Medicine> getMedicines() {
    return _medicineBox.values.toList();
  }

  static Future<void> addMedicine(Medicine medicine) async {
    await _medicineBox.add(medicine);
  }

  static Future<void> updateMedicine(int index, Medicine medicine) async {
    await _medicineBox.putAt(index, medicine);
  }

  static Future<void> deleteMedicine(int index) async {
    await _medicineBox.deleteAt(index);
  }

  // =========================
  // HISTORIAL
  // =========================

  static Map<String, Map<String, dynamic>> getHistorial() {
    final raw = _historyBox.toMap();

    return raw.map(
          (key, value) => MapEntry(
        key.toString(),
        Map<String, dynamic>.from(value),
      ),
    );
  }

  static Future<void> guardarHistorial({
    required String nombre,
    required int dosisTotal,
    required int dosisTomadas,
  }) async {
    final hoy = DateTime.now();

    final fecha =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

    final key = '${nombre}_$fecha';

    await _historyBox.put(key, {
      'nombre': nombre,
      'fecha': fecha,
      'dosisTotal': dosisTotal,
      'dosisTomadas': dosisTomadas,
    });
  }

  static Future<void> limpiarHistorial() async {
    await _historyBox.clear();
  }

  // =========================
  // ESTADÍSTICAS
  // =========================

  static Map<String, dynamic> calcularEstadisticas() {
    final historial = getHistorial();

    int totalDosis = 0;
    int dosisTomadas = 0;

    List<String> medsCumplidos = [];
    List<String> medsIncumplidos = [];

    for (var item in historial.values) {
      final total = item['dosisTotal'] as int;
      final tomadas = item['dosisTomadas'] as int;
      final nombre = item['nombre'] as String;

      totalDosis += total;
      dosisTomadas += tomadas;

      if (tomadas == total) {
        if (!medsCumplidos.contains(nombre)) {
          medsCumplidos.add(nombre);
        }
      }

      if (tomadas == 0) {
        if (!medsIncumplidos.contains(nombre)) {
          medsIncumplidos.add(nombre);
        }
      }
    }

    int cumplimiento = 0;

    if (totalDosis > 0) {
      cumplimiento = ((dosisTomadas / totalDosis) * 100).round();
    }

    return {
      'totalDosis': totalDosis,
      'dosisTomadas': dosisTomadas,
      'cumplimientoSemanal': cumplimiento,
      'cumplimientoMensual': cumplimiento,
      'medicamentosCumplidos': medsCumplidos,
      'medicamentosIncumplidos': medsIncumplidos,
    };
  }
}