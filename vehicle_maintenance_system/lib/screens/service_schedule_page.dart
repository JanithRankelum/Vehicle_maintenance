import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:dr_vehicle/screens/noti_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

class ServiceSchedulePage extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const ServiceSchedulePage({super.key, required this.vehicleData});

  @override
  State<ServiceSchedulePage> createState() => _ServiceSchedulePageState();
}

class _ServiceSchedulePageState extends State<ServiceSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, DateTime?> _dates = {
    'insurance_expiry_date': null,
    'next_oil_change': null,
    'next_tire_replace': null,
    'next_service': null,
  };

  String? _insuranceCompany;
  String? _insurancePolicyNumber;
  String? _oilBrand;
  String? _oilViscosity;
  int? _recommendedMileage;
  String? _tireBrand;
  int? _tireRecommendedMileage;
  String? _serviceType;
  String? _otherMaintenance;
  bool isSaving = false;
  late String currentVehicleId;
  String? currentMaintenanceId;
  final NotiService _notiService = NotiService();

  // Individual timestamps for each service type
  DateTime? _lastUpdatedInsurance;
  DateTime? _lastUpdatedOil;
  DateTime? _lastUpdatedTire;
  DateTime? _lastUpdatedService;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    currentVehicleId = widget.vehicleData['vehicle_id'] ?? '';
    _loadExistingServiceData();
    _notiService.init();
  }

  Future<void> _selectDate(BuildContext context, String key) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dates[key] ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kYellow,
              onPrimary: Colors.black,
              surface: kDarkCard,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogTheme(backgroundColor: kBackground),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dates[key]) {
      final istDate = DateTime(picked.year, picked.month, picked.day, 7, 0);
      setState(() => _dates[key] = istDate);
    }
  }

  Future<void> _loadExistingServiceData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final maintenanceQuery = await FirebaseFirestore.instance
          .collection('maintenance')
          .where('user_id', isEqualTo: user.uid)
          .where('vehicle_id', isEqualTo: currentVehicleId)
          .limit(1)
          .get();

      if (maintenanceQuery.docs.isEmpty) return;

      currentMaintenanceId = maintenanceQuery.docs.first.id;

      final serviceQuery = await FirebaseFirestore.instance
          .collection('service')
          .where('user_id', isEqualTo: user.uid)
          .where('vehicle_id', isEqualTo: currentVehicleId)
          .where('maintenance_id', isEqualTo: currentMaintenanceId)
          .limit(1)
          .get();

      if (serviceQuery.docs.isNotEmpty) {
        final data = serviceQuery.docs.first.data();
        setState(() {
          _dates['insurance_expiry_date'] = _parseFirestoreDate(data['insurance_expiry_date']);
          _dates['next_oil_change'] = _parseFirestoreDate(data['next_oil_change']);
          _dates['next_tire_replace'] = _parseFirestoreDate(data['next_tire_replace']);
          _dates['next_service'] = _parseFirestoreDate(data['next_service']);
          
          _insuranceCompany = data['insurance_company'];
          _insurancePolicyNumber = data['insurance_policy_number'];
          _oilBrand = data['oil_brand'];
          _oilViscosity = data['oil_viscosity'];
          _recommendedMileage = data['recommended_mileage']?.toInt();
          _tireBrand = data['tire_brand'];
          _tireRecommendedMileage = data['tire_recommended_mileage']?.toInt();
          _serviceType = data['service_type'];
          _otherMaintenance = data['other_maintenance'];
          
          // Load individual timestamps
          _lastUpdatedInsurance = _parseFirestoreDate(data['last_updated_insurance']);
          _lastUpdatedOil = _parseFirestoreDate(data['last_updated_oil']);
          _lastUpdatedTire = _parseFirestoreDate(data['last_updated_tire']);
          _lastUpdatedService = _parseFirestoreDate(data['last_updated_service']);
        });
      }
    } catch (e) {
      debugPrint('Error loading service data: $e');
      _showError('Error loading service data');
    }
  }

  DateTime? _parseFirestoreDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is DateTime) return date;
    return null;
  }

  Future<void> _saveDateToFirestore(String key, String label) async {
    if (_dates[key] == null) {
      _showError('Please select a date first');
      return;
    }

    setState(() => isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || currentMaintenanceId == null) return;

      final serviceData = {
        key: Timestamp.fromDate(_dates[key]!),
        'updated_at': FieldValue.serverTimestamp(),
        'user_id': user.uid,
        'vehicle_id': currentVehicleId,
        'maintenance_id': currentMaintenanceId,
      };

      // Add the specific last_updated field based on the key
      if (key == 'insurance_expiry_date') {
        serviceData['last_updated_insurance'] = FieldValue.serverTimestamp();
      } else if (key == 'next_oil_change') {
        serviceData['last_updated_oil'] = FieldValue.serverTimestamp();
      } else if (key == 'next_tire_replace') {
        serviceData['last_updated_tire'] = FieldValue.serverTimestamp();
      } else if (key == 'next_service') {
        serviceData['last_updated_service'] = FieldValue.serverTimestamp();
      }

      final query = await FirebaseFirestore.instance
          .collection('service')
          .where('user_id', isEqualTo: user.uid)
          .where('vehicle_id', isEqualTo: currentVehicleId)
          .where('maintenance_id', isEqualTo: currentMaintenanceId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(serviceData);
        _showSuccess('$label updated successfully!');
        
        // Update the corresponding last_updated timestamp in state
        if (key == 'insurance_expiry_date') {
          setState(() => _lastUpdatedInsurance = DateTime.now());
        } else if (key == 'next_oil_change') {
          setState(() => _lastUpdatedOil = DateTime.now());
        } else if (key == 'next_tire_replace') {
          setState(() => _lastUpdatedTire = DateTime.now());
        } else if (key == 'next_service') {
          setState(() => _lastUpdatedService = DateTime.now());
        }
        
        await _notiService.cancelSingleNotification(currentVehicleId, key);
        if (_dates[key]!.isAfter(DateTime.now())) {
          await _notiService.schedule(
            vehicleId: currentVehicleId,
            serviceType: key,
            scheduledDate: _dates[key]!,
            title: '$label Reminder',
            body: 'Time to perform $label for ${widget.vehicleData['model']}',
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('service').add({
          ...serviceData,
          'created_at': FieldValue.serverTimestamp(),
          'insurance_company': _insuranceCompany ?? '',
          'insurance_policy_number': _insurancePolicyNumber ?? '',
          'oil_brand': _oilBrand ?? '',
          'oil_viscosity': _oilViscosity ?? '',
          'recommended_mileage': _recommendedMileage ?? 0,
          'tire_brand': _tireBrand ?? '',
          'tire_recommended_mileage': _tireRecommendedMileage ?? 0,
          'service_type': _serviceType ?? '',
          'other_maintenance': _otherMaintenance ?? '',
        });
        _showSuccess('$label created successfully!');
      }
    } catch (e) {
      debugPrint('Error saving $label: $e');
      _showError('Failed to save $label');
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _updateInsuranceDetails() async {
    final companyController = TextEditingController(text: _insuranceCompany);
    final policyController = TextEditingController(text: _insurancePolicyNumber);
    DateTime? selectedDate = _dates['insurance_expiry_date'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: kDarkCard,
              title: Text('Update Insurance Details', style: TextStyle(color: kYellow)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: companyController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Insurance Company',
                        labelStyle: TextStyle(color: kYellow),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kYellow),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: policyController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Policy Number',
                        labelStyle: TextStyle(color: kYellow),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kYellow),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        selectedDate != null
                            ? 'Expiry: ${DateFormat('MMM d, y').format(selectedDate!)}'
                            : 'Select Expiry Date',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: Icon(Icons.calendar_today, color: kYellow),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: kYellow,
                                  onPrimary: Colors.black,
                                  surface: kDarkCard,
                                  onSurface: Colors.white,
                                ),
                                dialogTheme: const DialogTheme(backgroundColor: kBackground),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = DateTime(picked.year, picked.month, picked.day, 7, 0);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: kYellow)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (companyController.text.isEmpty || 
                        policyController.text.isEmpty || 
                        selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _insuranceCompany = companyController.text;
                      _insurancePolicyNumber = policyController.text;
                      _dates['insurance_expiry_date'] = selectedDate;
                    });

                    await _saveInsuranceDetails(
                      companyController.text,
                      policyController.text,
                      selectedDate!,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kYellow,
                    foregroundColor: Colors.black,
                  ),
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveInsuranceDetails(
    String company, 
    String policyNumber, 
    DateTime expiryDate,
  ) async {
    setState(() => isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || currentMaintenanceId == null) {
        _showError('Authentication or maintenance record issue');
        return;
      }

      final serviceData = {
        'insurance_expiry_date': Timestamp.fromDate(expiryDate),
        'insurance_company': company,
        'insurance_policy_number': policyNumber,
        'last_updated_insurance': FieldValue.serverTimestamp(), // Only this timestamp
        'updated_at': FieldValue.serverTimestamp(),
        'user_id': user.uid,
        'vehicle_id': currentVehicleId,
        'maintenance_id': currentMaintenanceId,
      };

      final query = await FirebaseFirestore.instance
          .collection('service')
          .where('user_id', isEqualTo: user.uid)
          .where('vehicle_id', isEqualTo: currentVehicleId)
          .where('maintenance_id', isEqualTo: currentMaintenanceId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(serviceData);
        setState(() => _lastUpdatedInsurance = DateTime.now());
        _showSuccess('Insurance details saved successfully!');
        
        await _notiService.cancelSingleNotification(currentVehicleId, 'insurance_expiry_date');
        if (expiryDate.isAfter(DateTime.now())) {
          await _notiService.schedule(
            vehicleId: currentVehicleId,
            serviceType: 'insurance_expiry_date',
            scheduledDate: expiryDate,
            title: 'Insurance Expiry Reminder',
            body: 'Insurance for ${widget.vehicleData['model']} expires soon!',
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('service').add({
          ...serviceData,
          'created_at': FieldValue.serverTimestamp(),
        });
        setState(() => _lastUpdatedInsurance = DateTime.now());
        _showSuccess('Insurance details created successfully!');
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving insurance: $e');
      debugPrint('Stack trace: $stackTrace');
      _showError('Failed to save insurance details. Please try again.');
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _updateOilChangeDetails() async {
    final oilBrandController = TextEditingController(text: _oilBrand);
    final viscosityController = TextEditingController(text: _oilViscosity);
    final mileageController = TextEditingController(
      text: _recommendedMileage?.toString() ?? ''
    );
    DateTime? selectedDate = _dates['next_oil_change'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: kDarkCard,
              title: Text('Update Oil Change Details', 
                  style: TextStyle(color: kYellow)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: oilBrandController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Oil Brand',
                        labelStyle: TextStyle(color: kYellow),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kYellow),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: viscosityController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Viscosity Grade (e.g., 5W-30)',
                        labelStyle: TextStyle(color: kYellow),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kYellow),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: mileageController,
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Recommended Mileage',
                        labelStyle: TextStyle(color: kYellow),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kYellow),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        selectedDate != null
                            ? 'Next Change: ${DateFormat('MMM d, y').format(selectedDate!)}'
                            : 'Select Next Change Date',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: Icon(Icons.calendar_today, color: kYellow),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: kYellow,
                                  onPrimary: Colors.black,
                                  surface: kDarkCard,
                                  onSurface: Colors.white,
                                ),
                                dialogTheme: const DialogTheme(backgroundColor: kBackground),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = DateTime(picked.year, picked.month, picked.day, 7, 0);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: kYellow)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (oilBrandController.text.isEmpty || 
                        viscosityController.text.isEmpty || 
                        mileageController.text.isEmpty ||
                        selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _oilBrand = oilBrandController.text;
                      _oilViscosity = viscosityController.text;
                      _recommendedMileage = int.tryParse(mileageController.text) ?? 0;
                      _dates['next_oil_change'] = selectedDate;
                    });

                    await _saveOilChangeDetails(
                      oilBrandController.text,
                      viscosityController.text,
                      int.tryParse(mileageController.text) ?? 0,
                      selectedDate!,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kYellow,
                    foregroundColor: Colors.black,
                  ),
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveOilChangeDetails(
    String oilBrand,
    String viscosity,
    int recommendedMileage,
    DateTime nextChangeDate,
  ) async {
    setState(() => isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || currentMaintenanceId == null) {
        _showError('Authentication or maintenance record issue');
        return;
      }

      final serviceData = {
        'next_oil_change': Timestamp.fromDate(nextChangeDate),
        'oil_brand': oilBrand,
        'oil_viscosity': viscosity,
        'recommended_mileage': recommendedMileage,
        'last_updated_oil': FieldValue.serverTimestamp(), // Only this timestamp
        'updated_at': FieldValue.serverTimestamp(),
        'user_id': user.uid,
        'vehicle_id': currentVehicleId,
        'maintenance_id': currentMaintenanceId,
      };

      final query = await FirebaseFirestore.instance
          .collection('service')
          .where('user_id', isEqualTo: user.uid)
          .where('vehicle_id', isEqualTo: currentVehicleId)
          .where('maintenance_id', isEqualTo: currentMaintenanceId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(serviceData);
        setState(() => _lastUpdatedOil = DateTime.now());
        _showSuccess('Oil change details saved successfully!');
        
        await _notiService.cancelSingleNotification(currentVehicleId, 'next_oil_change');
        if (nextChangeDate.isAfter(DateTime.now())) {
          await _notiService.schedule(
            vehicleId: currentVehicleId,
            serviceType: 'next_oil_change',
            scheduledDate: nextChangeDate,
            title: 'Oil Change Reminder',
            body: 'Time to change oil for ${widget.vehicleData['model']}',
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('service').add({
          ...serviceData,
          'created_at': FieldValue.serverTimestamp(),
        });
        setState(() => _lastUpdatedOil = DateTime.now());
        _showSuccess('Oil change details created successfully!');
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving oil change: $e');
      debugPrint('Stack trace: $stackTrace');
      _showError('Failed to save oil change details. Please try again.');
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _updateTireReplacementDetails() async {
    final tireBrandController = TextEditingController(text: _tireBrand);
    final mileageController = TextEditingController(
      text: _tireRecommendedMileage?.toString() ?? ''
    );
    DateTime? selectedDate = _dates['next_tire_replace'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: kDarkCard,
              title: Text('Update Tire Replacement Details', 
                  style: TextStyle(color: kYellow)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: tireBrandController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Tire Brand',
                        labelStyle: TextStyle(color: kYellow),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kYellow),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: mileageController,
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Recommended Mileage',
                        labelStyle: TextStyle(color: kYellow),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kYellow),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        selectedDate != null
                            ? 'Next Replacement: ${DateFormat('MMM d, y').format(selectedDate!)}'
                            : 'Select Next Replacement Date',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: Icon(Icons.calendar_today, color: kYellow),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: kYellow,
                                  onPrimary: Colors.black,
                                  surface: kDarkCard,
                                  onSurface: Colors.white,
                                ),
                                dialogTheme: const DialogTheme(backgroundColor: kBackground),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = DateTime(picked.year, picked.month, picked.day, 7, 0);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: kYellow)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (tireBrandController.text.isEmpty || 
                        mileageController.text.isEmpty ||
                        selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _tireBrand = tireBrandController.text;
                      _tireRecommendedMileage = int.tryParse(mileageController.text) ?? 0;
                      _dates['next_tire_replace'] = selectedDate;
                    });

                    await _saveTireReplacementDetails(
                      tireBrandController.text,
                      int.tryParse(mileageController.text) ?? 0,
                      selectedDate!,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kYellow,
                    foregroundColor: Colors.black,
                  ),
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveTireReplacementDetails(
    String tireBrand,
    int recommendedMileage,
    DateTime nextReplacementDate,
  ) async {
    setState(() => isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || currentMaintenanceId == null) {
        _showError('Authentication or maintenance record issue');
        return;
      }

      final serviceData = {
        'next_tire_replace': Timestamp.fromDate(nextReplacementDate),
        'tire_brand': tireBrand,
        'tire_recommended_mileage': recommendedMileage,
        'last_updated_tire': FieldValue.serverTimestamp(), // Only this timestamp
        'updated_at': FieldValue.serverTimestamp(),
        'user_id': user.uid,
        'vehicle_id': currentVehicleId,
        'maintenance_id': currentMaintenanceId,
      };

      final query = await FirebaseFirestore.instance
          .collection('service')
          .where('user_id', isEqualTo: user.uid)
          .where('vehicle_id', isEqualTo: currentVehicleId)
          .where('maintenance_id', isEqualTo: currentMaintenanceId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(serviceData);
        setState(() => _lastUpdatedTire = DateTime.now());
        _showSuccess('Tire replacement details saved successfully!');
        
        await _notiService.cancelSingleNotification(currentVehicleId, 'next_tire_replace');
        if (nextReplacementDate.isAfter(DateTime.now())) {
          await _notiService.schedule(
            vehicleId: currentVehicleId,
            serviceType: 'next_tire_replace',
            scheduledDate: nextReplacementDate,
            title: 'Tire Replacement Reminder',
            body: 'Time to replace tires for ${widget.vehicleData['model']}',
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('service').add({
          ...serviceData,
          'created_at': FieldValue.serverTimestamp(),
        });
        setState(() => _lastUpdatedTire = DateTime.now());
        _showSuccess('Tire replacement details created successfully!');
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving tire replacement: $e');
      debugPrint('Stack trace: $stackTrace');
      _showError('Failed to save tire replacement details. Please try again.');
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _updateServiceDetails() async {
    final serviceTypeController = TextEditingController(text: _serviceType);
    final otherMaintenanceController = TextEditingController(text: _otherMaintenance);
    DateTime? selectedDate = _dates['next_service'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: kDarkCard,
              title: Text('Update Service Details', 
                  style: TextStyle(color: kYellow)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: serviceTypeController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Service Type',
                        labelStyle: TextStyle(color: kYellow),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kYellow),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: otherMaintenanceController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Other Maintenance',
                        labelStyle: TextStyle(color: kYellow),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kYellow),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        selectedDate != null
                            ? 'Next Service: ${DateFormat('MMM d, y').format(selectedDate!)}'
                            : 'Select Next Service Date',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: Icon(Icons.calendar_today, color: kYellow),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: kYellow,
                                  onPrimary: Colors.black,
                                  surface: kDarkCard,
                                  onSurface: Colors.white,
                                ),
                                dialogTheme: const DialogTheme(backgroundColor: kBackground),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = DateTime(picked.year, picked.month, picked.day, 7, 0);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: kYellow)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (serviceTypeController.text.isEmpty || 
                        selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _serviceType = serviceTypeController.text;
                      _otherMaintenance = otherMaintenanceController.text;
                      _dates['next_service'] = selectedDate;
                    });

                    await _saveServiceDetails(
                      serviceTypeController.text,
                      otherMaintenanceController.text,
                      selectedDate!,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kYellow,
                    foregroundColor: Colors.black,
                  ),
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveServiceDetails(
    String serviceType,
    String otherMaintenance,
    DateTime nextServiceDate,
  ) async {
    setState(() => isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || currentMaintenanceId == null) {
        _showError('Authentication or maintenance record issue');
        return;
      }

      final serviceData = {
        'next_service': Timestamp.fromDate(nextServiceDate),
        'service_type': serviceType,
        'other_maintenance': otherMaintenance,
        'last_updated_service': FieldValue.serverTimestamp(), // Only this timestamp
        'updated_at': FieldValue.serverTimestamp(),
        'user_id': user.uid,
        'vehicle_id': currentVehicleId,
        'maintenance_id': currentMaintenanceId,
      };

      final query = await FirebaseFirestore.instance
          .collection('service')
          .where('user_id', isEqualTo: user.uid)
          .where('vehicle_id', isEqualTo: currentVehicleId)
          .where('maintenance_id', isEqualTo: currentMaintenanceId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(serviceData);
        setState(() => _lastUpdatedService = DateTime.now());
        _showSuccess('Service details saved successfully!');
        
        await _notiService.cancelSingleNotification(currentVehicleId, 'next_service');
        if (nextServiceDate.isAfter(DateTime.now())) {
          await _notiService.schedule(
            vehicleId: currentVehicleId,
            serviceType: 'next_service',
            scheduledDate: nextServiceDate,
            title: 'Service Reminder',
            body: 'Time for ${serviceType.isEmpty ? 'scheduled' : serviceType} service for ${widget.vehicleData['model']}',
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('service').add({
          ...serviceData,
          'created_at': FieldValue.serverTimestamp(),
        });
        setState(() => _lastUpdatedService = DateTime.now());
        _showSuccess('Service details created successfully!');
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving service: $e');
      debugPrint('Stack trace: $stackTrace');
      _showError('Failed to save service details. Please try again.');
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _setReminders() async {
    try {
      final now = DateTime.now();
      final vehicleModel = widget.vehicleData['model'] ?? 'your vehicle';
      final vehicleNumber = widget.vehicleData['vehicle_number'] ?? '';

      await _notiService.cancelAllForVehicle(currentVehicleId);

      final reminders = {
        'insurance_expiry_date': {
          'title': '🛡 Insurance Expiry Reminder',
          'body': 'Insurance for $vehicleModel ($vehicleNumber) expires soon!'
        },
        'next_oil_change': {
          'title': '🛢 Oil Change Reminder',
          'body': 'Time to change oil for $vehicleModel ($vehicleNumber)'
        },
        'next_tire_replace': {
          'title': '𖣐 Tire Replacement Reminder',
          'body': 'Time to replace tires on $vehicleModel ($vehicleNumber)'
        },
        'next_service': {
          'title': '🛠 Service Reminder',
          'body': 'Scheduled service for $vehicleModel ($vehicleNumber)'
        },
      };

      for (final key in _dates.keys) {
        final date = _dates[key];
        if (date != null && date.isAfter(now)) {
          await _notiService.schedule(
            vehicleId: currentVehicleId,
            serviceType: key,
            scheduledDate: date,
            title: reminders[key]!['title']!,
            body: reminders[key]!['body']!,
          );
        }
      }
      _showSuccess('Reminders set successfully!');
    } catch (e) {
      debugPrint('Error setting reminders: $e');
      _showError('Failed to set reminders');
    }
  }

  Widget _buildDateTile(String label, String key) {
    final isOverdue = _dates[key]?.isBefore(DateTime.now()) ?? false;
    DateTime? lastUpdated;
    String lastUpdatedText = 'Not updated yet';

    // Determine which timestamp to show based on the key
    switch (key) {
      case 'insurance_expiry_date':
        lastUpdated = _lastUpdatedInsurance;
        break;
      case 'next_oil_change':
        lastUpdated = _lastUpdatedOil;
        break;
      case 'next_tire_replace':
        lastUpdated = _lastUpdatedTire;
        break;
      case 'next_service':
        lastUpdated = _lastUpdatedService;
        break;
    }

    if (lastUpdated != null) {
      lastUpdatedText = 'Last updated: ${DateFormat('MMM d, y h:mm a').format(lastUpdated)}';
    }

    return Container(
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red[900]?.withOpacity(0.3) : kDarkCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            title: Text(
              label,
              style: TextStyle(
                color: kYellow,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dates[key] != null
                      ? 'Scheduled: ${DateFormat('MMM d, y h:mm a').format(_dates[key]!)}'
                      : 'Not scheduled',
                  style: TextStyle(
                    color: isOverdue ? Colors.red[300] : Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastUpdatedText,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                if (key == 'insurance_expiry_date' && _insuranceCompany != null)
                  Text(
                    'Company: $_insuranceCompany',
                    style: TextStyle(color: Colors.grey),
                  ),
                if (key == 'insurance_expiry_date' && _insurancePolicyNumber != null)
                  Text(
                    'Policy: $_insurancePolicyNumber',
                    style: TextStyle(color: Colors.grey),
                  ),
                if (key == 'next_oil_change' && _oilBrand != null)
                  Text(
                    'Brand: $_oilBrand (${_oilViscosity ?? ''})',
                    style: TextStyle(color: Colors.grey),
                  ),
                if (key == 'next_oil_change' && _recommendedMileage != null)
                  Text(
                    'Mileage: $_recommendedMileage km',
                    style: TextStyle(color: Colors.grey),
                  ),
                if (key == 'next_tire_replace' && _tireBrand != null)
                  Text(
                    'Brand: $_tireBrand',
                    style: TextStyle(color: Colors.grey),
                  ),
                if (key == 'next_tire_replace' && _tireRecommendedMileage != null)
                  Text(
                    'Mileage: $_tireRecommendedMileage km',
                    style: TextStyle(color: Colors.grey),
                  ),
                if (key == 'next_service' && _serviceType != null)
                  Text(
                    'Type: $_serviceType',
                    style: TextStyle(color: Colors.grey),
                  ),
                if (key == 'next_service' && _otherMaintenance != null)
                  Text(
                    'Other: $_otherMaintenance',
                    style: TextStyle(color: Colors.grey),
                  ),
                if (isOverdue && _dates[key] != null)
                  Text(
                    'OVERDUE!',
                    style: TextStyle(
                      color: Colors.red[300],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit, color: kYellow),
              onPressed: () {
                if (key == 'insurance_expiry_date') {
                  _updateInsuranceDetails();
                } else if (key == 'next_oil_change') {
                  _updateOilChangeDetails();
                } else if (key == 'next_tire_replace') {
                  _updateTireReplacementDetails();
                } else if (key == 'next_service') {
                  _updateServiceDetails();
                } else {
                  _selectDate(context, key);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (key == 'insurance_expiry_date') {
                      _updateInsuranceDetails();
                    } else if (key == 'next_oil_change') {
                      _updateOilChangeDetails();
                    } else if (key == 'next_tire_replace') {
                      _updateTireReplacementDetails();
                    } else if (key == 'next_service') {
                      _updateServiceDetails();
                    } else if (_dates[key] != null) {
                      _saveDateToFirestore(key, label);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOverdue ? Colors.red : kYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isOverdue ? 'UPDATE NOW' : 'UPDATE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text(
          'Service Schedule - ${widget.vehicleData['model']}',
          style: const TextStyle(
            color: kYellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBackground,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: kYellow),
            onPressed: isSaving ? null : _setReminders,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDateTile("Insurance Expiry Date", "insurance_expiry_date"),
            _buildDateTile("Next Oil Change", "next_oil_change"),
            _buildDateTile("Next Tire Replacement", "next_tire_replace"),
            _buildDateTile("Next Service", "next_service"),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.notifications_active),
              label: const Text(
                "SET ALL REMINDERS",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kYellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _setReminders,
            ),
            if (isSaving)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: CircularProgressIndicator(color: kYellow),
                ),
              ),
          ],
        ),
      ),
    );
  }
}