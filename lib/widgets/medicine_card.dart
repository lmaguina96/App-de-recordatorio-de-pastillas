import 'package:flutter/material.dart';
import '../models/medicine.dart';
import 'dart:async';

class MedicineCard extends StatefulWidget {
  final Medicine medicine;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(int) onToggle;
  final Function(int) onDoseAction;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onDelete,
    required this.onEdit,
    required this.onToggle,
    required this.onDoseAction,
  });

  @override
  State<MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard> {
  Timer? _timer;
  Map<int, int> _secondsRemaining = {};

  @override
  void initState() {
    super.initState();
    _calcularTiemposRestantes();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _calcularTiemposRestantes());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calcularTiemposRestantes() {
    final med = widget.medicine;
    for (int i = 0; i < med.horas.length; i++) {
      if (med.pospuestas[i] && med.postponedUntil[i].isNotEmpty) {
        final partes = med.postponedUntil[i].split(':');
        final h = int.parse(partes[0]);
        final m = int.parse(partes[1]);
        final ahora = DateTime.now();
        final hasta = DateTime(ahora.year, ahora.month, ahora.day, h, m);
        final diff = hasta.difference(ahora).inSeconds;
        _secondsRemaining[i] = diff > 0 ? diff : 0;
      } else {
        _secondsRemaining[i] = 0;
      }
    }
  }

  String _formatTiempo(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.medicine;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.medication)),
              title: Text(med.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: widget.onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
            const Divider(),
            Wrap(
              spacing: 15,
              children: List.generate(med.horas.length, (index) {
                bool isTaken = med.tomadas[index];
                bool isSnoozed = med.pospuestas[index] && !isTaken;
                int secsLeft = _secondsRemaining[index] ?? 0;

                return GestureDetector(
                  onTap: () {
                    if (isSnoozed) {
                      // Si está pospuesto, mostrar popup
                      widget.onDoseAction(index);
                    } else {
                      // ✅ Fix 2: toggle simple gris <-> verde
                      widget.onToggle(index);
                    }
                  },
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isSnoozed && secsLeft > 0)
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                value: secsLeft / 600,
                                color: Colors.orange,
                                strokeWidth: 3,
                                backgroundColor:
                                Colors.orange.withOpacity(0.2),
                              ),
                            ),
                          Icon(
                            isTaken
                                ? Icons.check_circle
                                : isSnoozed
                                ? Icons.access_time_filled
                                : Icons.check_circle_outline,
                            // ✅ Fix 2: gris cuando no tomado, verde cuando tomado
                            color: isTaken
                                ? Colors.green
                                : isSnoozed
                                ? Colors.orange
                                : Colors.grey,
                            size: 35,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(med.horas[index],
                          style: const TextStyle(fontSize: 12)),
                      if (isSnoozed && secsLeft > 0)
                        Text(
                          _formatTiempo(secsLeft),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}