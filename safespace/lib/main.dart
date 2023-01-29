import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:safespace/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:localstore/localstore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import './services/APIService.dart';

import 'palette.dart';

@pragma('vm:entry-point')
Future<void> _messageHandler(RemoteMessage message) async {
  final db = Localstore.instance;
  final id = db.collection('HelpSignals').doc().id;
  db.collection("HelpSignals").doc(id).set({
    'id': id,
    'lat': message.data['lat'],
    'long': message.data['long']
  });
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  final db = Localstore.instance;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Palette.turqouise,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

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

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late TabController tabController;
  late FirebaseMessaging messaging;
  final db = Localstore.instance;
  APIService apiService = APIService();
  bool connected = false;
  String deviceToken = "";
  TextEditingController control = TextEditingController(text: "100");

  @override
  void initState() {
    super.initState();
    messaging = FirebaseMessaging.instance;
    messaging.getToken().then((value){
      apiService.subscribe(value!).then((value) {
        setState(() {
          connected = value;
        });
      }); 
      deviceToken = value;
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      final id = db.collection('HelpSignals').doc().id;
      db.collection('HelpSignals').doc(id).set({
        'id': id,
        'lat': event.data['lat'],
        'long': event.data['long']
      });
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(event.notification!.title!),
              content: Text("${event.notification!.body!} \n\nSee Received SOS Signal tab for more info."),
              actions: [
                TextButton(
                  child: const Text("Close"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
        });
    });

    tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    } 
  }

  Future<void> requestHelp(BuildContext context) async {
    await _determinePosition();
    Position position = await Geolocator.getCurrentPosition();

    bool result = await apiService.requestHelp(LatLng(position.latitude, position.longitude), deviceToken);

    if (result) {
      SnackBar snackBar = SnackBar(
        content: const Text("Emergency Signal Sent"),
        action: SnackBarAction(
          label: "Close",
          onPressed: () {},
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      SnackBar snackBar = SnackBar(
        content: const Text("Something Went Wrong"),
        action: SnackBarAction(
          label: "Close",
          onPressed: () {},
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Widget renderTabBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      height: 30,
      width: 300,
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(borderRadius: BorderRadius.circular(20), color: theme.colorScheme.background, border: Border.all(color: theme.colorScheme.surface, width: 3)),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(
            text: "Send SOS Signal",
          ),
          Tab(
            text: "Received SOS Signals",
          )
        ],
      ),
    );
  }

  Widget renderSecondTab() {
    return FutureBuilder(
      future: db.collection('HelpSignals').get(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        List<dynamic> signals;
        if (snapshot.hasData) {
          List<dynamic> temp = snapshot.data.values.toList();
          signals = temp.reversed.toList();
        } else {
          signals = [];
        }

        return Column(
          children: [
          
            Padding(
              padding: EdgeInsets.fromLTRB(6, 0, 6, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () {
                  setState(() {
                    
                  });
                }, 
                child: Text("Refresh")),
                TextButton(onPressed: () async {
                  await _determinePosition();
                  List<dynamic> markers = signals;
                  Navigator.push(context, MaterialPageRoute(builder: ((context) => Maps(markers: markers,))));
                }, 
                child: Text("See All")),
              ],
            ),
            ),
            Expanded(
              child: signals.isNotEmpty ? ListView.builder(
          itemCount: signals.length,
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
              leading: const Icon(Icons.emergency),
              title: Text("Latitude: ${signals[index]['lat']}, Longtitude: ${signals[index]['long']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding:  const EdgeInsets.fromLTRB(0, 0, 6, 0),
                    child: InkWell(borderRadius: BorderRadius.circular(10), child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.map, size: 18,),), 
                    onTap: () async {
                      await _determinePosition();
                      List<dynamic> markers = [signals[index]];
                      Navigator.push(context, MaterialPageRoute(builder: ((context) => Maps(markers: markers,))));
                    },
                  ),
                  ),
                  InkWell(borderRadius: BorderRadius.circular(10), child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete, size: 18,),), 
                    onTap: () {
                      db.collection('HelpSignals').doc(signals[index]['id']).delete();
                      setState(() {
                        
                      });
                    },
                  ),
                ],
              ),
            ),
            );
          },
        ) : Container(),
            )
          ],
        );
      },
    );
  }

  Widget renderTabView(ThemeData theme) {
    return Expanded(
      child: TabBarView(controller: tabController, children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(0, 130, 0, 100),
              child: Material(
              type: MaterialType.transparency, //Makes it usable on any background color, thanks @IanSmith
              child: Ink(
                
                child: Container(
                  decoration: BoxDecoration(
                  border: Border.all(color: Colors.yellow, width: 30.0),
                  color: Colors.red.shade500,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 3,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ]
                ),
                  child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll<Color>(Colors.red),
                    shape: MaterialStateProperty.all<CircleBorder>(
                      const CircleBorder(side: BorderSide.none)
                    )
                  ),
                  onPressed: (){
                    requestHelp(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Icon(
                      Icons.emergency_outlined,
                      size: 150.0,
                      color: Colors.white,
                    ),
                  ),
                )),
              )
            ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: connected ? [
                Icon(Icons.check, color: theme.colorScheme.primary, size: 30,),
                Text("Connected", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 25),)
              ] : [
                Icon(Icons.cancel, color: Colors.red, size: 30),
                Text("Disconnected", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 25),)
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
              child: SizedBox(
              width: 350,
              child: Text(
              connected ? 
                "Device is connected to SafeSpace. \nPress the button above to broadcast an emergency signal." 
                : "Device is not connected to SafeSpace. \nPlease wait until the connecion process is complete.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            )),
          ],
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(0, 6, 0, 0),
          child: renderSecondTab())
      ],),
    );
  }

  Widget renderTabPageSelector(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: Container(
        decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(20)),
        child: TabPageSelector(
          controller: tabController,
          indicatorSize: 10,
          selectedColor: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40),
        child: AppBar(
          title: renderTabBar(theme),
          backgroundColor: theme.colorScheme.primary,
          centerTitle: (true),
          elevation: 0,
        ),
      ),
      body: Container(
        color: theme.colorScheme.primary,
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: theme.colorScheme.background),
            child: Center(
              child: Stack(alignment: Alignment.center,children: [
                Column(
                  children: [renderTabView(theme)],
                ),
                Positioned(
                  bottom: 20,
                  child: renderTabPageSelector(theme),
                )
              ],),
            ),
          ),
        ),
      ) // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Maps extends StatefulWidget {
  final List<dynamic> markers;

  const Maps({this.markers = const []});

  @override
  _MapsState createState() => _MapsState();
}

class _MapsState extends State<Maps> {

  Set<Marker> _createMarker() {
    Iterable<Marker> ms = widget.markers.map((e) => Marker(
      markerId: MarkerId(e['id']),
      position: LatLng(double.parse(e['lat']),double.parse(e['long'])),
    ));
    return ms.toSet();
  }

  CameraPosition getInitialPosition() {
    return CameraPosition(
      target: LatLng(double.parse(widget.markers[0]['lat']), double.parse(widget.markers[0]['long'])),
      zoom: 15
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SOS Signals"),
      ),
      body: GoogleMap(
        initialCameraPosition: getInitialPosition(), 
        myLocationEnabled: true,
        markers: _createMarker(),
      )
    );
  }
}
