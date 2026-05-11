import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class NotificationService {
  static Future<void> init() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'alarma_v90',
          channelName: 'Alertas Médicas',
          channelDescription: 'Recordatorios de medicamentos',
          defaultColor: Colors.blue,
          importance: NotificationImportance.Max,
          defaultRingtoneType: DefaultRingtoneType.Alarm,
          playSound: true,
          enableVibration: true,
        )
      ],
      debug: true,
    );

    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
    );

    bool allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> crearNotificacion({
    required int id,
    required String titulo,
    required String cuerpo,
    required int hour,
    required int minute,
    required String nombreMedicamento,
    required int doseIndex,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'alarma_v90',
        title: titulo,
        body: cuerpo,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        fullScreenIntent: true,
        payload: {
          'nombreMedicamento': nombreMedicamento,
          'doseIndex': '$doseIndex',
          'notificationId': '$id',
        },
      ),
      // ✅ Sin botones de acción
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        millisecond: 0,
        repeats: true,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  }

  static Future<void> crearNotificacionPospuesta({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime cuando,
    required String nombreMedicamento,
    required int doseIndex,
  }) async {
    // ✅ Cancelar cualquier pospuesta anterior para esta dosis
    await AwesomeNotifications().cancel(id + 10000);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id + 10000,
        channelKey: 'alarma_v90',
        title: titulo,
        body: cuerpo,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        fullScreenIntent: true,
        payload: {
          'nombreMedicamento': nombreMedicamento,
          'doseIndex': '$doseIndex',
          'notificationId': '$id',
          'esPospuesta': 'true',
        },
      ),
      // ✅ Sin botones de acción
      schedule: NotificationCalendar.fromDate(
        date: cuando,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  }

  static Future<void> cancelarNotificacion(int id) async {
    await AwesomeNotifications().cancel(id);
    await AwesomeNotifications().cancel(id + 10000);
  }

  static Future<void> cancelarTodas() async {
    await AwesomeNotifications().cancelAll();
  }
}