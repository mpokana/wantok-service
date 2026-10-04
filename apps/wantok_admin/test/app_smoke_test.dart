import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_admin/src/app.dart';

void main() {
  testWidgets('shows configuration guidance without backend defines', (tester) async {
    await tester.pumpWidget(const WantokAdminApp(backendConfigured: false));

    expect(
      find.textContaining('Wantok Admin needs SUPABASE_URL'),
      findsOneWidget,
    );
  });
}
