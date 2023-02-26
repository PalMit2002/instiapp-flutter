import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart' as webview;
import 'package:permission_handler/permission_handler.dart';

import '../utils/common_widgets.dart';

class PutEntityPage extends StatefulWidget {
  final String? entityID;
  final String cookie;
  final bool isBody;

  const PutEntityPage({Key? key, required this.cookie, this.entityID, this.isBody = false}) : super(key: key);

  @override
  _PutEntityPageState createState() => _PutEntityPageState();
}

class _PutEntityPageState extends State<PutEntityPage> {
  final String hostUrl = 'https://www.insti.app/';
  final String addEventStr = 'add-event';
  final String editEventStr = 'edit-event';
  final String editBodyStr = 'edit-body';
  final String loginStr = 'login';
  final String sandboxTrueQParam = 'sandbox=true';

  bool firstBuild = true;
  bool addedCookie = false;
  bool hasPermission = false;

  StreamSubscription<String>? onUrlChangedSub;
  webview.WebViewController? webViewController;

  // Storing for dispose
  ThemeData? theme;

  @override
  void initState() {
    // Permission.camera.request();
    if (Platform.isAndroid) {
      Permission.storage.request().then((PermissionStatus e) {
        if (e.isGranted) {
          setState(() {
            hasPermission = true;
          });
        }
      });
    } else {
      Permission.photos.request().then((PermissionStatus e) {
        if (e.isGranted) {
          setState(() {
            hasPermission = true;
          });
        }
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    onUrlChangedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    String url =
        "$hostUrl${widget.entityID == null ? addEventStr : ("${widget.isBody ? editBodyStr : editEventStr}/${widget.entityID!}")}?${widget.cookie}&$sandboxTrueQParam";
    return Scaffold(
      bottomNavigationBar: MyBottomAppBar(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const BackButton(),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(
                Icons.refresh_outlined,
                semanticLabel: 'Refresh',
              ),
              onPressed: () {
                webViewController?.reload();
              },
            ),
          ],
        ),
      ),
      body: hasPermission
          ? Center(
              child: Text(
                'Permission Denined',
                style: theme.textTheme.displayLarge,
              ),
            )
          : webview.WebView(
              // javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (webview.WebViewController controller) {
                webViewController = controller;
              },
              initialUrl: url,
              onPageStarted: (String url) async {
                // print("Changed URL: $url");
                if (url.toString().contains('/event/')) {
                  String uri = url
                      .toString()
                      .substring(url.toString().lastIndexOf('/') + 1);

                  await Navigator.of(context).pushReplacementNamed('/event/$uri');
                } else if (url.toString().contains('/org/')) {
                  String uri = url
                      .toString()
                      .substring(url.toString().lastIndexOf('/') + 1);

                  await Navigator.of(context).pushReplacementNamed('/body/$uri');
                }
              },
            ),
    );
  }
}
