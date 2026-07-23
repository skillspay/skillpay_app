/// Matches the NestJS bookings response shape.
class BookingModel {
  final String id;
  final String jobId;
  final String artisanId;
  final String homeownerId;
  final String status; // CONFIRMED | IN_PROGRESS | COMPLETED | CANCELLED | DISPUTED
  final DateTime? startDate;
  final DateTime? completionDate;
  final DateTime createdAt;

  // Embedded relations
  final String? jobTitle;
  final String? jobAddress;
  final double? amount; // from application price
  final String? homeownerName;
  final String? homeownerPhoto;

  BookingModel({
    required this.id,
    required this.jobId,
    required this.artisanId,
    required this.homeownerId,
    required this.status,
    this.startDate,
    this.completionDate,
    required this.createdAt,
    this.jobTitle,
    this.jobAddress,
    this.amount,
    this.homeownerName,
    this.homeownerPhoto,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    final jobObj = map['job'] as Map<String, dynamic>?;
    final homeownerObj = map['homeowner'] as Map<String, dynamic>?;
    final applicationObj = map['application'] as Map<String, dynamic>?;

    return BookingModel(
      id: map['id']?.toString() ?? '',
      jobId: map['jobId']?.toString() ?? map['job_id']?.toString() ?? '',
      artisanId: map['artisanId']?.toString() ?? map['artisan_id']?.toString() ?? '',
      homeownerId: map['homeownerId']?.toString() ?? map['homeowner_id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'CONFIRMED',
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'].toString())
          : null,
      completionDate: map['completionDate'] != null
          ? DateTime.tryParse(map['completionDate'].toString())
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      jobTitle: jobObj?['title']?.toString(),
      jobAddress: jobObj?['address']?.toString(),
      amount: double.tryParse(applicationObj?['price']?.toString() ?? ''),
      homeownerName: homeownerObj?['fullName']?.toString() ?? homeownerObj?['full_name']?.toString(),
      homeownerPhoto: homeownerObj?['profilePhoto']?.toString(),
    );
  }

  bool get isConfirmed => status.toUpperCase() == 'CONFIRMED';
  bool get isInProgress => status.toUpperCase() == 'IN_PROGRESS';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';
  bool get isDisputed => status.toUpperCase() == 'DISPUTED';
}
