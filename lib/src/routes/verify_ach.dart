import 'dart:collection';

import 'package:flutter/material.dart';

import '../api/model/achievements.dart';
import '../bloc_provider.dart';
import '../blocs/ach_to_vefiry_bloc.dart';
import '../blocs/ia_bloc.dart';
import '../drawer.dart';
import '../utils/common_widgets.dart';

class VerifyAchPage extends StatefulWidget {
  final String? bodyId;
  const VerifyAchPage({Key? key, this.bodyId}) : super(key: key);

  @override
  _VerifyAchPageState createState() => _VerifyAchPageState();
}

class _VerifyAchPageState extends State<VerifyAchPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  bool firstBuild = true;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    InstiAppBloc bloc = BlocProvider.of(context)!.bloc;
    VerifyBloc verifyBloc = bloc.bodyAchBloc;
    // print("Body id:" + (widget.bodyId ?? ""));

    if (bloc.currSession == null) {
      Navigator.pop(context);
    }

    if (firstBuild) {
      verifyBloc.updateAchievements(widget.bodyId ?? '');
    }

    FloatingActionButton fab = FloatingActionButton.extended(
      icon: const Icon(Icons.add_outlined),
      label: const Text('Add Acheivement'),
      onPressed: () {
        Navigator.of(context).pushNamed('/achievements/add');
      },
    );

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
        child: RefreshIndicator(
          onRefresh: () {
            return verifyBloc.updateAchievements(widget.bodyId ?? '');
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Text(
                    'Verify',
                    style: theme.textTheme.displaySmall,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 10,
                  ),
                ),
                StreamBuilder(
                  stream: verifyBloc.achievements,
                  builder: (BuildContext context,
                      AsyncSnapshot<UnmodifiableListView<Achievement>>
                          snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data!.isNotEmpty) {
                        // print(snapshot.data);
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              // print(index);
                              Achievement data = snapshot.data![index];
                              // print("Data " +
                              //     index.toString() +
                              //     ": " +
                              //     data.title.toString());
                              return VerifyListItem(
                                achievement: data,
                              );
                            },
                            childCount: snapshot.data!.length,
                          ),
                        );
                      } else {
                        return SliverToBoxAdapter(
                            child: Container(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sports_basketball,
                                color: Colors.grey[500],
                                size: 200.0,
                              ),
                              const SizedBox(
                                height: 15.0,
                              ),
                              Text(
                                'Nothing to verify here!',
                                style: TextStyle(
                                    fontSize: 25.0,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w300),
                              ),
                            ],
                          ),
                        ));
                      }
                    } else {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: CircularProgressIndicatorExtended(
                            label: Text('Getting achievements to verify'),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}

class VerifyListItem extends StatefulWidget {
  final Achievement achievement;

  const VerifyListItem({Key? key, required this.achievement}) : super(key: key);

  @override
  _VerifyListItemState createState() => _VerifyListItemState();
}

class _VerifyListItemState extends State<VerifyListItem> {
  bool isVerified = false;
  bool isDismissed = false;

  String verifyText = 'Verify';

  void showAlertDialog(BuildContext context, VerifyBloc verifyBloc) {
    // set up the buttons
    Widget cancelButton = ElevatedButton(
      child: const Text('No'),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = ElevatedButton(
      child: const Text('Yes'),
      onPressed: () {
        verifyBloc.deleteAchievement(
            widget.achievement.id ?? '', widget.achievement.body?.bodyID ?? '');
        Navigator.of(context).pop();
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text('AlertDialog'),
      content: const Text('Are you sure you want to delete achievement forever?'),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    VerifyBloc verifyBloc = BlocProvider.of(context)!.bloc.bodyAchBloc;
    return Column(
      children: [
        DefListItem(
          title: widget.achievement.title ?? 'No title',
          company: widget.achievement.user?.userName ?? 'Anonymous',
          forText: widget.achievement.event != null
              ? widget.achievement.event!.eventName ?? ''
              : '',
          importance: widget.achievement.description ?? '',
          adminNote: widget.achievement.adminNote ?? '',
          isVerified: isVerified,
          isDismissed: isDismissed,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                verifyBloc.dismissAchievement(true, widget.achievement);

                setState(() {
                  isVerified = !isVerified;
                  if (isVerified) {
                    verifyText = 'Unverify';
                    isDismissed = false;
                  } else {
                    verifyText = 'Verify';
                    isDismissed = true;
                  }
                });
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
              ),
              child: Text(verifyText),
            ),
            ElevatedButton(
              onPressed: isVerified || isDismissed
                  ? null
                  : () {
                      verifyBloc.dismissAchievement(false, widget.achievement);
                      setState(() {
                        isDismissed = true;
                      });
                    },
              style: ButtonStyle(
                backgroundColor: isVerified || isDismissed
                    ? MaterialStateProperty.all(Colors.grey)
                    : MaterialStateProperty.all(Colors.yellow),
              ),
              child: const Text(
                'Dismiss',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                showAlertDialog(context, verifyBloc);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        Divider(
          color: Colors.grey[600],
        ),
      ],
    );
  }
}
