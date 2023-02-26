import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/model/venue.dart';
import 'ia_bloc.dart';

class MapBloc {
  // Unique ID for use in SharedPrefs
  static String locationsStorageID = 'alllocations';

  // parent bloc
  InstiAppBloc bloc;

  // Streams
  ValueStream<UnmodifiableListView<Venue>> get locations =>
      _locationsSubject.stream;
  final BehaviorSubject<UnmodifiableListView<Venue>> _locationsSubject =
      BehaviorSubject<UnmodifiableListView<Venue>>();

  // State
  List<Venue> _locations = <Venue>[];

  MapBloc(this.bloc);

  Future updateLocations() async {
    _locations = await bloc.client.getAllVenues();
    _locationsSubject.add(UnmodifiableListView(_locations));
  }

  Future saveToCache({SharedPreferences? sharedPrefs}) async {
    SharedPreferences prefs =
        sharedPrefs ?? await SharedPreferences.getInstance();
    if (_locations.isNotEmpty) {
      await prefs.setString(locationsStorageID,
          json.encode(_locations.map((Venue e) => e.toJson()).toList()));
    }
  }

  Future restoreFromCache({SharedPreferences? sharedPrefs}) async {
    SharedPreferences prefs =
        sharedPrefs ?? await SharedPreferences.getInstance();
    if (prefs.getKeys().contains(locationsStorageID)) {
      String? x = prefs.getString(locationsStorageID);
      if (x != null) {
        _locations = (json.decode(x) as List<Map<String, dynamic>>)
            .map(Venue.fromJson)
            .toList()
            .cast<Venue>();
        _locationsSubject.add(UnmodifiableListView(_locations));
      }
    }
  }
}
