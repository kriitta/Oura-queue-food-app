import 'package:flutter/material.dart';

class RewardPage extends StatelessWidget {
  const RewardPage({super.key});

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
            color: Colors.white
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Text(
                    '1',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text('coins'),
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
                children: const [
                  RewardCard(
                    assetIcon: 'assets/images/queue-pass.png',
                    title: 'Queue Pass',
                    coins: '500 coins',
                    useAsset: true,
                  ),
                  RewardCard(
                    assetIcon: 'assets/images/starbucks.png',
                    title: 'Gift Voucher',
                    coins: '150 coins',
                    useAsset: true,
                  ),
                  RewardCard(
                    assetIcon: 'assets/images/discount.png',
                    title: 'Discount 20%',
                    coins: '300 coins',
                    useAsset: true,
                  ),
                  RewardCard(
                    assetIcon: 'assets/images/discount.png',
                    title: 'Discount 10%',
                    coins: '200 coins',
                    useAsset: true,
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

void _showRewardPopup(BuildContext context, String title, String coins, {String? imagePath, IconData? icon, String? customIcon}) {
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
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ชื่อ Reward
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // เส้นคั่น
              const Divider(height: 20, color: Colors.black26),

              // คำถามยืนยันการรับ Reward
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                      // TODO: ใส่ฟังก์ชันการยืนยันการแลกรางวัล
                      Navigator.of(context).pop();
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


class RewardCard extends StatelessWidget {
  final IconData? icon;
  final String? assetIcon;
  final String? customIcon;
  final String title;
  final String coins;
  final bool useAsset;
  final bool useCustomIcon;

  const RewardCard({
    super.key,
    this.icon,
    this.assetIcon,
    this.customIcon,
    required this.title,
    required this.coins,
    this.useAsset = false,
    this.useCustomIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showRewardPopup(
          context,
          title,
          coins,
          imagePath: assetIcon,  // ✅ ส่ง assetIcon เสมอ
          icon: icon,
          customIcon: customIcon,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF8B2323),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (assetIcon != null && assetIcon!.isNotEmpty)  // ✅ ใช้ assetIcon เสมอถ้ามี
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
            else if (icon != null)  // ✅ ถ้าไม่มี assetIcon ให้แสดง Icon แทน
              Icon(icon, size: 84, color: Colors.black)
            else if (customIcon != null)  // ✅ ถ้าไม่มี Icon ก็ใช้ Custom Text
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

