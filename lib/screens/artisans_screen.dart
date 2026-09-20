import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillpay/theme/app_theme.dart';
import 'package:skillpay/widgets/artisan_card.dart';
import 'package:skillpay/services/worker_service.dart';
import 'package:skillpay/services/categories_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillpay/models/worker_model.dart';
import 'package:skillpay/models/category_model.dart';
import 'package:skillpay/screens/artisan_profile_screen.dart';

class ArtisansScreen extends StatefulWidget {
  final String? initialSearchQuery;
  final String? initialCategoryId;
  final String? initialCategoryName;
  
  const ArtisansScreen({
    super.key,
    this.initialSearchQuery,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<ArtisansScreen> createState() => _ArtisansScreenState();
}

class _ArtisansScreenState extends State<ArtisansScreen> {
  final WorkerService _workerService = WorkerService();
  final CategoriesService _categoriesService = CategoriesService();
  late Future<List<WorkerModel>> _workersFuture;
  final TextEditingController _searchController = TextEditingController();

  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _selectedCategoryName = widget.initialCategoryName;

    _loadCategories();

    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
      _workersFuture = _workerService.searchArtisans(widget.initialSearchQuery!.trim());
    } else {
      _workersFuture = _workerService.fetchNearbyWorkers(categoryId: _selectedCategoryId);
    }
  }

  Future<void> _loadCategories() async {
    final cats = await _categoriesService.fetchCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        if (_selectedCategoryId != null && _selectedCategoryName == null) {
          final found = cats.where((c) => c.id == _selectedCategoryId);
          if (found.isNotEmpty) {
            _selectedCategoryName = found.first.name;
          }
        }
      });
    }
  }

  void _onCategorySelected(String? categoryId, String? categoryName) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryName;
      _searchController.clear();
      _workersFuture = _workerService.fetchNearbyWorkers(categoryId: categoryId);
    });
  }

  void _onSearch(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _workersFuture = _workerService.fetchNearbyWorkers(categoryId: _selectedCategoryId);
      } else {
        _workersFuture = _workerService.searchArtisans(query.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleText = (_selectedCategoryName != null && _selectedCategoryName!.isNotEmpty)
        ? _selectedCategoryName!
        : 'Artisans';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titleText,
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
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 14, top: 4),
            child: Container(
              height: 50,
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
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.close_rounded, color: Color(0xFFB0B0B0), size: 18),
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

          // Category filter pills
          if (_categories.isNotEmpty)
            Container(
              color: Colors.black,
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildCategoryChip(
                      label: 'All',
                      isSelected: _selectedCategoryId == null,
                      onTap: () => _onCategorySelected(null, null),
                    ),
                    ..._categories.map((cat) => _buildCategoryChip(
                      label: cat.name,
                      isSelected: _selectedCategoryId == cat.id,
                      onTap: () => _onCategorySelected(cat.id, cat.name),
                    )),
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
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Unable to load artisans',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _onCategorySelected(_selectedCategoryId, _selectedCategoryName),
                            child: Text(
                              'Try Again',
                              style: GoogleFonts.outfit(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final workers = snapshot.data ?? [];

                if (workers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.handyman_outlined, size: 36, color: Colors.amber.shade700),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _selectedCategoryName != null
                                ? 'No ${_selectedCategoryName!} artisans yet'
                                : 'No artisans found',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedCategoryName != null
                                ? 'Try selecting "All" or searching for a different skill.'
                                : 'Check back later as new workers register.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppColors.textMedium,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_selectedCategoryId != null) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _onCategorySelected(null, null),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Text(
                                'View All Artisans',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 100),
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

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFC107) : const Color(0xFF222222),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC107) : const Color(0xFF383838),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }
}
