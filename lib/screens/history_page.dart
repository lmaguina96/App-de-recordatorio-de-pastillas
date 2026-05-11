import 'package:flutter/material.dart';
import '../services/hive_service.dart';

class HistoryPage extends StatefulWidget {
  final Map<String, Map<String, dynamic>> historial;
  final VoidCallback onClear;

  const HistoryPage({
    super.key,
    required this.historial,
    required this.onClear,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color? _colorDelDia(DateTime dia) {
    final fecha = _formatFecha(dia);
    final entradasDelDia = widget.historial.entries
        .where((e) => e.value['fecha'] == fecha)
        .toList();

    if (entradasDelDia.isEmpty) return null;

    int totalDosis = 0;
    int totalTomadas = 0;

    for (var entrada in entradasDelDia) {
      totalDosis += (entrada.value['dosisTotal'] as int);
      totalTomadas += (entrada.value['dosisTomadas'] as int);
    }

    if (totalTomadas == 0) return Colors.red;
    if (totalTomadas == totalDosis) return Colors.green;
    return Colors.orange;
  }

  String _formatFecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> _entradasDelDia(DateTime dia) {
    final fecha = _formatFecha(dia);
    return widget.historial.entries
        .where((e) => e.value['fecha'] == fecha)
        .map((e) => e.value)
        .toList();
  }

  void _irMesAnterior() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      _selectedDay = null;
    });
  }

  void _irMesSiguiente() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = HiveService.calcularEstadisticas();
    final diasEnMes = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final primerDia = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    int offsetInicio = (primerDia.weekday - 1) % 7;

    final entradasSeleccionadas = _selectedDay != null ? _entradasDelDia(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendario'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Estadísticas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('¿Limpiar historial?'),
                  content: const Text('Se borrará todo el historial de dosis.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(c);
                        widget.onClear();
                        Navigator.pop(context);
                      },
                      child: const Text('Limpiar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ✅ Pestaña Calendario
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLeyenda(Colors.green, 'Todo tomado'),
                    const SizedBox(width: 16),
                    _buildLeyenda(Colors.orange, 'Parcial'),
                    const SizedBox(width: 16),
                    _buildLeyenda(Colors.red, 'Sin tomar'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: _irMesAnterior),
                    Text(
                      _nombreMes(_focusedMonth),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.chevron_right), onPressed: _irMesSiguiente),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                      .map((d) => SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  itemCount: offsetInicio + diasEnMes,
                  itemBuilder: (context, index) {
                    if (index < offsetInicio) return const SizedBox();

                    final dia = DateTime(_focusedMonth.year, _focusedMonth.month, index - offsetInicio + 1);
                    final color = _colorDelDia(dia);
                    final esHoy = DateUtils.isSameDay(dia, DateTime.now());
                    final esSeleccionado = _selectedDay != null && DateUtils.isSameDay(dia, _selectedDay!);

                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedDay = DateUtils.isSameDay(dia, _selectedDay) ? null : dia;
                      }),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: esSeleccionado ? Colors.blue.withOpacity(0.2) : null,
                          border: esHoy ? Border.all(color: Colors.blue, width: 1.5) : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${dia.day}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: esHoy ? FontWeight.bold : FontWeight.normal,
                                color: esHoy ? Colors.blue : null,
                              ),
                            ),
                            if (color != null)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              if (_selectedDay != null)
                Expanded(
                  child: entradasSeleccionadas.isEmpty
                      ? Center(
                    child: Text(
                      'Sin registros el ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: entradasSeleccionadas.length,
                    itemBuilder: (c, i) {
                      final entrada = entradasSeleccionadas[i];
                      final total = entrada['dosisTotal'] as int;
                      final tomadas = entrada['dosisTomadas'] as int;
                      Color estadoColor;
                      String estadoTexto;

                      if (tomadas == 0) {
                        estadoColor = Colors.red;
                        estadoTexto = 'No tomado';
                      } else if (tomadas == total) {
                        estadoColor = Colors.green;
                        estadoTexto = 'Completo';
                      } else {
                        estadoColor = Colors.orange;
                        estadoTexto = 'Parcial ($tomadas/$total)';
                      }

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: estadoColor.withOpacity(0.15),
                            child: Icon(Icons.medication, color: estadoColor),
                          ),
                          title: Text(entrada['nombre'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('$tomadas de $total dosis'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: estadoColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(estadoTexto,
                                style: TextStyle(
                                    color: estadoColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text('Toca un día para ver el detalle', style: TextStyle(color: Colors.grey)),
                  ),
                ),
            ],
          ),

          // ✅ Pestaña Estadísticas
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cumplimiento semanal y mensual
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Cumplimiento\nÚltima Semana',
                        '${stats['cumplimientoSemanal']}%',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Cumplimiento\nÚltimo Mes',
                        '${stats['cumplimientoMensual']}%',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Total de dosis
                _buildStatCard(
                  'Total de Dosis Registradas',
                  '${stats['dosisTomadas']} / ${stats['totalDosis']}',
                  Colors.purple,
                ),
                const SizedBox(height: 20),

                // Medicamentos cumplidos
                if ((stats['medicamentosCumplidos'] as List).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ Medicamentos con Cumplimiento 100%',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...(stats['medicamentosCumplidos'] as List<String>)
                          .map((med) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(med),
                          ],
                        ),
                      ))
                          .toList(),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Medicamentos incumplidos
                if ((stats['medicamentosIncumplidos'] as List).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '❌ Medicamentos sin Registro',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...(stats['medicamentosIncumplidos'] as List<String>)
                          .map((med) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.cancel, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text(med),
                          ],
                        ),
                      ))
                          .toList(),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildLeyenda(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  String _nombreMes(DateTime d) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${meses[d.month - 1]} ${d.year}';
  }
}