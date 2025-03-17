import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Utils {
  static void showAlert(BuildContext context, String title, List<Widget> children) {
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

  static ButtonStyle getButtonStyle() {
    return ElevatedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))));
  }
}