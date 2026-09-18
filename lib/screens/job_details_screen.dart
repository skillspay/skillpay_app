import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillpay/theme/app_theme.dart';
import 'package:skillpay/models/job_model.dart';
import 'package:skillpay/screens/dashboard_screen.dart'; // for capitalize extension
import 'package:skillpay/screens/create_job_screen.dart';
import 'package:skillpay/screens/proposals_screen.dart';
import 'package:skillpay/screens/pay_invoice_modal.dart';
import 'package:skillpay/services/jobs_service.dart';
import 'package:skillpay/services/reviews_service.dart';


class JobDetailsScreen extends StatefulWidget {
  final JobModel job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  // 0 for Job Details, 1 for Track Progress
  int _selectedTabIndex = 0; 

  @override
  Widget build(BuildContext context) {
    // Generate derived values for UI
    final String shortId = widget.job.id.split('-').first.toUpperCase();
    final String artisanName = widget.job.isAccepted || widget.job.isInProgress || widget.job.isCompleted
        ? 'Assigned'
        : 'Searching';
    final String createdDate = "${widget.job.createdAt.month}/${widget.job.createdAt.day}/${widget.job.createdAt.year}";
    final String status = widget.job.status.capitalize();
    
    // Status color mapping based on mockups
    Color tagColor = const Color(0xFFFFF3E0);
    Color tagTextColor = const Color(0xFFEF6C00);
    
    if (status.toLowerCase() == 'completed' || status.toLowerCase() == 'accepted') {
      tagColor = const Color(0xFFE8F5E9);
      tagTextColor = const Color(0xFF2E7D32);
    } else if (status.toLowerCase() == 'canceled' || status.toLowerCase() == 'rejected') {
      tagColor = const Color(0xFFFFEEEE);
      tagTextColor = const Color(0xFFD32F2F);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Job Details',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'JOB-$shortId',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: tagColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tagTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        artisanName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '  |  $createdDate',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // --- Financials Row ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildFinancialCard(
                          'Job Proposed Cost',
                          '\$${widget.job.budget.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // --- Custom Tab Bar ---
                  Row(
                    children: [
                      _buildTab(0, 'Jobs Details'),
                      const SizedBox(width: 24),
                      _buildTab(1, 'Track Progress'),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // --- Tab Content ---
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _selectedTabIndex == 0 ? _buildJobDetailsTab() : _buildTrackProgressTab(),
            ),
          )
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget? _buildBottomActions() {
    if (widget.job.isPending || widget.job.isPublished) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Edit job',
                  backgroundColor: const Color(0xFFF0F0F0),
                  textColor: AppColors.textDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateJobScreen(initialJob: widget.job),
                      ),
                    ).then((result) {
                      if (!mounted) return;
                      if (result == true) {
                        Navigator.pop(context, true); // Pop back to refresh list
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'View proposals',
                  backgroundColor: AppColors.primary,
                  textColor: AppColors.textDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProposalsScreen(jobId: widget.job.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else if (widget.job.isInProgress || widget.job.isAccepted) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              label: 'Message',
              backgroundColor: AppColors.textDark,
              textColor: Colors.white,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please go to the Messages tab to chat with the artisan.')),
                );
              },
            ),
          ),
        ),
      );
    } else if (widget.job.isCompleted) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Message',
                  backgroundColor: AppColors.textDark,
                  textColor: Colors.white,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please go to the Messages tab to chat with the artisan.')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Approve Job',
                  backgroundColor: AppColors.primary,
                  textColor: AppColors.textDark,
                  onTap: () => _showApproveJobDialog(),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildFinancialCard(String title, String value, {bool isBold = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.textDark : AppColors.textMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildJobDetailsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Service Type', widget.job.categoryName),
        _buildDetailRow('Job Timeline', widget.job.timeline ?? widget.job.preferredDate ?? 'Flexible'),
        _buildDetailRow('Location', widget.job.address),
        _buildImageUploads(),
        _buildDetailRow('Additional Details', widget.job.description),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildImageUploads() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File Upload',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.job.images.isEmpty)
            Text(
              'None',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.job.images.map((imgUrl) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imgUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackProgressTab() {
    final bool isAssigned = widget.job.isAccepted || widget.job.isInProgress || widget.job.isCompleted;
    final bool isCompleted = widget.job.isCompleted;

    // Format the date properly for Job Posted
    final createdAt = widget.job.createdAt;
    final createdDateStr = "${createdAt.month}/${createdAt.day}/${createdAt.year}";

    final seventyPercent = widget.job.budget * 0.7;
    final thirtyPercent = widget.job.budget * 0.3;

    final children = <Widget>[];

    children.add(
      _buildTimelineItem(
        title: 'Job Posted',
        isCompleted: true,
        date: createdDateStr,
        isLast: !isAssigned,
      ),
    );

    if (isAssigned) {
      children.add(
        _buildTimelineItem(
          title: 'Artisan Assigned',
          isCompleted: true,
          date: createdDateStr,
          isLast: false,
        ),
      );
      
      children.add(
        _buildTimelineItem(
          title: '70% Prepayment',
          amount: '\$${seventyPercent.toStringAsFixed(2)}',
          isCompleted: true,
          date: createdDateStr,
          isLast: !isCompleted,
        ),
      );
    }

    if (isCompleted) {
      children.add(
        _buildTimelineItem(
          title: 'Job Completed',
          isCompleted: true,
          date: createdDateStr,
          isLast: false,
        ),
      );
      
      children.add(
        _buildTimelineItem(
          title: 'Final Payment',
          amount: '\$${thirtyPercent.toStringAsFixed(2)}',
          isCompleted: true,
          date: createdDateStr,
          isLast: true,
        ),
      );
    }

    return Column(
      children: children,
    );
  }

  Widget _buildTimelineItem({
    required String title,
    String? amount,
    required bool isCompleted,
    required String date,
    String? tag,
    String? actionText,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column for Line and Dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: AppColors.textDark)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  const SizedBox(height: 24), // spacing after last dot
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Right Column for Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32), // Space between items
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (amount != null) ...[
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '$amount • ',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'Paid', // Keeping it static for now as mockups imply context
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMedium),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textMedium,
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF6C00),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (actionText != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        actionText,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _showApproveJobDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Approve Job',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to confirm that this job as been fully completed and you are satisfied with the job done?',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This action means that the artisan is paid completely.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          
                          try {
                            await JobsService().approveJob(widget.job.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Job approved successfully'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                              // Show rating dialog before returning
                              await _showRatingDialog(widget.job.id);
                              
                              if (mounted) {
                                // Refresh job list/dashboard via Navigator
                                Navigator.pop(context, true);
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error approving job: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Confirm',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRatingDialog(String jobId) async {
    int rating = 5;
    final TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Rate the Artisan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How was your experience with this artisan?'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Leave a review (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Skip', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setState(() => isSubmitting = true);
                          try {
                            await ReviewsService().submitReview(
                              jobId: jobId,
                              rating: rating,
                              reviewText: reviewController.text,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Thank you for your feedback!')),
                              );
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            setState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to submit review: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Submit', style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
