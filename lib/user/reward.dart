import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> redemptionHistory = [];
  int availableCoins = 0; // เริ่มต้นที่ 0 และจะโหลดจาก Firebase
  bool _isLoading = true;
  StreamSubscription<DocumentSnapshot>? _rewardStatusListener;

  @override
  void initState() {
    super.initState();
    _loadUserCoinsAndHistory();
  }

  @override
  void dispose() {
    // ถ้ามีการติดตามสถานะ ให้ยกเลิกเมื่อออกจากหน้าจอ
    _rewardStatusListener?.cancel();
    super.dispose();
  }

  // โหลด coins และประวัติการแลกรางวัลของผู้ใช้
  Future<void> _loadUserCoinsAndHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        // 1. โหลดข้อมูล coins จากเอกสารของผู้ใช้
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // ตรวจสอบว่าผู้ใช้มีฟิลด์ coins หรือไม่
          if (userData.containsKey('coins')) {
            setState(() {
              availableCoins = userData['coins'] ?? 0;
            });
          } else {
            // ถ้าไม่มีฟิลด์ coins ให้เพิ่มฟิลด์นี้พร้อมตั้งค่าเริ่มต้นเป็น 10
            await _firestore
                .collection('users')
                .doc(currentUser.uid)
                .update({'coins': 10});

            setState(() {
              availableCoins = 10;
            });
          }

          // 2. โหลดประวัติการแลกรางวัล
          QuerySnapshot historySnapshot = await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('rewardHistory')
              .orderBy('redeemedAt', descending: true)
              .get();

          List<Map<String, dynamic>> historyList = [];
          for (var doc in historySnapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            Map<String, dynamic> historyItem = {
              'title': data['title'] ?? '',
              'coins': data['coins'] ?? '',
              'rewardId': data['rewardId'] ?? '',
              'date': _formatDate(data['redeemedAt']),
              'id': doc.id, // เก็บ ID ของเอกสารไว้ด้วย
            };
            historyList.add(historyItem);
          }

          setState(() {
            redemptionHistory = historyList;
          });
        }
      }
    } catch (e) {
      print('Error loading user coins and history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading rewards data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // เพิ่มประวัติการแลกรางวัลทั้งใน state และ Firestore
  // เพิ่มประวัติการแลกรางวัลทั้งใน state และ Firestore
  Future<bool> addRedemptionHistory(
      String title, String coins, String rewardId, String date) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      int deductedCoins = int.parse(coins.replaceAll(RegExp(r'[^0-9]'), '')) *
          -1; // แปลงเป็นตัวเลข

      // ตรวจสอบอีกครั้งว่ามี coins เพียงพอ (double check)
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) return false;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      int currentCoins = userData['coins'] ?? 0;

      if (currentCoins < -deductedCoins) {
        return false; // coins ไม่เพียงพอ
      }

      // สร้างข้อมูลประวัติการแลกรางวัลก่อน
      Map<String, dynamic> historyData = {
        'title': title,
        'coins': coins,
        'rewardId': rewardId,
        'redeemedAt': Timestamp.now(),
      };

      // กำหนด timeout สำหรับ transaction เพื่อป้องกันการค้าง
      bool isCompleted = false;

      // แทนการใช้ transaction ที่อาจมีปัญหา ให้แยกเป็น 2 ขั้นตอน
      try {
        // 1. อัพเดทจำนวน coins ก่อน
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .update({'coins': FieldValue.increment(deductedCoins)});

        // 2. เพิ่มประวัติการแลกรางวัล
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('rewardHistory')
            .add(historyData);

        isCompleted = true;
      } catch (e) {
        print('Error during reward transaction: $e');
        // ถ้าเกิดข้อผิดพลาด ลองคืน coins ให้ผู้ใช้
        try {
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .update({'coins': FieldValue.increment(-deductedCoins)});
        } catch (restoreError) {
          print('Error restoring coins: $restoreError');
        }
        return false;
      }

      // ถ้า timeout หรือไม่สำเร็จ ให้ return false
      if (!isCompleted) {
        return false;
      }

      // 3. อัพเดท UI หลังจากทำรายการสำเร็จ
      if (context.mounted) {
        setState(() {
          // อัพเดท coins ในแอพ
          availableCoins += deductedCoins;

          // เพิ่มประวัติลงใน list ที่แสดงใน UI
          redemptionHistory.insert(0, {
            'title': title,
            'coins': coins,
            'rewardId': rewardId,
            'date': date,
          });
        });
      }

      return true;
    } catch (e) {
      print('Error adding redemption history: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording reward: $e')),
        );
      }
      return false;
    }
  }

  // แปลง timestamp เป็นข้อความวันที่
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      if (timestamp is Timestamp) {
        DateTime dateTime = timestamp.toDate();
        List<String> months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  // Show history dialog
  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Redemption History',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            height: 300, // เพิ่มความสูงให้มากขึ้น
            width: 300,
            child: redemptionHistory.isEmpty
                ? const Center(
                    child: Text(
                      'No redemption history yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: redemptionHistory.length,
                    itemBuilder: (context, index) {
                      var history = redemptionHistory[index];
                      return ListTile(
                        leading: const Icon(Icons.card_giftcard,
                            color: Color(0xFF8B2323)),
                        title: Text(history['title'] ?? ''),
                        subtitle: Text('Redeemed on ${history['date']}'),
                        trailing: Text(
                          history['coins'] ?? '',
                          style: const TextStyle(color: Color(0xFF8B2323)),
                        ),
                        onTap: () {
                          // Show Reward ID
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Reward ID'),
                                content:
                                    Text('Reward ID: ${history['rewardId']}'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Close'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF8B2323)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRewardSuccessDialog(BuildContext context, String finalRewardId, String rewardHistoryId, User currentUser) {
  // สร้าง ValueNotifier สำหรับติดตามสถานะ
  ValueNotifier<bool> isConfirmed = ValueNotifier<bool>(false);
  ValueNotifier<String> statusMessage = ValueNotifier<String>('Waiting for restaurant staff confirmation...');

  // ติดตั้ง listener สำหรับติดตามการเปลี่ยนแปลงสถานะ
  if (rewardHistoryId.isNotEmpty) {
    _rewardStatusListener = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('rewardHistory')
        .doc(rewardHistoryId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        // ถ้าสถานะถูกเปลี่ยนเป็น confirmed
        if (data['status'] == 'confirmed') {
          isConfirmed.value = true;
          statusMessage.value = 'Your reward has been confirmed!';

          // แสดง dialog สำเร็จหลังจากรอสักครู่
          Future.delayed(const Duration(seconds: 1), () {
            // ยกเลิกการติดตาม
            _rewardStatusListener?.cancel();

            // รีโหลดข้อมูลล่าสุด
            _loadUserCoinsAndHistory();
          });
        }
      }
    });
  }

  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (dialogContext) {
      return ValueListenableBuilder<bool>(
        valueListenable: isConfirmed,
        builder: (context, confirmed, child) {
          return ValueListenableBuilder<String>(
            valueListenable: statusMessage,
            builder: (context, message, child) {
              return AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Reward Redeemed'),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        // ยกเลิกการติดตาม
                        _rewardStatusListener?.cancel();
                        Navigator.of(dialogContext).pop();
                        _loadUserCoinsAndHistory(); // รีเฟรชข้อมูล
                      },
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    confirmed
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 40)
                        : const CircularProgressIndicator(color: Color(0xFF8B2323)),
                    const SizedBox(height: 20),
                    confirmed ? const Text('Reward confirmed!') : const Text('Processing your request...'),
                    const SizedBox(height: 10),
                    Text(
                      'Your Reward ID: $finalRewardId',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    const Text('Please keep this ID for reference.'),
                    const SizedBox(height: 15),
                    Text(
                      message,
                      style: TextStyle(color: confirmed ? Colors.green : Colors.orange),
                    ),
                  ],
                ),
                actions: confirmed
                    ? [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _loadUserCoinsAndHistory(); // รีเฟรชข้อมูล
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B2323),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Close', style: TextStyle(color: Colors.white)),
                        ),
                      ]
                    : null,
              );
            },
          );
        },
      );
    },
  );
}

  // Show reward popup
  void _showRewardPopup(BuildContext context, String title, String coins,
      {String? imagePath,
      IconData? icon,
      String? customIcon,
      required String rewardId}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display reward image/icon
                if (imagePath != null && imagePath.isNotEmpty)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage(imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                else if (icon != null)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black12,
                    ),
                    child: Center(
                      child: Icon(icon, size: 60, color: Colors.black),
                    ),
                  )
                else if (customIcon != null)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black12,
                    ),
                    child: Center(
                      child: Text(
                        customIcon,
                        style: const TextStyle(
                            fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Divider(height: 20, color: Colors.black26),
                const Text(
                  'Do you want to get this reward ?',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  coins,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF8B2323)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Not yet',
                        style:
                            TextStyle(fontSize: 16, color: Color(0xFF8B2323)),
                      ),
                    ),
                    ElevatedButton(
  onPressed: () async {
    int rewardCoins = int.parse(coins.split(' ')[0]);
    if (availableCoins >= rewardCoins) {
      // แสดง loading dialog ทันทีเพื่อป้องกันการกดหลายครั้ง
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF8B2323)),
              SizedBox(height: 16),
              Text("กำลังดำเนินการ กรุณารอสักครู่...")
            ],
          ),
        ),
      );

      try {
        // เก็บตัวแปรที่จำเป็น
        String currentDate = _getCurrentDate();
        String finalRewardId = generateRandomRewardId(rewardId);
        User? currentUser = _auth.currentUser;
        
        if (currentUser == null) {
          // ปิด loading dialog
          Navigator.of(context).pop();
          // แจ้งเตือนว่าไม่มีการล็อกอิน
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('กรุณาล็อกอินก่อนแลกรางวัล')),
          );
          return;
        }

        // ใช้ transaction เพื่อให้แน่ใจว่าทั้งการหักเหรียญและการสร้างรายการแลกของทำงานพร้อมกัน
        bool success = await FirebaseFirestore.instance.runTransaction<bool>(
          (transaction) async {
            // 1. ตรวจสอบเหรียญอีกครั้ง
            DocumentSnapshot userDoc = await transaction.get(
              _firestore.collection('users').doc(currentUser.uid)
            );
            
            if (!userDoc.exists) {
              return false;
            }
            
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            int currentCoins = userData['coins'] ?? 0;
            
            if (currentCoins < rewardCoins) {
              return false; // เหรียญไม่พอ
            }
            
            // 2. สร้างข้อมูลประวัติการแลกรางวัล
            DocumentReference historyRef = _firestore
                .collection('users')
                .doc(currentUser.uid)
                .collection('rewardHistory')
                .doc(); // สร้าง ID ใหม่อัตโนมัติ
            
            // 3. อัปเดตข้อมูลในฐานข้อมูล (ทั้งการหักเหรียญและสร้างประวัติ)
            transaction.update(
              _firestore.collection('users').doc(currentUser.uid),
              {'coins': currentCoins - rewardCoins}
            );
            
            transaction.set(historyRef, {
              'title': title,
              'coins': '-$rewardCoins coins',
              'rewardId': finalRewardId,
              'redeemedAt': Timestamp.now(),
              'status': 'pending',
              'confirmedAt': null,
              'confirmedBy': null
            });
            
            return true;
          },
          // เพิ่ม timeout ที่นานขึ้นเพื่อรองรับการเชื่อมต่อที่อาจช้า
          timeout: const Duration(seconds: 10),
        ).catchError((error) {
          print('Transaction failed: $error');
          return false;
        });

        // ปิด dialog ทั้งหมด (ทั้ง loading dialog และ confirm dialog)
        Navigator.of(context).pop(); // ปิด loading dialog
        Navigator.of(context).pop(); // ปิด confirm dialog

        if (success) {
          // อัปเดต UI แสดงคะแนนที่ลดลง
          setState(() {
            availableCoins -= rewardCoins;
          });

          // แสดงข้อมูลการแลกสำเร็จ
          if (context.mounted) {
            // ค้นหา rewardHistoryId จาก Firestore
            QuerySnapshot historyQuery = await _firestore
                .collection('users')
                .doc(currentUser.uid)
                .collection('rewardHistory')
                .where('rewardId', isEqualTo: finalRewardId)
                .limit(1)
                .get();
            
            String rewardHistoryId = '';
            if (historyQuery.docs.isNotEmpty) {
              rewardHistoryId = historyQuery.docs.first.id;
            }

            _showRewardSuccessDialog(context, finalRewardId, rewardHistoryId, currentUser);
          }
        } else {
          // กรณีไม่สำเร็จ
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ไม่สามารถแลกรางวัลได้ กรุณาลองใหม่อีกครั้ง')),
            );
          }
        }
      } catch (e) {
        // ปิด loading dialog ในกรณีเกิดข้อผิดพลาด
        Navigator.of(context).pop();
        
        print('Error redeeming reward: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    } else {
      // Coins ไม่เพียงพอ
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Insufficient Coins'),
            content: const Text('You do not have enough coins to redeem this reward.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF8B2323),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  child: const Text(
    'Confirm',
    style: TextStyle(fontSize: 16, color: Colors.white),
  ),
),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // สร้างข้อความวันที่ปัจจุบัน
  String _getCurrentDate() {
    DateTime now = DateTime.now();
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B2323),
        title: const Text(
          'Reward',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.history, color: Colors.white, size: 30),
          onPressed: _showHistoryDialog,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    '$availableCoins',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('coins'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B2323)),
            )
          : RefreshIndicator(
              onRefresh: _loadUserCoinsAndHistory, // เพิ่ม refresh pull-down
              color: const Color(0xFF8B2323),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          RewardCard(
                            assetIcon: 'assets/images/discount.png',
                            title: 'Discount 30%',
                            coins: '150 coins',
                            rewardId: 'RP001',
                            useAsset: true,
                            onRedemption: (String newRewardId) async {},
                            showRewardPopup: _showRewardPopup,
                          ),
                          RewardCard(
                            assetIcon: 'assets/images/dessert.png',
                            title: 'Free Dessert/Drinks',
                            coins: '25 coins',
                            rewardId: 'RP002',
                            useAsset: true,
                            onRedemption: (String newRewardId) async {},
                            showRewardPopup: _showRewardPopup,
                          ),
                          RewardCard(
                            assetIcon: 'assets/images/discount.png',
                            title: 'Discount 10%',
                            coins: '50 coins',
                            rewardId: 'RP003',
                            useAsset: true,
                            onRedemption: (String newRewardId) async {},
                            showRewardPopup: _showRewardPopup,
                          ),
                          RewardCard(
                            assetIcon: 'assets/images/buy1free1.jpg',
                            title: 'Buy 1 Free 1',
                            coins: '80 coins',
                            rewardId: 'RP004',
                            useAsset: true,
                            onRedemption: (String newRewardId) async {},
                            showRewardPopup: _showRewardPopup,
                          ),
                          RewardCard(
                            assetIcon: 'assets/images/signature.png',
                            title: 'Free Signature Menu',
                            coins: '60 coins',
                            rewardId: 'RP005',
                            useAsset: true,
                            onRedemption: (String newRewardId) async {},
                            showRewardPopup: _showRewardPopup,
                          ),
                          RewardCard(
                            assetIcon: 'assets/images/friend.png',
                            title: 'Friend with Meal',
                            coins: '100 coins',
                            rewardId: 'RP006',
                            useAsset: true,
                            onRedemption: (String newRewardId) async {},
                            showRewardPopup: _showRewardPopup,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // แสดงข้อความบรรทัดล่างเพื่อบอกว่าสามารถดึงลงเพื่อรีเฟรชได้
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Pull down to refresh coins and history",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class RewardCard extends StatelessWidget {
  final IconData? icon;
  final String? assetIcon;
  final String? customIcon;
  final String title;
  final String coins;
  final String rewardId;
  final bool useAsset;
  final bool useCustomIcon;
  final Function(String) onRedemption; // Callback for redemption
  final Function(BuildContext, String, String,
      {String? imagePath,
      IconData? icon,
      String? customIcon,
      required String rewardId}) showRewardPopup;

  const RewardCard({
    super.key,
    this.icon,
    this.assetIcon,
    this.customIcon,
    required this.title,
    required this.coins,
    required this.rewardId,
    this.useAsset = false,
    this.useCustomIcon = false,
    required this.onRedemption, // callback to add redemption to history
    required this.showRewardPopup, // callback to show reward popup
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        String newRewardId = generateRandomRewardId(rewardId);
        // ไม่เรียก onRedemption ที่นี่อีกต่อไป
        // แต่จะเรียกใน showRewardPopup เมื่อผู้ใช้ยืนยันเท่านั้น
        showRewardPopup(
          context,
          title,
          coins,
          rewardId: newRewardId,
          imagePath: assetIcon,
          icon: icon,
          customIcon: customIcon,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFF8B2323),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (assetIcon != null && assetIcon!.isNotEmpty)
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(assetIcon!),
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else if (icon != null)
              Icon(icon, size: 84, color: Colors.black)
            else if (customIcon != null)
              Text(
                customIcon!,
                style: const TextStyle(fontSize: 48, color: Colors.black),
              ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              coins,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String generateRandomRewardId(String baseRewardId) {
  final random = Random();
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  String randomString = String.fromCharCodes(Iterable.generate(
      4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  return '$baseRewardId-$randomString';
}
