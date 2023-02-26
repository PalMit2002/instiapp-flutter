import 'dart:collection';

// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../api/model/mess.dart';
import '../bloc_provider.dart';
import '../blocs/ia_bloc.dart';
import '../drawer.dart';
import '../utils/common_widgets.dart';
import '../utils/title_with_backbutton.dart';

class MessPage extends StatefulWidget {
  const MessPage({Key? key}) : super(key: key);

  @override
  _MessPageState createState() => _MessPageState();
}

class _MessPageState extends State<MessPage> {
  String currHostel = '0';

  _MessPageState();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  bool firstBuild = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    InstiAppBloc bloc = BlocProvider.of(context)!.bloc;

    if (firstBuild) {
      bloc.updateHostels();
      firstBuild = false;
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
              tooltip: 'Show navigation drawer',
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
      drawer: const NavDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => bloc.updateHostels(),
          child: ListView(
            children: <Widget>[
              TitleWithBackButton(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mess Menu',
                      style: theme.textTheme.displaySmall,
                    ),
                    Text(
                      'If the menu is not accurate please contact your hostel council',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: StreamBuilder<UnmodifiableListView<Hostel>>(
                  stream: bloc.hostels,
                  builder: (BuildContext context,
                      AsyncSnapshot<UnmodifiableListView<Hostel>> hostels) {
                    if (currHostel == '0') {
                      currHostel = bloc.currSession?.profile?.hostel ?? '1';
                    }
                    if (hostels.hasData) {
                      List<HostelMess>? currMess = hostels.data!
                          .firstWhere((Hostel h) => h.shortName == currHostel)
                          .mess
                        ?..sort(
                            (HostelMess h1, HostelMess h2) => h1.compareTo(h2));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children:
                            currMess?.map(_buildSingleDayMess).toList() ?? [],
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicatorExtended(
                          label: Text('Loading mess menu'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 8.0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.secondary,
        icon: const Icon(
          Icons.home_outlined,
          // color: theme.accentColor,
        ),
        label: buildDropdownButton(theme),
        onPressed: () {},
        tooltip: 'Change hostel',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget buildDropdownButton(ThemeData theme) {
    InstiAppBloc bloc = BlocProvider.of(context)!.bloc;
    return StreamBuilder<UnmodifiableListView<Hostel>>(
      stream: bloc.hostels,
      builder: (BuildContext context,
          AsyncSnapshot<UnmodifiableListView<Hostel>> snapshot) {
        if (snapshot.hasData) {
          int val = snapshot.data!
              .indexWhere((Hostel h) => h.shortName == currHostel);
          return DropdownButton<int>(
            hint: const Text('Reload'),
            value: val != -1 ? val : null,
            items: snapshot.data!
                .asMap()
                .entries
                .map((MapEntry<int, Hostel> entry) => DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(
                        entry.value.name ?? '',
                      ),
                    ))
                .toList(),
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.secondary),
            onChanged: (int? h) {
              setState(() {
                currHostel = snapshot.data![h ?? 0].shortName ?? '0';
              });
            },
          );
        } else {
          return SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
              strokeWidth: 2,
            ),
          );
        }
      },
    );
  }

  Widget _buildSingleDayMess(HostelMess mess) {
    ThemeData theme = Theme.of(context);
    TextTheme localTheme = theme.textTheme;
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            mess.getDayName(),
            style:
                localTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 8.0,
          ),
          Text(
            'Breakfast',
            style: localTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.secondary),
          ),
          ContentText(mess.breakfast ?? '', context),
          const SizedBox(
            height: 8.0,
          ),
          Text(
            'Lunch',
            style: localTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.secondary),
          ),
          ContentText(mess.lunch ?? '', context),
          const SizedBox(
            height: 8.0,
          ),
          Text(
            'Snacks',
            style: localTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.secondary),
          ),
          ContentText(mess.snacks ?? '', context),
          const SizedBox(
            height: 8.0,
          ),
          Text(
            'Dinner',
            style: localTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.secondary),
          ),
          ContentText(mess.dinner ?? '', context),
          const SizedBox(
            height: 8.0,
          ),
          const Divider(
            height: 16.0,
          ),
        ],
      ),
    );
  }
}

class ContentText extends Text {
  ContentText(String data, BuildContext context, {Key? key})
      : super(data, key: key, style: Theme.of(context).textTheme.titleMedium);
}
