import 'package:flutter/material.dart';


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

class Member{
  final String name,id;
  final int points;

  Member(this.name, this.id, this.points);
}

class _MembershipHomePageState extends State<MembershipHomePage> {

  List<Member> sampleMembers = [
    Member("Alice", '001', 150),
    Member("Bob",  '008', 120),
    Member("Carol",  '018', 180),
    Member("David",  '025', 90),
    Member("Eve",  '035', 160),
    Member("Frank",  '042', 130),
    Member("Grace",  '052', 170),
    Member("Harry",  '059', 110),
    Member("Ivy",  '069', 140),
    Member("Jack",  '076', 170),
    Member("Karen",  '086', 100),
    Member("Larry",  '093', 190),
    Member("Megan",  '100', 110),
    Member("Nancy",  '107', 140),
    Member("Oscar",  '117', 180),
  ];
  List<Member> filteredMembers = [];

  @override
  void initState() {
    super.initState();
    filteredMembers = sampleMembers;
  }

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
        backgroundColor: Colors.indigo,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Row(

        children: [Align(

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
              height: screenHeight * 0.7,
              width:  screenWidth * 0.7,

              child: Column(

                children: [Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search member...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        // Implement the filtering logic here
                        if (value.isNotEmpty) {
                          setState(() {
                            filteredMembers = sampleMembers
                                .where((member) =>
                                member.name.toLowerCase().contains(
                                    value.toLowerCase()))
                                .toList() +
                              sampleMembers
                              .where((member) =>
                              member.id.contains(value)).toList();
                          });
                        }else{
                          setState(() {
                            filteredMembers = sampleMembers;
                          });
                        }

                      },
                    ),
                  ),
                  Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // Number of columns in the grid
                    ),
                    itemCount: filteredMembers.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _buildGridItem(filteredMembers[index]);
                    },
                  ),
                ),]
              ),
            ),
          ),
        )],
      )
    );
  }

  //Items for the grid
  Widget _buildGridItem(Member member) {
    return Card(
      child: Center(
        child: Text(
          member.id,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18,),
        ),
      ),
    );
  }
}