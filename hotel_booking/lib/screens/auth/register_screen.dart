import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/auth_layout.dart';
import '../../widgets/auth_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF123A52),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D2B3E),
                Color(0xFF123A52),
                Color(0xFF1B4D6B),
              ],
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFB58A45).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFB58A45).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                size: 16,
                color: Color(0xFFB58A45),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Đăng ký TTTP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFFB58A45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: const AuthLayout(child: AuthForm(register: true)),
    );
  }
}