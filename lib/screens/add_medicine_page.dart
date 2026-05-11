import 'package:flutter/material.dart';

class AddMedicinePage extends StatefulWidget {
  final String? nombreInicial;
  final List<String>? horasIniciales;
  final int? vecesInicial;

  const AddMedicinePage({
    super.key,
    this.nombreInicial,
    this.horasIniciales,
    this.vecesInicial,
  });

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final nombreController = TextEditingController();
  int vecesAlDia = 1;
  bool diario = true;
  List<String> diasSeleccionados = [];
  final List<String> diasSemana = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
  List<TextEditingController> horasControllers = [];

  @override
  void initState() {
    super.initState();
    nombreController.text = widget.nombreInicial ?? '';
    vecesAlDia = widget.vecesInicial ?? 1;
    _inicializarControllers();
  }

  void _inicializarControllers() {
    horasControllers = List.generate(
      vecesAlDia,
          (i) => TextEditingController(
        text: (widget.horasIniciales != null && i < widget.horasIniciales!.length)
            ? widget.horasIniciales![i]
            : '',
      ),
    );
  }

  void actualizarCampos(int cantidad) {
    setState(() {
      vecesAlDia = cantidad;
      _inicializarControllers();
    });
  }

  Future<void> seleccionarHora(int index) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (hora != null) {
      setState(() {
        horasControllers[index].text = hora.format(context);
      });
    }
  }

  // --- LÓGICA DEL PUNTO 4: VALIDACIÓN DE HORAS ---
  int _convertirAMinutos(String horaTexto) {
    if (horaTexto.isEmpty) return -1;
    // Convierte "08:30 PM" a minutos totales del día
    bool esPM = horaTexto.contains("PM");
    String limpia = horaTexto.replaceAll("AM", "").replaceAll("PM", "").trim();
    final partes = limpia.split(":");
    int h = int.parse(partes[0]);
    int m = int.parse(partes[1]);

    if (esPM && h != 12) h += 12;
    if (!esPM && h == 12) h = 0;

    return (h * 60) + m;
  }

  void guardar() {
    if (nombreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escribe el nombre del medicamento")),
      );
      return;
    }

    List<String> horas = [];
    List<int> minutosTotales = [];

    for (var controller in horasControllers) {
      if (controller.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor, completa todas las horas")),
        );
        return;
      }
      horas.add(controller.text);
      minutosTotales.add(_convertirAMinutos(controller.text));
    }

    // Validación cronológica (Punto 4)
    for (int i = 0; i < minutosTotales.length - 1; i++) {
      if (minutosTotales[i] >= minutosTotales[i + 1]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Error: La dosis ${i + 2} debe ser más tarde que la dosis ${i + 1}"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    Navigator.pop(
      context,
      {
        'nombre': nombreController.text,
        'horas': horas,
        'vecesAlDia': vecesAlDia,
        'diario': diario,
        'dias': diasSeleccionados,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Medicamento")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre medicamento",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              value: vecesAlDia,
              decoration: const InputDecoration(
                labelText: "Veces al día",
                border: OutlineInputBorder(),
              ),
              items: [1, 2, 3, 4, 5]
                  .map((e) => DropdownMenuItem(value: e, child: Text("$e")))
                  .toList(),
              onChanged: (value) => actualizarCampos(value!),
            ),
            const SizedBox(height: 20),
            ...List.generate(vecesAlDia, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: TextField(
                  controller: horasControllers[index],
                  readOnly: true,
                  onTap: () => seleccionarHora(index),
                  decoration: InputDecoration(
                    labelText: vecesAlDia == 1 ? "Hora" : "Hora ${index + 1}",
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.access_time),
                  ),
                ),
              );
            }),
            SwitchListTile(
              title: const Text("Todos los días"),
              value: diario,
              onChanged: (v) => setState(() => diario = v),
            ),
            if (!diario)
              Wrap(
                spacing: 5,
                children: diasSemana.map((dia) {
                  bool seleccionado = diasSeleccionados.contains(dia);
                  return FilterChip(
                    label: Text(dia),
                    selected: seleccionado,
                    onSelected: (v) {
                      setState(() {
                        v ? diasSeleccionados.add(dia) : diasSeleccionados.remove(dia);
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: guardar,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Guardar Medicamento", style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}