import 'package:cloud_firestore/cloud_firestore.dart';

/// This file is a package for salary and business income routes to use.
/// Without the proper input from either, this package may not function
/// as intended.


class Records{

  static WeekRecord selectedWeek = WeekRecord();

  /// === METHODS === ///
  void currToRecord(){
    //End-link to refreshCurr()
  }

  void refreshCurr(){

  }

  void saveToRecord(){
    //Check for if current week, if so then do following method instead
  }

  void saveToCurr(){

  }

}

class WeekRecord{
  Map<String, double> payments;
  List<Map<String, dynamic>> employeesWorked;

  double netTotal;
  double tipTotal;

  WeekRecord({
    this.payments = const {
      'VAT': 0,
      'card': 0,
      'cash': 0,
      'serviceCharge': 0,
    },
    this.employeesWorked = const [{
      'employeeID': "Test_Employee",
      'hoursRate': 0.0,
      'hoursWorked': 0.0,
      'tipDistribution': 0.0,
      'workedDays': [false, false, false, false, false, false, false],
    }],
    this.netTotal = 0,
    this.tipTotal = 0,
  });

  void printAll(){
    print('Payments: ${payments},\nEmployeesWorked: ');
    employeesWorked.forEach(print);
    print('Net Total: ${netTotal}\nTip Total: ${tipTotal}');
  }

  factory WeekRecord.fromFirestore(DocumentSnapshot doc, {bool currentWeek = false}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    // Helper function to safely parse a value to double
    double safeParseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    void printReturned(){
      print('${(data['Payments'] as Map).cast<String, double>()} payments');
      print(data['employeesWorked']);
      print('${safeParseDouble(data['netTotal'])}');
      print('${safeParseDouble(data['tipTotal'])}');
    }


    return WeekRecord(
      payments: (data['Payments'] as Map).cast<String, double>(),
      employeesWorked: (data['employeesWorked'] as List)
          .map((item) => item as Map<String, dynamic>)
          .toList(),
      netTotal: safeParseDouble(data['netTotal']),
      tipTotal: safeParseDouble(data['tipTotal']),
    );
  }
}
