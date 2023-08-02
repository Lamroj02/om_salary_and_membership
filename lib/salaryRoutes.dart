import 'package:flutter/material.dart';

//Employee class
class Employee{
  final String name;
  final double hoursRate;
  final List<double> hoursWeek;

  Employee(this.name,this.hoursRate,this.hoursWeek);
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
  ];


  @override
  Widget build(BuildContext context) {
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
                Tab(text: 'Pay'),
              ],
            ),
          ),

          body: TabBarView(
            children: [
              //OVERVIEW TAB
              ListView.builder(
                itemCount: empList.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(empList[index].name),
                  );
                },
              )

              //EMPLOYEES TAB


              //PAY TAB


            ],
          ),
        ),
    );
  }
}