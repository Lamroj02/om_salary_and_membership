import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:om_salary_and_membership/records.dart';

//Instantiates firestore database for use within flutter application
final db = FirebaseFirestore.instance;

class IncomeRoutesHomePage extends StatefulWidget {
  const IncomeRoutesHomePage({super.key, required this.title});


  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<IncomeRoutesHomePage> createState() => _IncomeRoutesHomePageState();
}


class _IncomeRoutesHomePageState extends State<IncomeRoutesHomePage> {

  /// VARIABLES ///
  //Controller variables
  late TextEditingController _cashController;
  late TextEditingController _cardController;
  late TextEditingController _sChargeController;
  late TextEditingController _weekTipsController;
  late TextEditingController _weekVATController;
  late TextEditingController _weekGTotalController;

  //Calendar variables
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  //General variables
  double grossTotal = 0;


  /// ========= ///
  /// Overrides ///
  /// ========= ///
  //#region
  @override
  void initState() {
    super.initState();
    _cashController = TextEditingController(text: '');
    _cardController = TextEditingController(text: '');
    _sChargeController = TextEditingController(text: '');
    _weekTipsController = TextEditingController(text: '');
    _weekGTotalController = TextEditingController(text: '');
    _weekVATController = TextEditingController(text: '');

    dbFetchRecord(_selectedDay)
      .then((_) {updateControllers();
    }).then((_) {grossTotal = updateTotal(
        valueControllers: [_cashController,_cardController,_sChargeController],);
    });
  }

  @override
  void dispose() {
    //Saving Information Logic
    _cashController.dispose();
    _cardController.dispose();
    _sChargeController.dispose();
    _weekGTotalController.dispose();
    _weekTipsController.dispose();
    _weekVATController.dispose();
    super.dispose();
  }
  //#endregion

  /// General Methods ///
  //#region
  Future<void> saveMessage() async {
    return showDialog<void>(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: const Text('Saved Changes!'),
            content: const Text('You can safely leave the\npage if you wish.'),
            actions: [
              TextButton(onPressed: (){Navigator.of(context).pop();}, child: const Text('OK')),
            ],
          );
        }
    );
  }

  Future<void> unsavedChangesMessage() async {
    return showDialog<void>(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: const Text('Changes made!'),
            content: const Text('Do you want to leave anyways?\nAll un-saved changes will be lost.'),
            actions: [
              TextButton(onPressed: (){
                Navigator.of(context).pop();
              }, child: const Text('No')),
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }, child: const Text('Yes')),
            ],
          );
        }
    );
  }

  DateTime getFirstDateOfCurrentWeek(DateTime date) {
    int currentWeekday = date.weekday;
    DateTime firstDateOfWeek = date.subtract(Duration(days: currentWeekday - 1));

    return DateTime(firstDateOfWeek.year, firstDateOfWeek.month, firstDateOfWeek.day);
  }

  double updateTotal({required List<TextEditingController> valueControllers}){
    double numTotal = 0;

    for(int i = 0; i < valueControllers.length; i++){
      numTotal += double.tryParse(valueControllers[i].text) ?? 0;
    }

    return numTotal;
  }

  double readableParse(String parseableObject){
    return (double.tryParse(parseableObject) ?? 0);
  }
  //#endregion

  /// === FIRESTORE METHODS === ///
  //#region

  Future<void> dbFetchRecord(DateTime documentId) async {
    try {
      final DocumentSnapshot doc = await db.collection("Records").doc(getFirstDateOfCurrentWeek(documentId).toString().split(' ')[0]).get();
      if (doc.exists) {
        setState(() {
          Records.selectedWeek = WeekRecord.fromFirestore(doc);
        });
      }
      else {
        print("No such document! ~ dbFetchRecord(else)");
        // Handle the case where the document doesn't exist, e.g., show a user-friendly message
        setState((){
          Records.selectedWeek = WeekRecord(payments: {}, tipTotal: 0, netTotal: 0, employeesWorked: []);
        });
      }
    }
    catch (e) {
      print("Error fetching record data: $e ~ dbFetchRecord(catch)");
      // Handle the error appropriately, e.g., show a user-friendly message
      setState((){
        Records.selectedWeek = WeekRecord(payments: {}, tipTotal: 0, netTotal: 0, employeesWorked: []);
      });
    }
  }

  // Save method
  void uploadRecord(){
    Records.selectedWeek.payments['VAT'] = (Records.selectedWeek.payments['VAT'] ?? 0) + (
      (readableParse(_sChargeController.text) + readableParse(_cardController.text) + readableParse(_cashController.text)) * 0.2);
    Records.selectedWeek.payments['cash'] = (Records.selectedWeek.payments['cash'] ?? 0) + readableParse(_cashController.text);
    Records.selectedWeek.payments['card'] = (Records.selectedWeek.payments['card'] ?? 0) + readableParse(_cardController.text);
    Records.selectedWeek.payments['serviceCharge'] = (Records.selectedWeek.payments['serviceCharge'] ?? 0) + readableParse(_sChargeController.text);
    Records.selectedWeek.netTotal = (Records.selectedWeek.payments['cash'] ?? 0) + (Records.selectedWeek.payments['card'] ?? 0)
      + (Records.selectedWeek.payments['serviceCharge'] ?? 0) - (Records.selectedWeek.payments['VAT'] ?? 0);
    Records.setRecords(getFirstDateOfCurrentWeek(_selectedDay).toString().split(' ')[0], Records.selectedWeek);
  }


  //#endregion

//#endregion

  /// Controller Methods ///
  //#region
  updateControllers() {
    Map<String, double> payments = Records.selectedWeek.payments;

    _cardController.text = '';
    _cashController.text = '';
    _sChargeController.text = '';
    _weekTipsController.text = (((Records.selectedWeek.payments['serviceCharge'] ?? 0) * 0.8)
        + Records.selectedWeek.tipTotal).toStringAsFixed(2);
    _weekVATController.text = (Records.selectedWeek.payments['VAT'] ?? 0).toStringAsFixed(2);
    _weekGTotalController.text = Records.selectedWeek.netTotal.toStringAsFixed(2);
  }

  //#endregion
//#endregion

  /// === WIDGETS === ///
  //#region
  Widget prefixedCalendar({double givenWidth = 300, double givenHeight = 300, bool writeComponent = false}){

    return Container(
      padding: const EdgeInsets.all(7),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.lightBlue.shade50,
          border: Border.all(
            color: Colors.lightBlue.shade500,
            width: 10,
          )
      ),
      child:
      SizedBox(
        width: givenWidth,
        height: givenHeight,
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
              color: Colors.lightBlue.shade200,
            ),
            todayDecoration:
            BoxDecoration(
              color: Colors.blue.shade300,
            ),

          ),

          //Interactivity for selection
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay; // update `_focusedDay` here as well
              dbFetchRecord(_selectedDay)
                  .then((_) {updateControllers();});
            });
          },

          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarFormat: CalendarFormat.twoWeeks,

          //Prevents rolling back to focused day on rebuild
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
      ),
    );
  }

  Widget _sizedPadding({double width = 0.1, double height = 0.1}){
    return SizedBox(
        width:  MediaQuery.of(context).size.width * width,
        height: MediaQuery.of(context).size.height * height
    );
  }
  //#endregion

  /// -=-=-=-=-=- ///
  ///    MAIN     ///
  /// -=-=-=-=-=- ///

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
          title: const Text('Business Income Manager', style: TextStyle(color: Colors.white),),
          toolbarHeight: 80.0,
          backgroundColor: Colors.blue.shade400,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white,),
            onPressed: () => Navigator.pop(context),
            color: Colors.indigo.shade100,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children:[
                ElevatedButton(
                  onPressed: (){
                    setState(() {
                      uploadRecord();
                      updateControllers();
                      saveMessage();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20.0),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.save, color: Colors.lightBlue,),
                ),
              ],
            ),
          ],
        ),

        body: Row(
      children: [
        Expanded(
          child:
          Container(
              margin: const EdgeInsets.all(16),
              decoration:
              BoxDecoration(
                border: Border.all(
                  width: 10,
                  color: Colors.lightBlue.shade400,
                ),
                color: Colors.lightBlue.shade50,
              ),
              child:
                Row(
                  children: [
                    Column( // PAYMENT FIELDS
                      children: [
                        // ======================================
                        _sizedPadding(height: 0.02),
                        const Text( //   HEADER TEXT
                          '\nPayment Methods',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // ======================================
                        _sizedPadding(height: 0.05),
                        Row( // Row
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container( // Card Payment Text
                              margin:
                              EdgeInsets
                                  .fromLTRB(screenWidth * 0.05, 0, screenWidth * 0.02, 0),
                              padding:
                              const EdgeInsets.all(10.0),

                              decoration:
                              BoxDecoration(
                                border: Border.all(
                                  width: 5.0,
                                  color: Colors.lightBlue.shade200,
                                ),

                                color: Colors.lightBlue.shade400,
                              ),

                              child:
                              const Text(
                                'Card:',
                                style:
                                TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),

                              ),
                            ), // Card Payment Text
                            Container( // Card Payment Input Field
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
                                  color: Colors.lightBlue.shade200,
                                ),

                                color: Colors.lightBlue.shade400,
                              ),

                              child:
                              TextField(
                                controller: _cardController,

                                onChanged: (_){
                                  setState(() {
                                    grossTotal = updateTotal(valueControllers: [_cashController,_cardController,_sChargeController]);
                                  });
                                },
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d*)?'))],

                                decoration: const InputDecoration(
                                  prefixIcon: Text('£', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                  prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                                  hintText: '00.00',
                                ),

                                style:
                                const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),

                              ),
                            ), // Card Payment Input Field
                          ],
                        ),  // CARD PAYMENT INPUT FIELD
                        // ======================================
                        _sizedPadding(height: 0.05),
                        Row( // CASH PAYMENT INPUT FIELD Row
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                  color: Colors.lightBlue.shade200,
                                ),

                                color: Colors.lightBlue.shade400,
                              ),

                              child:
                              const Text(
                                'Cash:',
                                style:
                                TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),

                              ),
                            ), // Cash Payment Text
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
                                  color: Colors.lightBlue.shade200,
                                ),

                                color: Colors.lightBlue.shade400,
                              ),

                              child:
                              TextField(
                                controller: _cashController,

                                onChanged: (_){
                                  setState(() {
                                    grossTotal = updateTotal(valueControllers: [_cashController,_cardController,_sChargeController]);
                                  });
                                },
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d*)?'))],

                                decoration: const InputDecoration(
                                  prefixIcon: Text('£', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                  prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                                  hintText: '00.00',
                                ),

                                style:
                                const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),

                              ),
                            ), // Cash Payment Input Field
                          ],
                        ),  // CASH PAYMENT INPUT FIELD
                        // ======================================
                        _sizedPadding(height: 0.05),
                        Row( // SERVICE CHARGE INPUT FIELD Row
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                  color: Colors.lightBlue.shade200,
                                ),

                                color: Colors.lightBlue.shade400,
                              ),

                              child:
                              const Text(
                                'Service Charge:',
                                style:
                                TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),

                              ),
                            ), // Service Charge Text
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
                                  color: Colors.lightBlue.shade200,
                                ),

                                color: Colors.lightBlue.shade400,
                              ),

                              child:
                              TextField(
                                controller: _sChargeController,

                                onChanged: (_){
                                  setState(() {
                                    grossTotal = updateTotal(valueControllers: [_cashController,_cardController,_sChargeController]);
                                  });
                                },
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d*)?'))],
                                decoration: const InputDecoration(
                                  prefixIcon: Text('£', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                  prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                                  hintText: '00.00',
                                ),

                                style:
                                const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),

                              ),
                            ), // Service Charge Input Field
                          ],
                        ),  // SERVICE CHARGE INPUT FIELD
                        // ======================================
                        _sizedPadding(height: 0.1),
                        Row( // GROSS REVENUE FIELD Row
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                  color: Colors.lightBlue.shade200,
                                ),

                                color: Colors.lightBlue.shade400,
                              ),

                              child:
                              const Text(
                                'Gross Total:',
                                style:
                                TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),

                              ),
                            ), // Gross Total Text
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
                                  color: Colors.lightBlue.shade200,
                                ),

                                color: Colors.lightBlue.shade400,
                              ),

                              child:
                              TextField(
                                controller: TextEditingController(text: grossTotal.toStringAsFixed(2)),

                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d*)?'))],

                                decoration: const InputDecoration(
                                  prefixIcon: Text('£', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                  prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                                  hintText: '00.00',
                                ),

                                style:
                                const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                enabled: false,

                              ),
                            ), // Gross Revenue Output Field
                          ],
                        ),  // GROSS REVENUE OUTPUT FIELD
                      ],
                    ),
                    // =========================================
                    Container( // VAT COLUMN
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(
                          color: Colors.black45,
                          width: 5,
                        )),
                      ),

                      child:
                      Column( // VAT DISPLAYS
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ======================================
                          _sizedPadding(height: 0.02),
                          const Text( //   HEADER TEXT
                            '\nVAT',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ), // HEADER
                          // ======================================
                          _sizedPadding(height: 0.05),
                          Container( // CARD VAT
                            width: screenWidth * 0.15,
                            margin:
                            EdgeInsets
                                .fromLTRB(screenWidth * 0.02, 0,0, 0),
                            padding:
                            const EdgeInsets.all(5.0),

                            decoration:
                            BoxDecoration(
                              border: Border.all(
                                width: 5.0,
                                color: Colors.lightBlue.shade200,
                              ),

                              color: Colors.lightBlue.shade400,
                            ),

                            child:
                            TextField(
                              controller:
                                TextEditingController(
                                  text: '£${((double.tryParse(_cardController.text) ?? 0) * 0.2).toStringAsFixed(2)}'
                                ),

                              style:
                                const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              enabled: false,

                            ),
                          ),  // CARD VAT DISPLAY
                          // ========================================
                          _sizedPadding(height: 0.05),
                          Container( // CASH VAT
                            width: screenWidth * 0.15,
                            margin:
                            EdgeInsets
                                .fromLTRB(screenWidth * 0.02, 0,0, 0),
                            padding:
                            const EdgeInsets.all(5.0),

                            decoration:
                            BoxDecoration(
                              border: Border.all(
                                width: 5.0,
                                color: Colors.lightBlue.shade200,
                              ),

                              color: Colors.lightBlue.shade400,
                            ),

                            child:
                            TextField(
                              controller:
                              TextEditingController(
                                  text: '£${((double.tryParse(_cashController.text) ?? 0) * 0.2).toStringAsFixed(2)}'
                              ),

                              style:
                              const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              enabled: false,

                            ),
                          ),  // CASH VAT DISPLAY
                          // ======================================
                          _sizedPadding(height: 0.05),
                          Container( // SERVICE CHARGE VAT
                            width: screenWidth * 0.15,
                            margin:
                            EdgeInsets
                                .fromLTRB(screenWidth * 0.02, 0,0, 0),
                            padding:
                            const EdgeInsets.all(5.0),

                            decoration:
                            BoxDecoration(
                              border: Border.all(
                                width: 5.0,
                                color: Colors.lightBlue.shade200,
                              ),

                              color: Colors.lightBlue.shade400,
                            ),

                            child:
                            TextField(
                              controller:
                              TextEditingController(
                                  text: '£${((double.tryParse(_sChargeController.text) ?? 0) * 0.2).toStringAsFixed(2)}'
                              ),

                              style:
                              const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              enabled: false,

                            ),
                          ),  // SERVICE CHARGE VAT DISPLAY
                          // ======================================
                          _sizedPadding(height: 0.1),
                          Container( // DAY'S TOTAL VAT
                            width: screenWidth * 0.15,
                            margin:
                            EdgeInsets
                                .fromLTRB(screenWidth * 0.02, 0,0, 0),
                            padding:
                            const EdgeInsets.all(5.0),

                            decoration:
                            BoxDecoration(
                              border: Border.all(
                                width: 5.0,
                                color: Colors.lightBlue.shade200,
                              ),

                              color: Colors.lightBlue.shade400,
                            ),

                            child:
                            TextField(
                              controller:
                              TextEditingController(
                                  text: '£${(
                                      ((double.tryParse(_cashController.text) ?? 0) * 0.2)
                                      + ((double.tryParse(_cardController.text) ?? 0) * 0.2)
                                      + ((double.tryParse(_sChargeController.text) ?? 0) * 0.2)
                                  ).toStringAsFixed(2)}'
                              ),

                              style:
                              const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              enabled: false,

                            ),
                          ),  // DAY'S TOTAL VAT DISPLAY
                        ],
                      ),
                    ) // VAT COLUMN
                  ],
                )


          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child:
            Column(
              children: [
                // ======================================
                prefixedCalendar(givenWidth: screenWidth * 0.3, givenHeight: screenHeight * 0.3),
                // ======================================
                _sizedPadding(height: 0.03),
                Row( // Row
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container( // Week's Tips and SC Text
                      padding:
                      const EdgeInsets.all(10.0),

                      decoration:
                      BoxDecoration(
                        border: Border.all(
                          width: 5.0,
                          color: Colors.lightBlue.shade200,
                        ),

                        color: Colors.lightBlue.shade400,
                      ),

                      child:
                      const Text(
                        "Week's Tips\nand SC:",
                        style:
                        TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),

                      ),
                    ), // Week's Tips and SC Text
                    _sizedPadding(width: 0.03, height: 0),
                    Container( // Week's Tips and SC Input Field
                      width: screenWidth * 0.15,
                      padding:
                      const EdgeInsets.all(5.0),

                      decoration:
                      BoxDecoration(
                        border: Border.all(
                          width: 5.0,
                          color: Colors.lightBlue.shade200,
                        ),

                        color: Colors.lightBlue.shade400,
                      ),

                      child:
                      TextField(
                        controller: _weekTipsController,

                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d*)?'))],

                        decoration: const InputDecoration(
                          prefixIcon: Text('£', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                          hintText: '00.00',
                        ),

                        style:
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        enabled: false,

                      ),
                    ), // Week's Tips and SC Input Field
                  ],
                ),  // WEEK'S TIP AND SC TOTAL FIELD
                // ======================================
                _sizedPadding(height: 0.03),
                Row( // Row
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container( // Card Payment Text
                      padding:
                      const EdgeInsets.all(10.0),

                      decoration:
                      BoxDecoration(
                        border: Border.all(
                          width: 5.0,
                          color: Colors.lightBlue.shade200,
                        ),

                        color: Colors.lightBlue.shade400,
                      ),

                      child:
                      const Text(
                        "Week's Total\nVAT:",
                        style:
                        TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),

                      ),
                    ), // Card Payment Text
                    _sizedPadding(width: 0.03, height: 0),
                    Container( // Card Payment Input Field
                      width: screenWidth * 0.15,
                      padding:
                      const EdgeInsets.all(5.0),

                      decoration:
                      BoxDecoration(
                        border: Border.all(
                          width: 5.0,
                          color: Colors.lightBlue.shade200,
                        ),

                        color: Colors.lightBlue.shade400,
                      ),

                      child:
                      TextField(
                        controller: _weekVATController,

                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d*)?'))],

                        decoration: const InputDecoration(
                          prefixIcon: Text('£', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                          hintText: '00.00',
                        ),

                        style:
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        enabled: false,

                      ),
                    ), // Card Payment Input Field
                  ],
                ),  // WEEK'S VAT TOTAL FIELD
                // ======================================
                _sizedPadding(height: 0.05),
                Row( // Row
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container( // Card Payment Text
                      padding:
                      const EdgeInsets.all(10.0),

                      decoration:
                      BoxDecoration(
                        border: Border.all(
                          width: 5.0,
                          color: Colors.lightBlue.shade200,
                        ),

                        color: Colors.lightBlue.shade400,
                      ),

                      child:
                      const Text(
                        'Grand Total:\n(minus VAT)',
                        style:
                        TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),

                      ),
                    ), // Card Payment Text
                    _sizedPadding(width: 0.03, height: 0),
                    Container( // Card Payment Input Field
                      width: screenWidth * 0.15,
                      padding:
                      const EdgeInsets.all(5.0),

                      decoration:
                      BoxDecoration(
                        border: Border.all(
                          width: 5.0,
                          color: Colors.lightBlue.shade200,
                        ),

                        color: Colors.lightBlue.shade400,
                      ),

                      child:
                      TextField(
                        controller: _weekGTotalController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d*)?'))],

                        decoration: const InputDecoration(
                          prefixIcon: Text('£', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                          hintText: '00.00',
                        ),

                        style:
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        enabled: false,

                      ),
                    ), // Card Payment Input Field
                  ],
                ),  // WEEK'S GRAND TOTAL FIELD
              ]
            ),
        ),

      ],
    )
    );
  }
}