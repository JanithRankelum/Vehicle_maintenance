class MaintenanceService {
  static String checkNextService(int mileage) {
    String service = '';

    if (mileage % 5000 == 0) {
      service += 'Oil change required\n';
    }
    if (mileage % 10000 == 0) {
      service += 'Tire rotation required\n';
    }
    if (service.isEmpty) {
      service = 'No immediate service required';
    }
    return service;
  }
}
