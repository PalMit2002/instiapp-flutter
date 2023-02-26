import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/model/body.dart';
import '../api/response/explore_response.dart';
import 'ia_bloc.dart';

class ExploreBloc {
  // Unique ID for use in SharedPrefs
  static String storageID = 'explore';

  // parent bloc
  InstiAppBloc bloc;

  // Streams
  ValueStream<ExploreResponse> get explore => _exploreSubject.stream;
  final BehaviorSubject<ExploreResponse> _exploreSubject =
      BehaviorSubject<ExploreResponse>();

  ValueStream<UnmodifiableListView<Body>> get bodies => _bodiesSubject.stream;
  final BehaviorSubject<UnmodifiableListView<Body>> _bodiesSubject =
      BehaviorSubject<UnmodifiableListView<Body>>();

  // Params
  String query = '';

  // State
  List<Body> allBodies = <Body>[];
  ExploreResponse? currExploreResponse;

  ExploreBloc(this.bloc);

  _push(ExploreResponse resp) {
    currExploreResponse = resp;
    _exploreSubject.add(resp);
  }

  Future saveToCache({SharedPreferences? sharedPrefs}) async {
    SharedPreferences prefs =
        sharedPrefs ?? await SharedPreferences.getInstance();
    if (allBodies.isNotEmpty) {
      await prefs.setString(storageID,
          json.encode(allBodies.map((Body e) => e.toJson()).toList()));
    }
  }

  Future restoreFromCache({SharedPreferences? sharedPrefs}) async {
    final SharedPreferences prefs =
        sharedPrefs ?? await SharedPreferences.getInstance();
    if (prefs.getKeys().contains(storageID)) {
      String? x = prefs.getString(storageID);
      if (x != null) {
        allBodies = (json.decode(x) as List<Map<String, dynamic>>)
            .map(Body.fromJson)
            .toList()
            .cast<Body>();
        _push(ExploreResponse(bodies: allBodies));
      }
    }
    _bodiesSubject.add(UnmodifiableListView(allBodies));
  }

  Future refresh() async {
    if (query == '') {
      if (allBodies.isEmpty) {
        allBodies = await bloc.client.getAllBodies(bloc.getSessionIdHeader());
      }
      _push(ExploreResponse(bodies: allBodies));
    } else {
      _push(await bloc.client.search(bloc.getSessionIdHeader(), query));
    }
  }
}
