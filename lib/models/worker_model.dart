/// Matches the NestJS artisan profile response shape.
///
/// DB tables: artisans (joined with users)
/// NestJS endpoint: GET /artisans/:id  |  GET /artisans/nearby
class WorkerModel {
  final String id; // artisans.id
  final String userId;
  final String fullName;
  final String? profileImageUrl;
  final String? bio;
  final String? businessName;
  final double? hourlyRate;
  final int yearsExperience;
  final double averageRating;
  final int completedJobs;
  final String availabilityStatus; // available | busy | unavailable
  final List<String> categories; // skill category names
  final double? latitude;
  final double? longitude;
  final double? distanceKm; // populated by nearby endpoint

  WorkerModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.profileImageUrl,
    this.bio,
    this.businessName,
    this.hourlyRate,
    required this.yearsExperience,
    required this.averageRating,
    required this.completedJobs,
    required this.availabilityStatus,
    required this.categories,
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  factory WorkerModel.fromMap(Map<String, dynamic> map) {
    // NestJS may embed the user object or return fields flat
    final userObj = map['user'] as Map<String, dynamic>?;

    // Categories come as a list of category objects or strings
    final rawCats = map['categories'] as List<dynamic>? ?? [];
    final categoryNames = rawCats.map((c) {
      if (c is String) return c;
      if (c is Map) return c['name']?.toString() ?? '';
      return '';
    }).where((s) => s.isNotEmpty).toList();

    return WorkerModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      fullName: userObj?['email']?.toString() ??
          map['fullName']?.toString() ??
          map['full_name']?.toString() ??
          'Unknown Artisan',
      profileImageUrl: map['profilePhoto']?.toString() ??
          map['profile_photo']?.toString(),
      bio: map['bio']?.toString(),
      businessName: map['businessName']?.toString() ?? map['business_name']?.toString(),
      hourlyRate: double.tryParse(map['hourlyRate']?.toString() ?? map['hourly_rate']?.toString() ?? ''),
      yearsExperience: (map['yearsExperience'] as int?) ??
          (map['years_experience'] as int?) ??
          0,
      averageRating:
          double.tryParse(map['averageRating']?.toString() ?? map['average_rating']?.toString() ?? '0') ?? 0.0,
      completedJobs: (map['completedJobs'] as int?) ??
          (map['completed_jobs'] as int?) ??
          0,
      availabilityStatus: map['availabilityStatus']?.toString() ??
          map['availability_status']?.toString() ??
          'available',
      categories: categoryNames,
      latitude: double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: double.tryParse(map['longitude']?.toString() ?? ''),
      distanceKm: double.tryParse(map['distanceKm']?.toString() ?? ''),
    );
  }

  bool get isAvailable =>
      availabilityStatus.toLowerCase() == 'available';
}
