import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../drawer.dart';
import '../utils/common_widgets.dart';
import '../utils/title_with_backbutton.dart';

class AboutPage extends StatefulWidget {
  String get title => 'About';

  Map<String, Map<String, Map<String, String>>> get sectionToNameToImageUrl =>
      const <String, Map<String, Map<String, String>>>{
        'Maintainer': {
          'Rishabh Arya': {
            'img':
                'https://raw.githubusercontent.com/wncc/devcomiitb.github.io/master/images/avatars/rishabh.jpg',
          },
        },
        'Core Developers': {
          'Varun Patil': {
            'img': 'https://insti.app/team-pics/varun.jpg',
          },
          'Sajal Narang': {
            'img': 'https://insti.app/team-pics/sajal.jpg',
          },
          'Harshith Goka': {
            'img': 'https://insti.app/team-pics/harshith.jpg',
          },
          'Abeen': {
            'img':
                'https://raw.githubusercontent.com/wncc/devcomiitb.github.io/master/images/avatars/abeen.jpg',
          },
        },
        'Developers': {
          'Mrunmayi Mungekar': {
            'img': 'https://insti.app/team-pics/mrunmayi.jpg',
          },
          'Owais Chunawala': {
            'img': 'https://insti.app/team-pics/owais.jpg',
          },
          'Hrushikesh Bodas': {
            'img': 'https://insti.app/team-pics/hrushikesh.jpg',
          },
          'Yash Khemchandani': {
            'img': 'https://insti.app/team-pics/yashkhem.jpg',
          },
          'Bavish Kulur': {
            'img': 'https://insti.app/team-pics/bavish.jpg',
          },
          'Mayuresh Bhattu': {
            'img': 'https://insti.app/team-pics/mayu.jpg',
          },
          'Maitreya Verma': {
            'img': 'https://insti.app/team-pics/maitreya.jpg',
          },
          'E Aakash': {
            'img':
                'https://raw.githubusercontent.com/wncc/devcomiitb.github.io/master/images/avatars/e%20aakash.jpg',
          },
          'Dev Desai': {
            'img':
                'https://raw.githubusercontent.com/wncc/devcomiitb.github.io/master/images/avatars/DevDesai.jpg',
          },
          'Ashwin Ramachandran': {
            'img':
                'https://raw.githubusercontent.com/wncc/devcomiitb.github.io/master/images/avatars/Ashwin%20Ram.jpg',
          },
          'Palash Mittal': {
            'img':
                'https://raw.githubusercontent.com/wncc/devcomiitb.github.io/master/images/avatars/Palash%20Mittal.jpg',
          },
          'Harsh Jha': {
            'img': 'https://devcom-iitb.org/images/avatars/Harsh%20Jha.png',
          },
        },
        'Design': {
          'Soham Khadtare': {
            'img': 'https://insti.app/team-pics/soham.jpg',
          },
        },
        'Ideation': {
          'Nihal Singh': {
            'img': 'https://insti.app/team-pics/nihal.jpg',
          },
          'Yashvardhan Didwania': {
            'img': 'https://insti.app/team-pics/ydidwania.jpg',
          },
          'Kumar Ayush': {
            'img': 'https://insti.app/team-pics/cheeku.jpg',
          },
          'Sarthak Khandelwal': {
            'img': 'https://insti.app/team-pics/sarthak.jpg',
          },
        },
        'Alumni': {
          'Abhijit Tomar': {
            'img': 'https://insti.app/team-pics/tomar.jpg',
          },
          'Bijoy Singh Kochar': {
            'img': 'https://insti.app/team-pics/bijoy.jpg',
          },
          'Dheerendra Rathor': {
            'img': 'https://insti.app/team-pics/dheerendra.jpg',
          },
          'Ranveer Aggarwal': {
            'img': 'https://insti.app/team-pics/ranveer.jpg',
          },
          'Aman Gour': {
            'img': 'https://insti.app/team-pics/amangour.jpg',
          },
        },
        'Testing': {
          'tty0': {
            'img': 'https://insti.app/team-pics/wncc.jpg',
          },
        },
        'Contribute': {
          'Flutter iOS/Android': {
            'img': 'https://insti.app/team-pics/flutter.png',
            'url': 'https://github.com/tastelessjolt/instiapp-flutter',
          },
          'Android App': {
            'img': 'https://insti.app/team-pics/android.png',
            'url': 'https://github.com/wncc/InstiApp',
          },
          'Angular PWA': {
            'img': 'https://insti.app/team-pics/angular.png',
            'url': 'https://github.com/pulsejet/iitb-app-angular',
          },
          'Django API': {
            'img': 'https://insti.app/team-pics/python.png',
            'url': 'https://github.com/wncc/IITBapp',
          },
        }
      };

  const AboutPage({Key? key}) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

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
                _scaffoldKey.currentState!.openDrawer();
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            TitleWithBackButton(
              child: Text(
                widget.title,
                style: theme.textTheme.displaySmall,
              ),
            ),
            ..._buildContent(theme, widget.sectionToNameToImageUrl),
          ],
        ),
      ),
    );
  }

  Iterable<Widget> _buildContent(
      ThemeData theme, Map<String, Map<String, Map<String, String>>> data) {
    return data.entries
        .map((MapEntry<String, Map<String, Map<String, String>>> entry) {
      return <Widget>[
        Center(
          child: Text(
            entry.key,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 28,
            left: 28,
            right: 28,
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.spaceEvenly,
            direction: Axis.horizontal,
            children: entry.value.entries
                .map((MapEntry<String, Map<String, String>> nameEntry) =>
                    SizedBox(
                      width: 96,
                      child: InkWell(
                        onTap: nameEntry.value.containsKey('url')
                            ? () async {
                                if (await canLaunchUrl(
                                    Uri.parse(nameEntry.value['url']!))) {
                                  await launchUrl(
                                    Uri.parse(nameEntry.value['url']!),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              }
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            NullableCircleAvatar(
                              nameEntry.value['img'] ?? '',
                              Icons.person_outline_outlined,
                              radius: 48,
                              backgroundColor: Colors.transparent,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              nameEntry.key,
                              textAlign: TextAlign.center,
                            )
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(
          height: 48,
        )
      ];
    }).expand((List<Widget> li) => li);
  }
}
