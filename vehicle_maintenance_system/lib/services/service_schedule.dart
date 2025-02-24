import 'package:intl/intl.dart';

class ServiceScheduler {
  static String calculateNextService(int mileage, String lastServiceDate) {
    int nextServiceMileage = mileage + 5000;  // Service every 5000 km
    DateTime lastService = DateFormat('yyyy-MM-dd').parse(lastServiceDate);
    DateTime nextServiceDate = lastService.add(Duration(days: 180)); // 6 months
    
    return DateFormat('yyyy-MM-dd').format(nextServiceDate);
  }

  static String calculateOilChange(int mileage, String lastServiceDate) {
    int nextOilChangeMileage = mileage + 7000; // Oil change every 7000 km
    DateTime lastService = DateFormat('yyyy-MM-dd').parse(lastServiceDate);
    DateTime nextOilChangeDate = lastService.add(Duration(days: 150)); // 5 months
    
    return DateFormat('yyyy-MM-dd').format(nextOilChangeDate);
  }

  static String calculateTireReplacement(int mileage) {
    int nextTireReplaceMileage = mileage + 40000; // Replace tires every 40,000 km
    return "At $nextTireReplaceMileage km";
  }

  static String calculateInsuranceExpiry(String insuranceDate) {
    DateTime expiryDate = DateFormat('yyyy-MM-dd').parse(insuranceDate);
    return DateFormat('yyyy-MM-dd').format(expiryDate);
  }
}
