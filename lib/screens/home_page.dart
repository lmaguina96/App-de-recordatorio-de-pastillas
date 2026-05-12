import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/hive_service.dart';
import '../utils/colors.dart';
import '../widgets/medicine_card.dart';
import 'add_medicine_page.dart';
import 'history_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Medicine> _medicamentos = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _cargarMedicamentos();
  }

  void _cargarMedicamentos() {
    setState(() {
      _medicamentos = HiveService.getMedicamentos();
    });
  }

  void _agregarMedicamento(Medicine medicine) async {
    await HiveService.guardarMedicamento(medicine);
    _cargarMedicamentos();
  }

  void _eliminarMedicamento(int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar medicamento'),
        content: const Text(
          '¿Estás seguro de que quieres eliminarlo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await HiveService.eliminar(index);

              await HiveService.eliminarDelHistorial(
                _medicamentos[index].nombre,
              );

              _cargarMedicamentos();

              Navigator.pop(context);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _onDoseAction(
      int medicamentIndex,
      int doseIndex,
      ) {
    final medicina = _medicamentos[medicamentIndex];

    setState(() {
      medicina.tomadas[doseIndex] =
      !medicina.tomadas[doseIndex];
    });

    HiveService.guardarMedicamento(
      medicina,
      index: medicamentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicinas de Clau'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),

      body: _selectedIndex == 0
          ? _buildHomePage()
          : _selectedIndex == 1
          ? HistoryPage(
        historial:
        HiveService.getHistorial(),

        onClear: () async {
          await HiveService
              .limpiarHistorial();

          setState(() {});
        },
      )
          : const SettingsPage(),

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result =
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const AddMedicinePage(),
            ),
          );

          if (result != null) {
            _agregarMedicamento(result);
          }
        },
        child: const Icon(Icons.add),
      )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,

        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    if (_medicamentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication,
              size: 80,
              color: Colors.grey[300],
            ),

            const SizedBox(height: 20),

            Text(
              'No hay medicamentos',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),

            const SizedBox(height: 10),

            const Text(
              'Agrega uno con el botón +',
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _medicamentos.length,

      itemBuilder: (context, index) {
        final med = _medicamentos[index];

        return Padding(
          padding: const EdgeInsets.all(8.0),

          child: MedicineCard(
            medicine: med,

            onDelete: () =>
                _eliminarMedicamento(index),

            onEdit: () {
              // editar después
            },

            onToggle: (doseIndex) {
              setState(() {
                med.tomadas[doseIndex] =
                !med.tomadas[doseIndex];
              });

              HiveService.guardarMedicamento(
                med,
                index: index,
              );
            },

            onDoseAction: (doseIndex) =>
                _onDoseAction(
                  index,
                  doseIndex,
                ),
          ),
        );
      },
    );
  }
}