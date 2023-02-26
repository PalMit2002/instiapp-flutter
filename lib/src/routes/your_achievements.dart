import 'dart:collection';

import 'package:flutter/material.dart';

import '../api/model/achievements.dart';
import '../api/model/body.dart';
import '../bloc_provider.dart';
import '../blocs/ia_bloc.dart';
import '../drawer.dart';
import '../utils/common_widgets.dart';
import '../utils/title_with_backbutton.dart';
import 'verify_ach.dart';

class YourAchievementPage extends StatefulWidget {
  const YourAchievementPage({Key? key}) : super(key: key);

  @override
  _YourAchievementPageState createState() => _YourAchievementPageState();
}

class _YourAchievementPageState extends State<YourAchievementPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  bool firstBuild = true;
  bool perToVerify = false;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final InstiAppBloc bloc = BlocProvider.of(context)!.bloc;
    if (firstBuild && bloc.currSession != null) {
      bloc.updateAchievements();
      bloc.achievementBloc.getVerifiableBodies();
      firstBuild = false;
    }
    FloatingActionButton fab;
    fab = FloatingActionButton.extended(
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
                      'Login To View Achievements',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () {
                  bloc.achievementBloc.getVerifiableBodies();
                  return bloc.updateAchievements();
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomScrollView(
                    slivers: [
                      StreamBuilder(
                        stream: bloc.achievementBloc.verifiableBodies,
                        builder: (BuildContext context,
                            AsyncSnapshot<UnmodifiableListView<Body>>
                                snapshot) {
                          if (snapshot.hasData) {
                            if (snapshot.data!.isNotEmpty) {
                              return SliverToBoxAdapter(
                                child: TitleWithBackButton(
                                  child: Text(
                                    'Verify',
                                    style: theme.textTheme.headlineMedium,
                                  ),
                                ),
                              );
                            } else {
                              return const SliverToBoxAdapter(
                                child: Center(),
                              );
                            }
                          } else {
                            return const SliverToBoxAdapter(
                              child: Center(),
                            );
                          }
                        },
                      ),
                      StreamBuilder(
                        stream: bloc.achievementBloc.verifiableBodies,
                        builder: (BuildContext context,
                            AsyncSnapshot<UnmodifiableListView<Body>>
                                snapshot) {
                          if (snapshot.hasData) {
                            if (snapshot.data!.isNotEmpty) {
                              return SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (BuildContext context, int index) =>
                                      BodyCard(thing: snapshot.data![index]),
                                  childCount: snapshot.data!.length,
                                ),
                              );
                            } else {
                              return const SliverToBoxAdapter(
                                child: Center(),
                              );
                            }
                          } else {
                            return const SliverToBoxAdapter(
                              child: Center(),
                            );
                          }
                        },
                      ),
                      SliverToBoxAdapter(
                        child: TitleWithBackButton(
                          child: Text(
                            'Your Acheivements',
                            style: theme.textTheme.headlineMedium,
                          ),
                        ),
                      ),
                      StreamBuilder(
                        stream: bloc.achievements,
                        builder: (BuildContext context,
                            AsyncSnapshot<UnmodifiableListView<Achievement>>
                                snapshot) {
                          if (snapshot.hasData) {
                            if (snapshot.data!.isNotEmpty) {
                              return SliverList(
                                delegate: SliverChildBuilderDelegate(
                                    (BuildContext context, int index) => AchListItem(
                                        achievement: snapshot.data![index]),
                                    childCount: snapshot.data!.length),
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
                                      'No achievments yet',
                                      style: TextStyle(
                                          fontSize: 25.0,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w300),
                                    ),
                                    const SizedBox(
                                      height: 5.0,
                                    ),
                                    Text('Let${"'"}s change that!!',
                                        style: TextStyle(
                                            fontSize: 25.0,
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.w300))
                                  ],
                                ),
                              ));
                            }
                          } else {
                            return const SliverToBoxAdapter(
                              child: Center(
                                child: CircularProgressIndicatorExtended(
                                  label: Text('Getting your Achievements'),
                                ),
                              ),
                            );
                          }
                        },
                      )
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: bloc.currSession == null ? null : fab,
      floatingActionButtonLocation: bloc.currSession == null
          ? null
          : FloatingActionButtonLocation.endDocked,
    );
  }
}

class AchListItem extends StatefulWidget {
  final String title;
  final String company;
  final String icon;
  final String forText;
  final String importance;
  final bool isVerified;
  final bool isHidden;
  final bool isDismissed;
  final Achievement achievement;

  AchListItem({
    Key? key,
    required this.achievement,
  })  : title = achievement.title ?? '',
        company = achievement.body?.bodyName ?? '',
        icon = achievement.body?.bodyImageURL ?? '',
        forText = (achievement.event != null
            ? achievement.event!.eventName
            : 'No event name specified')!,
        importance = achievement.description ?? '',
        isVerified = achievement.verified ?? false,
        isDismissed = achievement.dismissed ?? false,
        isHidden = achievement.hidden ?? false,
        super(key: key);

  @override
  _AchListItemState createState() => _AchListItemState();
}

class _AchListItemState extends State<AchListItem> {
  bool isSwitchOn = false;

  @override
  void initState() {
    // print(widget.company);
    isSwitchOn = widget.isHidden;
    super.initState();
  }

  void toggleSwitch(bool value) {
    if (isSwitchOn) {
      setState(() {
        isSwitchOn = false;
      });
    } else {
      setState(() {
        isSwitchOn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    InstiAppBloc bloc = BlocProvider.of(context)!.bloc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefListItem(
          title: widget.title,
          company: widget.company,
          icon: widget.icon,
          forText: widget.forText,
          importance: widget.importance,
          isVerified: widget.isVerified,
          isDismissed: widget.isDismissed,
        ),
        Row(
          children: [
            Switch(
              value: isSwitchOn,
              onChanged: (bool value) {
                toggleSwitch(value);
                bloc.updateHiddenAchievement(widget.achievement, value);
              },
              activeColor: const Color(0xFFFFEB3B),
              activeTrackColor: Colors.yellow[200],
              inactiveThumbColor: Colors.grey[600],
              inactiveTrackColor: Colors.grey[400],
            ),
            const Text('Hidden'),
          ],
        ),
        Divider(
          color: Colors.grey[600],
        ),
      ],
    );
  }
}

class BodyCard extends StatefulWidget {
  final Body? thing;

  const BodyCard({Key? key, this.thing}) : super(key: key);

  @override
  BodyCardState createState() => BodyCardState();
}

class BodyCardState extends State<BodyCard> {
  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return ListTile(
      title: Text(
        widget.thing?.bodyName ?? '',
        style: theme.textTheme.titleLarge,
      ),
      enabled: true,
      leading: NullableCircleAvatar(
        widget.thing?.bodyImageURL ?? widget.thing?.bodyImageURL ?? '',
        Icons.event_outlined,
        heroTag: widget.thing?.bodyID ?? '',
      ),
      subtitle: Text(widget.thing?.bodyShortDescription ?? ''),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => VerifyAchPage(
                      bodyId: widget.thing?.bodyID,
                    )));
      },
    );
  }
}
