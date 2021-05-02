import 'dart:io';

import 'package:air_brother/air_brother.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Air Brother Scan Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<String> _scannedFiles = [];

  int _counter = 0;

  /// We'll use this to scan for our devices.
  Future<List<Connector>> _fetchDevices = AirBrother.getNetworkDevices(5000);

  /// Connectors is how we communicate with the scanner. Given a connector
  /// we request a scan from it.
  /// Connectors can be retrieved using AirBrother.getNetworkDevices(timeout_millis);
  void _scanFiles(Connector connector) async {
    // This is the list where the paths for the scanned files will be placed.
    List<String> outScannedPaths = [];
    // Scan Parameters are used to configure your scanner.
    ScanParameters scanParams = ScanParameters();
    // In this case we want a scan in a paper of size A6
    scanParams.documentSize = MediaSize.A6;
    // When a scan is completed we get a JobState which could be an error if
    // something failed.
    JobState jobState = await connector.performScan(scanParams, outScannedPaths);
    print ("JobState: $jobState");
    print("Files Scanned: $outScannedPaths");

    // This is how we tell Flutter to refresh so it can use the scanned files.
    setState(() {
      _scannedFiles = outScannedPaths;
    });
  }


  @override
  Widget build(BuildContext context) {

    Widget body;

    // If we have some files scanned, let's display the.
    if (_scannedFiles.isNotEmpty) {
      body = ListView.builder(
          itemCount: _scannedFiles.length,
          itemBuilder: (context ,index) {
            return GestureDetector(
                onTap: () {
                  setState(() {
                    _scannedFiles = [];
                  });
                },
                // The _scannedFiles list contains the path to each image so let's show it.
                child: Image.file(File(_scannedFiles[index])));
          });
    }
    else {

      // If we don't have any files then will allow the user to look for a scanner
      // to scan.
      body = Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder(
          future: _fetchDevices,
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text("Searching for scanners in your network.");
            }

            if (snapshot.hasData) {
              List<Connector> connectors = snapshot.data;

              if (connectors.isEmpty) {
                return Text("No Scanners Found");
              }
              return ListView.builder(
                  itemCount: connectors.length,
                  itemBuilder: (context ,index) {
                    return ListTile(title: Text(connectors[index].getModelName()),
                      subtitle: Text(connectors[index].getDescriptorIdentifier()),
                      onTap: () {
                      // Once the user clicks on one of the scanners let's perform the scan.
                      _scanFiles(connectors[index]);
                      },);
                  });
            }
            else {
              return Text("Searching for Devices");
            }
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            // Add your onPressed code here!
            _fetchDevices = AirBrother.getNetworkDevices(5000);
          });
        },
        tooltip: 'Find Scanners',
        child: Icon(Icons.search),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
