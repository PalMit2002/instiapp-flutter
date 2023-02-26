import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart' as webview;
import 'package:jaguar/jaguar.dart' as jag;
import 'package:jaguar_flutter_asset/jaguar_flutter_asset.dart';

import '../api/apiclient.dart';
import '../api/interceptors.dart';
import '../api/model/user.dart';
import '../bloc_provider.dart';
import '../blocs/ia_bloc.dart';
import '../utils/common_widgets.dart';
import '../utils/notif_settings.dart';

class LoginPage extends StatefulWidget {
  final InstiAppBloc bloc;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final GlobalKey<NavigatorState>? navigatorKey;
  const LoginPage(this.bloc,
      {Key? key, this.scaffoldMessengerKey, this.navigatorKey})
      : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  jag.Jaguar? server;
  final Dio dio = Dio();

  final String successUrl = 'https://www.insti.app/login-android.html';
  final String guestUrl = 'https://guesturi';
  final String alumniUrl = 'https://alumniurl';
  final String gymkhanaUrl = 'https://gymkhana.iitb.ac.in';
  final String httpGymkhanaUrl = 'http://gymkhana.iitb.ac.in';
  final String ssoLogin = 'https://sso.iitb.ac.in/login';
  final String ssoAuth = 'https://sso.iitb.ac.in/authorize';
  InstiAppBloc? _bloc;
  StreamSubscription<String>? onUrlChangedSub;
  bool loading = true;
  bool firstBuild = true;
  // StreamSubscription<WebViewStateChanged>? onStateChangedSub;

  String statusMessage = 'Initializing';

  String? loginurl;
  Session? currSession;

  @override
  void dispose() {
    server?.close();

    onUrlChangedSub?.cancel();
    // onStateChangedSub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => setupNotifications(
        widget.navigatorKey?.currentContext ?? context, widget.bloc));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String? args = ModalRoute.of(context)?.settings.arguments as String?;
      if (args != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(args),
          duration: const Duration(seconds: 2),
        ));
      }
    });

    _bloc = widget.bloc;
    if (Platform.isAndroid) {
      webview.WebView.platform = webview.SurfaceAndroidWebView();
    }

    // Creating login url
    loginurl =
        "http://127.0.0.1:9399/${(_bloc!.brightness.toBrightness() == Brightness.dark) ? "login_dark.html" : "login.html"}";

    checkLogin().then((Session? sess) {
      // If session already exists, continue to homepage with current session
      if (sess != null) {
        _bloc!.patchFcmKey().then((_) {
          _bloc?.reloadCurrentUser();
        });

        Navigator.of(context).pushReplacementNamed(_bloc!.homepageName);
        return;
      }

      // No stored session found
      startLoginPageServer().then((_) async {
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() {
          loading = false;
        });
      });
    });
  }

  Future<Session?> checkLogin() async {
    await _bloc?.restorePrefs();
    return _bloc?.currSession;
  }

  @override
  Widget build(BuildContext context) {
    _bloc = BlocProvider.of(context)!.bloc;

    if (firstBuild) {
      if (widget.scaffoldMessengerKey?.currentContext != null &&
          widget.navigatorKey != null) {
        if (widget.bloc.dio.interceptors.isEmpty) {
          widget.bloc.dio
            ..interceptors.add(ErrorInterceptor(
                context: widget.scaffoldMessengerKey!.currentContext!,
                navigatorKey: widget.navigatorKey!));
        }
      }
      firstBuild = false;
    }

    return loading
        ? Material(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Image(
                    color: Theme.of(context).colorScheme.secondary,
                    image: const AssetImage('assets/login/lotus.png'),
                    width: 250.0,
                    fit: BoxFit.scaleDown,
                  ),
                  Text(
                    'InstiApp',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                  CircularProgressIndicatorExtended(
                    label: Text(statusMessage),
                  ),
                ],
              ),
            ),
          )
        : webview.WebView(
            javascriptMode: webview.JavascriptMode.unrestricted,
            initialUrl: loginurl,
            onPageStarted: (String url) async {
              if (url.startsWith(successUrl)) {
                Uri uri = Uri.parse(url);
                String? code = uri.queryParameters['code'];

                setState(() {
                  loading = true;
                });
                await login(
                    code ?? '', 'https://www.insti.app/login-android.html');
                setState(() {
                  loading = false;
                });
              } else if (url.startsWith(guestUrl)) {
                setState(() {
                  loading = true;
                });
                await Navigator.of(context).pushNamedAndRemoveUntil(
                    _bloc!.homepageName, (Route r) => false);
              } else if (url.startsWith(alumniUrl)) {
                // print(alumniUrl);
                setState(() {
                  loading = true;
                });
                await Navigator.of(context).pushNamedAndRemoveUntil(
                    _bloc!.alumniLoginPage, (Route r) => false);
              }
            },
            onPageFinished: (String url) {},
            gestureNavigationEnabled: true,
          );
  }

  Future<void> startLoginPageServer() async {
    server = jag.Jaguar(port: 9399, multiThread: true);
    server?.addRoute(serveFlutterAssets(prefix: 'login/'));
    return server?.serve();
  }

  Future<void> login(final String authCode, final String redirectUrl) async {
    setState(() {
      statusMessage = 'Logging you in';
    });
    Session? response;
    try {
      response = await InstiAppApi(dio).login(authCode, redirectUrl);
    } catch (e) {
      // print(e);
    }
    if (response?.sessionid != null) {
      _bloc?.updateSession(response);
      setState(() {
        statusMessage = 'Logged in';
      });
      await _bloc?.patchFcmKey();

      await Navigator.of(context)
          .pushReplacementNamed(_bloc?.homepageName ?? '');

      await onUrlChangedSub?.cancel();
    } else {
      setState(() {
        statusMessage = 'Log in failed. Reinitializing.';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Authentication Failed'),
      ));
    }
  }
}
