import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/employee.dart';
import 'database_helper.dart';

class AuthService {
  static AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  static const int _defaultIterations = 600000;
  static const int _keyBits = 256;
  static const int _saltLength = 16;
  static const String _hashAlgorithm = 'pbkdf2-sha256';
  static const String _separator = r'$';
  static const String _rememberedEmployeeKey = 'remembered_employee_id';

  final int _hashIterations;

  AuthService._({this._hashIterations = _defaultIterations});

  @visibleForTesting
  static void useTestHashIterations(int iterations) {
    if (iterations < 1000 || iterations > 1000000) {
      throw ArgumentError.value(iterations, 'iterations');
    }
    _instance = AuthService._(hashIterations: iterations);
  }

  Future<Employee?> initialize() async {
    await DatabaseHelper.instance.database;
    return restoreRememberedEmployee();
  }

  Future<Employee?> restoreRememberedEmployee() async {
    final preferences = await SharedPreferences.getInstance();
    final employeeId = preferences.getString(_rememberedEmployeeKey);
    if (employeeId == null || employeeId.isEmpty) return null;

    final employee = await DatabaseHelper.instance.getEmployeeByEmployeeId(
      employeeId,
    );
    if (employee == null) {
      await preferences.remove(_rememberedEmployeeKey);
    }
    return employee;
  }

  Future<Employee?> login({
    required String employeeId,
    required String password,
    required bool rememberMe,
  }) async {
    final employee = await DatabaseHelper.instance.getEmployeeByEmployeeId(
      employeeId.trim(),
    );
    if (employee == null ||
        !await _verifyPassword(password, employee.passwordHash)) {
      return null;
    }

    final preferences = await SharedPreferences.getInstance();
    if (rememberMe) {
      await preferences.setString(_rememberedEmployeeKey, employee.employeeId);
    } else {
      await preferences.remove(_rememberedEmployeeKey);
    }
    return employee;
  }

  Future<Employee> registerEmployee({
    required String fullName,
    required String employeeId,
    required String designation,
    required String department,
    required String division,
    required String subdivision,
    required String mobile,
    required String email,
    required String password,
  }) async {
    final normalizedId = employeeId.trim().toUpperCase();
    if (await DatabaseHelper.instance.getEmployeeByEmployeeId(normalizedId) !=
        null) {
      throw const EmployeeIdAlreadyExistsException();
    }

    final employee = Employee(
      employeeId: normalizedId,
      fullName: fullName.trim(),
      designation: designation.trim(),
      department: department.trim(),
      division: division.trim(),
      subdivision: subdivision.trim(),
      mobile: mobile.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: await _hashPassword(password),
      createdAt: DateTime.now().toIso8601String(),
    );
    await DatabaseHelper.instance.insertEmployee(employee);
    return (await DatabaseHelper.instance.getEmployeeByEmployeeId(
      normalizedId,
    ))!;
  }

  Future<bool> changePassword({
    required Employee employee,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (employee.id == null) return false;
    final currentEmployee = await DatabaseHelper.instance.getEmployeeById(
      employee.id!,
    );
    if (currentEmployee == null ||
        !await _verifyPassword(currentPassword, currentEmployee.passwordHash)) {
      return false;
    }

    final newHash = await _hashPassword(newPassword);
    await DatabaseHelper.instance.updateEmployeePassword(employee.id!, newHash);
    return true;
  }

  Future<Employee?> updateProfile(Employee employee) async {
    if (employee.id == null) return null;
    await DatabaseHelper.instance.updateEmployee(employee);
    return DatabaseHelper.instance.getEmployeeById(employee.id!);
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_rememberedEmployeeKey);
  }

  Future<String> _hashPassword(String password) async {
    final salt = SecretKeyData.random(length: _saltLength).bytes;
    final key = await _pbkdf2(
      _hashIterations,
    ).deriveKeyFromPassword(password: password, nonce: salt);
    final hash = await key.extractBytes();
    return [
      _hashAlgorithm,
      '$_hashIterations',
      base64Url.encode(salt),
      base64Url.encode(hash),
    ].join(_separator);
  }

  Future<bool> _verifyPassword(String password, String encodedHash) async {
    try {
      final parts = encodedHash.split(_separator);
      if (parts.length != 4 || parts[0] != _hashAlgorithm) return false;

      final iterations = int.tryParse(parts[1]);
      if (iterations == null || iterations < 100000 || iterations > 1000000)
        return false;

      final salt = base64Url.decode(parts[2]);
      final expectedHash = base64Url.decode(parts[3]);
      if (salt.length != _saltLength || expectedHash.length != _keyBits ~/ 8)
        return false;

      final key = await _pbkdf2(
        iterations,
      ).deriveKeyFromPassword(password: password, nonce: salt);
      final actualHash = await key.extractBytes();
      return _constantTimeEquals(actualHash, expectedHash);
    } on FormatException {
      return false;
    }
  }

  Pbkdf2 _pbkdf2(int iterations) => Cryptography.instance.pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: _keyBits,
  );

  bool _constantTimeEquals(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first[index] ^ second[index];
    }
    return difference == 0;
  }
}

class EmployeeIdAlreadyExistsException implements Exception {
  const EmployeeIdAlreadyExistsException();
}
