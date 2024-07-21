import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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


/// USER CLASSES ///
//#region


//#endregion

class _IncomeRoutesHomePageState extends State<IncomeRoutesHomePage> {

  /// VARIABLES ///



  /// ========= ///
  /// Overrides ///
  /// ========= ///
  //#region
  @override
  void initState() {
    super.initState();
    dbFetchMembers();
  }

  @override
  void dispose() {
    //Saving Information Logic

    super.dispose();
  }

  Future<void> SaveMessage() async {
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
  //#endregion

  /// === FIRESTORE METHODS === ///
  //#region

  //#endregion

//#endregion

  /// Controller Methods ///
  //#region
  void updateSum({String voucher = ''}) { /*
    int value1 = int.tryParse(pointController.text) ?? 0;
    int value2 = int.tryParse(tdPointController.text) ?? 0;
    int sum = value1 + value2;
    setState(() {
      sumController.text = sum.toString();
      if (sum > 199 && !gotVoucher) {
        gotVoucher = true;
        selectedMember.voucher = DateTime.now().add(const Duration(days:31));
      }

      voucherController = TextEditingController(text: (gotVoucher ? selectedMember.voucher.toString().split(' ')[0] : 'Inactive'));
    });
  */ }

  //#endregion
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
          title: const Text('Membership Manager'),
          toolbarHeight: 80.0,
          backgroundColor: Colors.indigo,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: Colors.indigo.shade100,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children:[
                ElevatedButton(
                  onPressed: (){
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20.0),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.save),
                ),
              ],
            ),
          ],
        ),

        body: Row(
      children: [],
    );
  }
}