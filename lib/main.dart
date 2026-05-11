import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'screens/home_page.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';
import 'models/medicine.dart';

class NotificationActionStream {
  static final _instance = NotificationActionStream._();
  static NotificationActionStream get instance => _instance;
  NotificationActionStream._();

  final List<Function(ReceivedAction)> _listeners = [];
  void addListener(Function(ReceivedAction) listener) => _listeners.add(listener);
  void removeListener(Function(ReceivedAction) listener) => _listeners.remove(listener);
  void notify(ReceivedAction action) {
    for (var l in _listeners) l(action);
  }
}

class NotificationDisplayedStream {
  static final _instance = NotificationDisplayedStream._();
  static NotificationDisplayedStream get instance => _instance;
  NotificationDisplayedStream._();

  final List<Function(ReceivedNotification)> _listeners = [];
  void addListener(Function(ReceivedNotification) listener) => _listeners.add(listener);
  void removeListener(Function(ReceivedNotification) listener) => _listeners.remove(listener);
  void notify(ReceivedNotification notification) {
    for (var l in _listeners) l(notification);
  }
}

class NotificationController {
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    NotificationActionStream.instance.notify(action);
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification notification) async {
    NotificationDisplayedStream.instance.notify(notification);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MedicineAdapter());
  await Hive.openBox<Medicine>('medicamentos');
  await Hive.openBox('historial');
  await NotificationService.init();
  runApp(const RecordatorioPastillaApp());
}

class RecordatorioPastillaApp extends StatefulWidget {
  const RecordatorioPastillaApp({super.key});
  @override
  State<RecordatorioPastillaApp> createState() => _RecordatorioPastillaAppState();
}

class _RecordatorioPastillaAppState extends State<RecordatorioPastillaApp> {
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: HomePage(onToggleTheme: () => setState(() => darkMode = !darkMode)),
    );
  }
}