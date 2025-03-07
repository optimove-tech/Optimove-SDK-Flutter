import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:optimove_flutter/optimove_flutter.dart';
import 'package:flutter/services.dart';


import '../inbox.dart';
import '../utils.dart';

class InAppSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 167, 184, 204),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
                style: Utils.getButtonStyle(),
                onPressed: () async {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Inbox()));
                },
                child: const Text('Inbox')),
            ElevatedButton(
                style: Utils.getButtonStyle(),
                onPressed: () async {
                  var summary = await Optimove.inAppGetInboxSummary();
                  Utils.showAlert(context, 'In-app inbox summary', [Text('Total: ${summary?.totalCount} Unread: ${summary?.unreadCount}')]);
                },
                child: const Text('In-app inbox summary')),
            ElevatedButton(
                style: Utils.getButtonStyle(),
                onPressed: () async {
                  await Optimove.inAppUpdateConsent(true);
                  Utils.showAlert(context, 'In-app consent', [const Text('Opted in to in-app messaging')]);
                },
                child: const Text('Opt in')),
            ElevatedButton(
                style: Utils.getButtonStyle(),
                onPressed: () async {
                  await Optimove.inAppUpdateConsent(false);
                  Utils.showAlert(context, 'In-app consent', [const Text('Opted out from in-app messaging')]);
                },
                child: const Text('Opt out')),
            const DisplayModeSegmentedButton()
          ],
        ),
      ),
    );
  }
}

class DisplayModeSegmentedButton extends StatefulWidget {
  const DisplayModeSegmentedButton({Key? key}) : super(key: key);

  @override
  State<DisplayModeSegmentedButton> createState() => _DisplayModeSegmentedButtonState();
}

class _DisplayModeSegmentedButtonState extends State<DisplayModeSegmentedButton> {
  Set<OptimoveInAppDisplayMode> _selection = {OptimoveInAppDisplayMode.automatic};

  @override
  void initState() {
    super.initState();
    getDisplayMode();
  }
  @override
  Widget build(BuildContext context) {
    return SegmentedButton<OptimoveInAppDisplayMode>(
      selected: _selection,
      onSelectionChanged: (Set<OptimoveInAppDisplayMode> newSelection) {
        Optimove.inAppSetDisplayMode(newSelection.first);
        setState(() {
          _selection = newSelection;
        });
      },
      segments: <ButtonSegment<OptimoveInAppDisplayMode>>[
        ButtonSegment(value: OptimoveInAppDisplayMode.automatic, label: Text(OptimoveInAppDisplayMode.automatic.toStringValue())),
        ButtonSegment(value: OptimoveInAppDisplayMode.paused, label: Text(OptimoveInAppDisplayMode.paused.toStringValue())),
      ],
    );
  }

  Future<void> getDisplayMode() async {
    String data = await DefaultAssetBundle.of(context).loadString("optimove.json");
    final jsonResult = jsonDecode(data);

    String displayMode = jsonResult['inAppDisplayMode'];

    if (displayMode == "paused") {
      setState(() {
        _selection = {OptimoveInAppDisplayMode.paused};
      });
    }
  }
}
