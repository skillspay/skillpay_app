import 'package:flutter/material.dart';
import '../services/jobs_service.dart';
import '../services/artisan_profile_service.dart';
import '../services/location_service.dart';
import '../models/job_model.dart';
import '../models/booking_model.dart';
import '../services/bookings_service.dart';
import 'job_details_screen.dart';
import 'history_job_details_screen.dart';
import 'submit_proposal_screen.dart';

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  int _selectedTabIndex = 0;
  List<JobModel> _availableJobs = [];
  List<BookingModel> _recentBookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Category filter
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;

  // Near Me / Location filter
  bool _nearMeActive = false;
  bool _isLocating = false;
  double? _userLat;
  double? _userLng;
  String? _userLocationLabel;

  // Search
  final _searchCtrl = TextEditingController();

  final _jobsService = JobsService();
  final _profileService = ArtisanProfileService();

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await _profileService.fetchCategories();
    if (mounted) setState(() => _categories = cats);
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final available = await _jobsService.fetchAvailableJobs(
        categoryId: _selectedCategoryId,
        latitude: _nearMeActive ? _userLat : null,
        longitude: _nearMeActive ? _userLng : null,
        radiusKm: _nearMeActive ? 30 : null,
      );
      final bookings = await BookingsService().fetchMyBookings();
      final history = await BookingsService().fetchMyHistory();

      if (mounted) {
        setState(() {
          _availableJobs = available;
          _recentBookings = [...bookings, ...history];
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleNearMe() async {
    if (_nearMeActive) {
      setState(() {
        _nearMeActive = false;
        _userLat = null;
        _userLng = null;
        _userLocationLabel = null;
      });
      _fetchJobs();
      return;
    }

    setState(() => _isLocating = true);
    try {
      final pos = await LocationService.instance.getCurrentLocation();
      final label = await LocationService.instance.getReadableAddress(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
          _userLocationLabel = label;
          _nearMeActive = true;
        });
        _fetchJobs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Showing jobs near $label'),
            backgroundColor: const Color(0xFF1E88E5),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get GPS location: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Jobs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _fetchJobs(),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search for jobs',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Filter Chips: Near Me + All + Categories
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                // Near Me chip
                _buildFilterChip(
                  label: _nearMeActive
                      ? (_userLocationLabel != null ? 'Near: $_userLocationLabel' : 'Near Me')
                      : 'Near Me',
                  isSelected: _nearMeActive,
                  isLoading: _isLocating,
                  icon: _nearMeActive ? Icons.near_me : Icons.near_me_outlined,
                  accentColor: const Color(0xFF1E88E5),
                  onTap: _toggleNearMe,
                ),
                const SizedBox(width: 8),
                // All categories chip
                _buildFilterChip(
                  label: 'All Jobs',
                  isSelected: _selectedCategoryId == null,
                  onTap: () {
                    setState(() => _selectedCategoryId = null);
                    _fetchJobs();
                  },
                ),
                const SizedBox(width: 8),
                // Dynamic category chips
                ..._categories.map((cat) {
                  final catId = cat['id'] as String;
                  final catName = cat['name'] as String? ?? 'Unknown';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(
                      label: catName,
                      isSelected: _selectedCategoryId == catId,
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = _selectedCategoryId == catId ? null : catId;
                        });
                        _fetchJobs();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                _buildTabItem(title: 'Best Matches', index: 0),
                const SizedBox(width: 24),
                _buildTabItem(title: 'Recent Jobs', index: 1),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_errorMessage',
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            TextButton(
                                onPressed: _fetchJobs,
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _selectedTabIndex == 0
                        ? _buildAvailableJobsList()
                        : _buildRecentJobsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    bool isLoading = false,
    IconData? icon,
    Color accentColor = Colors.black,
    required VoidCallback onTap,
  }) {
    final bg = isSelected ? accentColor : const Color(0xFFF0F0F0);
    final fg = isSelected ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            else if (icon != null)
              Icon(icon, size: 13, color: fg),
            if (icon != null || isLoading) const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: fg,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected && !isLoading) ...[
              const SizedBox(width: 4),
              Icon(Icons.close_rounded, size: 12, color: fg),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableJobsList() {
    if (_availableJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              _nearMeActive
                  ? 'No jobs found near your location.\nTry expanding the search radius.'
                  : 'No jobs available at the moment.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchJobs,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
            horizontal: 24.0, vertical: 8.0),
        itemCount: _availableJobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) =>
            _buildJobCard(context, _availableJobs[index]),
      ),
    );
  }

  Widget _buildRecentJobsList() {
    if (_recentBookings.isEmpty) {
      return const Center(
        child: Text('No recent jobs available.',
            style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _fetchJobs,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
            horizontal: 24.0, vertical: 8.0),
        itemCount: _recentBookings.length,
        separatorBuilder: (_, __) =>
            const Divider(color: Color(0xFFEEEEEE), height: 1),
        itemBuilder: (context, index) =>
            _buildBookingItem(context, _recentBookings[index]),
      ),
    );
  }

  Widget _buildTabItem({required String title, required int index}) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.black : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobModel job) {
    final timePosted = _formatTimePosted(job.createdAt);
    final tags = job.categoryName.isNotEmpty ? [job.categoryName] : ['General'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + distance badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(job.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              if (job.distanceKm != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '📍 ${job.distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: Color(0xFF1E88E5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Budget: ',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.normal)),
              Text('\$${job.budget.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map(_buildTag).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Colors.grey, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(job.address,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            job.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.grey, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => JobDetailsScreen(job: job)),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubmitProposalScreen(jobId: job.id),
                      ),
                    );
                  },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child:
          Text(text, style: TextStyle(color: Colors.grey[800], fontSize: 11)),
    );
  }

  String _formatTimePosted(DateTime postedTime) {
    final diff = DateTime.now().difference(postedTime);
    if (diff.inDays > 1) return '${diff.inDays} days ago';
    if (diff.inDays == 1) return '1 day ago';
    if (diff.inHours > 1) return '${diff.inHours} hours ago';
    if (diff.inHours == 1) return '1 hour ago';
    if (diff.inMinutes > 1) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }

  Widget _buildBookingItem(BuildContext context, BookingModel booking) {
    Color statusColor;
    Color statusBgColor;
    switch (booking.status.toUpperCase()) {
      case 'PENDING':
      case 'CONFIRMED':
        statusColor = Colors.orange;
        statusBgColor = Colors.orange.withOpacity(0.1);
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.blue;
        statusBgColor = Colors.blue.withOpacity(0.1);
        break;
      case 'COMPLETED':
        statusColor = Colors.green;
        statusBgColor = Colors.green.withOpacity(0.1);
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusBgColor = Colors.red.withOpacity(0.1);
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.1);
    }

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryJobDetailsScreen(
              booking: booking,
              statusColor: statusColor,
            ),
          ),
        );
        if (result == true) {
          _fetchJobs();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.jobTitle ?? 'Job ${booking.id.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.homeownerName ?? 'Client',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(
                        booking.amount != null ? '\$${booking.amount!.toStringAsFixed(0)}' : 'N/A',
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                booking.status.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
