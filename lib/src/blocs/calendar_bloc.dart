import 'dart:async';
import 'dart:convert';

import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/model/event.dart';
import '../api/response/news_feed_response.dart';
import 'ia_bloc.dart';

class CalendarBloc {
  // monthToEventMap StorageID
  static String mteKeysStorageID = 'monthToEventsKeys';
  static String mteValuesStorageID = 'monthToEventsValues';

  // eventsMap StorageID
  static String eventsMapKeysStorageID = 'eventsMapKeys';
  static String eventsMapValuesStorageID = 'eventsMapValues';
  // parent bloc
  InstiAppBloc bloc;

  // Streams
  ValueStream<Map<DateTime, List<Event>>> get events => _eventsSubject.stream;
  final BehaviorSubject<Map<DateTime, List<Event>>> _eventsSubject =
      BehaviorSubject<Map<DateTime, List<Event>>>();

  ValueStream<bool> get loading => _loadingSubject.stream;
  final BehaviorSubject<bool> _loadingSubject = BehaviorSubject<bool>();

  // State
  Map<DateTime, List<Event>> monthToEvents = {};
  Map<DateTime, List<Event>> eventsMap = {};
  List<DateTime> receivingMonths = [];
  bool _loading = false;

  CalendarBloc(this.bloc) {
    _loadingSubject.add(_loading);
  }

  DateTime _getMonthStart(DateTime date) {
    return DateTime(date.year, date.month);
  }

  List<Event> _getEventsOfMonth(List<Event> evs, DateTime month) {
    return evs.where((Event e) {
      return e.eventStartDate!.year == month.year &&
          e.eventStartDate!.month == month.month;
    }).toList();
  }

  Future<void> fetchEvents(DateTime currMonth, Widget icon) async {
    if (!_loading) {
      _loading = true;
      _loadingSubject.add(_loading);
    }
    List<String> isoFormat = [
      yyyy,
      '-',
      mm,
      '-',
      dd,
      ' ',
      HH,
      ':',
      nn,
      ':',
      ss
    ];

    DateTime currMonthStart = _getMonthStart(currMonth);
    DateTime prevMonthStart =
        DateTime(currMonthStart.year, currMonthStart.month - 1);
    final DateTime nextMonthStart =
        DateTime(currMonthStart.year, currMonthStart.month + 1);
    DateTime nextNextMonthStart =
        DateTime(currMonthStart.year, currMonthStart.month + 2);

    receivingMonths.add(prevMonthStart);
    receivingMonths.add(currMonthStart);
    receivingMonths.add(nextMonthStart);

    NewsFeedResponse newsFeedResp = await bloc.client.getEventsBetweenDates(
        bloc.getSessionIdHeader(),
        formatDate(prevMonthStart, isoFormat),
        formatDate(nextNextMonthStart, isoFormat));
    List<Event>? evs = newsFeedResp.events;
    for (final Event e in evs!) {
      final DateTime time = DateTime.parse(e.eventStartTime!);
      e.eventStartDate = DateTime(time.year, time.month, time.day);
    }

    monthToEvents[prevMonthStart] = _getEventsOfMonth(evs, prevMonthStart);
    receivingMonths.remove(prevMonthStart);
    monthToEvents[currMonthStart] = _getEventsOfMonth(evs, currMonthStart);
    receivingMonths.remove(currMonthStart);
    monthToEvents[nextMonthStart] = _getEventsOfMonth(evs, nextMonthStart);
    receivingMonths.remove(nextMonthStart);
    for (final Event e in evs) {
      final List<Event> dateList =
          eventsMap.putIfAbsent(e.eventStartDate!, () => []);
      dateList.removeWhere((Event e1) => e1.eventID == e.eventID);
      dateList.add(e);
    }
    _eventsSubject.add(eventsMap);
    if (_loading) {
      _loading = false;
      _loadingSubject.add(_loading);
    }
  }

  Future saveToCache({SharedPreferences? sharedPrefs}) async {
    SharedPreferences prefs =
        sharedPrefs ?? await SharedPreferences.getInstance();
    if (monthToEvents.isNotEmpty) {
      List<String> keys = [];
      for (final DateTime i in monthToEvents.keys) {
        keys.add(i.toIso8601String());
      }
      await prefs.setString(mteKeysStorageID, json.encode(keys));
      await prefs.setString(
          mteValuesStorageID,
          json.encode(monthToEvents.values
              .map((List<Event> e) => e.map((Event k) => k.toJson()).toList())
              .toList()));
    }

    if (eventsMap.isNotEmpty) {
      List<String> keys = [];
      for (final DateTime i in eventsMap.keys) {
        keys.add(i.toIso8601String());
      }
      await prefs.setString(eventsMapKeysStorageID, json.encode(keys));
      await prefs.setString(
          eventsMapValuesStorageID,
          json.encode(eventsMap.values
              .map((List<Event> e) => e.map((Event k) => k.toJson()).toList())
              .toList()));
    }
  }

  Future restoreFromCache({SharedPreferences? sharedPrefs}) async {
    SharedPreferences prefs =
        sharedPrefs ?? await SharedPreferences.getInstance();
    if (prefs.getKeys().contains(mteKeysStorageID) &&
        prefs.getKeys().contains(mteValuesStorageID)) {
      if (prefs.getString(mteKeysStorageID) != null &&
          prefs.getString(mteValuesStorageID) != null) {
        Iterable<DateTime> keys =
            (json.decode(prefs.getString(mteKeysStorageID) ?? '') as List)
                .map((e) => DateTime.parse(e as String));
        List<List<Event>> values =
            (json.decode(prefs.getString(mteValuesStorageID) ?? '') as List)
                .map((evs) => evs.map(Event.fromJson).toList().cast<Event>())
                .toList()
                .cast<List<Event>>();
        monthToEvents = Map.fromIterables(keys, values);
      }
    }

    if (prefs.getKeys().contains(eventsMapKeysStorageID) &&
        prefs.getKeys().contains(eventsMapValuesStorageID)) {
      if (prefs.getString(mteKeysStorageID) != null &&
          prefs.getString(mteValuesStorageID) != null) {
        final Iterable<DateTime> keys =
            (json.decode(prefs.getString(mteKeysStorageID) ?? '')
                    as List<String>)
                .map(DateTime.parse);
        final Iterable<List<Event>> values =
            (json.decode(prefs.getString(mteValuesStorageID) ?? '')
                    as List<List<Map<String, dynamic>>>)
                .map((List<Map<String, dynamic>> evs) =>
                    evs.map(Event.fromJson).toList().cast<Event>());
        eventsMap = Map<DateTime, List<Event>>.fromIterables(keys, values);
        _eventsSubject.add(eventsMap);
      }
    }
  }
}
