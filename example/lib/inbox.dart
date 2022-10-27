import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optimove_flutter/optimove_flutter.dart';

class Inbox extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _InboxState();
  }
}

class _InboxState extends State<Inbox> {
  List<OptimoveInAppInboxItem> items = [];
  OptimoveInAppInboxSummary? summary;
  Object? error;

  @override
  void initState() {
    super.initState();

    Optimove.setOnInboxUpdatedHandler(() {
      _loadState();
    });

    _loadState();
  }

  @override
  void dispose() {
    super.dispose();
    Optimove.setOnInboxUpdatedHandler(null);
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (null != error) {
      content = Container(
          margin: const EdgeInsets.all(8),
          child: Center(child: Text(error.toString())));
    } else if (null == summary) {
      content = const Center(child: CircularProgressIndicator(value: null));
    } else {
      content = _renderInbox();
    }

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
            leading: BackButton(
                color: Colors.white,
                onPressed: () {
                    Navigator.pop(context);
                },
            ),
            title: const Text('In-app inbox'),
            actions: [
              IconButton(
                  tooltip: 'Mark all read',
                  onPressed: () {
                    Optimove.inAppMarkAllInboxItemsAsRead();
                  },
                  icon: const Icon(Icons.mark_email_read)),
            ],
          ),
          body: SafeArea(
            child: content,
          )),
    );
  }

  _loadState() async {
    try {
      var items = await Optimove.inAppGetInboxItems();
      var summary = await Optimove.inAppGetInboxSummary();

      setState(() {
        this.items = items;
        this.summary = summary;
        error = null;
      });
    } on PlatformException catch (e) {
      // Typically this exception would only happen when the in-app strategy
      // is set to explicit-by-user and consent management is being done
      // manually.
      setState(() {
        error = e.message;
      });
    }
  }

  Widget _renderInbox() {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items'),
      );
    }

    return Column(children: [
      Expanded(
          child: ListView.separated(
              itemBuilder: (ctx, idx) => _renderItem(items[idx]),
              separatorBuilder: (ctx, idx) => const Divider(),
              itemCount: items.length)),
      Container(
        margin: const EdgeInsets.all(8),
        child: Text(
            'Total: ${summary?.totalCount} Unread: ${summary?.unreadCount}'),
      ),
    ]);
  }

  Widget _renderItem(OptimoveInAppInboxItem item) {
    return ListTile(
      key: Key(item.id.toString()),
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      leading: Icon(
        Icons.label_important,
        color: item.isRead
            ? Theme.of(context).disabledColor
            : Theme.of(context).indicatorColor,
      ),
      trailing: item.imageUrl != null
          ? CircleAvatar(
        backgroundColor: Colors.grey.shade400,
        backgroundImage: NetworkImage(item.imageUrl!),
      )
          : null,
      onTap: () {
        showDialog(context: context, builder: (context) {
          return AlertDialog(
            title: const Text("Inbox data"),
            content: SingleChildScrollView(
              child:  Text(jsonEncode(item.data)),
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
      },
      onLongPress: () {
        showModalBottomSheet(
            context: context,
            builder: (context) {
              return SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading:const Icon(Icons.remove_red_eye),
                        title: const Text(
                          'View',
                        ),
                        onTap: () {
                          Optimove.inAppPresentInboxMessage(item);
                        },
                      ),
                      ListTile(
                        leading:const Icon(Icons.mark_email_read),
                        title: const Text(
                          'Mark as read',
                        ),
                        onTap: () {
                          Optimove.inAppMarkAsRead(item);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text(
                          'Delete from inbox',
                        ),
                        onTap: () {
                          Optimove.inAppDeleteMessageFromInbox(item);
                          Navigator.pop(context);
                        },
                      )
                    ],
                  ));
            });
      },
    );
  }
}