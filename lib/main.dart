import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/hive_service.dart';
import 'screens/home_page.dart';
import 'utils/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.inicializar();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicinas de Clau',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}