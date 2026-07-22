import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'onboarding_step1_screen.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? userNameOverrides;
  
  const OnboardingWelcomeScreen({
    super.key, 
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.userNameOverrides,
  });

  @override
  Widget build(BuildContext context) {
    // Attempt to get user's first name from Supabase Auth metadata
    final user = Supabase.instance.client.auth.currentUser;
    final String displayName = userNameOverrides ?? firstName ?? user?.userMetadata?['first_name'] ?? 'There';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Main Icon / Image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_pin,
                  size: 60,
                  color: Color(0xFFFFC107),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Hi $displayName, Ready for your first job opportunity?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 48),
              
              // List features
              _buildFeatureItem(
                icon: Icons.check_circle,
                iconColor: Colors.green,
                text: 'Get verified on Skillpay.',
              ),
              const SizedBox(height: 24),
              _buildFeatureItem(
                icon: Icons.check_circle_outline,
                iconColor: Colors.grey,
                text: 'Complete your profile today.',
              ),
              const SizedBox(height: 24),
              _buildFeatureItem(
                icon: Icons.check_circle_outline,
                iconColor: Colors.grey,
                text: 'Add your services & set your availability.',
              ),
              const SizedBox(height: 24),
              _buildFeatureItem(
                icon: Icons.check_circle_outline,
                iconColor: Colors.grey,
                text: 'And start receiving calls for your service.',
              ),
              
              const Spacer(),
              
              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => OnboardingStep1Screen(
                        email: email,
                        firstName: firstName,
                        lastName: lastName,
                        phone: phone,
                      )),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Get started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
