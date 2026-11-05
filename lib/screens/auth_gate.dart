import 'package:flutter/material.dart';

import '../models/employee.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Employee? _employee;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final employee = await AuthService.instance.initialize();
      if (!mounted) return;
      setState(() {
        _employee = employee;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to open local employee records.';
      });
    }
  }

  void _onAuthenticated(Employee employee) {
    setState(() => _employee = employee);
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (mounted) setState(() => _employee = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.storage_rounded,
                  color: AppTheme.statusDanger,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _restoreSession,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final employee = _employee;
    if (employee != null) {
      return HomeScreen(employee: employee, onLogout: _logout);
    }
    return LoginScreen(onAuthenticated: _onAuthenticated);
  }
}
