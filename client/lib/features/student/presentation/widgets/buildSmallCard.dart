import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget buildSmallCard(BuildContext context, Map<String, dynamic> card) {
  return Material(
    elevation: 6,
    borderRadius: BorderRadius.circular(16),
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (card["page"] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => card["page"]),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.02),
              Colors.white.withOpacity(0.01),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (card["color"] as Color).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(card["icon"], color: card["color"], size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (card["titleKey"] as String).tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'tap_to_open'.tr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
