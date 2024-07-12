import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';



/// === CLASSES === ///
//#region
class Employee{
  final String name;
  final double hoursRate;
  final List<double> hoursWeek;
  final double tipsWeek;

  Employee(this.name,this.hoursRate,this.hoursWeek, this.tipsWeek);

  double sumHoursWeek(){

    return hoursWeek.fold<double>(
        0, (previousValue, element) => previousValue + element
    );
  }

  double sumEarnedWeek({bool useTips = true}){
    return hoursRate * sumHoursWeek() + (useTips ? tipsWeek : 0);
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

//#endregion

class _SalaryHomePageState extends State<SalaryHomePage> {

  List<Employee> empList = [
    Employee( 'Anahjmas' , 15.74 , [0,3,4,4,4.5,5,6] , 24.00 ),
    Employee( 'Jor' , 14.96 , [0,6,7,7,7,8,9] , 24.00),
    Employee( 'Oluap' , 13.59 , [0,3,3.5,4,4,4.5,5.5] , 24.00 ),
    Employee( 'Hsetirh' , 10.25 , [0,0,0,0,4,4.5,2] , 12.00),
    Employee( 'Aniras' , 13.98 , [0,0,0,0,3.5,4,0] , 11.00 ),
    Employee( 'Nire' , 8.30 , [0,4,0,0,4,0,4] , 9.00 ),
    Employee( 'Aeht' , 7.20 , [0,0,0,0,4,0,4] , 6.75 ),
    Employee( 'Nire' , 8.30 , [0,4,0,0,4,0,4] , 9.00 ),
    Employee( 'Aeht' , 7.20 , [0,0,0,0,4,0,4] , 6.75 )
  ];

  List<Employee> empListFiltered = [];

  bool dayOrWeek = true;
  String dayOfWeek = '';

  //Calendar Variables
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  /// === OVERRIDES === ///
  //#region
  @override
  void initState(){
    super.initState();
    empListFiltered = empList;
  }

  //#endregion

  /// === WIDGETS === ///
//#region
  Widget prefixedCalendar({double screenWidth = 300}){

    return Container(
      padding: const EdgeInsets.all(7),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          border: Border.all( color: Colors.black45)
      ),
      child:
      SizedBox(

        width: screenWidth * 0.3,
        child:
        TableCalendar(
          firstDay: DateTime.utc(2023,07,26),
          lastDay: DateTime.now(),
          focusedDay: _focusedDay,

          //Interactivity for selection
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
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

  Widget employeeSearchBar(){
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Search member...',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) {
        // Implement the filtering logic here
        if (value.isNotEmpty) {
          setState(() {
            empListFiltered = empList
                .where((member) =>
                member.name.toLowerCase().contains(
                    value.toLowerCase()))
                .toList();
          });
        }else{
          setState(() {
            empListFiltered = empList;
          });
        }
      },
    );
  }
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
              labelColor: Colors.black,
              indicatorColor: Colors.limeAccent,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Employees'),
                Tab(text: 'Set Pay'),
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
                          child:
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

                                  child: ListTile(
                                    title: Text(
                                      empListFiltered[index].name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),

                                    subtitle: Text(
                                       '£${empListFiltered[index].hoursRate.toStringAsFixed(2)} hourly || '
                                           '${/*dayOrWeek ?*/ empListFiltered[index].sumHoursWeek().toStringAsFixed(2)} hours worked',

                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: Text(
                                      '£${empList[index].sumEarnedWeek(useTips: false).toStringAsFixed(2)} || '
                                        '£${empList[index].tipsWeek.toStringAsFixed(2)} tips/service',

                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      )
                                    ),



                                  ),
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
                //Refer to draw.io wireframe
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