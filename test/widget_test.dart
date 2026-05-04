import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/pages/splash_screen.dart';

void main() {
  testWidgets('app boots into splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
