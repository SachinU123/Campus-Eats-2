import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_eats_ag/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CampusEatsApp(),
      ),
    );
    // Just verify it builds without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
