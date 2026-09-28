import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home_app/main.dart';

void main() {
  testWidgets('Smart Home login screen is displayed', (tester) async {
    await tester.pumpWidget(const SmartHomeApp());

    expect(find.text('Smart Home'), findsOneWidget);
    expect(find.text('Enter password to continue'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
