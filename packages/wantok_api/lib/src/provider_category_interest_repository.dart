import 'wantok_backend.dart';

/// Non-commercial expression of interest for catalogue-only categories.
/// Never sends a provider application or changes verified-provider status.
class ProviderCategoryInterestRepository {
  const ProviderCategoryInterestRepository();

  Future<bool> hasRegisteredInterest(String categoryId) async {
    final user = WantokBackend.client.auth.currentUser;
    if (user == null) return false;

    final rows = await WantokBackend.client
        .from('provider_category_interests')
        .select('id')
        .eq('category_id', categoryId)
        .eq('user_id', user.id)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<void> registerInterest(String categorySlug) async {
    if (WantokBackend.client.auth.currentUser == null) {
      throw StateError('Sign in before registering provider interest.');
    }
    await WantokBackend.client.rpc(
      'register_provider_category_interest',
      params: {'p_category_slug': categorySlug},
    );
  }
}
