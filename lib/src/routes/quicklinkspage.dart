import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../drawer.dart';
import '../utils/common_widgets.dart';
import '../utils/title_with_backbutton.dart';

class QuickLinksPage extends StatefulWidget {
  Map<String, Map<String, String>> get links => {
        // "CMS": {
        //   "CMS": "https://gymkhana.iitb.ac.in/cms_new/",
        //   "CMS - Maintenance": "https://support.iitb.ac.in",
        //   "CMS - Network": "https://help-cc.iitb.ac.in/",
        //   "Insti Eateries Feedback":
        //       "https://gymkhana.iitb.ac.in/feedback/eateries/",
        // },
        'DevCom': {
          'Leave Portal': 'https://gymkhana.iitb.ac.in/lap',
          'Resume Portal': 'https://resume.devcom-iitb.org/',
          'AMS': 'https://ams.iitb.ac.in/',
        },
        'Academics': {
          'ASC': 'https://asc.iitb.ac.in',
          'External ASC': 'https://portal.iitb.ac.in/asc',
          'Moodle': 'https://moodle.iitb.ac.in',
          'Placement Blog':
              'https://campus.placements.iitb.ac.in/blog/placement',
          'Internship Blog':
              'https://campus.placements.iitb.ac.in/blog/internship',
          'Central Library': 'http://www.library.iitb.ac.in/',
        },
        'Calendar': {
          'Academic Calendar':
              'http://www.iitb.ac.in/newacadhome/toacadcalender.jsp',
          'Academic Timetable':
              'http://www.iitb.ac.in/newacadhome/timetable.jsp',
          'Holidays List':
              'http://www.iitb.ac.in/en/about-iit-bombay/iit-bombay-holidays-list',
          'Circulars': 'http://www.iitb.ac.in/newacadhome/circular.jsp',
          'Course List': 'https://portal.iitb.ac.in/asc/Courses',
        },
        'Services': {
          'WebMail': 'https://webmail-sso.iitb.ac.in/',
          // "GPO": "https://gpo.iitb.ac.in",
          'CAMP': 'https://camp.iitb.ac.in/',
          'Microsoft Store': 'http://msstore.iitb.ac.in/',
          'BigHome Cloud': 'https://home.iitb.ac.in/',
        },
        'Miscellaneous': {
          'Intercom Extensions':
              'https://portal.iitb.ac.in/TelephoneDirectory/',
          'Hospital': 'http://www.iitb.ac.in/hospital/',
        },
      };

  const QuickLinksPage({Key? key}) : super(key: key);

  @override
  _QuickLinksPageState createState() => _QuickLinksPageState();
}

class _QuickLinksPageState extends State<QuickLinksPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // var bloc = BlocProvider.of(context).bloc;
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
        child: ListView(children: <Widget>[
          TitleWithBackButton(
            child: Text(
              'Quick Links',
              style: theme.textTheme.displaySmall,
            ),
          ),
          const Divider(),
          ..._parseLinks(widget.links),
        ]),
      ),
    );
  }

  Iterable<Widget> _parseLinks(Map<String, Map<String, String>> links) {
    return links.entries.expand(_parseEachSection);
  }

  Iterable<Widget> _parseEachSection(
      MapEntry<String, Map<String, String>> section) {
    return [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 28),
        title: Text(section.key,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
      ),
      ...section.value.entries.map(_parseLink)
    ];
  }

  Widget _parseLink(MapEntry<String, String> link) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 28),
      title: Text(link.key, style: const TextStyle(fontSize: 24)),
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(link.value))) {
          await launchUrl(
            Uri.parse(link.value),
            mode: LaunchMode.externalApplication,
          );
        }
      },
    );
  }
}
