import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_rescuers/features/offers/presentation/screens/home_screen.dart';

void main() {
  testWidgets('Ana ekran acilir ve baslik gorunur', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Yakınındaki fırsatlar'), findsOneWidget);
  });
}