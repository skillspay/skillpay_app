import 'package:flutter/foundation.dart';
import 'package:skillpay/models/proposal_model.dart';
import 'package:skillpay/services/api_client.dart';

class ProposalsService {
  final _api = ApiClient.instance;

  /// Fetch all pending job applications (proposals) for the homeowner's jobs.
  Future<List<ProposalModel>> fetchProposals({String? jobId}) async {
    try {
      final query = <String, dynamic>{
        'status': 'PENDING',
        if (jobId != null) 'jobId': jobId,
      };
      final data =
          await _api.get('/applications', query: query) as List<dynamic>;
      return data
          .map((json) =>
              ProposalModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching proposals: ${e.message}');
      return [];
    }
  }

  /// Fetch a single application by ID.
  Future<ProposalModel?> fetchProposal(String applicationId) async {
    try {
      final data = await _api.get('/applications/$applicationId')
          as Map<String, dynamic>;
      return ProposalModel.fromMap(data);
    } on ApiException catch (e) {
      debugPrint('Error fetching proposal: ${e.message}');
      return null;
    }
  }

  /// Accept a proposal — creates a booking and updates application status.
  Future<void> acceptProposal(String applicationId) async {
    try {
      await _api.patch('/applications/$applicationId/accept');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Reject a proposal.
  Future<void> rejectProposal(String applicationId) async {
    try {
      await _api.patch('/applications/$applicationId/reject');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}
