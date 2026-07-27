import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/wallet_service.dart';

class PaymentDetailsScreen extends StatefulWidget {
  const PaymentDetailsScreen({super.key});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final _walletService = WalletService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _bankAccounts = [];

  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  bool _isAdding = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchBankAccounts();
  }

  Future<void> _fetchBankAccounts() async {
    setState(() => _isLoading = true);
    try {
      final accounts = await _walletService.fetchBankAccounts();
      if (mounted) {
        setState(() {
          _bankAccounts = accounts;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bank accounts: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addBankAccount() async {
    if (_bankNameController.text.isEmpty || 
        _accountNameController.text.isEmpty || 
        _accountNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final success = await _walletService.addBankAccount({
        'bankName': _bankNameController.text,
        'accountName': _accountNameController.text,
        'accountNumber': _accountNumberController.text,
      });

      if (success) {
        _bankNameController.clear();
        _accountNameController.clear();
        _accountNumberController.clear();
        if (mounted) setState(() => _isAdding = false);
        _fetchBankAccounts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank account added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add bank account')),
        );
      }
    } catch (e) {
      debugPrint('Error adding bank account: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Payment Details'),
        elevation: 0,
        actions: [
          if (!_isAdding)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => _isAdding = true),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isAdding
              ? _buildAddForm()
              : _buildList(),
    );
  }

  Widget _buildList() {
    if (_bankAccounts.isEmpty) {
      return const Center(
        child: Text(
          'No payment details added yet.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bankAccounts.length,
      itemBuilder: (context, index) {
        final acc = _bankAccounts[index];
        return Card(
          color: const Color(0xFF2C2C2E),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.account_balance, color: Colors.white),
            title: Text(acc['bankName'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('${acc['accountNumber']} • ${acc['accountName']}', style: const TextStyle(color: Colors.white70)),
            trailing: acc['isDefault'] == true
                ? const Icon(Icons.check_circle, color: Color(0xFF5F1ED9))
                : null,
          ),
        );
      },
    );
  }

  Widget _buildAddForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Add New Bank Account',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildTextField('Bank Name', _bankNameController),
          const SizedBox(height: 16),
          _buildTextField('Account Name', _accountNameController),
          const SizedBox(height: 16),
          _buildTextField('Account Number', _accountNumberController, isNumber: true),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _submitting ? null : _addBankAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F1ED9),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                : const Text('Save Bank Account'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _isAdding = false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
