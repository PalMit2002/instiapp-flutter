import 'package:flutter/material.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/model/user.dart';
import '../bloc_provider.dart';
import '../blocs/ia_bloc.dart';
import '../drawer.dart';
import '../utils/app_brightness.dart';
import '../utils/common_widgets.dart';
import '../utils/switch_list_tile.dart';
import '../utils/title_with_backbutton.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  final String updateProfileUrl = 'https://gymkhana.iitb.ac.in/sso/user';
  final String feedbackUrl = 'https://insti.app/feedback';

  bool updatingSCN = false;
  bool loggingOutLoading = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    InstiAppBloc bloc = BlocProvider.of(context)!.bloc;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const NavDrawer(),
      bottomNavigationBar: MyBottomAppBar(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              tooltip: 'Show Navigation Drawer',
              icon: const Icon(
                Icons.menu_outlined,
                semanticLabel: 'Show Navigation Drawer',
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: StreamBuilder(
            stream: bloc.session,
            builder: (BuildContext context, AsyncSnapshot<Session?> snapshot) {
              List<Widget> children = <Widget>[
                TitleWithBackButton(
                  child: Text(
                    'Settings',
                    style: theme.textTheme.displaySmall,
                  ),
                )
              ];
              if (snapshot.data != null) {
                children.addAll([
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28.0, vertical: 12.0),
                    child: Text(
                      'Profile settings',
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor),
                    ),
                  ),
                  MySwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 28.0),
                    secondary: updatingSCN
                        ? const CircularProgressIndicatorExtended()
                        : const Icon(Icons.contact_phone_outlined),
                    title: const Text('Show contact number'),
                    subtitle: const Text('Toggle visibility on your profile'),
                    value:
                        snapshot.data?.profile?.userShowContactNumber ?? false,
                    onChanged: updatingSCN
                        ? (_) {}
                        : (bool showContactNumber) async {
                            setState(() {
                              updatingSCN = true;
                            });
                            await bloc
                                .patchUserShowContactNumber(showContactNumber);
                            setState(() {
                              updatingSCN = false;
                            });
                          },
                  ),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 28.0),
                    leading: const Icon(Icons.person_outline_outlined),
                    trailing: const Icon(Icons.launch_outlined),
                    title: const Text('Update Profile'),
                    subtitle: const Text('Update personal details on SSO'),
                    onTap: () async {
                      if (await canLaunchUrl(Uri.parse(updateProfileUrl))) {
                        await launchUrl(
                          Uri.parse(updateProfileUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 28.0),
                    leading: const Icon(Icons.exit_to_app_outlined),
                    title: const Text('Logout'),
                    subtitle: const Text('Sign out of InstiApp'),
                    onTap: loggingOutLoading
                        ? null
                        : () async {
                            setState(() {
                              loggingOutLoading = true;
                            });
                            await bloc.logout();
                            setState(() {
                              loggingOutLoading = false;
                            });
                          },
                    trailing: loggingOutLoading
                        ? const CircularProgressIndicatorExtended()
                        : null,
                  ),
                ]);
              }
              children.addAll([
                Padding(
                  padding: const EdgeInsets.only(
                      left: 28.0, right: 28.0, top: 8.0, bottom: 24.0),
                  child: Text(
                    'App settings',
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, color: theme.primaryColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Text(
                    'Default Homepage',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: DropdownButton(
                    isExpanded: true,
                    items: {
                      '/mess': 'Mess',
                      '/placeblog': 'Placement Blog',
                      '/trainblog': 'Internship Blog',
                      '/feed': 'Feed',
                      '/quicklinks': 'Quick Links',
                      '/news': 'News',
                      '/InSeek': 'InSeek',
                      '/explore': 'Explore',
                      '/calendar': 'Calendar',
                      // "/complaints": "Complaints/Suggestions",
                      '/map': 'Map',
                      // "/settings": "Settings",
                      //TODO: Change to communities
                      '/groups': 'Insight Discussion Forum',
                    }.entries.map((MapEntry<String, String> entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (String? s) {
                      bloc.updateHomepage(s ?? '');
                      setState(() {});
                    },
                    value: bloc.homepageName,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 16.0, bottom: 12.0, left: 28.0, right: 28.0),
                  child: Text(
                    'App Theme',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary),
                  ),
                ),
                RadioListTile<AppBrightness>(
                  title: const Text('Light'),
                  value: AppBrightness.light,
                  groupValue: bloc.brightness,
                  onChanged: (AppBrightness? v) {
                    if (v != null) bloc.brightness = v;
                  },
                ),
                RadioListTile<AppBrightness>(
                  title: const Text('Dark'),
                  value: AppBrightness.dark,
                  groupValue: bloc.brightness,
                  onChanged: (AppBrightness? v) {
                    if (v != null) bloc.brightness = v;
                  },
                ),
                RadioListTile<AppBrightness>(
                  title: const Text('Black'),
                  value: AppBrightness.black,
                  groupValue: bloc.brightness,
                  onChanged: (AppBrightness? v) {
                    if (v != null) bloc.brightness = v;
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 28.0),
                  title: const Text('Primary Color'),
                  subtitle: const Text('Choose primary color of the app'),
                  trailing: CircleColor(
                    circleSize: 24,
                    color: bloc.primaryColor,
                  ),
                  onTap: () {
                    showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Select Primary Color'),
                            content: MaterialColorPicker(
                              onMainColorChange: (ColorSwatch? c) {
                                bloc.primaryColor = c ?? appColors[0];
                              },
                              selectedColor: bloc.primaryColor,
                              colors: appColors,
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Okay'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        });
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 28.0),
                  title: const Text('Accent Color'),
                  subtitle: const Text('Choose accent color of the app'),
                  trailing: CircleColor(
                    circleSize: 24,
                    color: bloc.accentColor,
                  ),
                  onTap: () {
                    showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Select Accent Color'),
                            content: MaterialColorPicker(
                              onMainColorChange: (ColorSwatch? c) {
                                bloc.accentColor = c ?? appColors[0];
                              },
                              selectedColor: bloc.accentColor,
                              colors: appColors,
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Okay'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restore_outlined),
                    label: const Text('Restore Default Theme'),
                    onPressed: () {
                      bloc.primaryColor = bloc.defaultThemes[0][0];
                      bloc.accentColor = bloc.defaultThemes[0][1];
                    },
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 28.0),
                  leading: const Icon(Icons.feedback_outlined),
                  trailing: const Icon(Icons.launch_outlined),
                  title: const Text('Feedback'),
                  subtitle:
                      const Text('Report technical issues or suggest new features'),
                  onTap: () async {
                    if (await canLaunchUrl(Uri.parse(feedbackUrl))) {
                      await launchUrl(
                        Uri.parse(feedbackUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 28.0),
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('The InstiApp Team'),
                  onTap: () {
                    Navigator.pushNamed(context, '/about');
                  },
                ),
              ]);

              return ListView(
                children: children,
              );
            }),
      ),
    );
  }
}
