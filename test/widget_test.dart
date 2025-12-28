import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_tracker/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LifeTrackerApp(),
      ),
    );

    // App should render without errors
    expect(find.byType(LifeTrackerApp), findsOneWidget);
  });
}
