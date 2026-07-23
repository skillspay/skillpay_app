/// Matches the NestJS job_applications response shape.
class ApplicationModel {
  final String id;
  final String jobId;
  final String artisanId;
  final double price;
  final String proposal;
  final String? estimatedDuration;
  final String status; // PENDING | ACCEPTED | REJECTED | WITHDRAWN

  // Job details (embedded by NestJS)
  final String? jobTitle;
  final String? jobAddress;
  final double? jobBudget;
  final String? jobStatus;
  final String? categoryName;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.artisanId,
    required this.price,
    required this.proposal,
    this.estimatedDuration,
    required this.status,
    this.jobTitle,
    this.jobAddress,
    this.jobBudget,
    this.jobStatus,
    this.categoryName,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map) {
    final jobObj = map['job'] as Map<String, dynamic>?;
    final categoryObj = jobObj?['category'] as Map<String, dynamic>?;

    return ApplicationModel(
      id: map['id']?.toString() ?? '',
      jobId: map['jobId']?.toString() ?? map['job_id']?.toString() ?? '',
      artisanId: map['artisanId']?.toString() ?? map['artisan_id']?.toString() ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      proposal: map['proposal']?.toString() ?? '',
      estimatedDuration: map['estimatedDuration']?.toString() ?? map['estimated_duration']?.toString(),
      status: map['status']?.toString() ?? 'PENDING',
      jobTitle: jobObj?['title']?.toString(),
      jobAddress: jobObj?['address']?.toString(),
      jobBudget: double.tryParse(jobObj?['budget']?.toString() ?? ''),
      jobStatus: jobObj?['status']?.toString(),
      categoryName: categoryObj?['name']?.toString(),
    );
  }

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';
  bool get isWithdrawn => status.toUpperCase() == 'WITHDRAWN';
}
