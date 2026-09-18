import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecoaudit/main.dart';

void main() {
  testWidgets('EcoAudit opens successfully', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const EcoAuditApp());
    await tester.pumpAndSettle();

    expect(find.text('EcoAudit'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
  });
}