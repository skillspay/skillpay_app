/// Matches the NestJS artisan profile response shape.
class ArtisanProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String? businessName;
  final String? bio;
  final String? experience;
  final int yearsExperience;
  final double? hourlyRate;
  final String verificationStatus; // UNVERIFIED | PENDING | VERIFIED | REJECTED
  final String? profilePhoto;
  final double averageRating;
  final int completedJobs;
  final String availabilityStatus; // AVAILABLE | BUSY | UNAVAILABLE
  final double? latitude;
  final double? longitude;
  final List<String> categoryNames;

  // User info
  final String email;
  final String? phone;

  ArtisanProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.businessName,
    this.bio,
    this.experience,
    required this.yearsExperience,
    this.hourlyRate,
    required this.verificationStatus,
    this.profilePhoto,
    required this.averageRating,
    required this.completedJobs,
    required this.availabilityStatus,
    this.latitude,
    this.longitude,
    required this.categoryNames,
    required this.email,
    this.phone,
  });

  factory ArtisanProfileModel.fromMap(Map<String, dynamic> map) {
    final userObj = map['user'] as Map<String, dynamic>?;
    final rawCats = map['categories'] as List<dynamic>? ?? [];
    final categoryNames = rawCats.map((c) {
      if (c is String) return c;
      if (c is Map) {
        final cat = c['category'] as Map<String, dynamic>?;
        return cat?['name']?.toString() ?? c['name']?.toString() ?? '';
      }
      return '';
    }).where((s) => s.isNotEmpty).toList();

    return ArtisanProfileModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? map['full_name']?.toString() ?? '',
      businessName: map['businessName']?.toString() ?? map['business_name']?.toString(),
      bio: map['bio']?.toString(),
      experience: map['experience']?.toString(),
      yearsExperience: (map['yearsExperience'] as int?) ?? (map['years_experience'] as int?) ?? 0,
      hourlyRate: double.tryParse(map['hourlyRate']?.toString() ?? map['hourly_rate']?.toString() ?? ''),
      verificationStatus: map['verificationStatus']?.toString() ?? map['verification_status']?.toString() ?? 'UNVERIFIED',
      profilePhoto: map['profilePhoto']?.toString() ?? map['profile_photo']?.toString(),
      averageRating: double.tryParse(map['averageRating']?.toString() ?? map['average_rating']?.toString() ?? '0') ?? 0.0,
      completedJobs: (map['completedJobs'] as int?) ?? (map['completed_jobs'] as int?) ?? 0,
      availabilityStatus: map['availabilityStatus']?.toString() ?? map['availability_status']?.toString() ?? 'AVAILABLE',
      latitude: double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: double.tryParse(map['longitude']?.toString() ?? ''),
      categoryNames: categoryNames,
      email: userObj?['email']?.toString() ?? map['email']?.toString() ?? '',
      phone: userObj?['phone']?.toString() ?? map['phone']?.toString(),
    );
  }

  bool get isVerified => verificationStatus.toUpperCase() == 'VERIFIED';
  bool get isAvailable => availabilityStatus.toUpperCase() == 'AVAILABLE';
}
