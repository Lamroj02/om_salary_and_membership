import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

//Employee class
class Employee{
  final String name;
  final double hoursRate;
  final List<double> hoursWeek;

  Employee(this.name,this.hoursRate,this.hoursWeek);

  double sumHoursWeek(){

    return hoursWeek.fold<double>(
        0, (previousValue, element) => previousValue + element
    );
  }

  double sumEarnedWeek(){
    return hoursRate * sumHoursWeek();
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

class _SalaryHomePageState extends State<SalaryHomePage> {

  List<Employee> empList = [
    Employee( 'Samjhana Lama' , 15.74 , [0,3,4,4,4.5,5,6] ),
    Employee( 'Roj Kumar Lama' , 14.96 , [0,6,7,7,7,8,9] ),
    Employee( 'Paulo' , 13.59 , [0,3,3.5,4,4,4.5,5.5] ),
    Employee( 'Hritesh' , 7.25 , [0,0,0,0,4,4.5,2] ),
    Employee( 'Sarina' , 13.98 , [0,0,0,0,3.5,4,0] ),
    Employee( 'Erin' , 8.30 , [0,4,0,0,4,0,4] ),
    Employee( 'Thea' , 7.20 , [0,0,0,0,4,0,4] )
  ];

  bool dayWeek = true;


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

                    child: SizedBox(
                      height: screenHeight * 0.65, // Set the height of the container as you like
                      width: screenWidth * 0.5,
                      child: ListView.builder(
                        itemCount: empList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.lightGreen,
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: Colors.black45)

                            ),

                            child: ListTile(
                              title: Text(
                                empList[index].name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),

                              trailing: Text(
                                  '£${empList[index].sumEarnedWeek().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                  ),
                                ),
                            ),
                            // You can customize the ListTile or use any other widget to display your data
                          );
                          },
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
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
                                lastDay: DateTime.utc(2025,12,16),
                                focusedDay: DateTime.now(),
                              ),
                            ),
                      ),
                      Row(
                        children: [
                        const Text('Show by:  Day  '),
                        Switch(
                          // This bool value toggles the switch.
                          value: dayWeek,
                          activeColor: Colors.green.shade500,
                          inactiveThumbColor: Colors.lightGreen.shade300,
                          inactiveTrackColor: Colors.lightGreen.shade50,
                          onChanged: (bool value) {
                            // This is called when the user toggles the switch.
                            setState(() {
                              dayWeek = value;
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