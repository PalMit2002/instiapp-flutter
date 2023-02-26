import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../api/model/community.dart';
import '../api/model/communityPost.dart';
import '../api/model/role.dart';
import '../api/model/user.dart';
import '../bloc_provider.dart';
import '../blocs/community_bloc.dart';
import '../blocs/community_post_bloc.dart';
import '../blocs/ia_bloc.dart';
import '../drawer.dart';
import '../utils/common_widgets.dart';
import '../utils/customappbar.dart';
import 'createpost_form.dart';

class CommunityDetails extends StatefulWidget {
  final Community? initialCommunity;
  final Future<Community?> communityFuture;

  const CommunityDetails(
      {Key? key, required this.communityFuture, this.initialCommunity})
      : super(key: key);

  static void navigateWith(
      BuildContext context, CommunityBloc bloc, Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
          name: "/group/${community.id ?? ""}",
        ),
        builder: (BuildContext context) => CommunityDetails(
          initialCommunity: community,
          communityFuture: bloc.getCommunity(community.id ?? ''),
        ),
      ),
    );
  }

  @override
  _CommunityDetailsState createState() => _CommunityDetailsState();
}

class _CommunityDetailsState extends State<CommunityDetails> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  Community? community;
  bool loadingFollow = false;

  int aboutIndex = 0;

  @override
  void initState() {
    super.initState();
    community = widget.initialCommunity;
    widget.communityFuture.then((Community? community) {
      if (mounted) {
        setState(() {
          this.community = community;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    final InstiAppBloc bloc = BlocProvider.of(context)!.bloc;
    double avatarRadius = 50;
    bool isLoggedIn = bloc.currSession != null;
    // print(community?.isUserFollowing);
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        transparentBackground: true,
        searchIcon: true,
        appBarSearchStyle:
            AppBarSearchStyle(hintText: "Search ${community?.name ?? ""}"),
        //TODO: Uncomment leading style
        // leadingStyle: LeadingStyle(
        //     icon: Icons.arrow_back,
        //     onPressed: () async {
        //       Navigator.of(context).pop();
        //     }),
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
      body: !isLoggedIn
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
                    'Login To Continue',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await bloc.communityBloc
                    .getCommunity(community!.id!)
                    .then((Community? community) {
                  setState(() {
                    this.community = community;
                  });
                });
              },
              child: StreamBuilder<Object>(builder:
                  (BuildContext context, AsyncSnapshot<Object> snapshot) {
                return SingleChildScrollView(
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (community?.coverImg != null)
                            Material(
                              type: MaterialType.transparency,
                              child: Ink.image(
                                image: CachedNetworkImageProvider(
                                  community?.coverImg ?? '',
                                ),
                                height: 200,
                                fit: BoxFit.cover,
                                child: Container(),
                              ),
                            )
                          else
                            const SizedBox(height: 200),
                          SizedBox(
                            height: avatarRadius + 5,
                          ),
                          _buildInfo(theme),
                          CommunityAboutSection(community: community),
                          CommunityPostSection(community: community),
                        ],
                      ),
                      Positioned(
                        top: 200 - avatarRadius,
                        left: 20,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
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
                                community?.logoImg ?? '',
                                Icons.person,
                                radius: avatarRadius,
                              ),
                            ),
                            const SizedBox(width: 20),
                            TextButton(
                              onPressed: () async {
                                if (bloc.currSession == null) {
                                  return;
                                }
                                setState(() {
                                  loadingFollow = true;
                                });
                                if (community != null) {
                                  await bloc.updateFollowCommunity(community!);
                                }
                                setState(() {
                                  loadingFollow = false;
                                  // event has changes
                                });
                              },
                              style: ButtonStyle(
                                  padding: MaterialStateProperty.all<EdgeInsets>(
                                      const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 1)),
                                  foregroundColor: MaterialStateProperty.all<Color>(
                                      Colors.white),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          (community?.isUserFollowing ?? false)
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.secondary),
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(100.0),
                                          side: const BorderSide(color: Colors.transparent)))),
                              child: Text(
                                (community?.isUserFollowing ?? false)
                                    ? 'Joined'
                                    : 'Join',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 1.25,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: const Color.fromARGB(255, 33, 89, 243),
          onPressed: () {
            Navigator.of(context).pushNamed('/posts/add',
                arguments: NavigateArguments(community: community!));
          },
          child: const Icon(
            Icons.mode_edit,
          )),
    );
  }

  Widget _buildInfo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            community?.name ?? '',
            style: theme.textTheme.headlineSmall,
          ),
          Text('${community?.followersCount ?? 0} followers'),
          const SizedBox(height: 10)
        ],
      ),
    );
  }
}

class CommunityAboutSection extends StatefulWidget {
  final Community? community;

  const CommunityAboutSection({Key? key, required this.community})
      : super(key: key);

  @override
  State<CommunityAboutSection> createState() => CommunityAboutSectionState();
}

class CommunityAboutSectionState extends State<CommunityAboutSection> {
  int _selectedIndex = 0;

  bool aboutExpanded = false;
  bool memberExpanded = false;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            child: TabBar(
              tabs: [
                Tab(
                  child: Text(
                    'About',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Tab(
                  child: Text(
                    'Members',
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              ],
              onTap: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildAbout(theme),
              _buildMembers(theme),
            ],
          ),
          _buildFeaturedPosts(theme, widget.community?.featuredPosts),
        ],
      ),
    );
  }

  Widget _buildAbout(ThemeData theme) {
    String about = widget.community?.description ?? '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text.rich(
        TextSpan(
          text: about.length > 210 && !aboutExpanded
              ? about.substring(0, 200) + (aboutExpanded ? '' : '...')
              : about,
          children: !aboutExpanded && about.length > 210
              ? [
                  TextSpan(
                    text: 'Read More.',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: theme.colorScheme.primary),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => setState(() {
                            aboutExpanded = true;
                          }),
                  )
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildMembers(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(5.0),

      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height / 6,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ...?widget.community?.roles?.expand<User>((Role r) {
                if (r.roleUsersDetail != null) {
                  return r.roleUsersDetail!
                      .map((User u) => u..currentRole = r.roleName)
                      .toList();
                }
                return [];
              }).map((User u) => _buildUserTile(theme, u))
              // ElevatedButton(
              //   child: Text(
              //     'SEE ALL',
              //     style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              //   ),
              //   style: ElevatedButton.styleFrom(
              //     primary: Colors.white,
              //     onPrimary: Colors.blue,
              //     minimumSize: Size(400, 20),
              //   ),
              //   onPressed: () {},
              // ),
            ],
          ),
        ),
      ),
      // ),
    );
  }

  Widget _buildUserTile(ThemeData theme, User u) {
    return ListTile(
      leading: NullableCircleAvatar(
        u.userProfilePictureUrl ?? '',
        Icons.person_outline_outlined,
        // heroTag: u.userID ?? "",
      ),
      title: Text(
        u.userName ?? '',
        style: theme.textTheme.titleLarge,
      ),
      subtitle: Text(
        u.getSubTitle() ?? '',
        style: theme.textTheme.bodySmall,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      minVerticalPadding: 0,
      dense: true,
      horizontalTitleGap: 4,
    );
  }

  Widget _buildFeaturedPosts(ThemeData theme, List<CommunityPost>? posts) {
    if (posts == null || posts.isEmpty) {
      return Container();
    }
    return Column(
      children: [
        Container(
          child: Text(
            'Featured',
            style: theme.textTheme.headlineSmall,
          ),
        ),
        Container(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // child: Container(
            //   child: CommunityPostWidget(
            //     communityPost: posts[0],
            //     communityId: posts[0].id,
            //     postType: CPType.Featured,
            //   ),
            // ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: posts
                  .map(
                    (CommunityPost e) => CommunityPostWidget(
                      communityPost: e,
                      postType: CPType.Featured,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class CommunityPostSection extends StatefulWidget {
  final Community? community;

  const CommunityPostSection({Key? key, required this.community})
      : super(key: key);

  @override
  State<CommunityPostSection> createState() => _CommunityPostSectionState();
}

class _CommunityPostSectionState extends State<CommunityPostSection> {
  bool firstBuild = true;
  // final Community? community;

  CPType cpType = CPType.All;

  _CommunityPostSectionState();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    firstBuild = true;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    InstiAppBloc bloc = BlocProvider.of(context)!.bloc;
    CommunityPostBloc communityPostBloc = bloc.communityPostBloc;

    if (firstBuild) {
      communityPostBloc.query = '';
      communityPostBloc.refresh();
      firstBuild = false;
    }

    Community? community = widget.community;

    return community == null
        ? const CircularProgressIndicatorExtended()
        : Container(
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.4)),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 20),
                        TextButton(
                          onPressed: () async {
                            setState(() {
                              loading = true;
                              cpType = CPType.All;
                            });
                            await communityPostBloc.refresh(type: CPType.All);
                            setState(() {
                              loading = false;
                            });
                          },
                          style: _getButtonStyle(cpType == CPType.All, theme),
                          child: const Text(
                            'All',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () async {
                            setState(() {
                              loading = true;
                              cpType = CPType.YourPosts;
                            });
                            await communityPostBloc.refresh(
                                type: CPType.YourPosts);
                            setState(() {
                              loading = false;
                            });
                          },
                          style: _getButtonStyle(
                              cpType == CPType.YourPosts, theme),
                          child: const Text(
                            'Your Posts',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (bloc.hasPermission(community.body!, 'AppP'))
                          TextButton(
                            onPressed: () async {
                              setState(() {
                                loading = true;
                                cpType = CPType.PendingPosts;
                              });
                              await communityPostBloc.refresh(
                                  type: CPType.PendingPosts);
                              setState(() {
                                loading = false;
                              });
                            },
                            style: _getButtonStyle(
                                cpType == CPType.PendingPosts, theme),
                            child: const Text(
                              'Pending posts',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          Container(),
                        const SizedBox(width: 10),
                        if (bloc.hasPermission(community.body!, 'ModC'))
                          TextButton(
                            onPressed: () async {
                              setState(() {
                                loading = true;
                                cpType = CPType.ReportedContent;
                              });
                              await communityPostBloc.refresh(
                                type: CPType.ReportedContent,
                              );
                              setState(() {
                                loading = false;
                              });
                            },
                            style: _getButtonStyle(
                                cpType == CPType.ReportedContent, theme),
                            child: const Text(
                              'Reported Content',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          Container(),
                      ],
                    ),
                  ),
                ),
                Divider(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 0,
                ),
                if (loading)
                  const CircularProgressIndicator()
                else
                  Container(
                    decoration:
                        BoxDecoration(color: theme.colorScheme.surfaceVariant),
                    child: StreamBuilder<List<CommunityPost>>(
                      stream: communityPostBloc.communityposts,
                      builder: (BuildContext context,
                          AsyncSnapshot<List<CommunityPost>> snapshot) {
                        return Column(
                          children: _buildPostList(
                              snapshot, theme, communityPostBloc, community.id),
                        );
                      },
                    ),
                  )
              ],
            ),
          );
  }

  ButtonStyle _getButtonStyle(bool selected, ThemeData theme) {
    return ButtonStyle(
      padding: MaterialStateProperty.all<EdgeInsets>(
          const EdgeInsets.symmetric(horizontal: 15, vertical: 0)),
      foregroundColor: MaterialStateProperty.all<Color>(
        selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100.0),
          side: BorderSide(
            width: selected ? 2 : 1,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPostList(
      AsyncSnapshot<List<CommunityPost>> snapshot,
      ThemeData theme,
      CommunityPostBloc communityPostBloc,
      String? communityId) {
    if (snapshot.hasData) {
      // print(snapshot.data ?? "hii");
      List<CommunityPost> communityPosts = snapshot.data!;

      if (communityPosts.isEmpty == true) {
        return [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
            child: Text.rich(
                TextSpan(style: theme.textTheme.titleLarge, children: const [
              TextSpan(text: 'Nothing here yet!'),
              // TextSpan(
              //     text: "\"${communityPostBloc.query}\"",
              //     style: TextStyle(fontWeight: FontWeight.bold)),
              // TextSpan(text: "."),
            ])),
          )
        ];
      }
      //print("a");
      return communityPosts
          .map(
            (CommunityPost c) => CommunityPostWidget(
              communityPost: c,
              postType: cpType,
            ),
          )
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
}
