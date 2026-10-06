import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_tech/src/app.dart';

void main() {
  testWidgets('shows configuration guidance without backend defines', (
    tester,
  ) async {
    await tester.pumpWidget(
      const WantokTechnicalControlApp(backendConfigured: false),
    );

    expect(
      find.textContaining('Wantok Technical Control needs SUPABASE_URL'),
      findsOneWidget,
    );
  });
}
