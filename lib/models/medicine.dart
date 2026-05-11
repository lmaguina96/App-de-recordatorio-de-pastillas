import 'package:hive/hive.dart';

part 'medicine.g.dart';

@HiveType(typeId: 0)
class Medicine extends HiveObject {
  @HiveField(0)
  String nombre;

  @HiveField(1)
  List<String> horas;

  @HiveField(2)
  int vecesAlDia;

  @HiveField(3)
  List<bool> tomadas;

  @HiveField(4)
  List<bool> pospuestas;

  @HiveField(5)
  bool diario;

  @HiveField(6)
  List<String> dias;

  @HiveField(7)
  List<int> notificationIds; // ✅ nuevo: IDs de notificaciones

  @HiveField(8)
  List<String> postponedUntil; // ✅ nuevo: hora hasta la que se pospuso "HH:mm"

  Medicine({
    required this.nombre,
    required this.horas,
    required this.vecesAlDia,
    this.diario = true,
    this.dias = const [],
    List<bool>? tomadas,
    List<bool>? pospuestas,
    List<int>? notificationIds,
    List<String>? postponedUntil,
  })  : this.tomadas = tomadas ?? List.filled(vecesAlDia, false),
        this.pospuestas = pospuestas ?? List.filled(vecesAlDia, false),
        this.notificationIds = notificationIds ?? List.filled(vecesAlDia, 0),
        this.postponedUntil = postponedUntil ?? List.filled(vecesAlDia, '');
}