import 'package:flutter_test/flutter_test.dart';
import 'package:neighbors_seniors_admin/main.dart';

void main() {
  testWidgets('Admin app shows login screen', (tester) async {
    await tester.pumpWidget(const AdminApp());
    expect(find.text('Panel Administracyjny'), findsOneWidget);
    expect(find.text('Sąsiedzi & Seniorzy'), findsOneWidget);
  });
}
