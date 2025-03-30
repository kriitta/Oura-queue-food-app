import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // คีย์สำหรับเก็บการแจ้งเตือนที่ถูกส่งแล้ว
  final Set<String> _sentNotifications = {};
  
  // เปลี่ยนคีย์ใหม่เพื่อเริ่มต้นระบบใหม่
  static const String _notificationHistoryKey = 'sent_notifications_history_v3';
  bool _historyLoaded = false;

  Future<void> init() async {
    // ยกเลิกการแจ้งเตือนปัจจุบันทั้งหมดเมื่อเริ่มแอป
    await _flutterLocalNotificationsPlugin.cancelAll();
    
    // โหลดประวัติการแจ้งเตือนก่อน
    await _loadNotificationHistory();
    
    // Initialize timezone
    tz_data.initializeTimeZones();

    // Initialize settings for different platforms
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
        print('🔔 การแจ้งเตือนถูกแตะ: ${response.payload}');
      },
    );
    
    print('✅ ระบบแจ้งเตือนเริ่มต้นพร้อมประวัติ ${_sentNotifications.length} รายการ');
  }
  
  // เพิ่มฟังก์ชันโหลดประวัติการแจ้งเตือน
  Future<void> _loadNotificationHistory() async {
    if (_historyLoaded) {
      print('⏩ ข้ามการโหลดประวัติเพราะโหลดไปแล้ว');
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ลบบรรทัดนี้ออก เพราะมันล้างประวัติทุกครั้ง!
      // await prefs.remove(_notificationHistoryKey);
      
      final String? historyJson = prefs.getString(_notificationHistoryKey);
      
      if (historyJson != null && historyJson.isNotEmpty) {
        try {
          final List<dynamic> historyList = jsonDecode(historyJson);
          _sentNotifications.clear();
          _sentNotifications.addAll(historyList.cast<String>());
          print('📚 โหลดประวัติการแจ้งเตือน: ${_sentNotifications.length} รายการ');
        } catch (e) {
          print('❌ ข้อผิดพลาดในการแปลง JSON: $e');
          _sentNotifications.clear();
          await prefs.remove(_notificationHistoryKey);
        }
      } else {
        print('📭 ไม่พบประวัติการแจ้งเตือน - เริ่มต้นใหม่');
        _sentNotifications.clear();
      }
      
      _historyLoaded = true;
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการโหลดประวัติการแจ้งเตือน: $e');
    }
  }
  
  // เพิ่มฟังก์ชันบันทึกประวัติการแจ้งเตือน
  Future<void> _saveNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = jsonEncode(_sentNotifications.toList());
      await prefs.setString(_notificationHistoryKey, historyJson);
      print('💾 บันทึกประวัติการแจ้งเตือน: ${_sentNotifications.length} รายการ');
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการบันทึกประวัติการแจ้งเตือน: $e');
    }
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

    // ยกเลิกการแจ้งเตือนด้วย ID เดียวกันที่อาจมีอยู่แล้ว
    await cancelNotification(id);

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
    
    // บันทึกว่าได้ตั้งเวลาแจ้งเตือนนี้แล้ว
    String notificationKey = 'scheduled:$id:${scheduledTime.millisecondsSinceEpoch}';
    _sentNotifications.add(notificationKey);
    await _saveNotificationHistory();
    
    print('⏰ ตั้งเวลาแจ้งเตือน ID $id สำหรับเวลา ${scheduledTime.toString()}');
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

    // ยกเลิกการแจ้งเตือนด้วย ID เดียวกันที่อาจมีอยู่แล้ว
    await cancelNotification(id);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
    
    print('🔔 แสดงการแจ้งเตือนทันที ID: $id');
  }

  // แจ้งเตือนเมื่อใกล้ถึงคิวของผู้ใช้ (สำหรับ walk-in queue)
  Future<void> notifyQueueProgress({
    required String restaurantId,
    required String restaurantName,
    required String queueCode,
    required int waitingCount,
  }) async {
    // ตรวจสอบให้แน่ใจว่าได้โหลดประวัติการแจ้งเตือนแล้ว
    if (!_historyLoaded) {
      await _loadNotificationHistory();
    }
    
    // ใช้วันที่ในการสร้างคีย์เพื่อป้องกันการแจ้งเตือนซ้ำในวันเดียวกัน
    final String today = DateTime.now().toString().split(' ')[0]; // เช่น '2023-03-30'
    
    // ป้องกันการส่งการแจ้งเตือนซ้ำสำหรับคิวเดียวกันที่จำนวนคิวเท่ากัน
    String notificationKey = '$today:$restaurantId:$queueCode:$waitingCount';
    
    // ถ้าเคยส่งแล้ว ให้ข้าม
    if (_sentNotifications.contains(notificationKey)) {
      print('🔕 ข้ามการแจ้งเตือน $notificationKey (เคยส่งแล้ว)');
      return;
    }
    
    // ลบประวัติการแจ้งเตือนเก่าของร้านอาหารและคิวนี้
    // ใช้ตัวกรองที่ละเอียดขึ้นเพื่อลบเฉพาะรายการที่เกี่ยวข้อง
    await clearQueueNotificationHistory(restaurantId, queueCode);
    
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
    
    print('🔔 กำลังส่งการแจ้งเตือน $notificationKey');
    
    // แสดงการแจ้งเตือน - ยกเลิกการแจ้งเตือนก่อนแสดงอันใหม่
    await cancelNotification(notificationId);
    
    await showNotification(
      id: notificationId,
      title: 'คิวร้าน $restaurantName',
      body: notificationBody,
      payload: 'waiting:$restaurantId:$queueCode:$waitingCount',
    );
    
    // บันทึกว่าได้ส่งการแจ้งเตือนนี้ไปแล้ว
    _sentNotifications.add(notificationKey);
    
    // บันทึกลง SharedPreferences
    await _saveNotificationHistory();
    
    print('✅ แจ้งเตือนสำเร็จและบันทึกประวัติแล้ว');
  }

  // ล้างประวัติการแจ้งเตือนที่เกี่ยวข้องกับคิวที่ระบุ
  Future<void> clearQueueNotificationHistory(String restaurantId, String queueCode) async {
    int countBefore = _sentNotifications.length;
    
    // ลบเฉพาะประวัติที่เกี่ยวข้องกับร้านและคิวนี้ (ไม่รวมส่วนวันที่)
    _sentNotifications.removeWhere((key) => 
      key.contains(':$restaurantId:$queueCode:'));
    
    // บันทึกการเปลี่ยนแปลงลง SharedPreferences
    if (countBefore != _sentNotifications.length) {
      await _saveNotificationHistory();
      
      int countAfter = _sentNotifications.length;
      print('🧹 ลบประวัติการแจ้งเตือนของคิว $queueCode แล้ว (ลบไป ${countBefore - countAfter} รายการ)');
    }
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      print('❌ ไม่สามารถยกเลิกการแจ้งเตือน ID $id: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      // ล้างประวัติการแจ้งเตือนทั้งหมด
      _sentNotifications.clear();
      await _saveNotificationHistory();
      print('🧹 ล้างการแจ้งเตือนและประวัติทั้งหมดแล้ว');
    } catch (e) {
      print('❌ ไม่สามารถยกเลิกการแจ้งเตือนทั้งหมด: $e');
    }
  }

  // Schedule queue advance notification (30 min, 15 min, and exactly at booking time)
  Future<void> scheduleQueueAdvanceNotifications({
    required String restaurantId,
    required String restaurantName,
    required DateTime bookingTime,
    required String queueCode,
  }) async {
    // ตรวจสอบให้แน่ใจว่าได้โหลดประวัติการแจ้งเตือนแล้ว
    if (!_historyLoaded) {
      await _loadNotificationHistory();
    }
    
    // ใช้วันที่ในการสร้างคีย์เพื่อป้องกันการแจ้งเตือนซ้ำในวันเดียวกัน
    final String bookingDate = bookingTime.toString().split(' ')[0]; // เช่น '2023-03-30'
    
    // สร้างคีย์สำหรับตรวจสอบว่าเคยตั้งเวลาแจ้งเตือนนี้ไปแล้วหรือไม่
    String bookingKey = '$bookingDate:$restaurantId:$queueCode:booking';
    
    // ถ้าเคยตั้งเวลาแจ้งเตือนแล้ว ให้ข้าม
    if (_sentNotifications.contains(bookingKey)) {
      print('🔕 ข้ามการตั้งเวลาแจ้งเตือนการจอง $bookingKey (เคยตั้งไว้แล้ว)');
      return;
    }
    
    // รีเซ็ตการแจ้งเตือนสำหรับคิวนี้ก่อน
    await cancelQueueNotifications(queueCode);
    
    // Generate unique IDs based on queue code to be able to cancel them later if needed
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
        id: baseId + 1,
        title: 'เตือนการจองคิวร้าน $restaurantName',
        body: 'อีก 15 นาทีจะถึงคิวของท่านแล้ว กรุณาแสดงตัวตนก่อนถึงเวลาเรียกคิว',
        scheduledTime: fifteenMinBefore,
        payload: 'queue:$restaurantId:$queueCode',
      );
    }
    
    // เพิ่มการแจ้งเตือนเมื่อถึงเวลาจองพอดี
    if (bookingTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: baseId + 2,
        title: 'ถึงเวลาจองร้าน $restaurantName',
        body: 'ถึงคิวของคุณตามเวลาที่จองแล้วครับ!',
        scheduledTime: bookingTime,
        payload: 'queue:$restaurantId:$queueCode:exact',
      );
    }
    
    // บันทึกว่าได้ตั้งเวลาแจ้งเตือนนี้แล้ว
    _sentNotifications.add(bookingKey);
    await _saveNotificationHistory();
    
    print('✅ ตั้งเวลาแจ้งเตือนการจองสำเร็จ: $bookingKey');
  }

  // Cancel notifications for a specific queue
  Future<void> cancelQueueNotifications(String queueCode) async {
    final int baseId = queueCode.hashCode;
    
    // ยกเลิกการแจ้งเตือนตามกำหนดเวลา
    await cancelNotification(baseId);     // 30 min notification
    await cancelNotification(baseId + 1); // 15 min notification
    await cancelNotification(baseId + 2); // exact time notification
    
    // ยกเลิกการแจ้งเตือนสำหรับคิวที่รออยู่
    for (int i = 1; i <= 10; i++) {
      await cancelNotification(baseId + i);
    }
    await cancelNotification(baseId + 100); // การแจ้งเตือนเมื่อถึงคิว
    
    print('❌ ยกเลิกการแจ้งเตือนสำหรับคิว $queueCode แล้ว');
  }
  
  // เพิ่มฟังก์ชันดูประวัติการแจ้งเตือนทั้งหมด (สำหรับการดีบัก)
  List<String> getAllNotificationHistory() {
    return _sentNotifications.toList();
  }
  
  // เพิ่มฟังก์ชันล้างประวัติการแจ้งเตือนทั้งหมด
  Future<void> clearAllNotificationHistory() async {
    _sentNotifications.clear();
    await _saveNotificationHistory();
    print('🧹 ล้างประวัติการแจ้งเตือนทั้งหมดแล้ว');
  }
  
  // เพิ่มฟังก์ชันรีเซ็ตทั้งหมด
  Future<void> resetAll() async {
    // ยกเลิกการแจ้งเตือนทั้งหมด
    await _flutterLocalNotificationsPlugin.cancelAll();
    
    // ล้างประวัติ
    _sentNotifications.clear();
    _historyLoaded = false;
    
    // ลบข้อมูลจาก SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationHistoryKey);
    
    print('🔄 รีเซ็ตระบบแจ้งเตือนทั้งหมดแล้ว');
  }
}