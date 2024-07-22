import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:om_salary_and_membership/salaryRoutes.dart';
import 'package:om_salary_and_membership/membershipRoutes.dart';
import 'package:om_salary_and_membership/incomeRoutes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//Instantiates firestore database for use within flutter application
late final FirebaseFirestore db;

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // <-- Ensure Flutter is initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  db = FirebaseFirestore.instance;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) { 
    return MaterialApp(
      title: 'OM App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'OM Salary and Membership App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  /// === VARIABLES === ///
  int authorised = 0;
  String signedUser = '';
  late TextEditingController usrNameController;
  late TextEditingController passController;


  /// === OVERRIDES === ///
  @override
  void initState() {
    super.initState();
    usrNameController = TextEditingController(text:'');
    passController = TextEditingController(text: '');
  }

  @override
  void dispose(){
    usrNameController.dispose();
    passController.dispose();
    super.dispose();
  }


  /// === METHODS === ///
  Widget _sizedPadding({double width = 0.1, double height = 0.1}){
    return SizedBox(
        width:  MediaQuery.of(context).size.width * width,
        height: MediaQuery.of(context).size.height * height
    );
  }

  // true if successful, false otherwise
  Future<void> trySignIn() async {
    try {
      final DocumentSnapshot doc = await db.collection("Users").doc(usrNameController.text).get();
      if (doc.exists) {
        if(doc['password'] == passController.text) {
          setState(() {
            authorised = doc['hasFullAccess'] ? 2 : 1;
            signedUser = doc.id;
            signInMessage(true);
          });
          return;
        }
      }
      // Handle the case where the document doesn't exist, e.g., show a user-friendly message
      setState((){
        signInMessage(false);
      });
    }
    catch (e) {
      signInMessage(false);
    }
  }

  Future<void> signInMessage(bool isSuccess) async {
    return showDialog<void>(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: Text((isSuccess ? 'Successfully signed in!' : 'Wrong username\nor password')),
            content: Text(isSuccess ? 'You can now access\n${authorised < 2 ? 'membership services!' : 'all services!'}' : 'Please try again.'),
            actions: [
              TextButton(onPressed: (){Navigator.of(context).pop();}, child: const Text('OK')),
            ],
          );
        }
    );
  }


  /// /// //// /// ///
  /// /// MAIN /// ///
  /// /// //// /// ///

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth  = MediaQuery.of(context).size.width;


    return Scaffold(
      appBar: AppBar(

        backgroundColor: Colors.deepPurple,

        title: Text(widget.title, style: const TextStyle(color: Colors.white70)),
        actions: [
          Text(signedUser, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w400),),
          _sizedPadding(width: 0.01),
          const Icon(Icons.account_circle, color: Colors.white, size: 36,),
          _sizedPadding(width: 0.1),
        ],
      ),

      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          //_sizedPadding(width: 0.2),
          Column(
            children: [
              Image.asset(
                'assets/images/OM.jpg',
                scale: 2,
              ),
              Container(
                width: screenWidth * 0.4,
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border.all(width: 5, color: Colors.grey.shade600),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                  Column(
                    children: [
                      _sizedPadding(height: 0.01),
                      const Text('Username:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                      Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(width: 5)),
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                        child: TextField(
                          controller: usrNameController,
                          style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15),
                        ),
                      ),
                      const Text('Password:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                      Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(width: 5)),
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                        child: TextField(
                          controller: passController,
                          obscureText: true,
                          style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(width: 3)),
                        margin: const EdgeInsets.all(5),
                        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                        child: TextButton(
                          onPressed: (){
                            trySignIn().then((_) {
                                usrNameController.text = '';
                                passController.text = '';
                              });
                          },
                          child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w400, color: Colors.black),),
                        ),
                      ),


                    ],
                  ),
              ),
            ],
          ),

          Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[

            const Text(
              'Would you like to manage the:',
              style: TextStyle( fontSize: 30 ),
            ),
            TextButton(
              style:
                ButtonStyle( backgroundColor: WidgetStateProperty.resolveWith((states){
                  if (states.contains(WidgetState.disabled)) {return Colors.grey;}
                  else {return (const Color.fromRGBO(149, 117, 205, 1));}
                }),
              ),

              onPressed: authorised < 1 ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MembershipHomePage(title: 'Membership Manager',) //Remember to change this out!
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Memberships',
                    style: TextStyle( fontSize: 24, color: (authorised < 1 ? Colors.grey.shade200 : Colors.white),),
                ),
              ),
            ),
            TextButton(
              style:
                ButtonStyle( backgroundColor: WidgetStateProperty.resolveWith((states){
                  if (states.contains(WidgetState.disabled)) {return Colors.grey;}
                  else {return Colors.lightGreen;}
                  }),
                ),
              onPressed: authorised < 2 ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SalaryHomePage(title: 'Salary Manager',)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Salaries',
                style: TextStyle( fontSize: 24, color: (authorised < 1 ? Colors.grey.shade200 : Colors.white),)),
              ),
            ),


            TextButton(
              style:
                ButtonStyle( backgroundColor: WidgetStateProperty.resolveWith((states){
                  if (states.contains(WidgetState.disabled)) {return Colors.grey;}
                  else {return const Color.fromARGB(255, 66, 165, 245);}
                }),
                ),
              onPressed: authorised < 2 ? null : ()  {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IncomeRoutesHomePage(title: 'Business Income Manager',)
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Business Income',
                    style: TextStyle( fontSize: 24, color: (authorised < 1 ? Colors.grey.shade200 : Colors.white))),
              ),
            )
          ],
        ),],
      ),
    );
  }
}
