import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'features/auth/presentation/pages/login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.blue,
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );

    return SafeArea(
      bottom: true,
      top: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade300],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: size.height * 0.25,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Column(
                    children: [
                      Text(
                        'welcome'.tr,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'subtitle'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => LoginPage());
                      },
                      style: buttonStyle,
                      child: Text(
                        'login'.tr,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
