import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // คีย์สำหรับเก็บการแจ้งเตือนที่ถูกส่งแล้ว
  final Set<String> _sentNotifications = {};

  Future<void> init() async {
    // Initialize timezone
    tz_data.initializeTimeZones();

    // Initialize settings for different platforms
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // แก้ icon ให้ใช้ ic_launcher แทน app_icon

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );
  }

  // Schedule a notification for a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'queue_notification_channel',
      'Queue Notifications',
      channelDescription: 'Notifications for queue status',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'queue_notification_channel',
      'Queue Notifications',
      channelDescription: 'Notifications for queue status',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // แจ้งเตือนเมื่อใกล้ถึงคิวของผู้ใช้ (สำหรับ walk-in queue)
  Future<void> notifyQueueProgress({
    required String restaurantId,
    required String restaurantName,
    required String queueCode,
    required int waitingCount,
  }) async {
    // ป้องกันการส่งการแจ้งเตือนซ้ำสำหรับคิวเดียวกันที่จำนวนคิวเท่ากัน
    String notificationKey = '$restaurantId:$queueCode:$waitingCount';
    
    // ถ้าเคยส่งแล้ว ให้ข้าม
    if (_sentNotifications.contains(notificationKey)) {
      return;
    }
    
    // สร้าง ID สำหรับการแจ้งเตือนจาก queueCode
    final int baseId = queueCode.hashCode;
    
    // ข้อความแจ้งเตือนตามจำนวนคิวที่รออยู่
    String notificationBody;
    int notificationId;
    
    if (waitingCount == 0) {
      notificationBody = "ถึงคิวของคุณแล้ว!";
      notificationId = baseId + 100; // ใช้ ID พิเศษสำหรับถึงคิวแล้ว
    } else if (waitingCount == 1) {
      notificationBody = "อีก 1 คิวจะถึงคิวของท่านแล้ว!";
      notificationId = baseId + 1;
    } else if (waitingCount == 2) {
      notificationBody = "อีก 2 คิวจะถึงคิวของท่านแล้ว!";
      notificationId = baseId + 2;
    } else if (waitingCount == 3) {
      notificationBody = "อีก 3 คิวจะถึงคิวของท่านแล้ว!";
      notificationId = baseId + 3;
    } else if (waitingCount == 4) {
      notificationBody = "อีก 4 คิวจะถึงคิวของท่านแล้ว!";
      notificationId = baseId + 4;
    } else if (waitingCount == 5) {
      notificationBody = "อีก 5 คิวใกล้จะถึงคิวของท่านแล้ว!";
      notificationId = baseId + 5;
    } else if (waitingCount == 10) {
      notificationBody = "อีก 10 คิวจะถึงคิวของท่านแล้ว อย่าลืมมาแสดงตนหน้าร้านเมื่อถึงคิวของท่านด้วยนะครับ!";
      notificationId = baseId + 10;
    } else {
      // ไม่อยู่ในเงื่อนไขที่ต้องแจ้งเตือน
      return;
    }
    
    // แสดงการแจ้งเตือน
    await showNotification(
      id: notificationId,
      title: 'คิวร้าน $restaurantName',
      body: notificationBody,
      payload: 'waiting:$restaurantId:$queueCode:$waitingCount',
    );
    
    // บันทึกว่าได้ส่งการแจ้งเตือนนี้ไปแล้ว
    _sentNotifications.add(notificationKey);
  }

  // ล้างประวัติการแจ้งเตือนที่เกี่ยวข้องกับคิวที่ระบุ
  void clearQueueNotificationHistory(String restaurantId, String queueCode) {
    _sentNotifications.removeWhere((key) => key.startsWith('$restaurantId:$queueCode:'));
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Schedule queue advance notification (30 min, 15 min, and exactly at booking time)
  Future<void> scheduleQueueAdvanceNotifications({
    required String restaurantId,
    required String restaurantName,
    required DateTime bookingTime,
    required String queueCode,
  }) async {
    // Generate unique IDs based on queue code to be able to cancel them later if needed
    // Using a simple hash function based on queueCode
    final int baseId = queueCode.hashCode;
    
    // Schedule 30 minutes notification
    final DateTime thirtyMinBefore = bookingTime.subtract(const Duration(minutes: 30));
    if (thirtyMinBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: baseId,
        title: 'เตือนการจองคิวร้าน $restaurantName',
        body: 'อีก 30 นาทีจะถึงเวลาที่ท่านจองร้านอาหารไว้แล้ว!',
        scheduledTime: thirtyMinBefore,
        payload: 'queue:$restaurantId:$queueCode',
      );
    }

    // Schedule 15 minutes notification
    final DateTime fifteenMinBefore = bookingTime.subtract(const Duration(minutes: 15));
    if (fifteenMinBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: baseId + 1, // Using baseId + 1 to make it unique from the 30 min notification
        title: 'เตือนการจองคิวร้าน $restaurantName',
        body: 'อีก 15 นาทีจะถึงคิวของท่านแล้ว กรุณาแสดงตัวตนก่อนถึงเวลาเรียกคิว',
        scheduledTime: fifteenMinBefore,
        payload: 'queue:$restaurantId:$queueCode',
      );
    }
    
    // เพิ่มการแจ้งเตือนเมื่อถึงเวลาจองพอดี
    if (bookingTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: baseId + 2, // Using baseId + 2 to make it unique from other notifications
        title: 'ถึงเวลาจองร้าน $restaurantName',
        body: 'ถึงคิวของคุณตามเวลาที่จองแล้วครับ!',
        scheduledTime: bookingTime,
        payload: 'queue:$restaurantId:$queueCode:exact',
      );
    }
  }

  // Cancel notifications for a specific queue
  Future<void> cancelQueueNotifications(String queueCode) async {
    final int baseId = queueCode.hashCode;
    await cancelNotification(baseId);     // 30 min notification
    await cancelNotification(baseId + 1); // 15 min notification
    await cancelNotification(baseId + 2); // exact time notification
    
    // ยกเลิกการแจ้งเตือนสำหรับคิวที่รออยู่
    for (int i = 1; i <= 10; i++) {
      await cancelNotification(baseId + i);
    }
    await cancelNotification(baseId + 100); // การแจ้งเตือนเมื่อถึงคิว
  }
}