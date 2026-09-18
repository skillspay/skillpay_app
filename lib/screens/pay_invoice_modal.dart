import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillpay/theme/app_theme.dart';
// import 'package:skillpay/screens/main_navigation_screen.dart'; // Navigation back to history

void showPayInvoiceModal(
  BuildContext context, {
  required double jobAmount,
  required VoidCallback onPaymentSuccess,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PayInvoiceModal(
      jobAmount: jobAmount,
      onPaymentSuccess: onPaymentSuccess,
    ),
  );
}

class _PayInvoiceModal extends StatefulWidget {
  final double jobAmount;
  final VoidCallback onPaymentSuccess;

  const _PayInvoiceModal({
    required this.jobAmount,
    required this.onPaymentSuccess,
  });

  @override
  State<_PayInvoiceModal> createState() => _PayInvoiceModalState();
}

class _PayInvoiceModalState extends State<_PayInvoiceModal> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final fullAmount = widget.jobAmount;
    _amountController.text = fullAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onMakePayment() {
    Navigator.pop(context); // Close this modal
    showPaymentMethodModal(
      context,
      _amountController.text.isEmpty ? '0.00' : _amountController.text,
      widget.onPaymentSuccess,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32, // Adjusts for keyboard
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pay Invoice',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textMedium),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'To start a job you are required to pay 100% of the job budget as an upfront payment (held in escrow).',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Text(
                'Job Amount: ',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '\$${widget.jobAmount.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4CAF50), // Green amount
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Amount to pay (Full Budget)',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          
          const SizedBox(height: 8),
          
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'e.g. ${(widget.jobAmount).toStringAsFixed(2)}',
              prefixIcon: const Icon(Icons.attach_money, color: AppColors.textDark, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onMakePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Make payment',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PAYMENT METHOD MODAL
// -----------------------------------------------------------------------------

void showPaymentMethodModal(BuildContext context, String amountStr, VoidCallback onPaymentSuccess) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PaymentMethodModal(
      amount: amountStr,
      onPaymentSuccess: onPaymentSuccess,
    ),
  );
}

class _PaymentMethodModal extends StatefulWidget {
  final String amount;
  final VoidCallback onPaymentSuccess;

  const _PaymentMethodModal({
    required this.amount,
    required this.onPaymentSuccess,
  });

  @override
  State<_PaymentMethodModal> createState() => _PaymentMethodModalState();
}

class _PaymentMethodModalState extends State<_PaymentMethodModal> {
  String _selectedMethod = 'stripe';

  void _onPay() {
    widget.onPaymentSuccess(); // Call backend hire action here
    Navigator.pop(context); // Close this modal
    showPaymentSuccessModal(context, widget.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Payment Method',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          GestureDetector(
            onTap: () => setState(() => _selectedMethod = 'stripe'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedMethod == 'stripe' ? AppColors.primary : const Color(0xFFE0E0E0),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _selectedMethod == 'stripe' ? AppColors.primary.withAlpha(20) : Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.credit_card, color: Color(0xFF0066FF), size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Pay with Stripe (Card)',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (_selectedMethod == 'stripe')
                    const Icon(Icons.check_circle, color: AppColors.primary),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: () => setState(() => _selectedMethod = 'paypal'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedMethod == 'paypal' ? AppColors.primary : const Color(0xFFE0E0E0),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _selectedMethod == 'paypal' ? AppColors.primary.withAlpha(20) : Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.paypal, color: Color(0xFF003087), size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Pay with PayPal',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (_selectedMethod == 'paypal')
                    const Icon(Icons.check_circle, color: AppColors.primary),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            onPressed: _onPay,
            icon: const Icon(Icons.lock_outline, size: 18),
            label: Text(
              'Pay \$${widget.amount}',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedMethod == 'stripe' ? const Color(0xFF0066FF) : const Color(0xFF003087),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PAYMENT SUCCESS MODAL
// -----------------------------------------------------------------------------

void showPaymentSuccessModal(BuildContext context, String amount) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PaymentSuccessModal(amount: amount),
  );
}

class _PaymentSuccessModal extends StatelessWidget {
  final String amount;
  const _PaymentSuccessModal({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: AppColors.textMedium),
            ),
          ),
          
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Payment Success',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Payment of \$$amount has been\nmade successfully.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // In a real app we'd pop until HistoryScreen, for now just close
                Navigator.pop(context); // Close Success Modal
                Navigator.pop(context); // Close Proposal Details Screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'View job details',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
