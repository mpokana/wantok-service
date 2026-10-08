import 'wantok_backend.dart';

/// Guarded, non-activating preliminary provider onboarding.
class StagedOnboardingRepository {
  const StagedOnboardingRepository();

  Future<Map<String, dynamic>?> loadPolicy(String categoryId) async {
    final row = await WantokBackend.client
        .from('provider_onboarding_policies')
        .select('intake_status, requirements, guidance')
        .eq('category_id', categoryId)
        .maybeSingle();
    return row;
  }

  Future<Map<String, dynamic>?> loadMyApplication(String categoryId) async {
    final user = WantokBackend.client.auth.currentUser;
    if (user == null) return null;
    return WantokBackend.client
        .from('staged_provider_applications')
        .select('id, status, submitted_at, applicant_name, coverage_province')
        .eq('category_id', categoryId)
        .eq('user_id', user.id)
        .maybeSingle();
  }

  Future<void> submit({
    required String categorySlug,
    required String applicantName,
    required String applicantKind,
    required String province,
    required String town,
    required String summary,
  }) async {
    if (WantokBackend.client.auth.currentUser == null) {
      throw StateError('Sign in before submitting an application.');
    }
    await WantokBackend.client.rpc(
      'submit_staged_provider_application',
      params: {
        'p_category_slug': categorySlug,
        'p_applicant_name': applicantName,
        'p_applicant_kind': applicantKind,
        'p_coverage_province': province,
        'p_coverage_town': town,
        'p_service_summary': summary,
      },
    );
  }
}
