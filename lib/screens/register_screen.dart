import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _designationController = TextEditingController();
  final _departmentController = TextEditingController();
  final _divisionController = TextEditingController();
  final _subdivisionController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSaving = false;
  String? _formError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    _divisionController.dispose();
    _subdivisionController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required.' : null;

  String? _validateEmployeeId(String? value) {
    final requiredError = _required(value, 'Employee ID');
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{2,31}$').hasMatch(value!.trim())) {
      return 'Use 3-32 letters, numbers, hyphens, or underscores.';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    final requiredError = _required(value, 'Mobile number');
    if (requiredError != null) return requiredError;
    final normalized = value!.replaceAll(RegExp(r'[\s()-]'), '');
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(normalized)) {
      return 'Enter a valid mobile number.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final requiredError = _required(value, 'Email address');
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^[\w.+-]+@[\w-]+(?:\.[\w-]+)+$').hasMatch(value!.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 10) return 'Use at least 10 characters.';
    return null;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _formError = null;
    });

    try {
      final employee = await AuthService.instance.registerEmployee(
        fullName: _fullNameController.text,
        employeeId: _employeeIdController.text,
        designation: _designationController.text,
        department: _departmentController.text,
        division: _divisionController.text,
        subdivision: _subdivisionController.text,
        mobile: _mobileController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: AppTheme.statusActive,
            size: 44,
          ),
          title: const Text('Registration complete'),
          content: Text('Employee ${employee.employeeId} is ready to sign in.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue to login'),
            ),
          ],
        ),
      );
      if (mounted) {
        Navigator.pop(context, employee.employeeId);
      }
    } on EmployeeIdAlreadyExistsException {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _formError = 'That employee ID is already registered.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _formError = 'Registration could not be completed. Please try again.';
        });
      }
    }
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.words,
    TextInputAction textInputAction = TextInputAction.next,
    Iterable<String>? autofillHints,
    Key? key,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Employee')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Image.asset(
                            'SBDPCL LOGO.jpg',
                            width: 68,
                            height: 68,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'SBPDCL Employee Registration',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _textField(
                          label: 'Full Name',
                          controller: _fullNameController,
                          validator: (value) => _required(value, 'Full name'),
                          icon: Icons.person_outline,
                          autofillHints: const [AutofillHints.name],
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          key: const ValueKey('register-employee-id'),
                          label: 'Employee ID',
                          controller: _employeeIdController,
                          validator: _validateEmployeeId,
                          icon: Icons.badge_outlined,
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          label: 'Designation',
                          controller: _designationController,
                          validator: (value) => _required(value, 'Designation'),
                          icon: Icons.work_outline,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          label: 'Department',
                          controller: _departmentController,
                          validator: (value) => _required(value, 'Department'),
                          icon: Icons.account_balance_outlined,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          label: 'Office / Circle',
                          controller: _divisionController,
                          validator: (value) => _required(value, 'Division'),
                          icon: Icons.apartment_outlined,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          label: 'Subdivision / Section',
                          controller: _subdivisionController,
                          validator: (value) =>
                              _required(value, 'Subdivision / Section'),
                          icon: Icons.location_city_outlined,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          label: 'Mobile Number',
                          controller: _mobileController,
                          validator: _validateMobile,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textCapitalization: TextCapitalization.none,
                          autofillHints: const [AutofillHints.telephoneNumber],
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          label: 'Email Address',
                          controller: _emailController,
                          validator: _validateEmail,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textCapitalization: TextCapitalization.none,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirmPassword
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final error = _validatePassword(value);
                            if (error != null) {
                              return error;
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                        ),
                        if (_formError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _formError!,
                            style: const TextStyle(
                              color: AppTheme.statusDanger,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _register,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('CREATE EMPLOYEE ACCOUNT'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
