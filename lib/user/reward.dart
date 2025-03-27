import 'dart:math';
import 'package:flutter/material.dart';

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  List<Map<String, String>> redemptionHistory = [];
  int availableCoins = 1000;  // จำนวนเหรียญที่ผู้ใช้มี

  // Add a new redemption record to history
  void addRedemptionHistory(String title, String coins, String rewardId, String date) {
    setState(() {
      redemptionHistory.add({
        'title': title,
        'coins': coins,
        'rewardId': rewardId,
        'date': date,
      });
    });
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
            height: 200,
            width: 300,
            child: ListView.builder(
              itemCount: redemptionHistory.length,
              itemBuilder: (context, index) {
                var history = redemptionHistory[index];
                return ListTile(
                  leading: Icon(Icons.card_giftcard, color: Colors.brown),
                  title: Text(history['title']!),
                  subtitle: Text('Redeemed on ${history['date']}'),
                  trailing: Text(
                    '${history['coins']}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    // Show Reward ID
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Reward ID'),
                          content: Text('Reward ID: ${history['rewardId']}'),
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

  // Show reward popup
  void _showRewardPopup(BuildContext context, String title, String coins,
      {String? imagePath, IconData? icon, String? customIcon, required String rewardId}) {
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
                        style: TextStyle(fontSize: 16, color: Color(0xFF8B2323)),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        int rewardCoins = int.parse(coins.split(' ')[0]);
                        if (availableCoins >= rewardCoins) {
                          // After confirming, show Reward ID
                          setState(() {
                            availableCoins -= rewardCoins;
                          });

                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Reward Confirmed'),
                                content: Text('Your Reward ID: $rewardId'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop(); // Close both dialogs
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          // Not enough coins
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
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
      body: Column(
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
                    assetIcon: 'assets/images/queue-pass.png',
                    title: 'Queue Pass',
                    coins: '500 coins',
                    rewardId: 'RP001',
                    useAsset: true,
                    onRedemption: (String newRewardId) {
                      addRedemptionHistory('Queue Pass', '-500 coins', newRewardId, 'Mar 5, 2025');
                    },
                    showRewardPopup: _showRewardPopup,
                  ),
                  RewardCard(
                    assetIcon: 'assets/images/starbucks.png',
                    title: 'Gift Voucher',
                    coins: '150 coins',
                    rewardId: 'RP002',
                    useAsset: true,
                    onRedemption: (String newRewardId) {
                      addRedemptionHistory('Gift Voucher', '-150 coins', newRewardId, 'Feb 28, 2025');
                    },
                    showRewardPopup: _showRewardPopup,
                  ),
                  RewardCard(
                    assetIcon: 'assets/images/discount.png',
                    title: 'Discount 20%',
                    coins: '300 coins',
                    rewardId: 'RP003',
                    useAsset: true,
                    onRedemption: (String newRewardId) {
                      addRedemptionHistory('Discount 20%', '-300 coins', newRewardId, 'Feb 28, 2025');
                    },
                    showRewardPopup: _showRewardPopup,
                  ),
                  RewardCard(
                    assetIcon: 'assets/images/discount.png',
                    title: 'Discount 10%',
                    coins: '200 coins',
                    rewardId: 'RP004',
                    useAsset: true,
                    onRedemption: (String newRewardId) {
                      addRedemptionHistory('Discount 10%', '-200 coins', newRewardId, 'Feb 28, 2025');
                    },
                    showRewardPopup: _showRewardPopup,
                  ),
                ],
              ),
            ),
          ),
        ],
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
  final Function(BuildContext, String, String, {String? imagePath, IconData? icon, String? customIcon, required String rewardId}) showRewardPopup;

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
        onRedemption(newRewardId); // Add reward to history after confirmation
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
      6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  return '$baseRewardId-$randomString';
}