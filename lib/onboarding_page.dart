import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Center(
                child: Image.asset(
                  'assets/images/onboarding.png', 
                  width: double.infinity,
                  height: 380, 
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Connecting Communities Together',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 30,
                  height: 1.5, // 24 * 1.5 = 36 line height
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'Stay informed, vote, report issues, and engage with the government — all in one place.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  height: 1.5, // 16 * 1.5 = 24 line height
                  color:Color(0xFF4E4B66)
,
                ),
              ),
              const Spacer(),

              // Get Started button aligned right and text-fit width
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600, 
                        fontSize: 14,
                        color: Colors.white,
                      ),
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
}
