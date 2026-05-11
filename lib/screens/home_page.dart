import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../models/medicine.dart';
import '../widgets/medicine_card.dart';
import 'add_medicine_page.dart';
import 'history_page.dart';
import '../services/notification_service.dart';
import '../services/hive_service.dart';
import '../main.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomePage({super.key, required this.onToggleTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Medicine> medicamentos = [];
  String busqueda = '';
  bool _mostrandoPopup = false; // ✅ Flag para evitar pop-ups duplicados

  @override
  void initState() {
    super.initState();
    cargarMedicamentos();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarAlarmasActivas();
    });

    NotificationActionStream.instance.addListener(_onNotificationAction);
    NotificationDisplayedStream.instance.addListener(_onNotificationDisplayed);
  }

  @override
  void dispose() {
    NotificationActionStream.instance.removeListener(_onNotificationAction);
    NotificationDisplayedStream.instance.removeListener(_onNotificationDisplayed);
    super.dispose();
  }

  // ✅ Evitar pop-ups duplicados con flag
  void _verificarAlarmasActivas() {
    if (_mostrandoPopup) return;

    final ahora = DateTime.now();
    final ahoraMinutos = ahora.hour * 60 + ahora.minute;

    for (var med in medicamentos) {
      for (int i = 0; i < med.horas.length; i++) {
        final parsed = _parsearHora(med.horas[i]);
        final horaMinutos = parsed['hour']! * 60 + parsed['minute']!;
        final diff = (ahoraMinutos - horaMinutos).abs();

        if (diff <= 5 && diff >= 0) {
          _mostrandoPopup = true;
          _mostrarDialogo(med, i, med.notificationIds[i]);
          return;
        }
      }
    }
  }

  void _onNotificationAction(ReceivedAction action) {
    if (_mostrandoPopup) return;

    cargarMedicamentos();
    if (action.buttonKeyPressed.isEmpty) {
      final payload = action.payload ?? {};
      final nombreMedicamento = payload['nombreMedicamento'] ?? '';
      final doseIndex = int.tryParse(payload['doseIndex'] ?? '0') ?? 0;
      final notificationId = int.tryParse(payload['notificationId'] ?? '0') ?? 0;
      try {
        final med = medicamentos.firstWhere((m) => m.nombre == nombreMedicamento);
        _mostrandoPopup = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mostrarDialogo(med, doseIndex, notificationId);
        });
      } catch (_) {}
    }
  }

  void _onNotificationDisplayed(ReceivedNotification notification) {
    if (_mostrandoPopup) return;

    final payload = notification.payload ?? {};
    final nombreMedicamento = payload['nombreMedicamento'] ?? '';
    final doseIndex = int.tryParse(payload['doseIndex'] ?? '0') ?? 0;
    final notificationId = int.tryParse(payload['notificationId'] ?? '0') ?? 0;
    cargarMedicamentos();
    try {
      final med = medicamentos.firstWhere((m) => m.nombre == nombreMedicamento);
      _mostrandoPopup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarDialogo(med, doseIndex, notificationId);
      });
    } catch (_) {}
  }

  void _mostrarDialogo(Medicine med, int doseIndex, int notificationId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text('💊 ${med.nombre}'),
        content: Text('Es hora de tu dosis ${doseIndex + 1} — ${med.horas[doseIndex]}'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(c);
              _mostrandoPopup = false;
              await _posponer(med, doseIndex, notificationId);
            },
            child: const Text('⏰ Posponer 10 min', style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(c);
              _mostrandoPopup = false;
              await _marcarTomada(med, doseIndex, notificationId);
            },
            child: const Text('✅ Ya tomé'),
          ),
        ],
      ),
    );
  }

  Future<void> _marcarTomada(Medicine med, int doseIndex, int notificationId) async {
    med.tomadas[doseIndex] = true;
    med.pospuestas[doseIndex] = false;
    med.postponedUntil[doseIndex] = '';
    await med.save();
    await NotificationService.cancelarNotificacion(notificationId);
    await _actualizarHistorial(med);
    cargarMedicamentos();
  }

  Future<void> _posponer(Medicine med, int doseIndex, int notificationId) async {
    final ahora = DateTime.now();
    final postponeUntil = ahora.add(const Duration(minutes: 10));

    if (med.pospuestas[doseIndex] && med.postponedUntil[doseIndex].isNotEmpty) {
      await NotificationService.cancelarNotificacion(notificationId);
    }

    bool puedePosponer = true;
    if (doseIndex < med.horas.length - 1) {
      final sig = _parsearHora(med.horas[doseIndex + 1]);
      final sigDateTime = DateTime(ahora.year, ahora.month, ahora.day, sig['hour']!, sig['minute']!);
      final limite = sigDateTime.subtract(const Duration(minutes: 15));
      if (postponeUntil.isAfter(limite)) puedePosponer = false;
    }

    if (!puedePosponer) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No puedes posponer, la siguiente dosis es muy pronto'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    med.pospuestas[doseIndex] = true;
    med.postponedUntil[doseIndex] =
    '${postponeUntil.hour.toString().padLeft(2, '0')}:${postponeUntil.minute.toString().padLeft(2, '0')}';
    await med.save();

    await NotificationService.crearNotificacionPospuesta(
      id: notificationId,
      titulo: '💊 ${med.nombre}',
      cuerpo: 'Recordatorio pospuesto — ¡No olvides tomarlo!',
      cuando: postponeUntil,
      nombreMedicamento: med.nombre,
      doseIndex: doseIndex,
    );

    cargarMedicamentos();
  }

  Future<void> _actualizarHistorial(Medicine med) async {
    final hoy = DateTime.now();
    final fecha =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    final tomadas = med.tomadas.where((t) => t).length;
    await HiveService.guardarEntradaHistorial(
      fecha: fecha,
      nombreMedicamento: med.nombre,
      dosisTotal: med.vecesAlDia,
      dosisTomadas: tomadas,
    );
  }

  Map<String, int> _parsearHora(String horaTexto) {
    bool esPM = horaTexto.contains("PM");
    String limpia = horaTexto.replaceAll("AM", "").replaceAll("PM", "").trim();
    final partes = limpia.split(":");
    int h = int.parse(partes[0]);
    int m = int.parse(partes[1]);
    if (esPM && h != 12) h += 12;
    if (!esPM && h == 12) h = 0;
    return {'hour': h, 'minute': m};
  }

  void _confirmarEliminar(int index, Medicine med) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Eliminar medicamento?'),
        content: Text('¿Segura que quieres eliminar "${med.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(c);
              for (int id in med.notificationIds) {
                await NotificationService.cancelarNotificacion(id);
              }
              // ✅ Eliminar del historial también
              await HiveService.eliminarDelHistorial(med.nombre);
              HiveService.eliminar(index);
              cargarMedicamentos();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void cargarMedicamentos() =>
      setState(() => medicamentos = HiveService.getMedicamentos());

  @override
  Widget build(BuildContext context) {
    int total = medicamentos.fold(0, (sum, m) => sum + m.horas.length);
    int completas = medicamentos.fold(
        0, (sum, m) => sum + m.tomadas.where((t) => t).length);
    final filtrados = medicamentos
        .where((m) => m.nombre.toLowerCase().contains(busqueda.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medicinas de Clau"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => HistoryPage(
                    historial: HiveService.getHistorial(),
                    onClear: () async {
                      await HiveService.limpiarHistorial();
                    },
                  ),
                ),
              ).then((_) {
                // ✅ Recargar al volver del historial
                cargarMedicamentos();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat("Dosis Hoy", "$total", Colors.blue),
                _buildStat("Completadas", "$completas", Colors.green),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: (v) => setState(() => busqueda = v),
              decoration: const InputDecoration(
                hintText: "Buscar medicina...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtrados.length,
              itemBuilder: (c, i) => MedicineCard(
                medicine: filtrados[i],
                onDelete: () => _confirmarEliminar(i, filtrados[i]),
                onToggle: (idx) async {
                  filtrados[i].tomadas[idx] = !filtrados[i].tomadas[idx];
                  if (!filtrados[i].tomadas[idx]) {
                    filtrados[i].pospuestas[idx] = false;
                    filtrados[i].postponedUntil[idx] = '';
                  }
                  await filtrados[i].save();
                  await _actualizarHistorial(filtrados[i]);
                  cargarMedicamentos();
                },
                onEdit: () async {
                  final med = filtrados[i];
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => AddMedicinePage(
                        nombreInicial: med.nombre,
                        horasIniciales: med.horas,
                        vecesInicial: med.vecesAlDia,
                      ),
                    ),
                  );
                  if (res != null) {
                    for (int id in med.notificationIds) {
                      await NotificationService.cancelarNotificacion(id);
                    }
                    final horas = List<String>.from(res['horas']);
                    final List<int> ids = [];
                    for (int j = 0; j < horas.length; j++) {
                      final parsed = _parsearHora(horas[j]);
                      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000 + j;
                      await NotificationService.crearNotificacion(
                        id: id,
                        titulo: '💊 ${res['nombre']}',
                        cuerpo: 'Es hora de tomar tu medicamento',
                        hour: parsed['hour']!,
                        minute: parsed['minute']!,
                        nombreMedicamento: res['nombre'],
                        doseIndex: j,
                      );
                      ids.add(id);
                    }
                    await HiveService.guardarMedicamento(
                      Medicine(
                        nombre: res['nombre'],
                        horas: horas,
                        vecesAlDia: res['vecesAlDia'],
                        notificationIds: ids,
                      ),
                      index: i,
                    );
                    cargarMedicamentos();
                  }
                },
                onDoseAction: (doseIndex) {
                  if (!_mostrandoPopup) {
                    _mostrandoPopup = true;
                    _mostrarDialogo(
                      filtrados[i],
                      doseIndex,
                      filtrados[i].notificationIds[doseIndex],
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => AddMedicinePage()),
          );
          if (res != null) {
            final horas = List<String>.from(res['horas']);
            final List<int> ids = [];
            for (int i = 0; i < horas.length; i++) {
              final parsed = _parsearHora(horas[i]);
              final id = DateTime.now().millisecondsSinceEpoch ~/ 1000 + i;
              await NotificationService.crearNotificacion(
                id: id,
                titulo: '💊 ${res['nombre']}',
                cuerpo: 'Es hora de tomar tu medicamento',
                hour: parsed['hour']!,
                minute: parsed['minute']!,
                nombreMedicamento: res['nombre'],
                doseIndex: i,
              );
              ids.add(id);
            }
            await HiveService.guardarMedicamento(Medicine(
              nombre: res['nombre'],
              horas: horas,
              vecesAlDia: res['vecesAlDia'],
              notificationIds: ids,
            ));
            await _crearEntradaHistorialInicial(res['nombre'], res['vecesAlDia']);
            cargarMedicamentos();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _crearEntradaHistorialInicial(String nombreMedicamento, int vecesAlDia) async {
    final hoy = DateTime.now();
    final fecha =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    await HiveService.guardarEntradaHistorial(
      fecha: fecha,
      nombreMedicamento: nombreMedicamento,
      dosisTotal: vecesAlDia,
      dosisTomadas: 0,
    );
  }

  Widget _buildStat(String l, String v, Color c) {
    return Column(children: [
      Text(v, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c)),
      Text(l),
    ]);
  }
}