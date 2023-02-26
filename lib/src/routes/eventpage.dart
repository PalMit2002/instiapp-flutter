import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:device_calendar/device_calendar.dart' as cal;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:share/share.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import '../api/model/body.dart';
import '../api/model/event.dart';
import '../bloc_provider.dart';
import '../blocs/ia_bloc.dart';
import '../drawer.dart';
import '../utils/common_widgets.dart';
import '../utils/footer_buttons.dart';
import '../utils/notif_settings.dart';
import '../utils/share_url_maker.dart';
import '../utils/title_with_backbutton.dart';
import 'bodypage.dart';

class EventPage extends StatefulWidget {
  final Event? initialEvent;
  final Future<Event?> eventFuture;

  const EventPage({Key? key, required this.eventFuture, this.initialEvent}) : super(key: key);

  static void navigateWith(
      BuildContext context, InstiAppBloc bloc, Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
          name: "/event/${event.eventID ?? ""}",
        ),
        builder: (BuildContext context) => EventPage(
          initialEvent: event,
          eventFuture: bloc.getEvent(event.eventID ?? ''),
        ),
      ),
    );
  }

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  Event? event;

  UES loadingUes = UES.NotGoing;

  final bool _bottomSheetActive = false;

  bool firstBuild = true;

  @override
  void initState() {
    super.initState();
    event = widget.initialEvent;
    widget.eventFuture.then((Event? ev) {
      markdown.TableSyntax tableParse = const markdown.TableSyntax();
      ev?.eventDescription = markdown.markdownToHtml(
          ev.eventDescription
                  ?.split('\n')
                  .map((String s) => s.trimRight())
                  .toList()
                  .join('\n') ??
              '',
          blockSyntaxes: [tableParse]);
      if (mounted) {
        setState(() {
          event = ev;
        });
      } else {
        event = ev;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    InstiAppBloc bloc = BlocProvider.of(context)!.bloc;
    final NotificationRouteArguments? args = ModalRoute.of(context)!
        .settings
        .arguments as NotificationRouteArguments?;
    List<Widget> footerButtons = [];
    bool editAccess = false;
    if (event != null) {
      footerButtons = <Widget>[];
      editAccess = bloc.editEventAccess(event!);
      if (bloc.currSession != null) {
        footerButtons.addAll([
          buildUserStatusButton('Going', UES.Going, theme, bloc),
          buildUserStatusButton('Interested', UES.Interested, theme, bloc),
        ]);

        if (args?.key == ActionKeys.ADD_TO_CALENDAR && firstBuild) {
          UESButtonOnClicked(UES.Going, theme, bloc, forceInterested: true);
          firstBuild = false;
        }
      }

      if ((event!.eventWebsiteURL ?? '') != '') {
        footerButtons.add(IconButton(
          tooltip: 'Open website',
          icon: const Icon(Icons.language_outlined),
          onPressed: () async {
            if (await canLaunchUrl(Uri.parse(event!.eventWebsiteURL!))) {
              await launchUrl(
                Uri.parse(event!.eventWebsiteURL!),
                mode: LaunchMode.externalApplication,
              );
            }
          },
        ));
      }
      if ((event!.eventVenues?.isNotEmpty ?? false) &&
          event!.eventVenues![0].venueLatitude != null) {
        footerButtons.add(IconButton(
          tooltip: 'Navigate to event',
          icon: const Icon(Icons.navigation_outlined),
          onPressed: () async {
            String uri = defaultTargetPlatform == TargetPlatform.iOS
                ? 'http://maps.apple.com/?ll=${event!.eventVenues![0].venueLatitude},${event!.eventVenues![0].venueLongitude}&z=20'
                : 'google.navigation:q=${event!.eventVenues![0].venueLatitude},${event!.eventVenues![0].venueLongitude}';
            if (await canLaunchUrl(Uri.parse(uri))) {
              await launchUrl(
                Uri.parse(uri),
                mode: LaunchMode.externalApplication,
              );
            }
          },
        ));
      }

      footerButtons.add(
        IconButton(
          icon: const Icon(Icons.share_outlined),
          tooltip: 'Share this event',
          padding: const EdgeInsets.all(0),
          onPressed: () async {
            await Share.share(
                'Check this event: ${ShareURLMaker.getEventURL(event!)}');
          },
        ),
      );
    }

    return Scaffold(
        key: _scaffoldKey,
        drawer: const NavDrawer(),
        bottomNavigationBar: MyBottomAppBar(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: const Icon(
                  Icons.menu_outlined,
                  semanticLabel: 'Show navigation drawer',
                ),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: event == null
              ? const Center(
                  child: CircularProgressIndicatorExtended(
                  label: Text('Loading the event page'),
                ))
              : ListView(
                  children: <Widget>[
                    TitleWithBackButton(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            event!.eventName ?? '',
                            style: theme.textTheme.displaySmall,
                          ),
                          const SizedBox(height: 8.0),
                          Text(event!.getSubTitle(),
                              style: theme.textTheme.titleLarge),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: PhotoViewableImage(
                        url: event!.eventImageURL ??
                            event!.eventBodies?[0].bodyImageURL ??
                            defUrl,
                        heroTag: event!.eventID ?? '',
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                    const SizedBox(
                      height: 16.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28.0, vertical: 16.0),
                      child: CommonHtml(
                        data: event!.eventDescription ?? '',
                        defaultTextStyle:
                            theme.textTheme.titleMedium ?? const TextStyle(),
                      ),
                    ),
                    const SizedBox(
                      height: 16.0,
                    ),
                    const Divider(), ...?event!.eventBodies?.map(
                            (Body b) => _buildBodyTile(bloc, theme.textTheme, b)), const Divider(),
                      const SizedBox(
                        height: 64.0,
                      ),
                  ]
                    
                    ,
                ),
        ),
        floatingActionButton: _bottomSheetActive || event == null
            ? null
            : editAccess
                ? FloatingActionButton.extended(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                    tooltip: 'Edit this event',
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed('/putentity/event/${event!.eventID}');
                    },
                  )
                : FloatingActionButton(
                    tooltip: 'Share this event',
                    onPressed: () async {
                      await Share.share(
                          'Check this event: ${ShareURLMaker.getEventURL(event!)}');
                    },
                    child: const Icon(Icons.share_outlined),
                  ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        persistentFooterButtons: [
          FooterButtons(
            footerButtons: footerButtons,
          )
        ]);
  }

  Widget _buildBodyTile(InstiAppBloc bloc, TextTheme theme, Body body) {
    return ListTile(
      title: Text(body.bodyName ?? '', style: theme.titleLarge),
      subtitle: Text(body.bodyShortDescription ?? '', style: theme.titleSmall),
      leading: NullableCircleAvatar(
        body.bodyImageURL ?? defUrl,
        Icons.work_outline_outlined,
        heroTag: body.bodyID ?? '',
      ),
      onTap: () {
        BodyPage.navigateWith(context, bloc, body: body);
      },
    );
  }

  ElevatedButton buildUserStatusButton(
      String name, UES uesButton, ThemeData theme, InstiAppBloc bloc) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: event?.eventUserUes == uesButton
            ? theme.colorScheme.secondary
            : theme.scaffoldBackgroundColor,
        foregroundColor: event?.eventUserUes == uesButton
            ? theme.floatingActionButtonTheme.foregroundColor
            : theme.textTheme.bodyLarge?.color,
        shape: RoundedRectangleBorder(
            side: BorderSide(
              color: theme.colorScheme.secondary,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(4))),
      ),
      child: Row(children: () {
        List<Widget> rowChildren = <Widget>[
          Text(name),
          const SizedBox(
            width: 8.0,
          ),
          Text(
              '${uesButton == UES.Interested ? event?.eventInterestedCount : event?.eventGoingCount}'),
        ];
        if (loadingUes == uesButton) {
          rowChildren.insertAll(0, [
            SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color?>(
                      event?.eventUserUes == uesButton
                          ? theme.floatingActionButtonTheme.foregroundColor
                          : theme.colorScheme.secondary),
                  strokeWidth: 2,
                )),
            const SizedBox(
              width: 8.0,
            )
          ]);
        }
        return rowChildren;
      }()),
      onPressed: () {
        UESButtonOnClicked(uesButton, theme, bloc);
      },
    );
  }

  Future<void> UESButtonOnClicked(UES uesButton, ThemeData theme, InstiAppBloc bloc,
      {bool forceInterested = false}) async {
    if (bloc.currSession == null) {
      return;
    }
    setState(() {
      loadingUes = uesButton;
    });
    await bloc.updateUesEvent(
        event!,
        forceInterested
            ? UES.Going
            : (event!.eventUserUes == uesButton ? UES.NotGoing : uesButton));
    setState(() {
      loadingUes = UES.NotGoing;
      // event has changes
    });

    if (event?.eventUserUes != UES.NotGoing) {
      if (forceInterested) {
        await _actualAddEventToDeviceCalendar(bloc);
      } else {
        // Add to calendar (or not)
        await _addEventToCalendar(theme, bloc);
      }
    }
  }

  bool lastCheck = false;

  Future<void> _addEventToCalendar(ThemeData theme, InstiAppBloc bloc) async {
    lastCheck = false;
    if (bloc.addToCalendarSetting == AddToCalendar.AlwaysAsk) {
      bool? addToCal = await showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title: const Text('Add to Calendar?'),
                content: DialogContent(
                  parent: this,
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('No'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      if (lastCheck) {
                        bloc.addToCalendarSetting = AddToCalendar.No;
                      }
                    },
                  ),
                  TextButton(
                    child: const Text('Yes'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              ));
      if (addToCal == null) {
        return;
      }

      if (lastCheck) {
        bloc.addToCalendarSetting =
            addToCal ? AddToCalendar.Yes : AddToCalendar.No;
      }

      if (addToCal) {
        await _actualAddEventToDeviceCalendar(bloc);
      }
    } else if (bloc.addToCalendarSetting == AddToCalendar.Yes) {
      await _actualAddEventToDeviceCalendar(bloc);
    }
  }

  List<bool>? selector;
  Future<void> _actualAddEventToDeviceCalendar(InstiAppBloc bloc) async {
    // Init Device Calendar plugin
    cal.DeviceCalendarPlugin calendarPlugin = cal.DeviceCalendarPlugin();

    // Get Calendar Permissions
    cal.Result<bool> permissionsGranted = await calendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !(permissionsGranted.data ?? false)) {
      permissionsGranted = await calendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess ||
          !(permissionsGranted.data ?? false)) {
        return;
      }
    }

    // Get All Calendars
    final cal.Result<UnmodifiableListView<cal.Calendar>> calendarsResult = await calendarPlugin.retrieveCalendars();
    if (calendarsResult.data != null) {
      lastCheck = false;
      // Get Calendar Permissions
      if (bloc.defaultCalendarsSetting.isEmpty) {
        bool? toContinue = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Select which calendars to add to?'),
                content: CalendarList(calendarsResult.data ?? [], parent: this),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                  TextButton(
                    child: const Text('Yes'),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
                ],
              );
            });
        if (!(toContinue ?? false)) {
          return;
        }

        if (lastCheck) {
          bloc.defaultCalendarsSetting =
              calendarsResult.data?.asMap().entries.expand((MapEntry<int, cal.Calendar> entry) {
                    if (selector?[entry.key] == true) {
                      return <String>[entry.value.id ?? ''];
                    }
                    return <String>[];
                  }).toList() ??
                  [];
        }
      }

      if (!lastCheck && bloc.defaultCalendarsSetting.isNotEmpty) {
        selector = calendarsResult.data
            ?.map((cal.Calendar calen) => bloc.defaultCalendarsSetting.contains(calen.id))
            .toList();
      }

      List<Future<cal.Result<String>?>> futures =
          calendarsResult.data?.asMap().entries.expand((MapEntry<int, cal.Calendar> entry) {
                if (selector?[entry.key] == true) {
                  DateTime? startTime;
                  if (event?.eventStartTime != null) {
                    startTime = DateTime.parse(event!.eventStartTime!);
                  }
                  DateTime? endTime;
                  if (event?.eventEndTime != null) {
                    endTime = DateTime.parse(event!.eventEndTime!);
                  }

                  cal.Event ev = cal.Event(
                    entry.value.id,
                    description: event?.eventDescription,
                    eventId: event?.eventID,
                    title: event?.eventName,
                    start: startTime == null
                        ? null
                        : Platform.isAndroid
                            ? tz.TZDateTime.utc(
                                startTime.year,
                                startTime.month,
                                startTime.day,
                                startTime.hour,
                                startTime.minute,
                                startTime.second)
                            : tz.TZDateTime.from(startTime, tz.local),
                    end: endTime == null
                        ? null
                        : Platform.isAndroid
                            ? tz.TZDateTime.utc(
                                endTime.year,
                                endTime.month,
                                endTime.day,
                                endTime.hour,
                                endTime.minute,
                                endTime.second)
                            : tz.TZDateTime.from(endTime, tz.local),
                  );
                  return <Future<cal.Result<String>?>>[
                    calendarPlugin.createOrUpdateEvent(ev)
                  ];
                }
                return <Future<cal.Result<String>?>>[];
              }).toList() ??
              [];

      if ((await Future.wait(futures)).every((cal.Result<String>? res) {
        return res?.isSuccess ?? false;
      })) {
        await showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(
                  'Success',
                  style: TextStyle(color: Colors.green),
                ),
                content: Text(
                    'Event has been successfully added to ${futures.length} calendar${futures.length > 1 ? "s" : ""}.\n \nIt may take a few minutes to appear in your calendar.'),
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
    }
  }

  // tz.TZDateTime? dateTimeToTZ(DateTime? dateTime){
  //   final timeZone = TimeZone()
  // }
}

class CalendarList extends StatefulWidget {
  final List<cal.Calendar> calendarsResult;
  final _EventPageState? parent;
  final List<bool>? defaultSelector;

  const CalendarList(this.calendarsResult, {Key? key, this.parent, this.defaultSelector}) : super(key: key);

  @override
  _CalendarListState createState() => _CalendarListState();
}

class _CalendarListState extends State<CalendarList> {
  List<bool>? selector;

  @override
  void initState() {
    super.initState();
    widget.parent?.selector = widget.defaultSelector ??
        List.filled(widget.calendarsResult.length, false);
    selector = widget.parent?.selector;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[...widget.calendarsResult
            .asMap()
            .entries
            .where((MapEntry<int, cal.Calendar> entry) => !(entry.value.isReadOnly ?? false))
            .map((MapEntry<int, cal.Calendar> calEntry) => CheckboxListTile(
                  title: Text(calEntry.value.name ?? ''),
                  dense: true,
                  value: selector?[calEntry.key],
                  onChanged: (bool? val) {
                    setState(() {
                      selector?[calEntry.key] = val ?? false;
                    });
                  },
                )), DialogContent(
          parent: widget.parent,
        )]
        
        ,
    );
  }
}

class DialogContent extends StatefulWidget {
  final _EventPageState? parent;
  const DialogContent({Key? key, this.parent}) : super(key: key);

  @override
  _DialogContentState createState() => _DialogContentState();
}

class _DialogContentState extends State<DialogContent> {
  bool lastCheck = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Checkbox(
          value: lastCheck,
          onChanged: (bool? val) {
            setState(() {
              lastCheck = val ?? false;
              widget.parent?.lastCheck = val ?? false;
            });
          },
        ),
        const Text('Do not ask again?'),
      ],
    );
  }
}
