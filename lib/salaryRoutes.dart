import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:om_salary_and_membership/records.dart';
import 'dart:math';
import 'dart:async';

//Instantiates firestore database for use within flutter application
final db = FirebaseFirestore.instance;
/*
List<Employee> tempList = [
  Employee( id: 'Test_Employee', name: 'Test Employee', hoursRate: 11, isPostGrad: false, studentPlan: 0),
  Employee( name: 'Beth', hoursRate: 11, isPostGrad: false, studentPlan: 0),
  Employee( name: 'Beth', hoursRate: 11, isPostGrad: false, studentPlan: 0),
  Employee( name: 'Beth', hoursRate: 11, isPostGrad: false, studentPlan: 0),
  Employee( name: 'Beth', hoursRate: 11, isPostGrad: false, studentPlan: 0),
  Employee( name: 'Beth', hoursRate: 11, isPostGrad: false, studentPlan: 0),
  Employee( name: 'Beth', hoursRate: 11, isPostGrad: false, studentPlan: 0),
  Employee( name: 'Beth', hoursRate: 11, isPostGrad: false, studentPlan: 0),
  Employee( name: 'Beth', hoursRate: 11, isPostGrad: false, studentPlan: 0),
  Employee( name: 'Beth', hoursRate: 11, isPostGrad: false, studentPlan: 0),
];*/

/// === CLASSES === ///
//#region
class Employee{
  final String id;
  String name;
  double hoursRate;
  int studentPlan;
  bool isPostGrad;

  Employee({
    required this.id,
    required this.name,
    required this.hoursRate,
    required this.studentPlan,
    required this.isPostGrad
  });




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
      studentPlan: data['studentPlan'] ?? 0,
      isPostGrad: data['isPostGrad'] ?? false,
    );
  }

}

//#endregion


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
      'isStudent': employee.studentPlan,
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
  return
    Records.selectedWeek.employeesWorked.firstWhere((employee) => employee['employeeID'] == empListFiltered[index].id,
      orElse: () => {'hoursWorked': 0}
    );
}

double loanRepaymentDue({int planThreshold = 0, bool postGrad = false, double hoursRate = 0, double hoursWorked = 0}){
  double repayment = 0;
  double grossWeek = hoursRate * hoursWorked;
  print('grossWeek: $grossWeek');
  const int pgThreshold = 403;
  if (planThreshold == 0 && !postGrad 
      || postGrad && grossWeek <= pgThreshold 
      || planThreshold > 0 && grossWeek <= planThreshold
  ){
    print('repayment: $repayment');
    return 0;
  }
  if(postGrad && grossWeek > 403){
    repayment += (grossWeek - pgThreshold) * 0.06;
  }
  if(planThreshold > 0 && grossWeek > planThreshold){
    repayment += (grossWeek - planThreshold) * 0.09;
  }
  print(repayment);
  return repayment;
}

double incomeTaxDue({double hoursRate = 0, double hoursWorked = 0}){
  double grossWeek = hoursRate * hoursWorked;
  if (grossWeek <= 241.73){
    return 0;
  }
  double taxed = grossWeek - 241.73;
  if (taxed > 725){
    taxed = ((grossWeek - 725) * 0.4) + (725 * 0.2);
  }
  else{
    taxed *= 0.2;
  }

  return taxed;
}

double nicDue({double hoursRate = 0, double hoursWorked = 0}){
  double grossWeek = hoursRate * hoursWorked;
  if (grossWeek < 242){
    return 0;
  }
  double contribution = 0;
  if (grossWeek > 967){
    contribution = (grossWeek - 967) * 0.02;
    grossWeek = 967;
  }
  contribution += (grossWeek - 242) * 0.08;

  return contribution;
}

//#endregion

class _SalaryHomePageState extends State<SalaryHomePage>
    with SingleTickerProviderStateMixin {

  ///  === VARIABLES ===  ///
  //     Controllers      //
  late TabController _tabController;
  late TextEditingController _rateController;
  late TextEditingController _nameController;
  late TextEditingController _loanController;
  late TextEditingController _incTaxController;
  late TextEditingController _nicController;

  // <Employee> variables //
  List<Employee> empList = [];
  List<Employee> empListWorked = [];
  List<Employee> empListFiltered = [];
  List<Employee> empListToUpdate = [];
  Employee _selectedEmployee = Employee(hoursRate: 0,id: '',studentPlan: 0,isPostGrad: false,name: '');

  // Day/Week switch variables
  bool dayOrWeek = true;
  String dayOfWeek = '';

  //Calendar variables
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Error check variables
  int catchCount = 0;



  /// === OVERRIDES === ///
  //#region
  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(text:'');
    _nameController = TextEditingController(text:'');
    _loanController = TextEditingController(text:'');
    _incTaxController = TextEditingController(text:'');
    _nicController = TextEditingController(text:'');

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      int selectedIndex = _tabController.index;
      print('Selected tab index: $selectedIndex');
      // Perform any actions based on the selected tab
      setState(() {
        switch(selectedIndex){
          case 0:
            findWorkingEmployees();

          case 1:
            empListFiltered = empList;

          default:

        }
      });
    });

    dbFetchEmployees().then((_){
      findWorkingEmployees();
    });
  }

 @override
  void dispose(){
    _tabController.dispose();
    _nameController.dispose();
    _rateController.dispose();
    _loanController.dispose();
    _incTaxController.dispose();
    _nicController.dispose();
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

  Widget _sizedPadding({double width = 0.1, double height = 0.1}){
    return SizedBox(
        width:  MediaQuery.of(context).size.width * width,
        height: MediaQuery.of(context).size.height * height
    );
  }
  // =<ENDED>= Component Widgets =<ENDED>= //


  // =<START>= Part-Feature Widgets =<START>= //
  //A widget that is only a small part of a full feature.
  //Items for the grid
  Widget _buildGridItem(Employee employee) {
    bool isSelected = _selectedEmployee.name == employee.name;

    return Card(
      color: isSelected ? Colors.lightGreen.shade200 : Colors.lightGreen.shade100,
      child: Center(
        child: Text(
          employee.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18,),
        ),
      ),
    );
  }

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
    return Scaffold(
          appBar: AppBar(

            title: const Text('Salaries Manager'),
            backgroundColor: Colors.lightGreen,
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color.fromARGB(255, 49, 84, 28),
              labelStyle: const TextStyle(

                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
              ),
              indicatorColor: const Color.fromARGB(255, 58, 95, 34),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 5,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Current Employee Info'),
                Tab(text: 'Track Work'),
              ],

            ),
          ),

          body: TabBarView(
            controller: _tabController,

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
                                        setState(() {
                                          empListFiltered = empList.where((employee) => employee.name.contains(value)).toList();
                                        });
                                      }
                                  ),
                                ),
                                //=========================================
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: (){ // Adds employee to newEmpList, if save then all newEmpList employees get added to database.

                                      },
                                      child: Icon(Icons.add, color: Colors.lightGreen.shade700,),
                                    )
                                  ],
                                ),
                                _sizedPadding(height: 0.02,),
                                SizedBox(
                                  width: 0.45 * screenWidth,
                                  height: 0.55 * screenHeight,

                                  child: GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3, // Number of columns in the grid
                                    ),
                                    itemCount: empListFiltered.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {

                                            _selectedEmployee.name = _nameController.text;
                                            _selectedEmployee.hoursRate = double.tryParse(_rateController.text)
                                              ?? _selectedEmployee.hoursRate;

                                            //checks if its already queued to update, yes then it replaces, no then it adds.
                                            if (!empListToUpdate.contains(_selectedEmployee)) {
                                              empListToUpdate.add(
                                                  _selectedEmployee);
                                            }
                                            else{
                                              empListToUpdate[empListToUpdate.indexWhere((emp) => emp.id == _selectedEmployee.id)] = _selectedEmployee;
                                            }

                                            //De/select action
                                            if (_selectedEmployee.name == empListFiltered[index].name) {
                                              _selectedEmployee = Employee(id: '', name: '', hoursRate: 0, studentPlan: 0, isPostGrad: false,);
                                            }
                                            else {
                                              _selectedEmployee = empListFiltered[index];
                                            }

                                            //Update displays
                                            _nameController.text = _selectedEmployee.name;
                                            _rateController.text = _selectedEmployee.hoursRate.toStringAsFixed(2);
                                            _loanController.text = '£${loanRepaymentDue(
                                                planThreshold: _selectedEmployee.studentPlan,
                                                postGrad: _selectedEmployee.isPostGrad,
                                                hoursRate: findEmployeesRecord([_selectedEmployee], 0)['hoursRate'],
                                                hoursWorked: findEmployeesRecord([_selectedEmployee], 0)['hoursWorked']).toStringAsFixed(2)
                                            }';

                                            _incTaxController.text = '£${incomeTaxDue(
                                                hoursWorked: findEmployeesRecord([_selectedEmployee], 0)['hoursWorked'],
                                                hoursRate: findEmployeesRecord([_selectedEmployee], 0)['hoursRate']).toStringAsFixed(2)}';
                                            _nicController.text = '£${nicDue(
                                                hoursRate: findEmployeesRecord([_selectedEmployee], 0)['hoursRate'],
                                                hoursWorked: findEmployeesRecord([_selectedEmployee], 0)['hoursWorked']
                                            ).toStringAsFixed(2)}';
                                          });
                                        },
                                        child: _buildGridItem(empListFiltered[index]),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )

                      ),
                  ),

                  //Right-hand side
                  Align(
                    alignment: Alignment.centerRight,
                    child:
                      Container(
                        margin: const EdgeInsets.all(16.0),
                        padding: const EdgeInsets.all(4.0),
                        width: screenWidth * 0.45,
                        decoration:
                          BoxDecoration(
                            border: Border.all(
                              color: Colors.lightGreen.shade500, // Set the border color here
                              width: 10.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.lightGreen.shade50,
                          ),
                        child:
                          SingleChildScrollView(
                            child:
                            Column(
                              children: [
                                _sizedPadding(height: 0.025),
                                const Text(             // HEADER
                                  'Current Employee Details',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ), // Header
                                _sizedPadding(height: 0.025),
                                Container(
                                  margin:
                                    EdgeInsets
                                      .fromLTRB(screenWidth * 0.05, 0, screenWidth * 0.05, 0),
                                  padding:
                                    const EdgeInsets.all(10.0),

                                  decoration:
                                    BoxDecoration(
                                      border: Border.all(
                                        width: 5.0,
                                        color: Colors.lightGreen.shade200,
                                      ),

                                      color: Colors.white70,
                                    ),

                                  child:
                                    TextField(
                                      controller: _nameController,
                                      keyboardType: TextInputType.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: "Employee's Name",
                                      ),
                                      onChanged: (value){
                                        _selectedEmployee.name = value;
                                      },

                                    ),
                                ),  // Name text field
                                _sizedPadding(height: 0.05),
                                Row( // Hourly Rate Row
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      margin:
                                      EdgeInsets
                                          .fromLTRB(screenWidth * 0.05, 0, screenWidth * 0.02, 0),
                                      padding:
                                      const EdgeInsets.all(10.0),

                                      decoration:
                                      BoxDecoration(
                                        border: Border.all(
                                          width: 5.0,
                                          color: Colors.lightGreen.shade200,
                                        ),

                                        color: Colors.white70,
                                      ),

                                      child:
                                      const Text(
                                        'Hourly Rate:',
                                        style:
                                        TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),

                                      ),
                                    ), // Hourly Rate Text
                                    Container(
                                      width: screenWidth * 0.15,
                                      margin:
                                      EdgeInsets
                                          .fromLTRB(screenWidth * 0.01, 0, screenWidth * 0.05, 0),
                                      padding:
                                      const EdgeInsets.all(5.0),

                                      decoration:
                                      BoxDecoration(
                                        border: Border.all(
                                          width: 5.0,
                                          color: Colors.lightGreen.shade200,
                                        ),

                                        color: Colors.white70,
                                      ),

                                      child:
                                        TextField(
                                          controller: _rateController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                                          decoration: const InputDecoration(
                                            hintText: '£00.00',
                                            prefixText: '£',
                                          ),

                                          style:
                                            const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),

                                        ),
                                    ),
                                  ],
                                ),        // Hourly rate field

                                _sizedPadding(height: 0.05),
                                Row( // Student Plan dropdown menu Row
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      margin:
                                      EdgeInsets
                                          .fromLTRB(screenWidth * 0.05, 0, screenWidth * 0.02, 0),
                                      padding:
                                      const EdgeInsets.all(10.0),

                                      decoration:
                                      BoxDecoration(
                                        border: Border.all(
                                          width: 5.0,
                                          color: Colors.lightGreen.shade200,
                                        ),

                                        color: Colors.white70,
                                      ),

                                      child:
                                      const Text(
                                        'Student Loan plan:',
                                        style:
                                        TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),

                                      ),
                                    ), // Checkbox Text
                                    Container(
                                      margin:
                                      EdgeInsets
                                          .fromLTRB(screenWidth * 0.025, 0, screenWidth * 0.05, 0),

                                      color: Colors.white70,

                                      child:
                                        DropdownMenu(
                                          initialSelection: _selectedEmployee.studentPlan,
                                          onSelected: (int? value){
                                            if (value == null) {
                                              return;
                                            }
                                            setState(() {
                                              _selectedEmployee.studentPlan = value;
                                            });
                                          },

                                          dropdownMenuEntries: const [
                                            DropdownMenuEntry(value: 0, label: 'None'),
                                            DropdownMenuEntry(value: 480, label: 'Plan 1 or 5'),
                                            DropdownMenuEntry(value: 524, label: 'Plan 2'),
                                            DropdownMenuEntry(value: 603, label: 'Plan 4'),
                                          ],
                                        ),
                                    ),
                                  ],
                                ),        // student loan plan dropdown menu

                                _sizedPadding(height: 0.05),
                                Row(      // Post-grad loan checkbox
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      margin:
                                      EdgeInsets
                                          .fromLTRB(screenWidth * 0.05, 0, screenWidth * 0.02, 0),
                                      padding:
                                      const EdgeInsets.all(10.0),

                                      decoration:
                                      BoxDecoration(
                                        border: Border.all(
                                          width: 5.0,
                                          color: Colors.lightGreen.shade200,
                                        ),

                                        color: Colors.white70,
                                      ),

                                      child:
                                      const Text(
                                        'Has Post-Grad Loan:',
                                        style:
                                        TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),

                                      ),
                                    ),
                                    Checkbox(

                                      value: _selectedEmployee.isPostGrad,
                                      tristate: false,
                                      activeColor: Colors.lightGreen.shade600,
                                      onChanged: (value){
                                        if (value == null){
                                          return;
                                        }
                                        setState(() {
                                          _selectedEmployee.isPostGrad = value;
                                        });
                                      },
                                    ),
                                    _sizedPadding(width: 0.05),
                                  ]
                                ),        // Post grad plan checkbox
                                _sizedPadding(height: 0.05),
                                const Text(             // HEADER
                                  "Selected Week's Deductions",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ), // Header
                                _sizedPadding(height: 0.05),
                                Row( // S-Loan repayment Row
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      margin:
                                      EdgeInsets
                                          .fromLTRB(screenWidth * 0.05, 0, screenWidth * 0.02, 0),
                                      padding:
                                      const EdgeInsets.all(10.0),

                                      decoration:
                                      BoxDecoration(
                                        border: Border.all(
                                          width: 5.0,
                                          color: Colors.lightGreen.shade200,
                                        ),

                                        color: Colors.lightGreen.shade400,
                                      ),

                                      child:
                                      const Text(
                                        'Loan repayment:',
                                        style:
                                        TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),

                                      ),
                                    ), // Loan repayment Text
                                    Container(
                                      width: screenWidth * 0.15,
                                      margin:
                                      EdgeInsets
                                          .fromLTRB(screenWidth * 0.01, 0, screenWidth * 0.05, 0),
                                      padding:
                                      const EdgeInsets.all(5.0),

                                      decoration:
                                      BoxDecoration(
                                        border: Border.all(
                                          width: 5.0,
                                          color: Colors.lightGreen.shade200,
                                        ),

                                        color: Colors.lightGreen.shade400,
                                      ),

                                      child:
                                        TextField(
                                          controller: _loanController,

                                        style:
                                        const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),

                                      ),
                                    ),
                                  ],
                                ),        // Loan repayment text display
                                _sizedPadding(height: 0.05),
                                Row( // Income Tax Row
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      margin:
                                      EdgeInsets
                                          .fromLTRB(screenWidth * 0.05, 0, screenWidth * 0.02, 0),
                                      padding:
                                      const EdgeInsets.all(10.0),

                                      decoration:
                                      BoxDecoration(
                                        border: Border.all(
                                          width: 5.0,
                                          color: Colors.lightGreen.shade200,
                                        ),

                                        color: Colors.lightGreen.shade400,
                                      ),

                                      child:
                                      const Text(
                                        'Income Tax:',
                                        style:
                                        TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),

                                      ),
                                    ), // Loan repayment Text
                                    Container(
                                      width: screenWidth * 0.15,
                                      margin:
                                      EdgeInsets
                                          .fromLTRB(screenWidth * 0.01, 0, screenWidth * 0.05, 0),
                                      padding:
                                      const EdgeInsets.all(5.0),

                                      decoration:
                                      BoxDecoration(
                                        border: Border.all(
                                          width: 5.0,
                                          color: Colors.lightGreen.shade200,
                                        ),

                                        color: Colors.lightGreen.shade400,
                                      ),

                                      child:
                                      TextField(
                                        controller: _incTaxController,

                                        style:
                                        const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),

                                      ),
                                    ),
                                  ],
                                ),
                                _sizedPadding(height: 0.05),
                                Row( // NI contribution Row
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      margin:
                                      EdgeInsets
                                          .fromLTRB(screenWidth * 0.05, 0, screenWidth * 0.02, 0),
                                      padding:
                                      const EdgeInsets.all(10.0),

                                      decoration:
                                      BoxDecoration(
                                        border: Border.all(
                                          width: 5.0,
                                          color: Colors.lightGreen.shade200,
                                        ),

                                        color: Colors.lightGreen.shade400,
                                      ),

                                      child:
                                      const Text(
                                        'NI Contribution:',
                                        style:
                                        TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),

                                      ),
                                    ), // Loan repayment Text
                                    Container(
                                      width: screenWidth * 0.15,
                                      margin:
                                      EdgeInsets
                                          .fromLTRB(screenWidth * 0.01, 0, screenWidth * 0.05, 0),
                                      padding:
                                      const EdgeInsets.all(5.0),

                                      decoration:
                                      BoxDecoration(
                                        border: Border.all(
                                          width: 5.0,
                                          color: Colors.lightGreen.shade200,
                                        ),

                                        color: Colors.lightGreen.shade400,
                                      ),

                                      child:
                                      TextField(
                                        controller: _nicController,

                                        style:
                                        const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),

                                      ),
                                    ),
                                  ],
                                ),

                              ],
                            ),
                          ),
                      ),
                  )
                ],
              ),

              //PAY TAB
              Row(
                //Refer to draw.io wireframe
              ),

            ],
          ),
    );
  }
}