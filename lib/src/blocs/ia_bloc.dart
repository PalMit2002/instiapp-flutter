import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
// import 'package:http/io_client.dart';
// import 'package:http/browser_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../api/apiclient.dart';
import '../api/chatbotapiclient.dart';
import '../api/model/achievements.dart';
import '../api/model/body.dart';
import '../api/model/community.dart';
import '../api/model/event.dart';
import '../api/model/mess.dart';
import '../api/model/notification.dart' as ntf;
import '../api/model/role.dart';
import '../api/model/user.dart';
import '../api/model/venter.dart';
import '../api/request/achievement_hidden_patch_request.dart';
import '../api/request/postFAQ_request.dart';
import '../api/request/user_fcm_patch_request.dart';
import '../api/request/user_scn_patch_request.dart';
import '../api/response/alumni_login_response.dart';
import '../api/response/getencr_response.dart';
import '../api/response/news_feed_response.dart';
import '../drawer.dart';
import '../utils/app_brightness.dart';
import 'ach_to_vefiry_bloc.dart';
import 'achievementform_bloc.dart';
import 'blog_bloc.dart';
import 'calendar_bloc.dart';
import 'community_bloc.dart';
import 'community_post_bloc.dart';
import 'complaints_bloc.dart';
import 'drawer_bloc.dart';
import 'explore_bloc.dart';
import 'map_bloc.dart';
import 'mess_calendar_bloc.dart';

enum AddToCalendar { AlwaysAsk, Yes, No }

ColorSwatch _getMatSwatch(int darkColor, int lightColor) {
  return MaterialColor(
    darkColor,
    {
      50: Color(lightColor),
      100: Color(lightColor),
      200: Color(lightColor),
      300: Color(lightColor),
      400: Color(lightColor),
      500: Color(darkColor),
      600: Color(darkColor),
      700: Color(darkColor),
      800: Color(darkColor),
      900: Color(darkColor),
    },
  );
}

List<ColorSwatch<dynamic>> appColors = [
  _getMatSwatch(0xFF9747FF, 0xFFE4CCFF),
  _getMatSwatch(0xFF435FFE, 0xFFC0C9FF),
  _getMatSwatch(0xFF0D99FF, 0xFFBDE3FF),
  _getMatSwatch(0xFF14AE5C, 0xFFAFF4C6),
  _getMatSwatch(0xFFFFCD29, 0xFFFFE8A3),
  _getMatSwatch(0xFFFFA629, 0xFFFCD19C),
  _getMatSwatch(0xFFF24822, 0xFFFFC7C2),
  _getMatSwatch(0xFFB3B3B3, 0xFFE6E6E6),
  _getMatSwatch(0xFF1E1E1E, 0xFF757575),
];

class InstiAppBloc {
  // Dio instance
  final Dio dio = Dio();

  // Events StorageID
  static String eventStorageID = 'events';
  // Mess StorageID
  static String messStorageID = 'mess';
  // Notifications StorageID
  static String notificationsStorageID = 'notifications';
  // Achievement StorageID
  static String achievementStorageID = 'achievement';

  // FCM handle
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  // Different Streams for the state
  ValueStream<UnmodifiableListView<Hostel>> get hostels =>
      _hostelsSubject.stream;
  final BehaviorSubject<UnmodifiableListView<Hostel>> _hostelsSubject =
      BehaviorSubject<UnmodifiableListView<Hostel>>();

  ValueStream<Session?> get session => _sessionSubject.stream;
  final BehaviorSubject<Session?> _sessionSubject = BehaviorSubject<Session?>();

  ValueStream<UnmodifiableListView<Event>> get events => _eventsSubject.stream;
  final BehaviorSubject<UnmodifiableListView<Event>> _eventsSubject =
      BehaviorSubject<UnmodifiableListView<Event>>();

  ValueStream<UnmodifiableListView<ntf.Notification>> get notifications =>
      _notificationsSubject.stream;
  final BehaviorSubject<UnmodifiableListView<ntf.Notification>>
      _notificationsSubject =
      BehaviorSubject<UnmodifiableListView<ntf.Notification>>();

  ValueStream<UnmodifiableListView<Achievement>> get achievements =>
      _achievementSubject.stream;
  final BehaviorSubject<UnmodifiableListView<Achievement>> _achievementSubject =
      BehaviorSubject<UnmodifiableListView<Achievement>>();

  // Sub Blocs
  late PostBloc placementBloc;
  late PostBloc externalBloc;
  late PostBloc trainingBloc;
  late PostBloc newsBloc;
  late PostBloc queryBloc;
  late PostBloc chatBotBloc;
  late ExploreBloc exploreBloc;
  late CalendarBloc calendarBloc;
  late MessCalendarBloc messCalendarBloc;
  late ComplaintsBloc complaintsBloc;
  late DrawerBloc drawerState;
  late MapBloc mapBloc;
  late Bloc achievementBloc;
  late VerifyBloc bodyAchBloc;
  late CommunityBloc communityBloc;
  late CommunityPostBloc communityPostBloc;
  // actual current state
  Session? currSession;
  List<Hostel> _hostels = <Hostel>[];
  List<Event> _events = <Event>[];
  List<Achievement> _achievements = <Achievement>[];
  List<ntf.Notification> _notifications = <ntf.Notification>[];

  // api functions
  late final InstiAppApi client;
  late final ChatBotApi clientChatBot;

  // default homepage
  String homepageName = '/feed';
  bool isAlumni = false;
  String msg = '';
  String alumniLoginPage = '/alumniLoginPage';
  String ldap = '';
  //to implement method for toggling isAlumnReg
  String alumni_OTP_Page = '/alumni-OTP-Page';
  String _alumniOTP = '';
  // to create method to update this from apiclient.dart
  // default theme
  AppBrightness _brightness = AppBrightness.light;
  // Color _primaryColor = Color.fromARGB(255, 63, 81, 181);
  // Color _accentColor = Color.fromARGB(255, 139, 195, 74);
  ColorSwatch _primaryColor = appColors[1];
  ColorSwatch _accentColor = appColors[6];

  List<List<ColorSwatch>> defaultThemes = [
    // default theme 1
    [
      appColors[1],
      appColors[6],
    ]
  ];

  // Default Add To Calendar
  AddToCalendar _addToCalendarSetting = AddToCalendar.AlwaysAsk;

  AddToCalendar get addToCalendarSetting => _addToCalendarSetting;

  set addToCalendarSetting(AddToCalendar mAddToCalendarSetting) {
    if (mAddToCalendarSetting != _addToCalendarSetting) {
      _addToCalendarSetting = mAddToCalendarSetting;
      SharedPreferences.getInstance().then((SharedPreferences s) {
        s.setInt('addToCalendarSetting', _addToCalendarSetting.index);
      });
    }
  }

  // Default Calendars to add
  List<String> _defaultCalendarsSetting = <String>[];

  List<String> get defaultCalendarsSetting => _defaultCalendarsSetting;

  set defaultCalendarsSetting(List<String> mDefaultCalendarsSetting) {
    if (mDefaultCalendarsSetting != _defaultCalendarsSetting) {
      _defaultCalendarsSetting = mDefaultCalendarsSetting;
      SharedPreferences.getInstance().then((SharedPreferences s) {
        s.setStringList('defaultCalendarsSetting', _defaultCalendarsSetting);
      });
    }
  }

  // Navigator Stack
  late MNavigatorObserver navigatorObserver;

  AppBrightness get brightness => _brightness;

  set brightness(AppBrightness newBrightness) {
    if (newBrightness != _brightness) {
      wholeAppKey.currentState?.setTheme(() => _brightness = newBrightness);
      SharedPreferences.getInstance().then((SharedPreferences s) {
        s.setInt('brightness', newBrightness.index);
      });
    }
  }

  ColorSwatch get primaryColor => _primaryColor;

  set primaryColor(ColorSwatch newColor) {
    if (newColor != _primaryColor) {
      wholeAppKey.currentState?.setTheme(() => _primaryColor = newColor);
      SharedPreferences.getInstance().then((SharedPreferences s) {
        s.setInt('primaryColor', appColors.indexOf(newColor));
      });
    }
  }

  ColorSwatch get accentColor => _accentColor;

  set accentColor(ColorSwatch newColor) {
    if (newColor != _accentColor) {
      wholeAppKey.currentState?.setTheme(() => _accentColor = newColor);
      SharedPreferences.getInstance().then((SharedPreferences s) {
        s.setInt('accentColor', appColors.indexOf(newColor));
      });
    }
  }

  // all pages
  Map<String, int> pageToIndex = {
    '/feed': 0,
    '/news': 1,
    '/explore': 2,
    '/mess': 3,
    '/placeblog': 4,
    '/trainblog': 5,
    '/calendar': 6,
    '/map': 7,
    '/complaints': 8,
    '/quicklinks': 9,
    '/settings': 10,
    '/externalblog': 12,
    '/groups': 15,
  };

  // MaterialApp reference
  GlobalKey<MyAppState> wholeAppKey;

  InstiAppBloc({required this.wholeAppKey}) {
    // if (kIsWeb) {
    //   globalClient = BrowserClient();
    // } else {
    // }
    client = InstiAppApi(dio);
    clientChatBot = ChatBotApi(dio);
    placementBloc = PostBloc(this, postType: PostType.Placement);
    externalBloc = PostBloc(this, postType: PostType.External);
    trainingBloc = PostBloc(this, postType: PostType.Training);
    newsBloc = PostBloc(this, postType: PostType.NewsArticle);
    queryBloc = PostBloc(this, postType: PostType.Query);
    chatBotBloc = PostBloc(this, postType: PostType.ChatBot);
    exploreBloc = ExploreBloc(this);
    calendarBloc = CalendarBloc(this);
    // complaintsBloc = ComplaintsBloc(this);
    drawerState = DrawerBloc(homepageName, highlightPageIndexVal: 0);
    navigatorObserver = MNavigatorObserver(this);
    mapBloc = MapBloc(this);
    achievementBloc = Bloc(this);
    bodyAchBloc = VerifyBloc(this);
    messCalendarBloc = MessCalendarBloc(this);
    communityBloc = CommunityBloc(this);
    communityPostBloc = CommunityPostBloc(this);

    _initNotificationBatch();
  }

  // Settings bloc
  Future<void> updateHomepage(String s) async {
    homepageName = s;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('homepage', s);
  }

  Future<void> patchUserShowContactNumber(bool userShowContactNumber) async {
    final User userMe = await client.patchSCNUserMe(getSessionIdHeader(),
        UserSCNPatchRequest()..userShowContactNumber = userShowContactNumber);
    currSession?.profile = userMe;
    updateSession(currSession!);
  }

  // PostBloc helper function
  PostBloc? getPostsBloc(PostType blogType) {
    return {
      PostType.Placement: placementBloc,
      PostType.External: externalBloc,
      PostType.Training: trainingBloc,
      PostType.NewsArticle: newsBloc,
      PostType.Query: queryBloc,
      PostType.ChatBot: chatBotBloc,
    }[blogType];
  }

  // Mess bloc
  Future<void> updateHostels() async {
    List<Hostel> hostels = await client.getHostelMess();
    hostels.sort((Hostel h1, Hostel h2) => h1.compareTo(h2));
    _hostels = hostels;
    _hostelsSubject.add(UnmodifiableListView(_hostels));
  }

  Future<String?> getQRString() async {
    GetEncrResponse res = await client.getEncr(getSessionIdHeader());
    return res.qrstring;
  }

  // Event bloc
  Future<void> updateEvents() async {
    NewsFeedResponse newsFeedResponse =
        await client.getNewsFeed(getSessionIdHeader());
    _events = newsFeedResponse.events ?? [];
    if (_events.isNotEmpty) {
      _events[0].eventBigImage = true;
    }
    _eventsSubject.add(UnmodifiableListView(_events));
  }

  String get alumniID => ldap;
  void setAlumniID(String updtAlumniID) {
    ldap = updtAlumniID;
  }

  String get alumniOTP => _alumniOTP;
  void setAlumniOTP(String updtAlumniOTP) {
    _alumniOTP = updtAlumniOTP;
  }

  Future<void> updateAlumni() async {
    final AlumniLoginResponse alumniLoginResponse =
        await client.AlumniLogin(ldap);
    isAlumni = alumniLoginResponse.exist ?? false;
    msg = alumniLoginResponse.msg ?? '';
  }

  Future<void> logAlumniIn(bool resend) async {
    AlumniLoginResponse alumniLoginResponse = resend
        ? await client.ResendAlumniOTP(ldap)
        : await client.AlumniOTP(ldap, _alumniOTP);
    isAlumni = !(alumniLoginResponse.error_status ?? true);
    msg = alumniLoginResponse.msg ?? '';
    if (!resend) {
      if (isAlumni) {
        Session newSession = Session(
          sessionid: alumniLoginResponse.sessionid,
          user: alumniLoginResponse.user,
          profile: alumniLoginResponse.profile,
          profileId: alumniLoginResponse.profileId,
        );
        // print(newSession.toJson());
        updateSession(newSession);
      }
    }
  }

  // Your Achievement Bloc
  Future<void> updateAchievements() async {
    final List<Achievement> yourAchievementResponse =
        await client.getYourAchievements(getSessionIdHeader());
    _achievements = yourAchievementResponse;
    _achievementSubject.add(UnmodifiableListView(_achievements));
  }

  // Notifications bloc
  Future<void> updateNotificationPermission(bool permitted) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifP', permitted);
  }

  Future<bool?> hasNotificationPermission() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifP');
  }

  Future<void> updateNotifications() async {
    List<ntf.Notification> notifs =
        await client.getNotifications(getSessionIdHeader());
    _notifications = notifs;
    _notificationsSubject.add(UnmodifiableListView(_notifications));
  }

  Future clearAllNotifications() async {
    await client.markAllNotificationsRead(getSessionIdHeader());
    _notifications = [];
    _notificationsSubject.add(UnmodifiableListView(_notifications));
  }

  Future clearNotification(ntf.Notification notification) async {
    await clearNotificationUsingID('${notification.notificationId}');
    int idx = _notifications.indexWhere((ntf.Notification n) =>
        n.notificationId == notification.notificationId);
    // print(idx);
    if (idx != -1) {
      _notifications.removeAt(idx);
      _notificationsSubject.add(UnmodifiableListView(_notifications));
    }
  }

  Future clearNotificationUsingID(String notificationId) async {
    return client.markNotificationRead(getSessionIdHeader(), notificationId);
  }

  // Section
  // Navigator helper
  Future<Event?> getEvent(String uuid) async {
    try {
      return _events.firstWhere((Event event) => event.eventID == uuid);
    } catch (ex) {
      return client.getEvent(getSessionIdHeader(), uuid);
    }
  }

  Future<Body> getBody(String uuid) async {
    return client.getBody(getSessionIdHeader(), uuid);
  }

  Future<User> getUser(String uuid) async {
    return uuid == 'me'
        ? (currSession?.profile ?? await client.getUserMe(getSessionIdHeader()))
        : await client.getUser(getSessionIdHeader(), uuid);
  }

  Future<Complaint?>? getComplaint(String uuid, {bool reload = false}) async {
    return complaintsBloc.getComplaint(uuid, reload: reload);
  }

  // Section
  // Send FCM key
  Future<void> patchFcmKey() async {
    UserFCMPatchRequest req = UserFCMPatchRequest()
      ..userAndroidVersion = 28
      ..userFCMId = await firebaseMessaging.getToken();
    User userMe = await client.patchFCMUserMe(getSessionIdHeader(), req);
    currSession?.profile = userMe;
    updateSession(currSession!);
  }

  // Section
  // User/Body/Event updates
  Future<void> updateUesEvent(Event e, UES ues) async {
    try {
      // print("updating Ues from ${e.eventUserUes} to $ues");
      await client.updateUserEventStatus(
          getSessionIdHeader(), e.eventID ?? '', ues.index);
      if (e.eventUserUes == UES.Going) {
        e.eventGoingCount--;
      }
      if (e.eventUserUes == UES.Interested) {
        e.eventInterestedCount--;
      }
      if (ues == UES.Interested) {
        e.eventInterestedCount++;
      } else if (ues == UES.Going) {
        e.eventGoingCount++;
      }
      // print("updated Ues from ${e.eventUserUes} to $ues");
      e.eventUserUes = ues;
    } catch (ex) {
      // print(ex);
    }
  }

  Future<void> updateHiddenAchievement(
      Achievement achievement, bool hidden) async {
    try {
      // print("Updating hidden");
      await client.toggleHidden(getSessionIdHeader(), achievement.id ?? '',
          AchievementHiddenPathRequest()..hidden = hidden);
      achievement.hidden = hidden;
      // print("Updated hidden");
    } catch (e) {
      // print(e);
    }
  }

  Future<void> postFAQ(PostFAQRequest postFAQRequest) async {
    try {
      await client.postFAQ(getSessionIdHeader(), postFAQRequest);
    } catch (e) {
      // print(e);
    }
  }

  Future<void> updateFollowBody(Body b) async {
    try {
      await client.updateBodyFollowing(
          getSessionIdHeader(), b.bodyID ?? '', b.bodyUserFollows! ? 0 : 1);
      b.bodyUserFollows = !b.bodyUserFollows!;
      b.bodyFollowersCount =
          b.bodyFollowersCount! + (b.bodyUserFollows! ? 1 : -1);
    } catch (ex) {
      // print(ex);
    }
  }

  Future<void> updateFollowCommunity(Community c) async {
    try {
      await client.updateBodyFollowing(
          getSessionIdHeader(), c.body ?? '', c.isUserFollowing! ? 0 : 1);
      c.isUserFollowing = !c.isUserFollowing!;
      c.followersCount = c.followersCount! + (c.isUserFollowing! ? 1 : -1);
    } catch (ex) {
      // print(ex);
    }
  }

  bool editEventAccess(Event event) {
    return currSession?.profile?.userRoles?.any((Role r) => r.roleBodies!.any(
            (Body b) =>
                event.eventBodies!.any((Body b1) => b.bodyID == b1.bodyID))) ??
        false;
  }

  List<Body> getBodiesWithPermission(String permission) {
    if (currSession?.profile == null) {
      return [];
    }
    List<Body> bodies = [];
    List<Role>? roles = currSession?.profile?.userRoles!;
    if (roles != null) {
      for (final Role role in roles) {
        if (role.rolePermissions!.contains(permission)) {
          for (final Body body in role.roleBodies!) {
            bodies.add(body);
          }
        }
      }
    }
    return bodies;
  }

  bool deleteEventAccess(Event event) {
    for (final Body body in event.eventBodies!) {
      if (getBodiesWithPermission('DelE')
          .map((Body e) => e.bodyID!)
          .toList()
          .contains(body.bodyID!)) {
        return true;
      }
    }
    return currSession?.profile?.userRoles?.any((Role r) => r.roleBodies!.any(
            (Body b) =>
                event.eventBodies!.any((Body b1) => b.bodyID == b1.bodyID))) ??
        false;
  }

  bool editBodyAccess(Body body) {
    return currSession?.profile?.userRoles?.any((Role r) =>
            r.roleBodies!.any((Body b) => b.bodyID == body.bodyID)) ??
        false;
  }

  bool hasPermission(String bodyId, String permission) {
    if (currSession == null) {
      return false;
    }

    return currSession?.profile?.userRoles?.any((Role element) =>
            (element.rolePermissions?.contains(permission) ?? false) &&
            element.roleBody == bodyId) ??
        false;
  }

  // Section
  // Bloc state management
  Future<void> restorePrefs() async {
    // print("Restoring prefs");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getKeys().contains('session')) {
      String? x = prefs.getString('session');
      if (x != null && x != '') {
        Session? sess =
            Session.fromJson(json.decode(x) as Map<String, dynamic>);
        if (sess.sessionid != null) {
          updateSession(sess);
        }
      }
    }
    if (prefs.getKeys().contains('homepage')) {
      homepageName = prefs.getString('homepage') ?? homepageName;
      int? x = pageToIndex[homepageName];
      drawerState.setPageIndex(x!);
    }
    if (prefs.getKeys().contains('brightness')) {
      int? x = prefs.getInt('brightness');
      if (x != null) _brightness = AppBrightness.values[x];
    }
    if (prefs.getKeys().contains('accentColor')) {
      int? x = prefs.getInt('accentColor');
      if (x != null) {
        if (x < 0 || x >= appColors.length) {
          await prefs.remove('accentColor');
        } else {
          _accentColor = appColors[x];
        }
      }
    }
    if (prefs.getKeys().contains('primaryColor')) {
      int? x = prefs.getInt('primaryColor');
      if (x != null) {
        if (x < 0 || x >= appColors.length) {
          await prefs.remove('primaryColor');
        } else {
          _primaryColor = appColors[x];
        }
      }
    }
    if (prefs.getKeys().contains('addToCalendarSetting')) {
      int? x = prefs.getInt('addToCalendarSetting');
      if (x != null) _addToCalendarSetting = AddToCalendar.values[x];
    }
    if (prefs.getKeys().contains('defaultCalendarsSetting')) {
      _defaultCalendarsSetting =
          prefs.getStringList('defaultCalendarsSetting') ??
              _defaultCalendarsSetting;
    }

    await restoreFromCache(sharedPrefs: prefs);
  }

  // Section
  // Session management
  void updateSession(Session? sess) {
    currSession = sess;
    _sessionSubject.add(sess);
    _persistSession(sess);
  }

  Future<void> _persistSession(Session? sess) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (sess == null) {
      await prefs.setString('session', '');
      return;
    }
    await prefs.setString('session', json.encode(sess.toJson()));
  }

  Future<void> reloadCurrentUser() async {
    final User userMe = await client.getUserMe(getSessionIdHeader());
    currSession?.profile = userMe;
    updateSession(currSession!);
  }

  String getSessionIdHeader() {
    return currSession?.sessionid != null
        ? 'sessionid=${currSession?.sessionid}'
        : '';
  }

  Future<void> logout() async {
    await client.logout(getSessionIdHeader());
    updateSession(null);
    _notificationsSubject.add(UnmodifiableListView([]));
  }

  Future saveToCache({SharedPreferences? sharedPrefs}) async {
    final SharedPreferences prefs =
        sharedPrefs ?? await SharedPreferences.getInstance();
    if (_hostels.isNotEmpty) {
      await prefs.setString(messStorageID,
          json.encode(_hostels.map((Hostel e) => e.toJson()).toList()));
    }
    if (_events.isNotEmpty) {
      await prefs.setString(eventStorageID,
          json.encode(_events.map((Event e) => e.toJson()).toList()));
    }
    if (_achievements.isNotEmpty) {
      await prefs.setString(
          achievementStorageID,
          json.encode(
              _achievements.map((Achievement e) => e.toJson()).toList()));
    }
    if (_notifications.isNotEmpty) {
      await prefs.setString(
          notificationsStorageID,
          json.encode(
              _notifications.map((ntf.Notification e) => e.toJson()).toList()));
    }

    await exploreBloc.saveToCache(sharedPrefs: prefs);
    // complaintsBloc?.saveToCache(sharedPrefs: prefs);
    await calendarBloc.saveToCache(sharedPrefs: prefs);
    await messCalendarBloc.saveToCache(sharedPrefs: prefs);
    await mapBloc.saveToCache(sharedPrefs: prefs);
  }

  Future restoreFromCache({SharedPreferences? sharedPrefs}) async {
    final SharedPreferences prefs =
        sharedPrefs ?? await SharedPreferences.getInstance();
    if (prefs.getKeys().contains(messStorageID)) {
      String? x = prefs.getString(messStorageID);
      if (x != null) {
        _hostels = (json.decode(x) as List<Map<String, dynamic>>)
            .map(Hostel.fromJson)
            .toList()
            .cast<Hostel>();
        _hostelsSubject.add(UnmodifiableListView(_hostels));
      }
    }

    if (prefs.getKeys().contains(eventStorageID)) {
      String? x = prefs.getString(eventStorageID);
      if (x != null) {
        _events = (json.decode(x) as List<Map<String, dynamic>>)
            .map(Event.fromJson)
            .toList()
            .cast<Event>();
        if (_events.isNotEmpty) {
          _events[0].eventBigImage = true;
        }
        _eventsSubject.add(UnmodifiableListView(_events));
      }
    }

    if (prefs.getKeys().contains(achievementStorageID)) {
      final String? x = prefs.getString(achievementStorageID);
      if (x != null) {
        _achievements = (json.decode(x) as List<Map<String, dynamic>>)
            .map(Achievement.fromJson)
            .toList()
            .cast<Achievement>();
        _achievementSubject.add(UnmodifiableListView(_achievements));
      }
    }

    if (prefs.getKeys().contains(notificationsStorageID)) {
      final String? x = prefs.getString(notificationsStorageID);
      if (x != null) {
        _notifications = (json.decode(x) as List<Map<String, dynamic>>)
            .map(ntf.Notification.fromJson)
            .toList()
            .cast<ntf.Notification>();
        _notificationsSubject.add(UnmodifiableListView(_notifications));
      }
    }

    await exploreBloc.restoreFromCache(sharedPrefs: prefs);
    // complaintsBloc?.restoreFromCache(sharedPrefs: prefs);
    await calendarBloc.restoreFromCache(sharedPrefs: prefs);
    await messCalendarBloc.restoreFromCache(sharedPrefs: prefs);
    await mapBloc.restoreFromCache(sharedPrefs: prefs);
  }

  // Set batch number on icon for iOS
  void _initNotificationBatch() {
    if (!kIsWeb && Platform.isIOS) {
      notifications
          .listen((UnmodifiableListView<ntf.Notification> notifs) async {
        try {
          await AwesomeNotifications().setGlobalBadgeCounter(notifs.length);
        } on PlatformException {}
      });
    }
  }
}
