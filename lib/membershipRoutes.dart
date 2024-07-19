import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//Instantiates firestore database for use within flutter application
final db = FirebaseFirestore.instance;

class MembershipHomePage extends StatefulWidget {
  const MembershipHomePage({super.key, required this.title});


  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MembershipHomePage> createState() => _MembershipHomePageState();
}


  /// USER CLASSES ///
  //#region

class Member {
  String name, id;
  String email, contactNum;
  int points;
  DateTime voucher;

  Member({
    this.name = '',
    this.id = '',
    this.email = '',
    this.contactNum = '',
    this.points = 0,
    required this.voucher,
  });

  factory Member.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Helper function to safely parse a value to double
    /*double safeParseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }*/


    return Member(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      contactNum: (data['contactNumber'] as String?) ?? '',
      points: (data['points'] as int?) ?? 0,
      voucher: (data['voucherExpiry'] as Timestamp).toDate(),
    );
  }
}
  //#endregion


Future<void> uploadMember(Member member) async {
  try {
    await db.collection('Members').doc(member.id).set({
      'name': member.name,
      'email': member.email,
      'contactNumber': member.contactNum,
      'points': member.points,
      'voucherExpiry': member.voucher
    });
    print('Member added successfully');
  } catch (e) {
    print('Error adding Member: $e');
  }
}

class _MembershipHomePageState extends State<MembershipHomePage> {

  /// VARIABLES ///
  //#region
  /*
  List<Member> sampleMembers = [
    Member("Alice", '001', 'Alice20@gmail.com', '01214097350', 150, DateTime.now()),
    Member("Bob",  '008', 'Bob20@gmail.com', '01214097350', 120, DateTime.now()),
    Member("Carol",  '018', 'Carol20@gmail.com', '01214097350',180, DateTime.now()),
    Member("David",  '025', 'David20@gmail.com', '01214097350',90, DateTime.now()),
    Member("Eve",  '035', 'Eve20@gmail.com', '01214097350',160, DateTime.now()),
    Member("Frank",  '042', 'Frank20@gmail.com', '01214097350',130, DateTime.now()),
    Member("Grace",  '052', 'Grace20@gmail.com', '01214097350',170, DateTime.now()),
    Member("Harry",  '059', 'Harry20@gmail.com', '01214097350',110, DateTime.now()),
    Member("Ivy",  '069', 'Ivy20@gmail.com', '01214097350',140, DateTime.now()),
    Member("Jack",  '076', 'Jack20@gmail.com', '01214097350',170, DateTime.now()),
    Member("Karen",  '086', 'Karen20@gmail.com', '01214097350',100, DateTime.now()),
    Member("Larry",  '093', 'Larry20@gmail.com', '01214097350',190, DateTime.now()),
    Member("Megan",  '100', 'Megan20@gmail.com', '01214097350',110, DateTime.now()),
    Member("Nancy",  '107', 'Nancy20@gmail.com', '01214097350',140, DateTime.now()),
    Member("Oscar",  '117', 'Oscar20@gmail.com', '01214097350',180, DateTime.now()),
    Member("Sam Tangerine", '207','Sam-TangerGOD20@gmail.com', '01214097350',100, DateTime.now()),
    Member("Polly Amorus", '115','Polly20@gmail.com', '01214097350',100, DateTime.now())
  ];*/ //
  List<Member> rawMembers = [];
  List<Member> filteredMembers = [];
  late TextEditingController nameController, pointController,tdPointController,sumController,voucherController;
  Member selectedMember = Member(voucher: DateTime.now());
  late bool gotVoucher;
  late Color cancelColor;
  //#endregion

  /// ========= ///
  /// Overrides ///
  /// ========= ///
  //#region
  @override
  void initState() {
    super.initState();
    dbFetchMembers();

    nameController = TextEditingController(text: '');
    pointController = TextEditingController(text: '');
    tdPointController = TextEditingController(text: '');
    sumController = TextEditingController(text: '');
    voucherController = TextEditingController(text: '');
    gotVoucher = false;
    _eventDeselect();
  }

  @override
  void dispose() {
    nameController.dispose(); // Dispose of controller to ensure no memory leaks
    pointController.dispose();
    tdPointController.dispose();
    sumController.dispose();
    voucherController.dispose();
    //Saving Information Logic

    super.dispose();
  }
  //#endregion

  /// === FIRESTORE METHODS === ///
  //#region
  Future<void> dbFetchMembers() async {
    try {
      final QuerySnapshot event = await db.collection("Members").get();
      setState(() {
        rawMembers = event.docs.map((doc) => Member.fromFirestore(doc)).toList();
      });
      filteredMembers = rawMembers;
    } catch (e) {
      print("Error fetching employee data: $e ~ dbFetchEmployees(else)");
      // Handle the error appropriately, e.g., show a user-friendly message
    }
  }
  //#endregion


  /// Event Listeners ///
  //Triggers on member deselection
  //#region
  void _eventDeselect(){
    setState(() {
      cancelColor = Colors.grey;
    });
    print("Deselected");
  }

  void _eventSelect(){
    setState(() {
      cancelColor = Colors.white;
    });
  }
//#endregion

  /// Controller Methods ///
  //#region
  void updateSum({String voucher = ''}) { // Updates {sumController} with prev points and today points, checks for voucher eligibility and sets state.
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
  }

  void updateControllers( //Default - clears all controllers, otherwise allows editing of controllers.
      {String name = '',
      String prev = '',
      String today = '',
      String sum = '',
      String voucher = ''}){
    nameController = TextEditingController(text: name);
    pointController = TextEditingController(text: prev);
    tdPointController = TextEditingController(text: today);
    sumController = TextEditingController(text: sum);
    gotVoucher = voucher != '' ? DateTime.now().isBefore(DateTime.parse(voucher)) : false; //false = expired, true = active

    updateSum(voucher: voucher);
  }
  //#endregion

  /// Member Editing Methods ///
  //#region
  void pointsOverflow({String compID = ''}){
    compID = compID == '' ? selectedMember.id : compID;
    for(int i = 0; i < rawMembers.length; i++){
      if (compID == rawMembers[i].id){
        rawMembers[i].points = int.parse(sumController.text) > 199 ?
        int.parse(sumController.text) - 200 : int.parse(sumController.text); //Change required for else statement
      }
    }
  }

  void deleteMember() {
    if (cancelColor == Colors
        .redAccent) { // If the button is already red, delete selected member
      for (int i = 0; i < rawMembers.length; i++) {
        if (selectedMember.id == rawMembers[i].id) {
          for (int j = 0; j < filteredMembers.length; j++) {
            if (selectedMember.id == filteredMembers[j].id) {
              filteredMembers.removeAt(j);
              break;
            }
          }
          setState(() {
            rawMembers.removeAt(i);
            selectedMember = Member(voucher: DateTime.now());
            updateControllers();
            _eventDeselect();
          });
        }
      }
    }
    else if(cancelColor == Colors.grey){}
    else {
      setState(() {
        cancelColor = Colors.redAccent;
      });
    }
  }

  void addMember(){
    setState(() {
      selectedMember = Member(voucher: DateTime.now());
    });
    int i = 1; //stores last checked id
    for (int j = 0; j < rawMembers.length; j++){ //looks for the lowest available id
      if (int.parse(rawMembers[j].id) != i){ //condition if id found is not exactly 1 higher than id prior
        selectedMember.id = ' '; //placeholder to indicate available id found
        break;
      }
      i++;
    }
    if (selectedMember.id == ''){ //if prior search didn't find an id, give end id
      i = int.parse(rawMembers[rawMembers.length - 1].id);
    }
    selectedMember.id = i < 10 ? '00$i' : i > 99 ?  '$i' : '0$i'; //actual id being given using i
    Member temp = Member(id: selectedMember.id , voucher: DateTime.now());
    selectedMember = Member(voucher: DateTime.now());
    rawMembers.add(temp);
    updateControllers();

  }

//#endregion

  /// -=-=-=-=-=- ///
  ///    MAIN     ///
  /// -=-=-=-=-=- ///

  @override
  Widget build(BuildContext context) {
    rawMembers.sort((a, b) => a.id.compareTo(b.id));
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
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20.0),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.save),
              ),
              _sizedPadding(0.05, 0.01),
              ElevatedButton(
                onPressed: (){
                  addMember();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20.0),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.add),

              ),
              _sizedPadding(0.05, 0.01),
              ElevatedButton( // Delete Member button
                onPressed: (){
                    deleteMember();
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cancelColor,
                  padding: const EdgeInsets.all(20.0),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.cancel_rounded),

              ),
              _sizedPadding(0.05, 0.01),
            ],
          ),
        ],
      ),

      body: Row(

        children: [Center(

          child: Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(4),

            decoration: BoxDecoration(
              color: Colors.indigo.shade100,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: Colors.indigo.shade300, // Set the border color here
                width: 10.0, // Set the border width here
              ),
            ),

            child: SizedBox(
              //dynamic sizing
              height: screenHeight * 0.6,
              width:  screenWidth * 0.45,

              child: Column(

                children: [Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search member...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              // Implement the filtering logic here
                              if (value.isNotEmpty) {
                                setState(() {
                                  filteredMembers = rawMembers
                                      .where((member) =>
                                      member.name.toLowerCase().contains(
                                          value.toLowerCase()))
                                      .toList() +
                                      rawMembers
                                    .where((member) =>
                                    member.id.contains(value)).toList();
                                });
                              }else{
                                setState(() {
                                  filteredMembers = rawMembers;
                                });
                              }
                            },
                          ),
                      ),


                      ],
                    ),
                  ),
                  Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // Number of columns in the grid
                    ),
                    itemCount: filteredMembers.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            pointsOverflow();

                            if (selectedMember.id == filteredMembers[index].id) {
                            _eventDeselect();
                            selectedMember = Member(voucher: DateTime.now());
                            }
                            else {
                              _eventSelect();
                              selectedMember = filteredMembers[index];
                            }

                            updateControllers(
                              name: selectedMember.name,
                              prev: selectedMember.points.toString(),
                              voucher: selectedMember.voucher.toString().split(' ')[0],
                            );
                          });
                        },
                        child: _buildGridItem(filteredMembers[index]),
                      );
                    },
                  ),
                ),]
              ),
            ),
          ),
        ),
        Expanded(
          child:
            Container(
              margin: const EdgeInsets.only(
                left: 4,
                top: 16,
                right: 16,
                bottom: 8,
              ),
              padding: const EdgeInsets.all(4),

              decoration: BoxDecoration(
                color: Colors.indigo.shade100,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: Colors.indigo.shade300, // Set the border color here
                  width: 10.0, // Set the border width here
                ),
              ),

              child:
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row( //Text: "Name" and Delete Button
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Text('Name:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsetsDirectional.only(start: 40),
                      ),
                      SizedBox( //Member's name text field
                        width: screenWidth * 0.2,
                        child:
                        TextField(
                          controller: nameController,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                              hintText: "Member's name"
                          ),
                          onChanged: (value){
                            selectedMember.name = value;
                          },
                        ),
                      ),
                    ],
                  ),

                  Row( //Text: "Previous Points" and Input field
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Text('Previous Points:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: screenWidth * 0.1,
                        child: TextField(
                          controller: pointController,
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                  Row( //Text: "Today's Points:" and Input field
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                    children: [
                      const Text("Today's Points:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: screenWidth * 0.1,
                        child: TextField(
                          controller: tdPointController,
                          keyboardType: TextInputType.number, // Set the input type to number
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Accept only digits
                          onChanged: (value){
                            updateSum();
                          },
                        ),
                      ),
                    ],
                  ),
                  Row( //Text: "Total Points:" and Text field (not interactive)
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                    children: [
                      const Text(
                        "Total Points:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: screenWidth * 0.1,
                        child: TextField(
                          controller: sumController,
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                  Row( //Text: "Voucher" field.
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                    children: [
                      const Text('Voucher Expiry (Y-M-D):',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: screenWidth * 0.2,
                        child: TextField(
                          controller: voucherController,
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                  TextButton (
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.indigo.shade200,
                      backgroundColor: Colors.indigo.shade300,
                      padding: const EdgeInsets.all(25),
                    ),

                    onPressed: () {
                      if(!gotVoucher){return;} //Must have voucher to interact with button

                      setState(() {
                        gotVoucher = false;
                        selectedMember.voucher = DateTime.now();
                        updateSum();
                      });
                    },
                    child: const Text(
                        "Deactivate Voucher",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ]
              ),
            )
        ),
        ],
      )
    );
  }

  /// Widgets
  //#region
  //Items for the grid
  Widget _buildGridItem(Member member) {
    bool isSelected = selectedMember.id == member.id;

    return Card(
      color: isSelected ? Colors.indigo.shade200 : Colors.indigo.shade50,
      child: Center(
        child: Text(
          member.id,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18,),
        ),
      ),
    );
  }

  Widget _sizedPadding(double width, double height){
    return SizedBox(
      width:  MediaQuery.of(context).size.width * width,
      height: MediaQuery.of(context).size.height * height
    );
  }
  //#endregion
}