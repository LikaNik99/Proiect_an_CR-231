import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 900),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/logo.png', height: 54),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'welcome_back'.tr,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'signin_to_continue'.tr,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

