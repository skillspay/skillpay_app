import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum PolicyType { terms, privacy, disclaimers }

class PolicyViewerModal extends StatefulWidget {
  final PolicyType initialType;

  const PolicyViewerModal({super.key, this.initialType = PolicyType.terms});

  static Future<void> show(BuildContext context, {PolicyType initialType = PolicyType.terms}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PolicyViewerModal(initialType: initialType),
    );
  }

  @override
  State<PolicyViewerModal> createState() => _PolicyViewerModalState();
}

class _PolicyViewerModalState extends State<PolicyViewerModal> {
  late PolicyType _selectedType;

  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMedium = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Artisan Policies & Legal',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: textDark),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          // Policy Type Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTab('Artisan Terms', PolicyType.terms),
                  _buildTab('Privacy', PolicyType.privacy),
                  _buildTab('Disclaimers', PolicyType.disclaimers),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Policy Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: _buildContent(),
            ),
          ),

          // Bottom Bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'I Understand & Accept',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, PolicyType type) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? textDark : textMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedType) {
      case PolicyType.terms:
        return _buildTermsContent();
      case PolicyType.privacy:
        return _buildPrivacyContent();
      case PolicyType.disclaimers:
        return _buildDisclaimersContent();
    }
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              height: 1.55,
              color: textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Artisan & Worker Terms of Service',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Last updated: September 2026',
          style: GoogleFonts.outfit(fontSize: 12, color: textLight),
        ),
        const SizedBox(height: 16),
        _buildSection(
          '1. Independent Contractor Relationship',
          'You acknowledge and agree that your relationship with SkillPay is solely that of an independent contractor and freelance service provider. Nothing in these Terms creates an employment, agency, franchise, or joint venture relationship.',
        ),
        _buildSection(
          '2. Qualification & Verification',
          'You represent that all information, business registrations, licenses, and trade credentials provided during onboarding and verification are true, accurate, and kept current at all times.',
        ),
        _buildSection(
          '3. Escrow Payments & Payouts',
          'Customer payments are deposited into SkillPay secure escrow upon project booking. Funds are disbursed to your linked bank account or payout method upon completion verification or dispute resolution, minus agreed platform service fees.',
        ),
        _buildSection(
          '4. Quality of Work & Customer Satisfaction',
          'You agree to perform all contracted services in a workmanlike, professional, and timely manner. Willful neglect, substandard delivery, or unexcused abandonment may result in forfeiture of escrowed fees and account deactivation.',
        ),
        _buildSection(
          '5. Taxes & Statutory Compliance',
          'As an independent contractor, you are exclusively responsible for assessing, withholding, and remitting all applicable federal, state, and local taxes, levies, and contributions on earnings received through SkillPay.',
        ),
      ],
    );
  }

  Widget _buildPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Artisan Privacy & Data Policy',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Last updated: September 2026',
          style: GoogleFonts.outfit(fontSize: 12, color: textLight),
        ),
        const SizedBox(height: 16),
        _buildSection(
          '1. Identity & Credentials Data',
          'To maintain trust and safety on the platform, we collect government ID documents, face photos, biometric verification tokens, proof of address, and professional certifications. These are stored encrypted and used strictly for identity authentication and fraud prevention.',
        ),
        _buildSection(
          '2. Location & Job Dispatching',
          'We collect device geolocation data while the app is active to calculate distance to clients, display available local job proposals, and enable on-site navigation.',
        ),
        _buildSection(
          '3. Public Profile Information',
          'Your trade name, profile photo, verified skills, customer reviews, ratings, and completed job statistics are visible publicly to prospective customers on SkillPay.',
        ),
        _buildSection(
          '4. Bank & Payout Information',
          'Bank routing and account numbers are collected and processed via certified PCI-DSS compliant financial partners for automated earnings disbursements.',
        ),
      ],
    );
  }

  Widget _buildDisclaimersContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escrow & Service Disclaimers',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Last updated: September 2026',
          style: GoogleFonts.outfit(fontSize: 12, color: textLight),
        ),
        const SizedBox(height: 16),
        _buildSection(
          '1. Marketplace Intermediary Notice',
          'SkillPay functions as a technology facilitator and escrow platform. SkillPay does not guarantee minimum income, consistent job volume, or client demeanor.',
        ),
        _buildSection(
          '2. Tooling, Safety & Insurance',
          'Artisans are solely responsible for furnishing their own tools, safety equipment, personal protective wear, and liability insurance suitable for their trade.',
        ),
        _buildSection(
          '3. Dispute Mediation',
          'In case of conflicting claims regarding job completion or quality, SkillPay reserves the right to review photo evidence, chat history, and inspection reports before issuing final escrow determinations.',
        ),
      ],
    );
  }
}

/// Bottom Terms & Privacy footer for worker auth screens with clickable popups.
Widget buildWorkerAuthFooter(BuildContext context) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text(
        'By logging in, you agree to SkillPay',
        style: TextStyle(color: Colors.grey, fontSize: 12),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => PolicyViewerModal.show(context, initialType: PolicyType.terms),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                'Terms of Service',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const Text(
            ' and ',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          GestureDetector(
            onTap: () => PolicyViewerModal.show(context, initialType: PolicyType.privacy),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                'Privacy Policy.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

