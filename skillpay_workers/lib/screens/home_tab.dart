import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/jobs_service.dart';
import '../services/wallet_service.dart';
import '../models/job_model.dart';
import 'job_details_screen.dart';

class HomeTab extends StatefulWidget {
  final bool isVerified;

  const HomeTab({super.key, this.isVerified = false});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _jobsService = JobsService();
  final _walletService = WalletService();

  List<JobModel> _jobs = [];
  double _balance = 0.0;
  int _openJobs = 0;
  int _completedJobs = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _jobsService.fetchAvailableJobs(limit: 5),
        _walletService.fetchWallet(),
        _jobsService.fetchMyApplicationJobs(),
        _jobsService.fetchCompletedJobs(),
      ]);

      final jobs = results[0] as List<JobModel>;
      final wallet = results[1] as Map<String, dynamic>?;
      final appJobs = results[2] as List<JobModel>;
      final completedJobs = results[3] as List<JobModel>;

      if (mounted) {
        setState(() {
          _jobs = jobs;
          _balance =
              double.tryParse(wallet?['balance']?.toString() ?? '0') ?? 0.0;
          _openJobs = appJobs.length;
          _completedJobs = completedJobs.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName =
        user?.userMetadata?['full_name']?.toString() ?? 'Worker';
    final firstName = fullName.split(' ').first;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child:
                            const Icon(Icons.person, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Hi $firstName 👋',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (widget.isVerified) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.check,
                                      color: Colors.white, size: 10),
                                ),
                              ],
                            ],
                          ),
                          const Text('Welcome back',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: const Icon(Icons.notifications_none,
                        color: Colors.black),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Earnings card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Wallet Balance',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : Text(
                            '\$${_balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold),
                          ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Withdraw'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Job stats
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                        label: 'Open Jobs',
                        value: _isLoading ? '—' : '$_openJobs'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _statCard(
                        label: 'Completed',
                        value: _isLoading ? '—' : '$_completedJobs'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              const Text('Available Jobs',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Colors.black),
                ))
              else if (_jobs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: const Center(
                    child: Text('No jobs available right now.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _jobs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 16),
                  itemBuilder: (_, i) => _buildJobCard(_jobs[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobModel job) {
    final diff = DateTime.now().difference(job.createdAt);
    String timePosted = 'Just now';
    if (diff.inDays > 0) timePosted = '${diff.inDays}d ago';
    else if (diff.inHours > 0) timePosted = '${diff.inHours}h ago';
    else if (diff.inMinutes > 0) timePosted = '${diff.inMinutes}m ago';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Budget: ',
                  style: TextStyle(color: Colors.black, fontSize: 13)),
              Text('\$${job.budget.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (job.categoryName.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [_buildTag(job.categoryName)],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Colors.grey, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(job.address,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(job.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12, height: 1.5)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Posted $timePosted',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 11)),
              Text('Proposals: ${job.applicationCount}',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const JobDetailsScreen()),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFC107),
                    side: const BorderSide(color: Color(0xFFFFC107)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text,
          style: TextStyle(color: Colors.grey[800], fontSize: 11)),
    );
  }
}
