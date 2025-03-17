import 'dart:async';
import 'dart:convert';

import 'package:Optimove/utils.dart';
import 'package:Optimove/widgets/in_app_section.dart';
import 'package:Optimove/widgets/location_section.dart';
import 'package:flutter/material.dart';
import 'package:optimove_flutter/optimove_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<HomePage> {
  late final TextEditingController userIdTextController;
  late final TextEditingController emailTextController;

  late final TextEditingController pageTitleTextController;
  late final TextEditingController pageCategoryTextController;

  late final TextEditingController eventNameTextController;

  String optimoveVisitorId = "";
  Map<String, dynamic> eventParams = {};
  OptimoveInAppDisplayMode initialDisplayMode = OptimoveInAppDisplayMode.automatic;

  @override
  void initState() {
    super.initState();
    initListeners();
    getIdentifiers();
    userIdTextController = TextEditingController();
    emailTextController = TextEditingController();

    pageTitleTextController = TextEditingController();
    pageCategoryTextController = TextEditingController();

    eventNameTextController = TextEditingController();
  }

  Future<void> initListeners() async {
    Optimove.setPushOpenedAndDeeplinkHandlers((push) {
      Utils.showAlert(context, 'Opened Push', <Widget>[
        Text(push.title ?? 'No title'),
        Text(push.message ?? 'No message'),
        const Text(''),
        Text('Action button tapped: ${push.actionId ?? 'none'}'),
        const Text('Data:'),
        Text(jsonEncode(push.data))
      ]);
    }, (outcome) {
      var children = [Text('Url: ${outcome.url}'), Text('Resolved: ${outcome.resolution}')];

      if (outcome.resolution == OptimoveDeepLinkResolution.LinkMatched) {
        children.addAll([
          Text('Link title: ${outcome.content?.title}'),
          Text('Link description: ${outcome.content?.description}'),
          const Text('Link data:'),
          Text(jsonEncode(outcome.linkData))
        ]);
      }

      Utils.showAlert(context, 'Optimove Deep Link', children);
    });

    Optimove.setPushReceivedHandler((push) {
      Utils.showAlert(context, 'Received Push', <Widget>[Text(push.title ?? 'No title'), Text(push.message ?? 'No message'), const Text('Data:'), Text(jsonEncode(push.data))]);
    });

    Optimove.setInAppDeeplinkHandler((inAppPress) {
      Utils.showAlert(context, 'Optimove In app deeplink', <Widget>[
        Text('Message id: ${inAppPress.messageId}'),
        Text('Message data: ${jsonEncode(inAppPress.messageData)}'),
        Text('Deeplink data: ${jsonEncode(inAppPress.deepLinkData)}'),
      ]);
    });
  }

  Future<void> getIdentifiers() async {
    optimoveVisitorId = await Optimove.getVisitorId();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Colors.white,
        onPrimary: Colors.white,
        secondary:Color.fromARGB(255, 255, 133, 102),
        onSecondary: Colors.white,
        error: Colors.pink,
        onError: Colors.pink,
        surface: Color.fromARGB(255, 255, 133, 102),
        onSurface: Colors.black,
      )),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Optimove Flutter QA'),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _userInfoSection(),
                _getUserIdentitySection(),
                const SizedBox(height: 8),
                _getPushSection(),
                const SizedBox(height: 8),
                _getReportEventSection(),
                const SizedBox(height: 8),
                _getScreenVisitSection(),
                const SizedBox(height: 8),
                InAppSection(),
                const SizedBox(height: 8),
                LocationSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _userInfoSection() {
    return Card(
      color: const Color.fromARGB(255, 167, 184, 204),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Container(alignment: Alignment.centerLeft, child: Text("Current visitor id: $optimoveVisitorId")),
          ],
        ),
      ),
    );
  }

  Widget _getUserIdentitySection() {
    return Card(
      color: const Color.fromARGB(255, 167, 184, 204),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
                controller: userIdTextController,
                decoration: const InputDecoration(
                  hintText: 'User id',
                )),
            ElevatedButton(
                style: Utils.getButtonStyle(),
                onPressed: () {
                  Optimove.setUserId(userId: userIdTextController.text);
                  getIdentifiers();
                },
                child: const Text("Set user id")),
            TextField(
                controller: emailTextController,
                decoration: const InputDecoration(
                  hintText: 'Email',
                )),
            ElevatedButton(
                style: Utils.getButtonStyle(),
                onPressed: () {
                  Optimove.setUserEmail(email: emailTextController.text);
                },
                child: const Text("Set email")),
            ElevatedButton(
                style: Utils.getButtonStyle(),
                onPressed: () {
                  Optimove.registerUser(userId: userIdTextController.text, email: emailTextController.text);
                  getIdentifiers();
                },
                child: const Text("Register user")),
            ElevatedButton(
                style: Utils.getButtonStyle(),
                onPressed: () {
                  Optimove.signOutUser();
                  getIdentifiers();
                },
                child: const Text("Sign out")),
          ],
        ),
      ),
    );
  }

  Widget _getScreenVisitSection() {
    return Card(
      color: const Color.fromARGB(255, 167, 184, 204),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
                controller: pageTitleTextController,
                decoration: const InputDecoration(
                  hintText: 'Page title',
                )),
            TextField(
                controller: pageCategoryTextController,
                decoration: const InputDecoration(
                  hintText: 'Page category (optional)',
                )),
            ElevatedButton(
                style: Utils.getButtonStyle(),
                onPressed: () {
                  if (pageCategoryTextController.text.isEmpty) {
                    Optimove.reportScreenVisit(screenName: pageTitleTextController.text);
                  } else {
                    Optimove.reportScreenVisit(screenName: pageTitleTextController.text, screenCategory: pageCategoryTextController.text);
                  }
                },
                child: const Text("Report screen visit")),
          ],
        ),
      ),
    );
  }

  Widget _getPushSection() {
    return Card(
      color: const Color.fromARGB(255, 167, 184, 204),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
                style: Utils.getButtonStyle(),
                onPressed: () {
                  Optimove.pushRequestDeviceToken();
                },
                child: const Text("Register push")),
            ElevatedButton(
                style: Utils.getButtonStyle(),
                onPressed: () {
                  Optimove.pushUnregister();
                },
                child: const Text("Unregister push")),
          ],
        ),
      ),
    );
  }

  Widget _getReportEventSection() {
    return Card(
      color: const Color.fromARGB(255, 167, 184, 204),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
                controller: eventNameTextController,
                decoration: const InputDecoration(
                  hintText: 'Event name',
                )),
            ElevatedButton(
                style: Utils.getButtonStyle(),
                onPressed: () {
                  Optimove.reportEvent(event: eventNameTextController.text, parameters: {"string_param": "some_param"});
                },
                child: const Text("Report event")),
          ],
        ),
      ),
    );
  }
}
