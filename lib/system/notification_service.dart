import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Set<String> _sentNotifications = {};
  
  final Set<String> _permanentNotifications = {};
  
  static const String _notificationHistoryKey = 'sent_notifications_history_v3';
  static const String _permanentNotificationHistoryKey = 'permanent_notification_history_v1';
  
  bool _historyLoaded = false;
  bool _permanentHistoryLoaded = false;

  bool containsPermanentNotification(String key) {
    return _permanentNotifications.contains(key);
  }

  Future<void> addPermanentNotification(String key) async {
    _permanentNotifications.add(key);
    await _savePermanentNotificationHistory();
  }

  Future<void> init() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    
    await _loadNotificationHistory();
    await _loadPermanentNotificationHistory();
    
    tz_data.initializeTimeZones();

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
        print('🔔 การแจ้งเตือนถูกแตะ: ${response.payload}');
      },
    );
    
    print('✅ ระบบแจ้งเตือนเริ่มต้นพร้อมประวัติปกติ ${_sentNotifications.length} รายการ และประวัติถาวร ${_permanentNotifications.length} รายการ');
  }
  
  Future<void> _loadPermanentNotificationHistory() async {
    if (_permanentHistoryLoaded) {
      print('⏩ ข้ามการโหลดประวัติถาวรเพราะโหลดไปแล้ว');
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_permanentNotificationHistoryKey);
      
      if (historyJson != null && historyJson.isNotEmpty) {
        try {
          final List<dynamic> historyList = jsonDecode(historyJson);
          _permanentNotifications.clear();
          _permanentNotifications.addAll(historyList.cast<String>());
          print('📚 โหลดประวัติการแจ้งเตือนถาวร: ${_permanentNotifications.length} รายการ');
        } catch (e) {
          print('❌ ข้อผิดพลาดในการแปลง JSON สำหรับประวัติถาวร: $e');
          _permanentNotifications.clear();
          await prefs.remove(_permanentNotificationHistoryKey);
        }
      } else {
        print('📭 ไม่พบประวัติการแจ้งเตือนถาวร - เริ่มต้นใหม่');
        _permanentNotifications.clear();
      }
      
      _permanentHistoryLoaded = true;
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการโหลดประวัติการแจ้งเตือนถาวร: $e');
    }
  }
  
  Future<void> _savePermanentNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = jsonEncode(_permanentNotifications.toList());
      await prefs.setString(_permanentNotificationHistoryKey, historyJson);
      print('💾 บันทึกประวัติการแจ้งเตือนถาวร: ${_permanentNotifications.length} รายการ');
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการบันทึกประวัติการแจ้งเตือนถาวร: $e');
    }
  }
  
  Future<void> _loadNotificationHistory() async {
    if (_historyLoaded) {
      print('⏩ ข้ามการโหลดประวัติเพราะโหลดไปแล้ว');
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      
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
    
    String notificationKey = 'scheduled:$id:${scheduledTime.millisecondsSinceEpoch}';
    _sentNotifications.add(notificationKey);
    _permanentNotifications.add('permanent:$id');
    
    await _saveNotificationHistory();
    await _savePermanentNotificationHistory();
    
    print('⏰ ตั้งเวลาแจ้งเตือน ID $id สำหรับเวลา ${scheduledTime.toString()}');
  }

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

  Future<void> notifyQueueProgress({
    required String restaurantId,
    required String restaurantName,
    required String queueCode,
    required int waitingCount,
  }) async {
    if (!_historyLoaded) {
      await _loadNotificationHistory();
    }
    if (!_permanentHistoryLoaded) {
      await _loadPermanentNotificationHistory();
    }
    
    final String permanentKey = '$restaurantId:$queueCode:$waitingCount';
    
    if (_permanentNotifications.contains(permanentKey)) {
      print('🔕 ข้ามการแจ้งเตือน $permanentKey (เคยส่งแล้วอย่างถาวร)');
      return;
    }
    
    final String today = DateTime.now().toString().split(' ')[0]; 
    
    String notificationKey = '$today:$restaurantId:$queueCode:$waitingCount';
    
    if (_sentNotifications.contains(notificationKey)) {
      print('🔕 ข้ามการแจ้งเตือน $notificationKey (เคยส่งแล้ว)');
      return;
    }
    
    await clearQueueNotificationHistory(restaurantId, queueCode);
    
    final int baseId = queueCode.hashCode;
    
    String notificationBody;
    int notificationId;
    
    if (waitingCount == 0) {
      notificationBody = "ถึงคิวของคุณแล้ว!";
      notificationId = baseId + 100; 
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
      return;
    }
    
    print('🔔 กำลังส่งการแจ้งเตือน $notificationKey');
    
    await cancelNotification(notificationId);
    
    await showNotification(
      id: notificationId,
      title: 'คิวร้าน $restaurantName',
      body: notificationBody,
      payload: 'waiting:$restaurantId:$queueCode:$waitingCount',
    );
    
    _sentNotifications.add(notificationKey);
    _permanentNotifications.add(permanentKey);
    
    await _saveNotificationHistory();
    await _savePermanentNotificationHistory();
    
    print('✅ แจ้งเตือนสำเร็จและบันทึกประวัติแล้ว');
  }

  Future<void> clearQueueNotificationHistory(String restaurantId, String queueCode) async {
    int countBefore = _sentNotifications.length;
    
    _sentNotifications.removeWhere((key) => 
      key.contains(':$restaurantId:$queueCode:'));
    
    if (countBefore != _sentNotifications.length) {
      await _saveNotificationHistory();
      
      int countAfter = _sentNotifications.length;
      print('🧹 ลบประวัติการแจ้งเตือนของคิว $queueCode แล้ว (ลบไป ${countBefore - countAfter} รายการ)');
    }
  }
  
  Future<void> clearQueuePermanentNotificationHistory(String restaurantId, String queueCode) async {
    int countBefore = _permanentNotifications.length;
    
    _permanentNotifications.removeWhere((key) => 
      key.contains('$restaurantId:$queueCode:'));
    
    if (countBefore != _permanentNotifications.length) {
      await _savePermanentNotificationHistory();
      
      int countAfter = _permanentNotifications.length;
      print('🧹 ลบประวัติการแจ้งเตือนถาวรของคิว $queueCode แล้ว (ลบไป ${countBefore - countAfter} รายการ)');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      print('❌ ไม่สามารถยกเลิกการแจ้งเตือน ID $id: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      _sentNotifications.clear();
      await _saveNotificationHistory();
      print('🧹 ล้างการแจ้งเตือนและประวัติทั้งหมดแล้ว');
    } catch (e) {
      print('❌ ไม่สามารถยกเลิกการแจ้งเตือนทั้งหมด: $e');
    }
  }

  Future<void> scheduleQueueAdvanceNotifications({
    required String restaurantId,
    required String restaurantName,
    required DateTime bookingTime,
    required String queueCode,
  }) async {
    if (!_historyLoaded) {
      await _loadNotificationHistory();
    }
    if (!_permanentHistoryLoaded) {
      await _loadPermanentNotificationHistory();
    }
    
    String permanentBookingKey = '$restaurantId:$queueCode:booking';
    
    if (_permanentNotifications.contains(permanentBookingKey)) {
      print('🔕 ข้ามการตั้งเวลาแจ้งเตือนการจอง $permanentBookingKey (เคยตั้งไว้แล้วอย่างถาวร)');
      return;
    }
    
    final String bookingDate = bookingTime.toString().split(' ')[0]; 
    
    String bookingKey = '$bookingDate:$restaurantId:$queueCode:booking';
    
    if (_sentNotifications.contains(bookingKey)) {
      print('🔕 ข้ามการตั้งเวลาแจ้งเตือนการจอง $bookingKey (เคยตั้งไว้แล้ว)');
      return;
    }
    
    await cancelQueueNotifications(queueCode);
    
    final int baseId = queueCode.hashCode;
    
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
    
    if (bookingTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: baseId + 2,
        title: 'ถึงเวลาจองร้าน $restaurantName',
        body: 'ถึงคิวของคุณตามเวลาที่จองแล้วครับ!',
        scheduledTime: bookingTime,
        payload: 'queue:$restaurantId:$queueCode:exact',
      );
    }
    
    _sentNotifications.add(bookingKey);
    _permanentNotifications.add(permanentBookingKey);
    
    await _saveNotificationHistory();
    await _savePermanentNotificationHistory();
    
    print('✅ ตั้งเวลาแจ้งเตือนการจองสำเร็จ: $bookingKey');
  }

  Future<void> cancelQueueNotifications(String queueCode) async {
    final int baseId = queueCode.hashCode;
    
    await cancelNotification(baseId);     
    await cancelNotification(baseId + 1); 
    await cancelNotification(baseId + 2); 
    
    for (int i = 1; i <= 10; i++) {
      await cancelNotification(baseId + i);
    }
    await cancelNotification(baseId + 100); 
    
    _permanentNotifications.removeWhere((key) => key.contains(':$queueCode:'));
    await _savePermanentNotificationHistory();
    
    print('❌ ยกเลิกการแจ้งเตือนสำหรับคิว $queueCode แล้ว');
  }
  
  
  List<String> getAllNotificationHistory() {
    return _sentNotifications.toList();
  }
  
  
  List<String> getAllPermanentNotificationHistory() {
    return _permanentNotifications.toList();
  }
  
  Future<void> clearAllNotificationHistory() async {
    _sentNotifications.clear();
    await _saveNotificationHistory();
    print('🧹 ล้างประวัติการแจ้งเตือนทั้งหมดแล้ว');
  }
  
  Future<void> resetAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    
    _sentNotifications.clear();
    _permanentNotifications.clear();
    _historyLoaded = false;
    _permanentHistoryLoaded = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationHistoryKey);
    await prefs.remove(_permanentNotificationHistoryKey);
    
    print('🔄 รีเซ็ตระบบแจ้งเตือนทั้งหมดแล้ว');
  }
}