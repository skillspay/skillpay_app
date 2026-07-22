import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class CreateProposalScreen extends StatefulWidget {
  const CreateProposalScreen({super.key});

  @override
  State<CreateProposalScreen> createState() => _CreateProposalScreenState();
}

class _CreateProposalScreenState extends State<CreateProposalScreen> {
  final TextEditingController _coverLetterController = TextEditingController();
  bool _isWorkPhotoUploaded = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _coverLetterController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  void _validateForm() {
    bool isValid = _coverLetterController.text.isNotEmpty && _isWorkPhotoUploaded;
        
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Proposal',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cover letter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _coverLetterController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintText: 'Enter your cover letter',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Upload work photo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              // Upload Area
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isWorkPhotoUploaded = true;
                    _validateForm();
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.grey[50], // light grey area
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isWorkPhotoUploaded ? Icons.check_circle : Icons.backup_outlined,
                        color: _isWorkPhotoUploaded ? Colors.green : Colors.grey,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isWorkPhotoUploaded ? 'Work photo uploaded' : 'Click to upload',
                        style: TextStyle(
                          color: _isWorkPhotoUploaded ? Colors.green : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isFormValid ? () {
                    // Navigate to Dashboard, clearing the stack
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                      (route) => false,
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid 
                        ? const Color(0xFFFFC107) 
                        : const Color(0xFFFDE69F),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFFFDE69F),
                    disabledForegroundColor: Colors.black54,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
