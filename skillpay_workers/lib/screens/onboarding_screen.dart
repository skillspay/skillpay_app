import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../widgets/policy_viewer_modal.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _navigateToAuth(String title) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;

    if (title.contains('Login')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else if (title.contains('Create')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SignupScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AuthScreen(title: title)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage(
                    titleWidget: Image.asset(
                      'assets/images/logo.png',
                      height: 48,
                      alignment: Alignment.centerLeft,
                    ),
                    subtitle: 'Find the best and professional artisans for your job.',
                    imagePath: 'assets/images/onboarding_1.png',
                  ),
                  _buildPage(
                    title: 'Work Smarter.\nEarn Better.',
                    subtitle: 'Connecting clients in need to skilled artisans who deliver.',
                    imagePath: 'assets/images/onboarding_2.png',
                  ),
                ],
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    String? title,
    Widget? titleWidget,
    required String subtitle,
    required String imagePath,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          if (titleWidget != null)
            titleWidget
          else if (title != null)
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 4,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.black : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Terms & Disclaimers Agreement Checkbox
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreedToTerms,
                    activeColor: const Color(0xFFFFC107),
                    checkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                    onChanged: (val) {
                      setState(() {
                        _agreedToTerms = val ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'I confirm that I have read and agree to the ',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF666666),
                          height: 1.4,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => PolicyViewerModal.show(context, initialType: PolicyType.terms),
                        child: const Text(
                          'Artisan Terms of Use',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(
                        ', ',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF666666),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => PolicyViewerModal.show(context, initialType: PolicyType.privacy),
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(
                        ', & ',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF666666),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => PolicyViewerModal.show(context, initialType: PolicyType.disclaimers),
                        child: const Text(
                          'Platform Disclaimers',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(
                        '.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (!_agreedToTerms) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Please accept the Artisan Terms and Policies to continue.',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: const Color(0xFFD32F2F),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                _navigateToAuth('Create Account');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107), // Yellow
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _navigateToAuth('Login as Artisan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5F5F5), // Light Grey
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Login as an Artisan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),

        ],
      ),
    );
  }
}
