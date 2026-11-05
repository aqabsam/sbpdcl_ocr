import 'package:flutter/material.dart';

import '../models/employee.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final Employee employee;

  const EditProfileScreen({super.key, required this.employee});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _designationController;
  late final TextEditingController _departmentController;
  late final TextEditingController _divisionController;
  late final TextEditingController _subdivisionController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;

  bool _isSaving = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _fullNameController = TextEditingController(text: e.fullName);
    _designationController = TextEditingController(text: e.designation);
    _departmentController = TextEditingController(text: e.department);
    _divisionController = TextEditingController(text: e.division);
    _subdivisionController = TextEditingController(text: e.subdivision);
    _mobileController = TextEditingController(text: e.mobile);
    _emailController = TextEditingController(text: e.email);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    _divisionController.dispose();
    _subdivisionController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required.' : null;

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

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _formError = null;
    });

    try {
      final updated = widget.employee.copyWith(
        fullName: _fullNameController.text.trim(),
        designation: _designationController.text.trim(),
        department: _departmentController.text.trim(),
        division: _divisionController.text.trim(),
        subdivision: _subdivisionController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
      );

      final result = await AuthService.instance.updateProfile(updated);

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _formError = 'Could not update profile. Please try again.';
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
  }) {
    return TextFormField(
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
      appBar: AppBar(title: const Text('Edit Profile')),
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
                        const Text(
                          'Update Profile Information',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Employee ID — read only
                        TextFormField(
                          initialValue: widget.employee.employeeId,
                          readOnly: true,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Employee ID',
                            prefixIcon: Icon(Icons.badge_outlined),
                            suffixIcon: Icon(Icons.lock_outline, size: 18),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          label: 'Full Name',
                          controller: _fullNameController,
                          validator: (v) => _required(v, 'Full name'),
                          icon: Icons.person_outline,
                          autofillHints: const [AutofillHints.name],
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          label: 'Designation',
                          controller: _designationController,
                          validator: (v) => _required(v, 'Designation'),
                          icon: Icons.work_outline,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          label: 'Department',
                          controller: _departmentController,
                          validator: (v) => _required(v, 'Department'),
                          icon: Icons.account_balance_outlined,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          label: 'Division',
                          controller: _divisionController,
                          validator: (v) => _required(v, 'Division'),
                          icon: Icons.apartment_outlined,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          label: 'Subdivision / Section',
                          controller: _subdivisionController,
                          validator: (v) =>
                              _required(v, 'Subdivision / Section'),
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
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
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
                            onPressed: _isSaving ? null : _saveProfile,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('SAVE CHANGES'),
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
