import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbors_seniors/main.dart';

void main() {
  testWidgets('App startup shows loading screen', (tester) async {
    await tester.pumpWidget(const NeighborsSeniorsApp());
    expect(find.text('Sąsiedzi & Seniorzy'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
