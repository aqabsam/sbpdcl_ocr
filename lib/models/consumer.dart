class Consumer {
  final int? id;
  final String meterNo;
  final String? caNumber;
  final String? accountNumber;
  final String? consumerName;
  final String? tariffCategory;
  final String? connectionStatus;
  final String? make;
  final String? phase;
  final String? meterType;
  final String? installationDate;
  final String? address;
  final String? village;
  final String? section;
  final String? feeder;
  final String? dtr;
  final String? poleNo;
  final double totalOutstanding;
  final double currentBill;
  final String? lastPaymentDate;
  final double lastPaymentAmount;

  Consumer({
    this.id,
    required this.meterNo,
    this.caNumber,
    this.accountNumber,
    this.consumerName,
    this.tariffCategory,
    this.connectionStatus,
    this.make,
    this.phase,
    this.meterType,
    this.installationDate,
    this.address,
    this.village,
    this.section,
    this.feeder,
    this.dtr,
    this.poleNo,
    this.totalOutstanding = 0.0,
    this.currentBill = 0.0,
    this.lastPaymentDate,
    this.lastPaymentAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'meter_no': meterNo,
      'ca_number': caNumber,
      'account_number': accountNumber,
      'consumer_name': consumerName,
      'tariff_category': tariffCategory,
      'connection_status': connectionStatus,
      'make': make,
      'phase': phase,
      'meter_type': meterType,
      'installation_date': installationDate,
      'address': address,
      'village': village,
      'section': section,
      'feeder': feeder,
      'dtr': dtr,
      'pole_no': poleNo,
      'total_outstanding': totalOutstanding,
      'current_bill': currentBill,
      'last_payment_date': lastPaymentDate,
      'last_payment_amount': lastPaymentAmount,
    };
  }

  factory Consumer.fromMap(Map<String, dynamic> map) {
    return Consumer(
      id: map['id'] as int?,
      meterNo: (map['meter_no'] as String?)?.trim() ?? '',
      caNumber: (map['ca_number'] as String?)?.trim(),
      accountNumber: (map['account_number'] as String?)?.trim(),
      consumerName: (map['consumer_name'] as String?)?.trim(),
      tariffCategory: (map['tariff_category'] as String?)?.trim(),
      connectionStatus: (map['connection_status'] as String?)?.trim(),
      make: (map['make'] as String?)?.trim(),
      phase: (map['phase'] as String?)?.trim(),
      meterType: (map['meter_type'] as String?)?.trim(),
      installationDate: (map['installation_date'] as String?)?.trim(),
      address: (map['address'] as String?)?.trim(),
      village: (map['village'] as String?)?.trim(),
      section: (map['section'] as String?)?.trim(),
      feeder: (map['feeder'] as String?)?.trim(),
      dtr: (map['dtr'] as String?)?.trim(),
      poleNo: (map['pole_no'] as String?)?.trim(),
      totalOutstanding: (map['total_outstanding'] is num)
          ? (map['total_outstanding'] as num).toDouble()
          : double.tryParse(map['total_outstanding']?.toString() ?? '0') ?? 0.0,
      currentBill: (map['current_bill'] is num)
          ? (map['current_bill'] as num).toDouble()
          : double.tryParse(map['current_bill']?.toString() ?? '0') ?? 0.0,
      lastPaymentDate: (map['last_payment_date'] as String?)?.trim(),
      lastPaymentAmount: (map['last_payment_amount'] is num)
          ? (map['last_payment_amount'] as num).toDouble()
          : double.tryParse(map['last_payment_amount']?.toString() ?? '0') ?? 0.0,
    );
  }

  bool get isDefaulter => totalOutstanding > 0.0;
  bool get isActive =>
      (connectionStatus ?? '').toUpperCase().contains('ACTIVE') &&
      !(connectionStatus ?? '').toUpperCase().contains('DISCONNECTED');
}

