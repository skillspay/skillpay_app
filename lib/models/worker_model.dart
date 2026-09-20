/// Matches the NestJS artisan profile response shape.
///
/// DB tables: artisans (joined with users)
/// NestJS endpoint: GET /artisans/:id  |  GET /artisans/nearby
import 'artisan_post_model.dart';

class WorkerModel {
  final String id; // artisans.id
  final String userId;
  final String fullName;
  final String? email;
  final String? profileImageUrl;
  final String? bio;
  final String? businessName;
  final String? coverLetter;
  final double? hourlyRate;
  final int yearsExperience;
  final double averageRating;
  final int completedJobs;
  final String availabilityStatus; // available | busy | unavailable
  final List<String> categories; // skill category names
  final List<ArtisanPostModel> posts;
  final double? latitude;
  final double? longitude;
  final double? distanceKm; // populated by nearby endpoint
  final bool isVerified;

  WorkerModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.email,
    this.profileImageUrl,
    this.bio,
    this.businessName,
    this.coverLetter,
    this.hourlyRate,
    required this.yearsExperience,
    required this.averageRating,
    required this.completedJobs,
    required this.availabilityStatus,
    required this.categories,
    this.posts = const [],
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.isVerified = false,
  });

  factory WorkerModel.fromMap(Map<String, dynamic> map) {
    // NestJS may embed the user object or return fields flat
    final userObj = map['user'] as Map<String, dynamic>?;

    // Categories come as a list of category objects or strings
    final rawCats = map['categories'] as List<dynamic>? ?? [];
    final categoryNames = rawCats.map((c) {
      if (c is String) return c;
      if (c is Map) {
        if (c['category'] is Map) {
          return c['category']['name']?.toString() ?? '';
        }
        return c['name']?.toString() ?? '';
      }
      return '';
    }).where((s) => s.isNotEmpty).toList();

    return WorkerModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      fullName: map['fullName']?.toString() ??
          map['full_name']?.toString() ??
          userObj?['email']?.toString() ??
          'Unknown Artisan',
      email: userObj?['email']?.toString(),
      profileImageUrl: map['profilePhoto']?.toString() ??
          map['profile_photo']?.toString(),
      bio: map['bio']?.toString(),
      businessName: map['businessName']?.toString() ?? map['business_name']?.toString(),
      coverLetter: map['coverLetter']?.toString() ?? map['cover_letter']?.toString(),
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
      posts: (map['posts'] as List<dynamic>?)
              ?.map((p) => ArtisanPostModel.fromMap(p as Map<String, dynamic>))
              .toList() ??
          const [],
      latitude: double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: double.tryParse(map['longitude']?.toString() ?? ''),
      distanceKm: double.tryParse(map['distanceKm']?.toString() ?? ''),
      isVerified: map['verificationStatus'] == 'VERIFIED' || map['verification_status'] == 'VERIFIED',
    );
  }

  bool get isAvailable =>
      availabilityStatus.toLowerCase() == 'available';
}
