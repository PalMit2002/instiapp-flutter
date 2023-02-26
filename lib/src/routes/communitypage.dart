import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';

import '../api/model/body.dart';
import '../api/model/community.dart';
import '../bloc_provider.dart';
import '../blocs/community_bloc.dart';
import '../blocs/ia_bloc.dart';
import '../drawer.dart';
import '../utils/common_widgets.dart';
import '../utils/customappbar.dart';
import '../utils/share_url_maker.dart';
import 'communitydetails.dart';
// import 'package:flutter/rendering.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  Body? body;
  final FocusNode _focusNode = FocusNode();
  ScrollController? _hideButtonController;
  TextEditingController? _searchFieldController;
  double isFabVisible = 0;
  bool loadingFollow = false;

  bool searchMode = false;
  IconData actionIcon = Icons.search_outlined;

  bool firstBuild = true;

  bool firstCallBack = true;

  @override
  void initState() {
    super.initState();

    _searchFieldController = TextEditingController();
    _hideButtonController = ScrollController();
    _hideButtonController!.addListener(() {
      if (isFabVisible == 1 && _hideButtonController!.offset < 100) {
        setState(() {
          isFabVisible = 0;
        });
      } else if (isFabVisible == 0 && _hideButtonController!.offset > 100) {
        setState(() {
          isFabVisible = 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchFieldController?.dispose();
    _hideButtonController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    InstiAppBloc bloc = BlocProvider.of(context)!.bloc;
    CommunityBloc communityBloc = bloc.communityBloc;
    bool isLoggedIn = bloc.currSession != null;
    if (firstBuild) {
      communityBloc.query = '';
      communityBloc.refresh();
      firstBuild = false;
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      appBar: CustomAppBar(
        appBarSearchStyle: AppBarSearchStyle(
          focusNode: _focusNode,
          hintText: 'Search Communities',
          onChanged: (String query) {
            if (query.length > 2) {
              communityBloc.query = query;
              communityBloc.refresh();
            }
          },
          onSubmitted: (String query) {
            communityBloc.query = query;
            communityBloc.refresh();
          },
        ),
        searchIcon: isLoggedIn,
        title: 'Community',
      ),
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
        child: !isLoggedIn
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
                      'Login To View Communities',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              )
            : GestureDetector(
                onTap: _focusNode.unfocus,
                child: RefreshIndicator(
                  onRefresh: () {
                    return communityBloc.refresh();
                  },
                  child: ListView(
                      controller: _hideButtonController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: StreamBuilder<List<Community>>(
                            stream: communityBloc.communities,
                            builder: (BuildContext context,
                                AsyncSnapshot<List<Community>> snapshot) {
                              return Column(
                                children: _buildContent(
                                    snapshot, theme, communityBloc),
                              );
                            },
                          ),
                        ),
                      ]),
                ),
              ),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: isFabVisible == 0
          ? null
          : FloatingActionButton(
              tooltip: 'Go to the Top',
              onPressed: () {
                _hideButtonController!.animateTo(0.0,
                    curve: Curves.fastOutSlowIn,
                    duration: const Duration(milliseconds: 600));
              },
              child: const Icon(Icons.keyboard_arrow_up_outlined),
            ),
    );
  }

  List<Widget> _buildContent(AsyncSnapshot<List<Community>> snapshot,
      ThemeData theme, CommunityBloc communityBloc) {
    if (snapshot.hasData) {
      List<Community> communities = snapshot.data!;
      if (communities.isEmpty == true) {
        return [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
            child: Text.rich(
                TextSpan(style: theme.textTheme.titleLarge, children: const [
              TextSpan(text: 'Nothing here yet!'),
              // TextSpan(
              //     text: "\"${communityBloc.query}\"",
              //     style: TextStyle(fontWeight: FontWeight.bold)),
              // TextSpan(text: "."),
            ])),
          )
        ];
      }
      //move to next page

      if (firstCallBack) {
        //TODO: Remove this navigation if more than one community
        WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
          Navigator.of(context).pop();
          CommunityDetails.navigateWith(context, communityBloc, communities[0]);
        });
        firstCallBack = false;
      }

      return communities
          .map((Community c) => _buildListTile(c, theme, communityBloc))
          .toList();
    } else {
      return [
        const Center(
            child: CircularProgressIndicatorExtended(
          label: Text('Loading...'),
        ))
      ];
    }
  }

//RELATED TO TILES
  Widget _buildListTile(
    Community community,
    ThemeData theme,
    CommunityBloc bloc,
  ) {
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(10));
    InstiAppBloc instiBloc = BlocProvider.of(context)!.bloc;
    // print(community.isUserFollowing);
    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(0, 255, 255, 255), width: 0),
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          fit: BoxFit
              .cover, //I assumed you want to occupy the entire space of the card
          image: community.coverImg != null
              ? CachedNetworkImageProvider(community.coverImg!)
              : const CachedNetworkImageProvider(
                  'https://devcom-iitb.org/images/logos/DC_logo.png'),
          colorFilter:
              ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            child: ListTile(
              horizontalTitleGap: 0,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              leading: community.logoImg != null
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.25),
                          ),
                          BoxShadow(
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.25),
                            spreadRadius: -2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: NullableCircleAvatar(
                        community.logoImg!,
                        Icons.group,
                        heroTag: community.id,
                        radius: 15,
                        backgroundColor: Colors.white,
                      ),
                    )
                  : null,
              title: Text(
                community.name ?? 'Some community',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textColor: const Color.fromARGB(255, 221, 215, 255),
              trailing: PopupMenuButton<int>(
                itemBuilder: (BuildContext context) => [
                  // popupmenu item 1
                  PopupMenuItem(
                    value: 1,
                    // row has two child icon and text.
                    child: Row(
                      children: [
                        const Icon(Icons.people_alt),
                        const SizedBox(
                          // sized box with width 10
                          width: 10,
                        ),
                        Text((community.isUserFollowing ?? false)
                            ? 'Leave'
                            : 'Join')
                      ],
                    ),
                    onTap: () async {
                      if (instiBloc.currSession == null) {
                        return;
                      }
                      setState(() {
                        loadingFollow = true;
                      });

                      await instiBloc.updateFollowCommunity(community);
                      setState(() {
                        loadingFollow = false;
                        // event has changes
                      });
                    },
                  ),
                  // popupmenu item 2
                  PopupMenuItem(
                    value: 2,
                    // row has two child icon and text
                    onTap: () {
                      Share.share(
                          'Check this community: ${ShareURLMaker.getCommunityURL(community)}');
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.share),
                        SizedBox(
                          // sized box with width 10
                          width: 10,
                        ),
                        Text('Share'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 3,
                    // row has two child icon and text
                    child: Row(
                      children: const [
                        Icon(Icons.push_pin_outlined),
                        SizedBox(
                          // sized box with width 10
                          width: 10,
                        ),
                        Text('Pin')
                      ],
                    ),
                  ),
                ],
                // offset: Offset(0, 100),
                elevation: 2,
                tooltip: 'More',
                icon: const Icon(Icons.more_vert,
                    color: Color.fromARGB(255, 252, 250, 250)),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${community.followersCount ?? "0"} followers"),
                  const SizedBox(height: 10),
                  Text(
                    community.about ?? '',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 243, 243, 243),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              onTap: () {
                CommunityDetails.navigateWith(context, bloc, community);
              },
            ),
          ),
        ),
      ),
    );
  }
}
