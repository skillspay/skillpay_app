import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillpay/theme/app_theme.dart';
import 'package:skillpay/widgets/artisan_card.dart';
import 'package:skillpay/services/worker_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillpay/models/worker_model.dart';
import 'package:skillpay/screens/artisan_profile_screen.dart';

class ArtisansScreen extends StatefulWidget {
  final String? initialSearchQuery;
  
  const ArtisansScreen({super.key, this.initialSearchQuery});

  @override
  State<ArtisansScreen> createState() => _ArtisansScreenState();
}

class _ArtisansScreenState extends State<ArtisansScreen> {
  final WorkerService _workerService = WorkerService();
  late Future<List<WorkerModel>> _workersFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
      _workersFuture = _workerService.searchArtisans(widget.initialSearchQuery!.trim());
    } else {
      _workersFuture = _workerService.fetchNearbyWorkers();
    }
  }

  void _onSearch(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _workersFuture = _workerService.fetchNearbyWorkers();
      } else {
        _workersFuture = _workerService.searchArtisans(query.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Artisans',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.black,
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 8),
            child: Container(
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
                      controller: _searchController,
                      onSubmitted: _onSearch,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search artisans by name or skill...',
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
                  GestureDetector(
                    onTap: () => _onSearch(_searchController.text),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFFB0B0B0),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: FutureBuilder<List<WorkerModel>>(
              future: _workersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading artisans.',
                      style: GoogleFonts.outfit(color: AppColors.textMedium),
                    ),
                  );
                }

                final workers = snapshot.data ?? [];

                if (workers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No artisans found',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 24, right: 8, top: 24, bottom: 100),
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ArtisanCard(
                        width: double.infinity,
                        imagePath: worker.profileImageUrl ?? 'assets/images/avatar_placeholder.png',
                        name: worker.fullName,
                        profession: worker.categories.isNotEmpty
                            ? worker.categories.first
                            : worker.businessName ?? 'Artisan',
                        jobsCompleted: worker.completedJobs,
                        rating: worker.averageRating,
                        isVerified: worker.isVerified,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArtisanProfileScreen(worker: worker),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
