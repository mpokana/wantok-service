import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/activity_page.dart';

void main() {
  test('normalises PostgREST embedded to-one and to-many rows', () {
    final review = <String, dynamic>{
      'id': 'review-1',
      'rating': 5,
      'title': 'Great service',
    };
    final quote = <String, dynamic>{'id': 'quote-1', 'status': 'pending'};

    expect(normalisePostgrestEmbeddedRows(review), <dynamic>[review]);
    expect(normalisePostgrestEmbeddedRows(<dynamic>[quote]), <dynamic>[quote]);
    expect(normalisePostgrestEmbeddedRows(null), isEmpty);
  });
}
