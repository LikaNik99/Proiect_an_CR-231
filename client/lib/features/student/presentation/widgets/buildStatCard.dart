import 'package:flutter/material.dart';

Widget buildStatCard({
  required IconData icon,
  required String title,
  required String value,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.03)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
