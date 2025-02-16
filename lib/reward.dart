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
          // Rewards Grid
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
                    icon: Icons.low_priority_sharp,
                    title: 'Queue Pass',
                    coins: '500 coins',
                  ),
                  RewardCard(
                    assetIcon: 'assets/images/starbucks.png',
                    title: 'Gift Voucher',
                    coins: '150 coins',
                    useAsset: true,
                  ),
                  RewardCard(
                    customIcon: '%',
                    title: 'Discount 20%',
                    coins: '300 coins',
                    useCustomIcon: true,
                  ),
                  RewardCard(
                    customIcon: '%',
                    title: 'Discount 10%',
                    coins: '200 coins',
                    useCustomIcon: true,
                  ),
                ],
              ),
            ),
          ),
        ],));
  }

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
    return Container(
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
          if (!useAsset && !useCustomIcon && icon != null)
            Icon(icon, size: 84)
          else if (useAsset && assetIcon != null)
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(assetIcon!),
                  fit: BoxFit.contain,
                ),
              ),
            )
          else if (useCustomIcon && customIcon != null)
            Text(
              customIcon!,
              style: const TextStyle(fontSize: 48),
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
    );
  }
}