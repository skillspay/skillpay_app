import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillpay/theme/app_theme.dart';
import 'package:skillpay/screens/job_details_screen.dart';

import 'package:skillpay/models/job_model.dart';

class JobCard extends StatelessWidget {
  final JobModel job;

  final VoidCallback? onJobUpdated;

  const JobCard({
    super.key,
    required this.job,
    this.onJobUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobDetailsScreen(
              job: job,
            ),
          ),
        );
        if (result == true && onJobUpdated != null) {
          onJobUpdated!();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                text: 'Budget: ',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
                children: [
                  TextSpan(
                    text: '\$${job.budget.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(color: Colors.green.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [job.categoryName].map((tag) => _buildTag(tag)).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMedium),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              job.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Job ID: ${job.id.split('-').first.toUpperCase()}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(width: 12),
                const CircleAvatar(radius: 2, backgroundColor: AppColors.textLight),
                const SizedBox(width: 12),
                Text(
                  'Proposal ${job.applicationCount}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: AppColors.textMedium,
        ),
      ),
    );
  }
}
