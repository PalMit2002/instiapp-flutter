// import 'dart:convert';
// import 'dart:developer';
// import 'dart:ffi';

import 'package:flutter/material.dart';
// import 'package:flutter_html/shims/dart_ui_real.dart';
// import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../bloc_provider.dart';
import '../blocs/ia_bloc.dart';
import '../drawer.dart';
import '../utils/common_widgets.dart';
import '../utils/title_with_backbutton.dart';

class QRPage extends StatefulWidget {
  const QRPage({Key? key}) : super(key: key);

  @override
  _QRPageState createState() => _QRPageState();
}

class _QRPageState extends State<QRPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  String? qrString;
  bool first = true;
  bool loading = true;
  bool error = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> getQRString(InstiAppBloc bloc) async {
    String? qr = await bloc.getQRString();
    if (qr == 'Error' || qr == null) {
      setState(() {
        error = true;
        loading = false;
      });
    } else {
      setState(() {
        qrString = qr;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    InstiAppBloc bloc = BlocProvider.of(context)!.bloc;

    if (first && bloc.currSession != null) {
      getQRString(bloc);
      first = false;
    }

    return Scaffold(
      key: _scaffoldKey,
      bottomNavigationBar: MyBottomAppBar(
        shape: const RoundedNotchedRectangle(),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              tooltip: 'Show bottom sheet',
              icon: const Icon(
                Icons.menu_outlined,
                semanticLabel: 'Show bottom sheet',
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ],
        ),
      ),
      drawer: const NavDrawer(),
      body: SafeArea(
        child: bloc.currSession == null
            ? Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud,
                      size: 200,
                      color: Colors.grey[600],
                    ),
                    Text(
                      'Login To View QR',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              )
            : ListView(
                children: [
                  TitleWithBackButton(
                    child: Text(
                      'QR Code',
                      style: theme.textTheme.displaySmall,
                    ),
                  ),
                  if (loading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else
                    error
                        ? Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(50),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud,
                                  size: 200,
                                  color: Colors.grey[600],
                                ),
                                Text(
                                  'Some error in generating QR',
                                  style: theme.textTheme.headlineSmall,
                                  textAlign: TextAlign.center,
                                )
                              ],
                            ),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            margin: const EdgeInsets.all(50),
                            alignment: Alignment.center,
                            height: MediaQuery.of(context).size.height / 2,
                            child: QrImage(
                              // data: '',
                              data: '$qrString',
                              size: MediaQuery.of(context).size.width / 2,
                              foregroundColor: Colors.black,
                            ),
                          ),
                ],
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButton: (bloc.currSession?.profile != null)
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.calendar_month),
              label: const Text('Mess Calendar'),
              onPressed: () {
                Navigator.of(context).pushNamed('/messcalendar');
              },
            )
          : null,
    );
  }
}
