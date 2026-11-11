import 'package:flutter_test/flutter_test.dart';
import 'package:deep_sea_echo/main.dart';
import 'package:deep_sea_echo/ui/virtual_joystick.dart';
import 'package:deep_sea_echo/ui/sonar_button.dart';

void main() {
  testWidgets('DeepSeaEchoApp launches with canvas, joystick, and sonar controls', (WidgetTester tester) async {
    await tester.pumpWidget(const DeepSeaEchoApp());
    await tester.pump();

    // Verify presence of controls
    expect(find.byType(VirtualJoystick), findsOneWidget);
    expect(find.byType(SonarButton), findsOneWidget);
    expect(find.text('SONAR'), findsOneWidget);
    expect(find.textContaining('DEPTH:'), findsOneWidget);
  });
}
