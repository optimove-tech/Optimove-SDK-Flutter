import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:optimove_sdk_flutter/optimove.dart';

import 'inbox.dart';

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

  String? optimobileIdentifier = "";
  String optimoveVisitorId = "";
  Map<String, dynamic> eventParams = {};

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
    Optimove.setPushOpenedHandler((push) {
      _showAlert('Opened Push', <Widget>[
        Text(push.title ?? 'No title'),
        Text(push.message ?? 'No message'),
        const Text(''),
        Text('Action button tapped: ${push.actionId ?? 'none'}'),
        const Text('Data:'),
        Text(jsonEncode(push.data))
      ]);
    });

    Optimove.setPushReceivedHandler((push) {
      _showAlert('Received Push', <Widget>[
        Text(push.title ?? 'No title'),
        Text(push.message ?? 'No message'),
      ]);
    });

    Optimove.setDeeplinkHandler((outcome) {
      var children = [
        Text('Url: ${outcome.url}'),
        Text('Resolved: ${outcome.resolution}')
      ];

      if (outcome.resolution == OptimoveDeepLinkResolution.LinkMatched) {
        children.addAll([
          Text('Link title: ${outcome.content?.title}'),
          Text('Link description: ${outcome.content?.description}'),
          const Text('Link data:'),
          Text(jsonEncode(outcome.linkData))
        ]);
      }

      _showAlert('Optimove Deep Link', children);
    });

    Optimove.setInAppDeeplinkHandler((data) {
      _showAlert('Optimove In app deeplink', [
        Text(jsonEncode(data))
      ]);
    });
  }
  Future<void> getIdentifiers() async {
    optimobileIdentifier = await Optimove.getUserId();
    optimoveVisitorId = await Optimove.getVisitorId();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color.fromARGB(255, 255, 133, 102),
        onPrimary: Colors.white,
        secondary: Colors.pink,
        onSecondary: Colors.pink,
        error: Colors.pink,
        onError: Colors.pink,
        background: Colors.pink,
        onBackground: Colors.pink,
        surface: Colors.pink,
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
              children: [_userInfoSection(), _getUserIdentitySection(),const SizedBox(height: 8), _getPushSection(), const SizedBox(height: 8),_getReportEventSection(),const SizedBox(height: 8), _getScreenVisitSection(), const SizedBox(height: 8), _getInAppSection()],
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
            Container(alignment: Alignment.centerLeft, child: Text("Current user id: $optimobileIdentifier")),
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
                style: _getButtonStyle(),
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
                style: _getButtonStyle(),
                onPressed: () {
                  Optimove.setUserEmail(email: emailTextController.text);
                },
                child: const Text("Set email")),
            const SizedBox(height: 8),
            ElevatedButton(
                style: _getButtonStyle(),
                onPressed: () {
                  Optimove.registerUser(userId: userIdTextController.text, email: emailTextController.text);
                  getIdentifiers();
                },
                child: const Text("Register user")),
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
                style: _getButtonStyle(),
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

  Widget _getInAppSection() {
    return Card(
      color: const Color.fromARGB(255, 167, 184, 204),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
                style: _getButtonStyle(),
                onPressed: () async {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Inbox()));
                },
                child: const Text('Inbox')),
            ElevatedButton(
                style: _getButtonStyle(),
                onPressed: () async {
                  var summary = await Optimove.getInboxSummary();
                  _showAlert('In-app inbox summary', [
                    Text(
                        'Total: ${summary?.totalCount} Unread: ${summary?.unreadCount}')
                  ]);
                },
                child: const Text('In-app inbox summary')),
            ElevatedButton(
                style: _getButtonStyle(),
                onPressed: () async {
                  await Optimove.updateConsentForUser(true);
                  _showAlert('In-app consent',
                      [const Text('Opted in to in-app messaging')]);
                },
                child: const Text('Opt in')),
            ElevatedButton(
                style: _getButtonStyle(),
                onPressed: () async {
                  await Optimove.updateConsentForUser(false);
                  _showAlert('In-app consent',
                      [const Text('Opted out from in-app messaging')]);
                },
                child: const Text('Opt out')),
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
                style: _getButtonStyle(),
                onPressed: () {
                  Optimove.pushRequestDeviceToken();
                },
                child: const Text("Register push")),
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
                style: _getButtonStyle(),
                onPressed: () {
                  Optimove.reportEvent(event: eventNameTextController.text);
                },
                child: const Text("Report event")),
          ],
        ),
      ),
    );
  }

  void _showAlert(String title, List<Widget> children) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: children,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  ButtonStyle _getButtonStyle() {
    return ElevatedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))));
  }
}