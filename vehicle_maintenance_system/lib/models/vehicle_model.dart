class Vehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final int mileage;
  final int oilChangeDue;
  final int tireRotationDue;

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.mileage,
    required this.oilChangeDue,
    required this.tireRotationDue,
  });

  // Convert from Firestore
  factory Vehicle.fromMap(Map<String, dynamic> data, String documentId) {
    return Vehicle(
      id: documentId,
      make: data['make'],
      model: data['model'],
      year: data['year'],
      mileage: data['mileage'],
      oilChangeDue: data['oilChangeDue'],
      tireRotationDue: data['tireRotationDue'],
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'mileage': mileage,
      'oilChangeDue': oilChangeDue,
      'tireRotationDue': tireRotationDue,
    };
  }
}
