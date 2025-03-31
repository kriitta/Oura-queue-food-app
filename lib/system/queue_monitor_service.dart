import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../system/notification_service.dart';

class QueueMonitorService {
  static final QueueMonitorService _instance = QueueMonitorService._internal();
  factory QueueMonitorService() => _instance;
  QueueMonitorService._internal();

  final NotificationService _notificationService = NotificationService();
  
  final Map<String, StreamSubscription> _activeMonitors = {};
  
  final Set<String> _processedNotifications = {};
  
  Future<void> startMonitoringAllQueues() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    _monitorWalkInQueues(currentUser);
    
    _monitorAllQueueNotifications(currentUser);
  }
  
  void _monitorWalkInQueues(User currentUser) {
    final userQueuesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('myQueue')
        .where('isReservation', isEqualTo: false) 
        .where('status', isEqualTo: 'waiting') 
        .snapshots();
    
    userQueuesStream.listen((snapshot) {
      for (var doc in snapshot.docs) {
        final queueData = doc.data();
        final restaurantId = queueData['restaurantId'];
        final queueCode = queueData['queueCode'];
        
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
      final activeQueueIds = snapshot.docs.map((doc) {
        final data = doc.data();
        return '${data['restaurantId']}:${data['queueCode']}';
      }).toSet();
      
      final queuesToRemove = _activeMonitors.keys
          .where((id) => !activeQueueIds.contains(id))
          .toList();
      
      for (var id in queuesToRemove) {
        _stopMonitoringQueue(id);
      }
    });
  }
  
  void _monitorAllQueueNotifications(User currentUser) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('myQueue')
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            final queueData = change.doc.data() as Map<String, dynamic>;
            
            if (change.type == DocumentChangeType.modified) {
              _checkForNotifications(queueData);
            } else if (change.type == DocumentChangeType.added) {
              _checkForNotifications(queueData);
            }
          }
        });
  }
  
void _checkForNotifications(Map<String, dynamic> queueData) {
  final String queueCode = queueData['queueCode'] ?? '';
  if (queueCode.isEmpty) return;
  
  final bool hasNotification = queueData['notificationSent'] == true;
  final String? notificationMessage = queueData['notificationMessage'];
  final String status = queueData['status'] ?? '';
  
  final String notificationKey = '$queueCode:$status:${notificationMessage ?? ""}';
  
  final String permanentNotificationKey = '$queueCode:$status:${notificationMessage ?? ""}';
  
  bool alreadySentPermanent = _notificationService.containsPermanentNotification(permanentNotificationKey);
  
  if ((hasNotification || status == 'completed' || status == 'cancelled') && 
      !_processedNotifications.contains(notificationKey) &&
      !alreadySentPermanent) {
    
    String title = 'การจองของคุณ';
    String body = notificationMessage ?? '';
    
    if (body.isEmpty) {
      if (status == 'completed') {
        body = 'ถึงคิวของคุณเรียบร้อยแล้ว และได้รับ 2 coins!';
      } else if (status == 'cancelled') {
        title = 'การจองของคุณถูกยกเลิก';
        body = 'คิวของคุณถูกทางร้านยกเลิก';
      }
    }
    
    if (body.isNotEmpty) {
      _notificationService.showNotification(
        id: queueCode.hashCode,
        title: title,
        body: body,
        payload: 'queue:$queueCode:$status',
      );
      
      _processedNotifications.add(notificationKey);
      _notificationService.addPermanentNotification(permanentNotificationKey);
    }
  }
}
  
  void _startMonitoringQueue({
    required String restaurantId,
    required String restaurantName,
    required String queueCode,
    Timestamp? timestamp,
  }) {
    if (timestamp == null) return;
    
    final queueId = '$restaurantId:$queueCode';
    
    if (_activeMonitors.containsKey(queueId)) {
      print('ข้ามการเริ่มติดตาม: $queueId (กำลังติดตามอยู่แล้ว)');
      return;
    }
    
    print('เริ่มติดตามคิว: $queueId');
    
    final queueStream = FirebaseFirestore.instance
        .collection('queues')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('isReservation', isEqualTo: false)
        .where('status', isEqualTo: 'waiting')
        .snapshots();
    
    final subscription = queueStream.listen((snapshot) {
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
      
      _notificationService.notifyQueueProgress(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        queueCode: queueCode,
        waitingCount: waitingCount,
      );
    });
    
    _activeMonitors[queueId] = subscription;
  }
  
  void _stopMonitoringQueue(String queueId) {
    print('หยุดติดตามคิว: $queueId');
    
    _activeMonitors[queueId]?.cancel();
    _activeMonitors.remove(queueId);
    
    final parts = queueId.split(':');
    if (parts.length >= 2) {
      _notificationService.clearQueueNotificationHistory(parts[0], parts[1]);
      _notificationService.clearQueuePermanentNotificationHistory(parts[0], parts[1]);
    }
  }
  
  void clearQueueNotifications(String queueCode) {
    _processedNotifications.removeWhere((key) => key.startsWith('$queueCode:'));
    
    _notificationService.clearQueuePermanentNotificationHistory('', queueCode);
  }
  
  void stopAllMonitoring() {
    for (var subscription in _activeMonitors.values) {
      subscription.cancel();
    }
    _activeMonitors.clear();
  }
}