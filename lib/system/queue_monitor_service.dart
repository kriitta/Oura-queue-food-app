import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../system/notification_service.dart';

class QueueMonitorService {
  // Singleton pattern
  static final QueueMonitorService _instance = QueueMonitorService._internal();
  factory QueueMonitorService() => _instance;
  QueueMonitorService._internal();

  // ระบบการแจ้งเตือน
  final NotificationService _notificationService = NotificationService();
  
  // ตัวแปรสำหรับเก็บ active monitors
  final Map<String, StreamSubscription> _activeMonitors = {};
  
  // ชุดของการแจ้งเตือนที่ส่งไปแล้ว เพื่อป้องกันการส่งซ้ำ
  final Set<String> _processedNotifications = {};
  
  // เริ่มติดตามคิวของผู้ใช้ทุกคิว
  Future<void> startMonitoringAllQueues() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    // ติดตามคิวแบบ walk-in ที่รออยู่
    _monitorWalkInQueues(currentUser);
    
    // ติดตามการแจ้งเตือนจากการเปลี่ยนแปลงของคิวทั้งหมด (รวมทั้ง walk-in และการจองล่วงหน้า)
    _monitorAllQueueNotifications(currentUser);
  }
  
  // ติดตามคิวแบบ walk-in ที่รออยู่
  void _monitorWalkInQueues(User currentUser) {
    final userQueuesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('myQueue')
        .where('isReservation', isEqualTo: false) // เฉพาะคิวแบบ walk-in
        .where('status', isEqualTo: 'waiting') // เฉพาะคิวที่ยังรออยู่
        .snapshots();
    
    userQueuesStream.listen((snapshot) {
      // ตรวจสอบทุกคิวของผู้ใช้
      for (var doc in snapshot.docs) {
        final queueData = doc.data();
        final restaurantId = queueData['restaurantId'];
        final queueCode = queueData['queueCode'];
        
        // เริ่มติดตามคิวนี้ถ้ายังไม่ได้ติดตาม
        if (restaurantId != null && queueCode != null) {
          final queueId = '$restaurantId:$queueCode';
          
          if (!_activeMonitors.containsKey(queueId)) {
            _startMonitoringQueue(
              restaurantId: restaurantId,
              restaurantName: queueData['restaurantName'] ?? 'ร้านอาหาร',
              queueCode: queueCode,
              timestamp: queueData['timestamp'],
            );
          }
        }
      }
      
      // หยุดติดตามคิวที่ไม่มีอยู่ในรายการอีกต่อไป
      final activeQueueIds = snapshot.docs.map((doc) {
        final data = doc.data();
        return '${data['restaurantId']}:${data['queueCode']}';
      }).toSet();
      
      // หาคิวที่ควรหยุดติดตาม
      final queuesToRemove = _activeMonitors.keys
          .where((id) => !activeQueueIds.contains(id))
          .toList();
      
      // หยุดติดตามและทำความสะอาด
      for (var id in queuesToRemove) {
        _stopMonitoringQueue(id);
      }
    });
  }
  
  // ติดตามการเปลี่ยนแปลงของคิวทั้งหมดเพื่อรับการแจ้งเตือน
  void _monitorAllQueueNotifications(User currentUser) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('myQueue')
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            final queueData = change.doc.data() as Map<String, dynamic>;
            
            // ตรวจสอบการเปลี่ยนแปลงของเอกสาร
            if (change.type == DocumentChangeType.modified) {
              _checkForNotifications(queueData);
            } else if (change.type == DocumentChangeType.added) {
              // ตรวจสอบฟิลด์แจ้งเตือนในเอกสารที่เพิ่มใหม่ด้วย
              _checkForNotifications(queueData);
            }
          }
        });
  }
  
  // ตรวจสอบและส่งการแจ้งเตือนตามข้อมูลคิว
  // ตรวจสอบและส่งการแจ้งเตือนตามข้อมูลคิว
void _checkForNotifications(Map<String, dynamic> queueData) {
  final String queueCode = queueData['queueCode'] ?? '';
  if (queueCode.isEmpty) return;
  
  final bool hasNotification = queueData['notificationSent'] == true;
  final String? notificationMessage = queueData['notificationMessage'];
  final String status = queueData['status'] ?? '';
  
  // สร้าง key เฉพาะสำหรับการแจ้งเตือนนี้
  final String notificationKey = '$queueCode:$status:${notificationMessage ?? ""}';
  
  // สร้าง key ถาวร (ไม่มีวันที่)
  final String permanentNotificationKey = '$queueCode:$status:${notificationMessage ?? ""}';
  
  // ตรวจสอบว่าเป็นการแจ้งเตือนใหม่หรือไม่และยังไม่เคยส่ง (ทั้งในประวัติชั่วคราวและถาวร)
  bool alreadySentPermanent = _notificationService.containsPermanentNotification(permanentNotificationKey);
  
  if ((hasNotification || status == 'completed' || status == 'cancelled') && 
      !_processedNotifications.contains(notificationKey) &&
      !alreadySentPermanent) {
    
    String title = 'การจองของคุณ';
    String body = notificationMessage ?? '';
    
    // กำหนดค่าเริ่มต้นถ้าไม่มีข้อความ
    if (body.isEmpty) {
      if (status == 'completed') {
        body = 'ถึงคิวของคุณเรียบร้อยแล้ว และได้รับ 2 coins!';
      } else if (status == 'cancelled') {
        title = 'การจองของคุณถูกยกเลิก';
        body = 'คิวของคุณถูกทางร้านยกเลิก';
      }
    }
    
    // ส่งการแจ้งเตือนเฉพาะเมื่อมีข้อความ
    if (body.isNotEmpty) {
      _notificationService.showNotification(
        id: queueCode.hashCode,
        title: title,
        body: body,
        payload: 'queue:$queueCode:$status',
      );
      
      // เพิ่มเข้าไปในชุดของการแจ้งเตือนที่ประมวลผลแล้ว (ทั้งชั่วคราวและถาวร)
      _processedNotifications.add(notificationKey);
      _notificationService.addPermanentNotification(permanentNotificationKey);
    }
  }
}
  
  // เริ่มติดตามคิวที่ระบุ
  void _startMonitoringQueue({
    required String restaurantId,
    required String restaurantName,
    required String queueCode,
    Timestamp? timestamp,
  }) {
    if (timestamp == null) return;
    
    final queueId = '$restaurantId:$queueCode';
    
    // ตรวจสอบว่ามีการเริ่มติดตามไปแล้วหรือไม่
    if (_activeMonitors.containsKey(queueId)) {
      print('ข้ามการเริ่มติดตาม: $queueId (กำลังติดตามอยู่แล้ว)');
      return;
    }
    
    print('เริ่มติดตามคิว: $queueId');
    
    // ดึงข้อมูลคิวทั้งหมดจากร้านอาหารที่ระบุและติดตามการเปลี่ยนแปลง
    final queueStream = FirebaseFirestore.instance
        .collection('queues')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('isReservation', isEqualTo: false)
        .where('status', isEqualTo: 'waiting')
        .snapshots();
    
    final subscription = queueStream.listen((snapshot) {
      // นับจำนวนคิวที่รออยู่ก่อนคิวของผู้ใช้
      int waitingCount = 0;
      
      for (var doc in snapshot.docs) {
        final queueData = doc.data();
        final queueTimestamp = queueData['timestamp'];
        
        if (queueTimestamp is Timestamp && 
            queueTimestamp.toDate().isBefore(timestamp.toDate())) {
          waitingCount++;
        }
      }
      
      print('จำนวนคิวที่รออยู่ก่อนคิว $queueCode: $waitingCount');
      
      // ส่งการแจ้งเตือนตามจำนวนคิวที่รออยู่
      _notificationService.notifyQueueProgress(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        queueCode: queueCode,
        waitingCount: waitingCount,
      );
    });
    
    // เก็บการติดตามนี้ไว้
    _activeMonitors[queueId] = subscription;
  }
  
  // หยุดติดตามคิวที่ระบุ
  void _stopMonitoringQueue(String queueId) {
    print('หยุดติดตามคิว: $queueId');
    
    // ยกเลิกการติดตาม
    _activeMonitors[queueId]?.cancel();
    _activeMonitors.remove(queueId);
    
    // ล้างประวัติการแจ้งเตือน
    final parts = queueId.split(':');
    if (parts.length >= 2) {
      // ล้างทั้งประวัติปกติและถาวร
      _notificationService.clearQueueNotificationHistory(parts[0], parts[1]);
      _notificationService.clearQueuePermanentNotificationHistory(parts[0], parts[1]);
    }
  }
  
  // ล้างการแจ้งเตือนที่เกี่ยวข้องกับคิวที่ระบุ
  void clearQueueNotifications(String queueCode) {
    // ล้างประวัติทั้งในคลาสนี้
    _processedNotifications.removeWhere((key) => key.startsWith('$queueCode:'));
    
    // และในคลาส NotificationService
    _notificationService.clearQueuePermanentNotificationHistory('', queueCode);
  }
  
  // หยุดติดตามคิวทั้งหมด
  void stopAllMonitoring() {
    for (var subscription in _activeMonitors.values) {
      subscription.cancel();
    }
    _activeMonitors.clear();
  }
}