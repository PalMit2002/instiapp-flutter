import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../api/model/notification.dart' as ntf;
import '../bloc_provider.dart';
import '../blocs/ia_bloc.dart';
import '../drawer.dart';
import '../utils/common_widgets.dart';
import '../utils/title_with_backbutton.dart';
import 'eventpage.dart';

class NotificationsPage extends StatefulWidget {
  final String title = 'Notifications';

  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool clearAllLoading = false;
  bool shouldMarkAsRead = true;
  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    InstiAppBloc bloc = BlocProvider.of(context)!.bloc;

    bloc.updateNotifications();

    return Scaffold(
      key: _scaffoldKey,
      drawer: const NavDrawer(),
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
      body: SafeArea(
        child: StreamBuilder<UnmodifiableListView<ntf.Notification>>(
          stream: bloc.notifications,
          builder: (BuildContext context,
              AsyncSnapshot<UnmodifiableListView<ntf.Notification>> snapshot) {
            return RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: () {
                return bloc.updateNotifications();
              },
              child: ListView(
                scrollDirection: Axis.vertical,
                children: <Widget>[
                      TitleWithBackButton(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.displaySmall,
                        ),
                      )
                    ] +
                    _buildContent(snapshot, theme, bloc),
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Clear all notifications',
        onPressed: () async {
          setState(() {
            clearAllLoading = true;
          });
          await bloc.clearAllNotifications();
          setState(() {
            clearAllLoading = false;
          });
        },
        icon: clearAllLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary),
                ),
              )
            : const Icon(Icons.clear_all_outlined),
        label: const Text('Clear All'),
      ),
    );
  }

  List<Widget> _buildContent(
      AsyncSnapshot<UnmodifiableListView<ntf.Notification>> snapshot,
      ThemeData theme,
      InstiAppBloc bloc) {
    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
      return snapshot.data!
          .map((ntf.Notification n) => _buildNotificationTile(theme, bloc, n))
          .toList();
    } else {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
          child:
              Text.rich(TextSpan(style: theme.textTheme.titleLarge, children: const [
            TextSpan(text: 'No new '),
            TextSpan(
                text: 'notifications',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: '.'),
          ])),
        )
      ];
    }
  }

  Widget _buildNotificationTile(
      ThemeData theme, InstiAppBloc bloc, ntf.Notification notification) {
    return Dismissible(
      key: Key('${notification.notificationId}${Random().nextInt(10000)}'),
      background: Container(
        color: Colors.red,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.delete_outlined, color: Colors.white),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.delete_outlined, color: Colors.white),
            ),
          ],
        ),
      ),
      onDismissed: (DismissDirection direction) async {
        await ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(
              content: Text('Marked "${notification.getTitle()}" as read '),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  shouldMarkAsRead = false;
                },
              ),
            ))
            .closed;
        if (shouldMarkAsRead) {
          await bloc.clearNotification(notification);
        }
        shouldMarkAsRead = true;
        setState(() {});
      },
      child: ListTile(
        title: Text(notification.getTitle() ?? ''),
        subtitle: Text(notification.getSubtitle() ?? ''),
        leading: NullableCircleAvatar(
          notification.getAvatarUrl() ?? '',
          Icons.notifications_outlined,
          heroTag: notification.getID() ?? '',
        ),
        onTap: () {
          if (notification.isBlogPost) {
            Navigator.of(context).pushNamed(
                (notification.getBlogPost().link?.contains('internship') ??
                        false)
                    ? '/trainblog'
                    : '/placeblog');
          } else if (notification.isEvent) {
            EventPage.navigateWith(context, bloc, notification.getEvent());
          } else if (notification.isNews) {
            Navigator.of(context).pushNamed('/news');
          } else if (notification.isComplaintComment) {
            Navigator.of(context).pushNamed(
                '/complaint/${notification.getComment().complaintID}?reload=true');
          }

          bloc.client.markNotificationRead(
              bloc.getSessionIdHeader(), '${notification.notificationId}');
        },
      ),
    );
  }
}
