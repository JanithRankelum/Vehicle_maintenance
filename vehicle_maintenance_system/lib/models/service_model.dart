class ServiceSchedule {
  final String lastTireReplace;
  final String lastOilChange;
  final String lastService;
  final String insuranceExpiry;
  final String insuranceCompany;
  final String insurancePolicyNumber;
  final String otherMaintenance;

  ServiceSchedule({
    required this.lastTireReplace,
    required this.lastOilChange,
    required this.lastService,
    required this.insuranceExpiry,
    required this.insuranceCompany,
    required this.insurancePolicyNumber,
    required this.otherMaintenance,
  });

  // Calculate next tire replacement date (e.g., every 2 years)
  String get nextTireReplace {
    DateTime lastDate = DateTime.parse(lastTireReplace);
    DateTime nextDate = DateTime(lastDate.year + 2, lastDate.month, lastDate.day);
    return nextDate.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
  }

  // Calculate next oil change date (e.g., every 6 months)
  String get nextOilChange {
    DateTime lastDate = DateTime.parse(lastOilChange);
    DateTime nextDate = DateTime(lastDate.year, lastDate.month + 6, lastDate.day);
    return nextDate.toIso8601String().split('T')[0];
  }

  // Calculate next service date (e.g., every 1 year)
  String get nextService {
    DateTime lastDate = DateTime.parse(lastService);
    DateTime nextDate = DateTime(lastDate.year + 1, lastDate.month, lastDate.day);
    return nextDate.toIso8601String().split('T')[0];
  }

  // Update insurance details if expiry date is passed
  Map<String, dynamic> updateInsuranceDetails() {
    DateTime expiryDate = DateTime.parse(insuranceExpiry);
    if (DateTime.now().isAfter(expiryDate)) {
      return {
        'insurance_company': "New Insurance Company", // Update with new data
        'insurance_policy_number': "New Policy Number", // Update with new data
        'insurance_expiry': DateTime.now().add(Duration(days: 365)).toIso8601String().split('T')[0], // Renew for 1 year
      };
    }
    return {};
  }

  // Add maintenance entry to Firestore
  Map<String, dynamic> toMaintenanceEntry() {
    return {
      'date': DateTime.now().toIso8601String().split('T')[0],
      'last_tire_replace': lastTireReplace,
      'last_oil_change': lastOilChange,
      'last_service': lastService,
      'insurance_expiry': insuranceExpiry,
      'insurance_company': insuranceCompany,
      'insurance_policy_number': insurancePolicyNumber,
      'other_maintenance': otherMaintenance,
    };
  }
}