/// Matches the NestJS jobs response shape (artisan perspective).
class JobModel {
  final String id;
  final String homeownerId;
  final String title;
  final String description;
  final String address;
  final double budget;
  final String? preferredDate;
  final String status;
  final int applicationCount;
  final String? categoryId;
  final String categoryName;
  final List<String> images;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  // Homeowner info (embedded by NestJS)
  final String? homeownerName;
  final String? homeownerPhoto;

  JobModel({
    required this.id,
    required this.homeownerId,
    required this.title,
    required this.description,
    required this.address,
    required this.budget,
    this.preferredDate,
    required this.status,
    required this.applicationCount,
    this.categoryId,
    required this.categoryName,
    required this.images,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.homeownerName,
    this.homeownerPhoto,
  });

  factory JobModel.fromMap(Map<String, dynamic> map) {
    final categoryObj = map['category'] as Map<String, dynamic>?;
    final homeownerObj = map['homeowner'] as Map<String, dynamic>?;
    final imagesList = map['images'];

    return JobModel(
      id: map['id']?.toString() ?? '',
      homeownerId: map['homeownerId']?.toString() ?? map['homeowner_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled Job',
      description: map['description']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      budget: double.tryParse(map['budget']?.toString() ?? '0') ?? 0.0,
      preferredDate: map['preferredDate']?.toString() ?? map['preferred_date']?.toString(),
      status: map['status']?.toString() ?? 'PENDING',
      applicationCount: (map['applicationCount'] as int?) ?? (map['application_count'] as int?) ?? 0,
      categoryId: categoryObj?['id']?.toString() ?? map['categoryId']?.toString(),
      categoryName: categoryObj?['name']?.toString() ?? map['categoryName']?.toString() ?? 'General',
      images: imagesList is List ? List<String>.from(imagesList.whereType<String>()) : [],
      latitude: double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: double.tryParse(map['longitude']?.toString() ?? ''),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      homeownerName: homeownerObj?['fullName']?.toString() ?? homeownerObj?['full_name']?.toString(),
      homeownerPhoto: homeownerObj?['profilePhoto']?.toString() ?? homeownerObj?['profile_photo']?.toString(),
    );
  }

  bool get isPublished => status.toUpperCase() == 'PUBLISHED';
  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';
  bool get isInProgress => status.toUpperCase() == 'IN_PROGRESS';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
}
