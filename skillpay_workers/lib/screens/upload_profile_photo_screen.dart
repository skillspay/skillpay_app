import 'package:flutter/material.dart';
import 'create_proposal_screen.dart';

class UploadProfilePhotoScreen extends StatefulWidget {
  const UploadProfilePhotoScreen({super.key});

  @override
  State<UploadProfilePhotoScreen> createState() => _UploadProfilePhotoScreenState();
}

class _UploadProfilePhotoScreenState extends State<UploadProfilePhotoScreen> {
  bool _isPhotoUploaded = false; // Mocking photo upload state

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
          'Upload Profile Photo',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              
              // Upload Area
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPhotoUploaded = true;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                       Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          image: _isPhotoUploaded ? const DecorationImage(
                            // Using a network mock photo to show the generic uploaded state like in design
                            image: NetworkImage('https://i.pravatar.cc/150?u=a04258114e29026702d'), 
                            fit: BoxFit.cover,
                          ) : null,
                        ),
                        child: !_isPhotoUploaded ? const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 40,
                        ) : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isPhotoUploaded ? 'Photo uploaded' : 'Click to upload',
                        style: TextStyle(
                          color: _isPhotoUploaded ? Colors.green : Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isPhotoUploaded ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateProposalScreen()),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPhotoUploaded 
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
                    'Continue',
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
