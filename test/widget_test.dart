import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sbpdcl_ocr_app/screens/auth_gate.dart';
import 'package:sbpdcl_ocr_app/screens/home_screen.dart';
import 'package:sbpdcl_ocr_app/screens/login_screen.dart';
import 'package:sbpdcl_ocr_app/services/auth_service.dart';
import 'package:sbpdcl_ocr_app/services/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AuthService.useTestHashIterations(100000);
  });

  testWidgets('login screen validates required credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onAuthenticated: (_) {})),
    );

    expect(find.text('Employee Sign In'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('login-button')));
    await tester.pump();

    expect(find.text('Enter your employee ID.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(find.text('Register New Employee'), findsOneWidget);
  });

  testWidgets('existing SBPDCL Home Dashboard still renders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('SBPDCL'), findsOneWidget);
    expect(find.text('Scan Meter Serial No.'), findsOneWidget);
    expect(find.text('Import CSV'), findsOneWidget);
    expect(find.text('Inspection Logs'), findsOneWidget);
  });

  testWidgets('registration form is available from the initial login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onAuthenticated: (_) {})),
    );
    await tester.tap(find.text('Register New Employee'));
    await tester.pumpAndSettle();
    expect(find.text('SBPDCL Employee Registration'), findsOneWidget);
    expect(find.text('Office / Circle'), findsOneWidget);
    expect(find.text('Employee ID'), findsOneWidget);
  });

  testWidgets('registered employee can log in, restore session, and log out', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.instance.initialize();
    final database = await DatabaseHelper.instance.database;
    await database.delete(
      'employees',
      where: 'employee_id = ?',
      whereArgs: ['WIDGET-FLOW-01'],
    );
    await AuthService.instance.registerEmployee(
      fullName: 'Widget Test Employee',
      employeeId: 'WIDGET-FLOW-01',
      designation: 'Field Officer',
      department: 'Operations',
      division: 'Patna Circle',
      subdivision: 'Patna West',
      mobile: '9876543210',
      email: 'widget-flow@example.in',
      password: 'WidgetFlowPassword!2026',
    );

    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    await tester.pumpAndSettle();
    expect(find.text('Employee Sign In'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('employee-id-input')),
      'WIDGET-FLOW-01',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-input')),
      'WidgetFlowPassword!2026',
    );
    await tester.tap(find.byKey(const ValueKey('login-button')));
    await tester.pumpAndSettle();
    expect(find.text('Scan Meter Serial No.'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    await tester.pumpAndSettle();
    expect(find.text('Scan Meter Serial No.'), findsOneWidget);

    await tester.tap(find.byTooltip('Employee account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Employee Sign In'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    await tester.pumpAndSettle();
    expect(find.text('Employee Sign In'), findsOneWidget);
  });
}
