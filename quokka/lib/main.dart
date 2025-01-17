import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import 'package:flutter/services.dart'; // For platform channels

void main() {
  runApp(MacroApp());
}

class MacroApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automation App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MacroHomePage(),
    );
  }
}

class MacroHomePage extends StatefulWidget {
  @override
  _MacroHomePageState createState() => _MacroHomePageState();
}

class _MacroHomePageState extends State<MacroHomePage> {
  String _serverTime = "Fetching...";
  bool _isConnected = false;

  static const platform = MethodChannel('com.yourcompany.quokka/accessibility');

  @override
  void initState() {
    super.initState();
    checkAccessibilityService();
  }

  // Check if the Accessibility Service is enabled
  Future<void> checkAccessibilityService() async {
    try {
      final bool isEnabled =
          await platform.invokeMethod('isAccessibilityEnabled');
      setState(() {
        _isConnected = isEnabled;
      });
    } catch (e) {
      print("Failed to check accessibility service: $e");
    }
  }

  // Fetch server time from the provided URL
  Future<DateTime?> fetchServerTime() async {
    try {
      final response =
          await http.head(Uri.parse('https://api.jypfans.com')); // Perform a HEAD request
      debugPrint("Status Code: ${response.statusCode}");
      response.headers.forEach((key, value) {
        debugPrint("$key: $value");
      });

      // Extract the server time from the Date header
      String? serverTime = response.headers['date'];
      if (serverTime != null) {
        DateTime parsedTime = DateTime.parse(serverTime).toLocal();
        setState(() {
          _serverTime = parsedTime.toString();
        });
        return parsedTime;
      } else {
        setState(() {
          _serverTime = "Server time not available";
        });
      }
    } catch (e) {
      setState(() {
        _serverTime = "Error: $e";
      });
    }
    return null;
  }

  // Calculate the time difference and schedule actions
  Future<void> calculateTimeAndSchedule() async {
    DateTime? serverTime = await fetchServerTime();
    if (serverTime == null) return;

    // Target time (e.g., 12:30)
    DateTime now = serverTime;
    DateTime targetTime = DateTime(now.year, now.month, now.day, 12, 30);

    if (now.isAfter(targetTime)) {
      // Schedule for the next day if time has already passed
      targetTime = targetTime.add(Duration(days: 1));
    }

    Duration timeDifference = targetTime.difference(now);
    debugPrint("Time difference: ${timeDifference.inSeconds} seconds");

    // Wait for the time difference, then trigger actions
    Future.delayed(timeDifference, performActions);
  }

  // Perform actions in the external app
  Future<void> performActions() async {
    try {
      // Open the external app and perform actions
      await platform.invokeMethod('performActions', {
        "actions": [
          {"text": "Stray Kids", "bounds": [813, 2013]},
          {"text": "이벤트", "bounds": [1002, 1155]},
          {
            "text": "[2024.12.31] 2024 MBC 가요대제전 참여 안내",
            "bounds": [540, 760]
          },
          {"text": "신청마감", "bounds": [540, 2064]}
        ]
      });
    } catch (e) {
      print("Failed to perform actions: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Macro App"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Server Time: $_serverTime"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: calculateTimeAndSchedule,
              child: Text("Schedule Actions"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_isConnected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Accessibility Service is enabled.")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "Enable Accessibility Service for this app.")),
                  );
                }
              },
              child: Text("Check Accessibility Service"),
            ),
          ],
        ),
      ),
    );
  }
}
