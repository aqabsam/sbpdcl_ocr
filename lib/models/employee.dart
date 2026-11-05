class Employee {
  final int? id;
  final String employeeId;
  final String fullName;
  final String designation;
  final String department;
  final String division;
  final String subdivision;
  final String mobile;
  final String email;
  final String passwordHash;
  final String createdAt;

  const Employee({
    this.id,
    required this.employeeId,
    required this.fullName,
    required this.designation,
    required this.department,
    required this.division,
    required this.subdivision,
    required this.mobile,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'employee_id': employeeId,
        'full_name': fullName,
        'designation': designation,
        'department': department,
        'division': division,
        'subdivision': subdivision,
        'mobile': mobile,
        'email': email,
        'password_hash': passwordHash,
        'created_at': createdAt,
      };

  factory Employee.fromMap(Map<String, Object?> map) => Employee(
        id: map['id'] as int?,
        employeeId: map['employee_id'] as String,
        fullName: map['full_name'] as String,
        designation: map['designation'] as String,
        department: map['department'] as String,
        division: map['division'] as String,
        subdivision: map['subdivision'] as String,
        mobile: map['mobile'] as String,
        email: map['email'] as String,
        passwordHash: map['password_hash'] as String,
        createdAt: map['created_at'] as String,
      );

  Employee copyWith({
    int? id,
    String? employeeId,
    String? fullName,
    String? designation,
    String? department,
    String? division,
    String? subdivision,
    String? mobile,
    String? email,
    String? passwordHash,
    String? createdAt,
  }) =>
      Employee(
        id: id ?? this.id,
        employeeId: employeeId ?? this.employeeId,
        fullName: fullName ?? this.fullName,
        designation: designation ?? this.designation,
        department: department ?? this.department,
        division: division ?? this.division,
        subdivision: subdivision ?? this.subdivision,
        mobile: mobile ?? this.mobile,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        createdAt: createdAt ?? this.createdAt,
      );
}
