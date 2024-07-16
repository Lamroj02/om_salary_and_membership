import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:om_salary_and_membership/records.dart';
import 'dart:math';
import 'dart:async';

//Instantiates firestore database for use within flutter application
final db = FirebaseFirestore.instance;



/// === CLASSES === ///
//#region
class Employee{
  final String id;
  final String name;
  double hoursRate;
  bool isStudent;

  Employee({
    required this.id,
    required this.name,
    required this.hoursRate,
    required this.isStudent,});

  /*/#region === METHODS ===
  double sumHoursWeek(){

    return hoursWeek.fold<double>(
        0, (previousValue, element) => previousValue + element
    );
  }

  double sumEarnedWeek({bool useTips = true}){
    return hoursRate * sumHoursWeek() + (useTips ? tipsWeek : 0);
  }



  *///#endregion

  factory Employee.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Helper function to safely parse a value to double
    double safeParseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }


    return Employee(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      hoursRate: safeParseDouble(data['hoursRate']),
      isStudent: data['isStudent'] ?? false,
    );
  }

}



class SalaryHomePage extends StatefulWidget {
  const SalaryHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<SalaryHomePage> createState() => _SalaryHomePageState();
}
//#endregion

/// === METHODS === ///
//#region


Future<void> addEmployee(Employee employee) async {
  try {
    await db.collection('Employees').add({
      'name': employee.name,
      'isStudent': employee.isStudent,
      'hoursRate': employee.hoursRate,
    });
    print('Employee added successfully');
  } catch (e) {
    print('Error adding employee: $e');
  }
}

//Updates on save button tap - prior to tap, any updated employees are copied to a
//separate array<Employee> with updated details, then on save, update using array then clears.
Future<void> updateEmployee(String docId, Map<String, dynamic> updatedFields) async {
  try {
    await FirebaseFirestore.instance.collection('Employees').doc(docId).update(updatedFields);
    print('Employee updated successfully');
  } catch (e) {
    print('Error updating employee: $e');
  }
}

DateTime getFirstDateOfCurrentWeek(DateTime date) {
  int currentWeekday = date.weekday;
  DateTime firstDateOfWeek = date.subtract(Duration(days: currentWeekday - 1));

  return DateTime(firstDateOfWeek.year, firstDateOfWeek.month, firstDateOfWeek.day);
}

Employee? findEmployeeById(List<Employee> empList, String searchId) {
  return empList.firstWhere(
        (employee) => employee.id == searchId,
  );
}



Map<String,dynamic> findEmployeesRecord(List<Employee> empListFiltered, int index){
  print("A");
  return
    Records.selectedWeek.employeesWorked.firstWhere((employee) => employee['employeeID'] == empListFiltered[index].id,

      orElse: null,
    );
}


//#endregion

class _SalaryHomePageState extends State<SalaryHomePage> {

  List<Employee> empList = [];
  List<Employee> empListWorked = [];
  List<Employee> empListFiltered = [];
  late Employee _selectedEmployee;
  int catchCount = 0;
  bool dayOrWeek = true;
  String dayOfWeek = '';

  //Calendar Variables
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;



  /// === OVERRIDES === ///
  //#region
  @override
  void initState() {
    super.initState();

    dbFetchEmployees().then((_){
      findWorkingEmployees();
    });
  }

 @override
  void dispose(){
    super.dispose();
  }

  Future<void> dbFetchEmployees() async {
    try {
      final QuerySnapshot event = await db.collection("Employees").get();
      setState(() {
        empList = event.docs.map((doc) => Employee.fromFirestore(doc)).toList();
      });
      //addTestRecords('2024-07-15');
    } catch (e) {
      print("Error fetching employee data: $e ~ dbFetchEmployees(else)");
      // Handle the error appropriately, e.g., show a user-friendly message
    }
  }

  Future<void> dbFetchRecord(String documentId) async {
    try {
      final DocumentSnapshot doc = await db.collection("Records").doc(documentId).get();
      if (doc.exists) {
        setState(() {
          Records.selectedWeek = WeekRecord.fromFirestore(doc);
        });
      }
      else {
        print("No such document! ~ dbFetchRecord(else)");
        // Handle the case where the document doesn't exist, e.g., show a user-friendly message
        setState((){
          Records.selectedWeek = WeekRecord();
        });
      }
    }
    catch (e) {
      catchCount++;
      print("Error fetching record data: $e ~ dbFetchRecord(catch) - catchCount: $catchCount");
      // Handle the error appropriately, e.g., show a user-friendly message
      setState((){
        Records.selectedWeek = WeekRecord();
      });
    }
  }

  void findWorkingEmployees() async {
    empListWorked = [];
    await dbFetchRecord(getFirstDateOfCurrentWeek(_selectedDay).toString().split(' ')[0]);

    for (int i = 0; i < Records.selectedWeek.employeesWorked.length; i++){
      for(int j = 0; j < empList.length; j++){
        if(empList[j].id == Records.selectedWeek.employeesWorked[i]['employeeID']){
          empListWorked.add(empList[j]);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      empListFiltered = empListWorked;
    });
  }

  String weekIndexToDay(int weekday){
    switch(weekday){
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      default:
        return 'Sunday';
    }
  }

  Future<void> addTestRecords(String cursorTime) async {
    try {
      int card = Random().nextInt(1000) + 50;
      int cash = Random().nextInt(1000) + 50;
      double serviceCharge = (card + cash) * 0.1;
      double vat = (card + cash + serviceCharge) * 0.2;

      List<String> employeeIDs = [
        empList[Random().nextInt(empList.length)].id,
        empList[Random().nextInt(empList.length)].id,
        empList[Random().nextInt(empList.length)].id,
        empList[Random().nextInt(empList.length)].id,
      ];

      double netTotal = (card + cash + (serviceCharge * 0.2)) - vat;
      double tipTotal = (Random().nextDouble() * 200).truncateToDouble() + 50;


      db.collection('Records').doc(cursorTime).set({
          'Payments': {
            'VAT': vat,
            'card': card,
            'cash': cash,
            'serviceCharge': serviceCharge,
          },
          'employeesWorked': [{
            'employeeID': employeeIDs[0],
            'hoursRate': (Random().nextDouble()*5).truncateToDouble()+7,
            'hoursWorked': (Random().nextDouble()*30).truncateToDouble()+7,
            'tipDistribution': 0.0,
            'workedDays': [false, false, false, false, false, false, false],
          },
          {
            'employeeID': employeeIDs[1],
            'hoursRate': (Random().nextDouble()*5).truncateToDouble()+7,
            'hoursWorked': (Random().nextDouble()*30).truncateToDouble()+7,
            'tipDistribution': 0.0,
            'workedDays': [false, false, false, false, false, false, false],
          },
          {
            'employeeID': employeeIDs[2],
            'hoursRate': (Random().nextDouble()*5).truncateToDouble()+7,
            'hoursWorked': (Random().nextDouble()*30).truncateToDouble()+7,
            'tipDistribution': 0.0,
            'workedDays': [false, false, false, false, false, false, false],
          },
          {
            'employeeID': employeeIDs[3],
            'hoursRate': (Random().nextDouble()*5).truncateToDouble()+7,
            'hoursWorked': (Random().nextDouble()*30).truncateToDouble()+7,
            'tipDistribution': 0.0,
            'workedDays': [false, false, false, false, false, false, false],
          }
        ],
        'netTotal': netTotal,
        'tipTotal': tipTotal,
      });
      print('Record added successfully');

    }catch (e) {
      print('Error adding Record: $e');
    }
  }
  //#endregion

  /// === WIDGETS === ///
//#region

  // =<START>= Full-Feature Widgets =<START>= //
  //A widget that provides a whole feature

  Widget prefixedCalendar({double screenWidth = 300}){

    return Container(
      padding: const EdgeInsets.all(7),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.lightGreen.shade50,
          border: Border.all(
            color: Colors.lightGreen.shade500,
            width: 10,
          )
      ),
      child:
      SizedBox(

        width: screenWidth * 0.3,
        child:
        TableCalendar(
          firstDay: DateTime.utc(2023,07,26),
          lastDay: DateTime.now(),
          focusedDay: _focusedDay,

          calendarStyle:
            CalendarStyle(

              defaultTextStyle:
                const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
              selectedTextStyle:
                const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
              weekendTextStyle:
                const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
              todayTextStyle:
                const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),

              selectedDecoration:
                BoxDecoration(
                  color: Colors.lightGreen.shade200,
                ),
              todayDecoration:
                BoxDecoration(
                  color: Colors.green.shade300,
                ),

            ),

          //Interactivity for selection
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              findWorkingEmployees();
              _focusedDay = focusedDay; // update `_focusedDay` here as well
            });
          },

          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarFormat: _calendarFormat,
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              // Call `setState()` when updating calendar format
              setState(() {
                _calendarFormat = format;
              });
            }
          },

          //Prevents rolling back to focused day on rebuild
          onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          },
        ),
      ),
    );
  }

  Widget employeeSearchBar() {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Search member...',
        prefixIcon: Icon(Icons.search),
      ),

      onSubmitted: (value) {
        // Implement the filtering logic here

        if (value.isNotEmpty) {
          setState(() {
            empListFiltered = empListWorked
                .where((member) =>
                member.name.toLowerCase().contains(
                    value.toLowerCase()))
                .toList();
          });
        }else{
          print("empty!!!");
        }
      },
    );
  }
  // =<ENDED>= Feature Widgets =<ENDED>= //


  // =<START>= Component Widgets =<START>= //
  Widget employeeCard(int index){
    return ListTile(
      title: Text(
        empListFiltered[index].name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),

      subtitle: Text(
        '£${findEmployeesRecord(empListFiltered, index)['hoursRate'].toStringAsFixed(2)} hourly || '
            '${findEmployeesRecord(empListFiltered, index)['hoursWorked'].toStringAsFixed(2)} hours worked',

        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      trailing: Text(
          '£${(findEmployeesRecord(empListFiltered, index)['hoursRate']
              * findEmployeesRecord(empListFiltered, index)['hoursWorked']).toStringAsFixed(2)} || '
              '£${findEmployeesRecord(empListFiltered, index)['tipDistribution'].toStringAsFixed(2)} tips/service',

          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          )
      ),

    );
  }

  Widget errorCard(String errorMessage){
    print("Error occured ~ errorCard");
    return ListTile(
      title: Text(
        errorMessage,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
  // =<ENDED>= Component Widgets =<ENDED>= //


  // =<START>= Part-Feature Widgets =<START>= //
  //A widget that is only a small part of a full feature.


  // =<ENDED>= Part-Feature Widgets =<ENDED>= //
//#endregion

  @override
  Widget build(BuildContext context) {

    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth  = MediaQuery.of(context).size.width;


    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Salaries Manager'),
            backgroundColor: Colors.lightGreen,
            bottom: const TabBar(
              labelColor: Color.fromARGB(255, 49, 84, 28),
              labelStyle: TextStyle(

                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 16,
              ),
              indicatorColor: Color.fromARGB(255, 58, 95, 34),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 5,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Employee Info'),
                Tab(text: 'Track Work'),
              ],
            ),
          ),

          body: TabBarView(
            children: [




              //OVERVIEW TAB
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen.shade50,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: Colors.lightGreen.shade500, // Set the border color here
                        width: 10.0, // Set the border width here
                      ),
                    ),

                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                            width: 0.5 * screenWidth,
                            height: 0.1 * screenHeight,
                            child: employeeSearchBar(),
                        ),
                        SizedBox(
                          width: 0.5 * screenWidth,
                          height: screenHeight * 0.6,
                          child: empListFiltered.isEmpty ? errorCard('No employees worked the selected ${dayOrWeek ? 'week':'day'}!') :
                            ListView.separated(
                              itemCount: empListFiltered.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Container(
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.lightGreen,
                                    borderRadius: BorderRadius.circular(10.0),
                                    //border: Border.all(color: Colors.black45)

                                  ),

                                  child: employeeCard(index),
                                  // You can customize the ListTile or use any other widget to display your data
                                );
                              },
                              separatorBuilder: (BuildContext context, int index) => const Divider(),
                            ),
                          ),
                      ],),
                    ),
                  ),
                  Column( //Calendar and Switch
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      prefixedCalendar(screenWidth: screenWidth),

                      Row(
                        children: [
                        const Text('Show by:  Day  '),
                        Switch(
                          // This bool value toggles the switch.
                          value: dayOrWeek,
                          activeColor: Colors.green.shade500,
                          inactiveThumbColor: Colors.lightGreen.shade300,
                          inactiveTrackColor: Colors.lightGreen.shade50,
                          onChanged: (bool value) {
                            // This is called when the user toggles the switch.
                            setState(() {
                              dayOrWeek = value;
                            });
                          },
                        ),
                        const Text('  Week'),],
                      ),

                    ],
                  )
                ],
              ),



              //EMPLOYEES TAB
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //Left-hand side
                  Align(                    //ALIGN TO CENTRE-LEFT
                    alignment: Alignment.centerLeft,
                    child:
                      Container(            //DECORATION
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.lightGreen.shade500, // Set the border color here
                            width: 10.0,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.lightGreen.shade50,
                        ),
                        margin: const EdgeInsets.all(16.0),
                        padding: const EdgeInsets.all(4),
                        child:
                            Column(         //STRUCTURE WITHIN CONTAINER
                              children: [
                                SizedBox(   //CONTROL DIMENSIONS OF SEARCH BAR
                                  width: 0.37 * screenWidth,
                                  height: 0.1 * screenHeight,
                                  child:
                                  TextField( //SEARCH BAR WIDGET
                                      decoration:
                                      const InputDecoration(
                                        hintText: 'Search employees...',
                                        prefixIcon: Icon(Icons.search),
                                      ),
                                      onChanged: (value){
                                        empListFiltered = empList.where((employee) => employee.name.contains(value)).toList();
                                      }
                                  ),
                                ),

                                GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3, // Number of columns in the grid
                                  ),
                                  itemCount: empListFiltered.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {

                                          if (_selectedEmployee.id == empListFiltered[index].id) {
                                            _selectedEmployee = Employee(id: '', name: '', hoursRate: 0, isStudent: false);
                                          }
                                          else {
                                            _selectedEmployee = empListFiltered[index];
                                          }

                                          //updateControllers(
                                          //  name: selectedMember.name,
                                          //  prev: selectedMember.points.toString(),
                                          //  voucher: selectedMember.voucher,
                                          //);
                                        });
                                      },
                                      //child: _buildGridItem(filteredMembers[index]),
                                    );
                                  },
                                ),
                              ],
                            )

                      ),
                  ),

                  //Right-hand side
                  Column(

                  ),
                ],
              ),

              //PAY TAB
              Row(
                //Refer to draw.io wireframe
              ),

            ],
          ),
        ),
    );
  }
}