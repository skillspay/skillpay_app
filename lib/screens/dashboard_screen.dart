import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skillpay/theme/app_theme.dart';
import 'package:skillpay/widgets/artisan_card.dart';
import 'package:skillpay/services/jobs_service.dart';
import 'package:skillpay/models/job_model.dart';
import 'package:skillpay/screens/notifications_screen.dart';
import 'package:skillpay/services/worker_service.dart';
import 'package:skillpay/services/customer_profile_service.dart';
import 'package:skillpay/models/worker_model.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final JobsService _jobsService = JobsService();
  final WorkerService _workerService = WorkerService();
  final CustomerProfileService _profileService = CustomerProfileService();
  late Future<List<JobModel>> _jobsFuture;
  late Future<Map<String, dynamic>?> _userProfileFuture;
  late Future<List<WorkerModel>> _workersFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _jobsService.fetchMyJobs();
    _userProfileFuture = _profileService.fetchProfile();
    _workersFuture = _workerService.fetchNearbyWorkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Black Header Sliver
          SliverToBoxAdapter(
            child: Container(
              color: Colors.black,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 24,
                right: 24,
                bottom: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User area & Bell
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _userProfileFuture,
                        builder: (context, snapshot) {
                          String firstName = 'User';
                          String? profileImageUrl;
                          if (snapshot.hasData && snapshot.data != null) {
                            final data = snapshot.data!;
                            // NestJS returns fullName (camelCase)
                            final fullName = data['fullName']?.toString() ??
                                data['full_name']?.toString();
                            if (fullName != null && fullName.isNotEmpty) {
                              firstName = fullName.split(' ').first;
                            }
                            profileImageUrl = data['profilePhoto']?.toString() ??
                                data['profile_photo']?.toString();
                          }

                          return Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E0E0),
                                  shape: BoxShape.circle,
                                  image: profileImageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            '$profileImageUrl?v=${DateTime.now().millisecondsSinceEpoch}',
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: profileImageUrl == null
                                    ? const Icon(Icons.person, color: Colors.white, size: 26)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hi $firstName,',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'What do you want to do today?',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: const Color(0xFFB0B0B0),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      
                      // Notification bell
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                            ),
                            Positioned(
                              top: 10,
                              right: 12,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // Search Bar
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search for worker...',
                              hintStyle: GoogleFonts.outfit(
                                color: const Color(0xFFB0B0B0),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFB0B0B0),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content Below Header
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // Categories
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Categories',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _CategoryItem('assets/images/cat_cleaning.png', 'Cleaning'),
                        const SizedBox(width: 16),
                        _CategoryItem('assets/images/cat_plumbing.png', 'Plumbing'),
                        const SizedBox(width: 16),
                        _CategoryItem('assets/images/cat_electrical.png', 'Electrical'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF0F0F0), thickness: 8),
                  const SizedBox(height: 24),
                  
                  // Top Artisans
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Top Artisans',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'View all',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FutureBuilder<List<WorkerModel>>(
                      future: _workersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text(
                            'No artisans found near your location.', 
                            style: GoogleFonts.outfit(color: AppColors.textMedium)
                          );
                        }

                        return Row(
                          children: snapshot.data!.map((worker) => Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: ArtisanCard(
                              // fallback to local asset if no URL
                              imagePath: worker.profileImageUrl ?? 'assets/images/avatar_placeholder.png', 
                              name: worker.fullName,
                              profession: worker.profession,
                              jobsCompleted: worker.jobsCompleted,
                              rating: worker.averageRating,
                            ),
                          )).toList(),
                        );
                      }
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Dot indicators (static mock)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.textDark, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFE0E0E0), shape: BoxShape.circle)),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF0F0F0), thickness: 8),
                  const SizedBox(height: 24),
                  
                  // History
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'History',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'View all',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Dynamic Jobs History Data
                  FutureBuilder<List<JobModel>>(
                    future: _jobsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ));
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading history', style: GoogleFonts.outfit(color: AppColors.textMedium)));
                      }

                      final jobs = snapshot.data ?? [];

                      if (jobs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Text(
                            'No jobs history found.',
                            style: GoogleFonts.outfit(color: AppColors.textMedium, fontSize: 14),
                          ),
                        );
                      }

                      // Take top 3 for dashboard
                      final previewJobs = jobs.take(3).toList();

                      return Column(
                        children: previewJobs.map((job) {
                          return _buildHistoryItem(
                            id: job.id.split('-').first.toUpperCase(),
                            artisan: job.artisanId != null ? 'Assigned' : 'Searching',
                            trade: job.category,
                            status: job.status.capitalize(),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 80), // Padding for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String id,
    required String artisan,
    required String trade,
    required String status,
  }) {
    final isCompleted = status == 'Completed';
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.work_outline_rounded,
                    color: AppColors.textDark, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$artisan  |  $trade',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFE8F5E9)  // Light green
                      : const Color(0xFFFFF3E0), // Light orange
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String imagePath;
  final String title;

  const _CategoryItem(this.imagePath, this.title);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Image.asset(imagePath, width: 48, height: 48),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
