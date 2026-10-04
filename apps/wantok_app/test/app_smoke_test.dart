import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/app.dart';

void main() {
  testWidgets('shows configuration guidance without backend defines', (tester) async {
    await tester.pumpWidget(const WantokApp(backendConfigured: false));

    expect(
      find.text('Wantok backend is not configured'),
      findsOneWidget,
    );
  });
}
