import 'package:flutter/material.dart';

class RestaurantCard extends StatelessWidget {
  final String name;
  final String location;
  final String image;

  RestaurantCard({required this.name, required this.location, required this.image});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Color(0xFF8B2323)),
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(image, width: 60, height: 60, fit: BoxFit.cover),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(location, style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
