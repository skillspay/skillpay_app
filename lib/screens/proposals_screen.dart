import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillpay/theme/app_theme.dart';
import 'package:skillpay/screens/proposal_details_screen.dart';
import 'package:skillpay/services/proposals_service.dart';
import 'package:skillpay/models/proposal_model.dart';
// import 'package:skillpay/screens/chat_screen.dart'; // From previous task

class ProposalsScreen extends StatefulWidget {
  final String? jobId;
  
  const ProposalsScreen({super.key, this.jobId});

  @override
  State<ProposalsScreen> createState() => _ProposalsScreenState();
}

class _ProposalsScreenState extends State<ProposalsScreen> {
  final ProposalsService _proposalsService = ProposalsService();
  late Future<List<ProposalModel>> _proposalsFuture;

  @override
  void initState() {
    super.initState();
    _proposalsFuture = _proposalsService.fetchProposals(jobId: widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Light background
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Proposals',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: FutureBuilder<List<ProposalModel>>(
        future: _proposalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading proposals',
                style: GoogleFonts.outfit(color: AppColors.textMedium),
              ),
            );
          }

          final proposals = snapshot.data ?? [];

          if (proposals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No proposals yet',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When workers apply to your jobs,\ntheir proposals will appear here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textMedium,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            );
          }

          // Render real dynamic proposals
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            itemCount: proposals.length,
            itemBuilder: (context, index) {
              final prop = proposals[index];
              return _buildProposalCard(context, {
                'name': prop.artisanName ?? 'Unknown Artisan',
                'location': prop.artisanLocation ?? 'Location unknown',
                'badges': prop.artisanCategories.isNotEmpty ? prop.artisanCategories : <String>[],
                'bio': prop.proposal.isNotEmpty ? prop.proposal : (prop.artisanBio ?? ''),
                'rating': prop.artisanRating ?? 0.0,
                'jobsCompleted': prop.artisanCompletedJobs ?? 0,
                'imagePath': prop.artisanAvatarUrl, 
                'hourlyRate': prop.artisanHourlyRate ?? prop.price ?? 0.0,
                'price': prop.price,
                'jobId': prop.jobId,
                'id': prop.artisanId,
                'applicationId': prop.id,
                'isNetworkImage': prop.artisanAvatarUrl?.startsWith('http') ?? false,
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildProposalCard(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProposalDetailsScreen(artisanData: data)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar, Name, Location
            Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: (data['imagePath']?.toString().startsWith('http') == true)
                              ? NetworkImage(data['imagePath']) as ImageProvider
                              : AssetImage(data['imagePath'] ?? 'assets/images/avatar_james.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50), // Green active dot
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'],
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['location'],
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Badges
            Row(
              children: (data['badges'] as List<String>).map((badge) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium,
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Bio
            Text(
              data['bio'],
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textMedium,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 16),
            
            // Rating and Jobs
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.primary, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${data['rating']} Rating',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${data['jobsCompleted']} completed jobs',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProposalDetailsScreen(artisanData: data)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'View Proposal',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
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
  }
}
