/// Matches the NestJS `jobs` response shape.
///
/// DB columns: id, homeowner_id, category_id, title, description, budget,
/// preferred_date, status, latitude, longitude, address, images, created_at
///
/// NestJS enriches the response with: category (object), applicationCount.
class JobModel {
  final String id;
  final String homeownerId;
  final String title;
  final String description;
  final String address;
  final double budget;
  final String? preferredDate;
  final String status; // Draft | Pending | Published | Accepted | InProgress | Completed | Cancelled
  final int applicationCount;
  final String? categoryId;
  final String categoryName;
  final List<String> images;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

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
  });

  factory JobModel.fromMap(Map<String, dynamic> map) {
    // NestJS may embed category as an object or return categoryId + categoryName flat
    final categoryObj = map['category'] as Map<String, dynamic>?;
    final imagesList = map['images'];

    return JobModel(
      id: map['id']?.toString() ?? '',
      homeownerId: map['homeownerId']?.toString() ?? map['homeowner_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled Job',
      description: map['description']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      budget: double.tryParse(map['budget']?.toString() ?? '0') ?? 0.0,
      preferredDate: map['preferredDate']?.toString() ?? map['preferred_date']?.toString(),
      status: map['status']?.toString() ?? 'Pending',
      applicationCount: (map['applicationCount'] as int?) ??
          (map['application_count'] as int?) ??
          0,
      categoryId: categoryObj?['id']?.toString() ?? map['categoryId']?.toString(),
      categoryName: categoryObj?['name']?.toString() ??
          map['categoryName']?.toString() ??
          'General',
      images: imagesList is List
          ? List<String>.from(imagesList.whereType<String>())
          : <String>[],
      latitude: double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: double.tryParse(map['longitude']?.toString() ?? ''),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ??
              DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toCreatePayload() => {
        'title': title,
        'description': description,
        'address': address,
        'budget': budget,
        if (categoryId != null) 'categoryId': categoryId,
        if (preferredDate != null) 'preferredDate': preferredDate,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (images.isNotEmpty) 'images': images,
      };

  // ─── Status helpers ───────────────────────────────────────────────────────

  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isPublished => status.toLowerCase() == 'published';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isInProgress => status.toLowerCase() == 'inprogress' || status.toLowerCase() == 'in_progress';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isActive => isPublished || isAccepted || isInProgress;
}
