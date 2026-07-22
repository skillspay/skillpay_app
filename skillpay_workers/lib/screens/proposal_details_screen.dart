import 'package:flutter/material.dart';

// This screen looks identical to SubmitProposalScreen,
// but read-only with no active "Edit" or "Submit" buttons as per standard flow design at the end.
class ProposalDetailsScreen extends StatelessWidget {
  const ProposalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          // Pop until dashboard to prevent infinite stack
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: const Text(
          'Proposal Details',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Info
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage('https://i.pravatar.cc/150?u=a04258114e29026702d'), // Mock image
                        fit: BoxFit.cover,
                      ),
                    ),
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'James Walters P',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'CA, California',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTag('Engineering'),
                          const SizedBox(width: 8),
                          _buildTag('Plumbing'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 24),
              
              // Specs
              _buildSpecRow('Experience', '8 years +'),
              const SizedBox(height: 12),
              _buildSpecRow('Based in', 'California CA'),
              const SizedBox(height: 12),
              _buildSpecRow('Work preference', 'Short & Long term'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Starting rate', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const Text('\$100', style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Cover Letter
              const Text(
                'Cover Letter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'I am a professional and technical plumbing engineer with over 10yrs experience in...it. Quisque donec in accumsan enim vel vitae lectus odio. Posuere vitae in ornare ullamcorper ut est enim. Sed porttitor auctor quis sed. Pulvinar arcu urna libero viverra. Commodo tortor ac sed massa et aliquet adipiscing. See more...',
                  style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Images
              const Text(
                'Images',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMockWorkImage(),
                  const SizedBox(width: 12),
                  _buildMockWorkImage(),
                  const SizedBox(width: 12),
                  _buildMockWorkImage(),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Rating / Jobs
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                  const SizedBox(width: 4),
                  const Text('4.7 Rating', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle_outline, color: Colors.grey[400], size: 16),
                  const SizedBox(width: 4),
                  const Text('46 completed jobs', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[800], fontSize: 10),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 14)),
      ],
    );
  }

  Widget _buildMockWorkImage() {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
           image: NetworkImage('https://images.unsplash.com/photo-1581092160562-40aa08e78837?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=150&q=80'), // Mock plumbing work image
           fit: BoxFit.cover,
        ),
      ),
    );
  }
}
