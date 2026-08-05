import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kmediwell_app/main.dart';

void main() {
  testWidgets('KMediwellApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KMediwellApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
