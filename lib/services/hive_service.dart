import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/medicine.dart';
import 'web_storage_service.dart' if (dart.library.html) 'web_storage_service.dart';
import 'dart:convert';

class HiveService {
  static Box<Medicine>? _medicamentosBox;
  static Box? _historialBox;

  // Inicializar Hive
  static Future<void> inicializar() async {
    if (kIsWeb) {
      // En web, usamos localStorage
      print('Usando almacenamiento web (localStorage)');
    } else {
      // En mobile, usamos Hive normal
      await Hive.initFlutter();
      Hive.registerAdapter(MedicineAdapter());

      _medicamentosBox = await Hive.openBox<Medicine>('medicamentos');
      _historialBox = await Hive.openBox('historial');
    }
  }

  // Obtener medicamentos
  static List<Medicine> getMedicamentos() {
    if (kIsWeb) {
      return [];
    }
    return _medicamentosBox?.values.toList() ?? [];
  }

  // Guardar medicamento
  static Future<void> guardarMedicamento(Medicine medicine, {int? index}) async {
    if (kIsWeb) {
      await WebStorageService.guardarMedicamento(
        {
          'nombre': medicine.nombre,
          'horas': medicine.horas,
          'vecesAlDia': medicine.vecesAlDia,
          'tomadas': medicine.tomadas,
          'pospuestas': medicine.pospuestas,
          'diario': medicine.diario,
          'dias': medicine.dias,
          'notificationIds': medicine.notificationIds,
          'postponedUntil': medicine.postponedUntil,
        },
        index: index,
      );
    } else {
      if (index != null) {
        await _medicamentosBox?.putAt(index, medicine);
      } else {
        await _medicamentosBox?.add(medicine);
      }
    }
  }

  // Eliminar medicamento
  static Future<void> eliminar(int index) async {
    if (kIsWeb) {
      await WebStorageService.eliminarMedicamento(index);
    } else {
      await _medicamentosBox?.deleteAt(index);
    }
  }

  // Guardar entrada historial
  static Future<void> guardarEntradaHistorial({
    required String fecha,
    required String nombreMedicamento,
    required int dosisTotal,
    required int dosisTomadas,
  }) async {
    if (kIsWeb) {
      await WebStorageService.guardarEntradaHistorial({
        'fecha': fecha,
        'nombreMedicamento': nombreMedicamento,
        'dosisTotal': dosisTotal,
        'dosisTomadas': dosisTomadas,
      });
    } else {
      final key = '$fecha|$nombreMedicamento';
      await _historialBox?.put(key, {
        'fecha': fecha,
        'nombreMedicamento': nombreMedicamento,
        'dosisTotal': dosisTotal,
        'dosisTomadas': dosisTomadas,
      });
    }
  }

  // Obtener historial
  static Map<String, dynamic> getHistorial() {
    if (kIsWeb) {
      return {};
    }
    final historial = <String, dynamic>{};
    final keys = _historialBox?.keys ?? [];
    for (var key in keys) {
      historial[key] = _historialBox?.get(key) ?? {};
    }
    return historial;
  }

  // Eliminar del historial
  static Future<void> eliminarDelHistorial(String nombreMedicamento) async {
    if (kIsWeb) {
      // En web, limpiar todo por ahora
      await WebStorageService.limpiarHistorial();
    } else {
      final keys = _historialBox?.keys.toList() ?? [];
      for (var key in keys) {
        if (key.toString().contains(nombreMedicamento)) {
          await _historialBox?.delete(key);
        }
      }
    }
  }

  // Limpiar historial
  static Future<void> limpiarHistorial() async {
    if (kIsWeb) {
      await WebStorageService.limpiarHistorial();
    } else {
      await _historialBox?.clear();
    }
  }

  // Calcular estadísticas
  static Map<String, dynamic> calcularEstadisticas() {
    if (kIsWeb) {
      return {
        'cumplimientoSemanal': 0.0,
        'cumplimientoMensual': 0.0,
        'medicamentosCumplidos': 0,
        'medicamentosIncumplidos': 0,
        'totalDosis': 0,
        'dosisTomadas': 0,
      };
    }

    final historial = getHistorial();
    int totalDosis = 0;
    int dosisTomadas = 0;
    final medicamentosCumplidos = <String>{};
    final medicamentosIncumplidos = <String>{};

    for (var entry in historial.entries) {
      final data = entry.value as Map<String, dynamic>;
      totalDosis += data['dosisTotal'] as int? ?? 0;
      dosisTomadas += data['dosisTomadas'] as int? ?? 0;

      final nombre = data['nombreMedicamento'] as String? ?? 'Desconocido';
      if (data['dosisTomadas'] == data['dosisTotal']) {
        medicamentosCumplidos.add(nombre);
      } else {
        medicamentosIncumplidos.add(nombre);
      }
    }

    double cumplimiento = totalDosis > 0 ? (dosisTomadas / totalDosis) * 100 : 0;

    return {
      'cumplimientoSemanal': cumplimiento,
      'cumplimientoMensual': cumplimiento,
      'medicamentosCumplidos': medicamentosCumplidos.length,
      'medicamentosIncumplidos': medicamentosIncumplidos.length,
      'totalDosis': totalDosis,
      'dosisTomadas': dosisTomadas,
    };
  }
}