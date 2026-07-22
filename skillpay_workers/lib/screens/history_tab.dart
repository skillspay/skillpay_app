import 'package:flutter/material.dart';
import 'history_job_details_screen.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for history
    final List<Map<String, dynamic>> historyJobs = [
      {
        'id': 'JOB-36474849',
        'person': 'Felix Matson',
        'category': 'Plumbing',
        'status': 'Pending',
      },
      {
        'id': 'JOB-36474849',
        'person': 'Mary Janet',
        'category': 'Cleaning',
        'status': 'Completed',
      },
      {
        'id': 'JOB-36474849',
        'person': 'Felix Matson',
        'category': 'Plumbing',
        'status': 'Completed',
      },
      {
        'id': 'JOB-36474849',
        'person': 'Felix Matson',
        'category': 'Cleaning',
        'status': 'Cancelled',
      },
      {
        'id': 'JOB-36474849',
        'person': 'Felix Matson',
        'category': 'Plumbing',
        'status': 'Completed',
      },
      {
        'id': 'JOB-36474849',
        'person': 'Felix Matson',
        'category': 'Electrical',
        'status': 'Completed',
      },
      {
        'id': 'JOB-36474849',
        'person': 'Felix Matson',
        'category': 'Cleaning',
        'status': 'Cancelled',
      },
      {
        'id': 'JOB-36474849',
        'person': 'Felix Matson',
        'category': 'Plumbing',
        'status': 'Pending',
      },
      {
        'id': 'JOB-36474849',
        'person': 'Mary Janet',
        'category': 'Cleaning',
        'status': 'Completed',
      },
    ];

    return SafeArea(
      child: Column(
        children: [
          // App Bar Area
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50], // Very light background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search Jobs..',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // List of History items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              itemCount: historyJobs.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey[200], height: 1),
              itemBuilder: (context, index) {
                final job = historyJobs[index];
                return _buildHistoryItem(context, job);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> job) {
    Color statusColor;
    Color statusBgColor;

    switch (job['status']) {
      case 'Pending':
        statusColor = Colors.orange;
        statusBgColor = Colors.orange.withOpacity(0.1);
        break;
      case 'Completed':
        statusColor = Colors.green;
        statusBgColor = Colors.green.withOpacity(0.1);
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        statusBgColor = Colors.red.withOpacity(0.1);
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.1);
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryJobDetailsScreen(
              jobId: job['id'],
              status: job['status'],
              statusColor: statusColor,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Background
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work_outline,
                color: Colors.black54,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            
            // Job Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['id'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        job['person'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        job['category'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Status Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                job['status'],
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
