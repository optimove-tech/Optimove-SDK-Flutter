import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:optimove_flutter_sdk/optimove.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _optimoveFlutterSdkPlugin = Optimove();
  late final TextEditingController userIdTextController;
  late final TextEditingController emailTextController;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    userIdTextController = TextEditingController();
    emailTextController = TextEditingController();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _optimoveFlutterSdkPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Optimove SDK QA'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                color: Colors.white30,
                child: Column(
                  children: [
                    TextField(
                        controller: userIdTextController,
                        decoration: const InputDecoration(
                          hintText: 'User id',
                        )
                    ),
                    ElevatedButton(
                        onPressed: () {
                          Optimove.setUserId(userId: userIdTextController.text);
                        },
                        child: const Text("Set user id")),
                    const SizedBox(height: 16),
                    TextField(
                        controller: emailTextController,
                        decoration: const InputDecoration(
                          hintText: 'Email',
                        )
                    ),
                    ElevatedButton(
                        onPressed: () {
                          Optimove.setUserEmail(email: emailTextController.text);
                        },
                        child: const Text("Set email")),
                    const SizedBox(height: 8),
                    ElevatedButton(
                        onPressed: () {
                          Optimove.registerUser(userId: userIdTextController.text, email: emailTextController.text);
                        },
                        child: const Text("Register user")),
                  ],
                ),
              )

            ],
          )),
        ),
      ),
    );
  }
}
