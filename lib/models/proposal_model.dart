/// Matches the NestJS job_applications response shape.
///
/// DB table: job_applications
/// NestJS endpoint: GET /applications  |  GET /applications/:id
class ProposalModel {
  final String id;
  final String jobId;
  final String artisanId;
  final String proposal; // cover letter / pitch
  final double price;
  final String estimatedDuration;
  final String status; // PENDING | ACCEPTED | REJECTED | WITHDRAWN

  // Artisan details (embedded by NestJS via join)
  final String artisanName;
  final String? artisanLocation;
  final String? artisanBio;
  final String? artisanBusinessName;
  final List<String> artisanCategories;
  final double artisanRating;
  final int artisanCompletedJobs;
  final String? artisanAvatarUrl;
  final double? artisanHourlyRate;

  ProposalModel({
    required this.id,
    required this.jobId,
    required this.artisanId,
    required this.proposal,
    required this.price,
    required this.estimatedDuration,
    required this.status,
    required this.artisanName,
    this.artisanLocation,
    this.artisanBio,
    this.artisanBusinessName,
    required this.artisanCategories,
    required this.artisanRating,
    required this.artisanCompletedJobs,
    this.artisanAvatarUrl,
    this.artisanHourlyRate,
  });

  factory ProposalModel.fromMap(Map<String, dynamic> map) {
    // NestJS embeds the artisan as a nested object
    final artisan = map['artisan'] as Map<String, dynamic>? ?? {};
    final rawCats = artisan['categories'] as List<dynamic>? ?? [];
    final categoryNames = rawCats.map((c) {
      if (c is String) return c;
      if (c is Map) return c['name']?.toString() ?? '';
      return '';
    }).where((s) => s.isNotEmpty).toList();

    return ProposalModel(
      id: map['id']?.toString() ?? '',
      jobId: map['jobId']?.toString() ?? map['job_id']?.toString() ?? '',
      artisanId: map['artisanId']?.toString() ?? map['artisan_id']?.toString() ?? '',
      proposal: map['proposal']?.toString() ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      estimatedDuration: map['estimatedDuration']?.toString() ??
          map['estimated_duration']?.toString() ??
          '',
      status: map['status']?.toString() ?? 'PENDING',
      artisanName: artisan['fullName']?.toString() ??
          artisan['full_name']?.toString() ??
          'Unknown Artisan',
      artisanLocation: artisan['location']?.toString(),
      artisanBio: artisan['bio']?.toString(),
      artisanBusinessName: artisan['businessName']?.toString() ??
          artisan['business_name']?.toString(),
      artisanCategories: categoryNames,
      artisanRating: double.tryParse(
              artisan['averageRating']?.toString() ??
                  artisan['average_rating']?.toString() ??
                  '0') ??
          0.0,
      artisanCompletedJobs: (artisan['completedJobs'] as int?) ??
          (artisan['completed_jobs'] as int?) ??
          0,
      artisanAvatarUrl: artisan['profilePhoto']?.toString() ??
          artisan['profile_photo']?.toString(),
      artisanHourlyRate: double.tryParse(
          artisan['hourlyRate']?.toString() ??
              artisan['hourly_rate']?.toString() ??
              ''),
    );
  }

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';
  bool get isWithdrawn => status.toUpperCase() == 'WITHDRAWN';
}
