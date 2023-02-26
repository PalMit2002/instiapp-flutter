import 'dart:async';

import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/model/body.dart';
import '../api/model/event.dart';
import '../api/model/role.dart';
import '../api/model/user.dart';
import '../bloc_provider.dart';
import '../blocs/ia_bloc.dart';
import '../drawer.dart';
import '../utils/common_widgets.dart';
import '../utils/footer_buttons.dart';
import '../utils/share_url_maker.dart';
import '../utils/title_with_backbutton.dart';
import 'eventpage.dart';
import 'userpage.dart';

class BodyPage extends StatefulWidget {
  final Body? initialBody;
  final Future<Body>? bodyFuture;
  final String? heroTag;

  const BodyPage({Key? key, this.bodyFuture, this.initialBody, this.heroTag})
      : super(key: key);

  static void navigateWith(BuildContext context, InstiAppBloc bloc,
      {Body? body, Role? role}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
          name: '/body/${(role?.roleBodyDetails ?? body)?.bodyID}',
        ),
        builder: (BuildContext context) => BodyPage(
          initialBody: role?.roleBodyDetails ?? body,
          bodyFuture:
              bloc.getBody((role?.roleBodyDetails ?? body)?.bodyID ?? ''),
          heroTag: role?.roleID ?? body?.bodyID,
        ),
      ),
    );
  }

  @override
  _BodyPageState createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  Body? body;

  bool loadingFollow = false;

  @override
  void initState() {
    super.initState();
    body = widget.initialBody;
    widget.bodyFuture?.then((Body b) {
      markdown.TableSyntax tableParse = const markdown.TableSyntax();
      b.bodyDescription = markdown.markdownToHtml(
          b.bodyDescription
                  ?.split('\n')
                  .map((String s) => s.trimRight())
                  .toList()
                  .join('\n') ??
              '',
          blockSyntaxes: [tableParse]);
      if (mounted) {
        setState(() {
          body = b;
        });
      } else {
        body = b;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    InstiAppBloc bloc = BlocProvider.of(context)!.bloc;
    List<Widget> footerButtons = <Widget>[];
    bool editAccess = false;
    if (body != null) {
      editAccess = bloc.editBodyAccess(body!);
      if (bloc.currSession != null) {
        footerButtons.addAll([
          _buildFollowBody(theme, bloc),
        ]);
      }

      if ((body?.bodyWebsiteURL ?? '') != '') {
        footerButtons.add(IconButton(
          tooltip: 'Open website',
          icon: const Icon(Icons.language_outlined),
          onPressed: () async {
            if (body?.bodyWebsiteURL != null) {
              if (await canLaunchUrl(Uri.parse(body?.bodyWebsiteURL ?? ''))) {
                await launchUrl(
                  Uri.parse(body?.bodyWebsiteURL ?? ''),
                  mode: LaunchMode.externalApplication,
                );
              }
            }
          },
        ));
      }

      if (editAccess) {
        footerButtons.add(IconButton(
          icon: const Icon(Icons.share_outlined),
          tooltip: 'Share this body',
          onPressed: () async {
            await Share.share(
                'Check this Institute Body: ${ShareURLMaker.getBodyURL(body ?? Body())}');
          },
        ));
      }
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
        child: body == null
            ? const Center(
                child: CircularProgressIndicatorExtended(
                label: Text('Loading the body page'),
              ))
            : ListView(
                children: <Widget>[
                  TitleWithBackButton(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          body?.bodyName ?? '',
                          style: theme.textTheme.displaySmall,
                        ),
                        const SizedBox(height: 8.0),
                        Text(body?.bodyShortDescription ?? '',
                            style: theme.textTheme.titleLarge),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: body?.bodyImageURL != null
                        ? PhotoViewableImage(
                            url: body?.bodyImageURL ?? defUrl,
                            heroTag: widget.heroTag ?? body?.bodyID ?? '',
                            fit: BoxFit.fitWidth,
                          )
                        : const SizedBox(
                            height: 0.0,
                          ),
                  ),
                  if (body?.bodyImageURL != null)
                    const SizedBox(
                      height: 16.0,
                    )
                  else
                    const SizedBox(
                      height: 0.0,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28.0, vertical: 16.0),
                    child: CommonHtml(
                        data: body?.bodyDescription ?? '',
                        defaultTextStyle:
                            theme.textTheme.titleMedium ?? const TextStyle()),
                  ),
                  if (body?.bodyDescription != null)
                    const SizedBox(
                      height: 16.0,
                    )
                  else
                    const SizedBox(
                      height: 0.0,
                    ),
                  const Divider(),
                  ..._nonEmptyListWithHeaderOrEmpty(
                      body?.bodyEvents
                          ?.map((Event e) => _buildEventTile(bloc, theme, e))
                          .toList(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28.0, vertical: 16.0),
                        child: Text(
                          'Events',
                          style: theme.textTheme.headlineSmall,
                        ),
                      )),
                  ..._nonEmptyListWithHeaderOrEmpty(
                      body?.bodyChildren
                          ?.map((Body b) =>
                              _buildBodyTile(bloc, theme.textTheme, b))
                          .toList(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28.0, vertical: 16.0),
                        child: Text(
                          'Organizations',
                          style: theme.textTheme.headlineSmall,
                        ),
                      )),
                  ..._nonEmptyListWithHeaderOrEmpty(
                      body?.bodyRoles
                          ?.expand<User>((Role r) {
                            if (r.roleUsersDetail != null) {
                              return r.roleUsersDetail!
                                  .map((User u) => u..currentRole = r.roleName)
                                  .toList();
                            }
                            return [];
                          })
                          .map<Widget>(
                              (User u) => _buildUserTile(bloc, theme, u))
                          .toList(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28.0, vertical: 16.0),
                        child: Text(
                          'People',
                          style: theme.textTheme.headlineSmall,
                        ),
                      )),
                  ..._nonEmptyListWithHeaderOrEmpty(
                      body?.bodyParents
                          ?.map((Body b) =>
                              _buildBodyTile(bloc, theme.textTheme, b))
                          .toList(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28.0, vertical: 16.0),
                        child: Text(
                          'Part of',
                          style: theme.textTheme.headlineSmall,
                        ),
                      )),
                  const Divider(),
                  const SizedBox(
                    height: 64.0,
                  ),
                ] // Events

                // Children

                // People

                // Parents

                ,
              ),
      ),
      floatingActionButton: body == null
          ? null
          : editAccess
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                  tooltip: 'Edit this Body',
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamed('/putentity/body/${body!.bodyID}');
                  },
                )
              : FloatingActionButton(
                  tooltip: 'Share this body',
                  onPressed: () async {
                    await Share.share(
                        'Check this Institute Body: ${ShareURLMaker.getBodyURL(body!)}');
                  },
                  child: const Icon(Icons.share_outlined),
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      persistentFooterButtons: [
        FooterButtons(
          footerButtons: footerButtons,
        )
      ],
    );
  }

  List<Widget> _nonEmptyListWithHeaderOrEmpty(
      List<Widget>? list, Widget header) {
    return list != null
        ? (list.isNotEmpty ? (list..insert(0, header)) : <Widget>[])
        : [
            CircularProgressIndicatorExtended(
              label: header,
            )
          ];
  }

  ElevatedButton _buildFollowBody(ThemeData theme, InstiAppBloc bloc) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: body?.bodyUserFollows ?? false
            ? theme.colorScheme.secondary
            : theme.scaffoldBackgroundColor,
        foregroundColor: body?.bodyUserFollows ?? false
            ? theme.floatingActionButtonTheme.foregroundColor
            : theme.textTheme.bodyLarge?.color,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: theme.colorScheme.secondary,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
      ),
      // color: body.bodyUserFollows ?? false
      //     ? theme.accentColor
      //     : theme.scaffoldBackgroundColor,
      // textColor:
      //     body.bodyUserFollows ?? false ? theme.accentIconTheme.color : null,
      // shape: RoundedRectangleBorder(
      //     side: BorderSide(
      //       color: theme.accentColor,
      //     ),
      //     borderRadius: BorderRadius.all(Radius.circular(4))),
      child: Row(children: () {
        List<Widget> rowChildren = <Widget>[
          Text(
            body?.bodyUserFollows ?? false ? 'Following' : 'Follow',
            // style: TextStyle(color: Colors.black),
          ),
          const SizedBox(
            width: 8.0,
          ),
          if (body?.bodyFollowersCount != null)
            Text('${body?.bodyFollowersCount}')
          else
            SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    body?.bodyUserFollows ?? false
                        ? theme.floatingActionButtonTheme.foregroundColor!
                        : theme.colorScheme.secondary,
                  ),
                  strokeWidth: 2,
                )),
        ];
        if (loadingFollow) {
          rowChildren.insertAll(0, [
            SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      body?.bodyUserFollows ?? false
                          ? theme.floatingActionButtonTheme.foregroundColor!
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
      onPressed: () async {
        if (bloc.currSession == null) {
          return;
        }
        setState(() {
          loadingFollow = true;
        });
        if (body != null) await bloc.updateFollowBody(body!);
        setState(() {
          loadingFollow = false;
          // event has changes
        });
      },
    );
  }

  Widget _buildBodyTile(InstiAppBloc bloc, TextTheme theme, Body body) {
    return ListTile(
      title: Text(body.bodyName ?? '', style: theme.titleLarge),
      subtitle: Text(body.bodyShortDescription ?? '', style: theme.titleSmall),
      leading: NullableCircleAvatar(
        body.bodyImageURL ?? '',
        Icons.people_outline_outlined,
        heroTag: body.bodyID ?? '',
      ),
      onTap: () {
        BodyPage.navigateWith(context, bloc, body: body);
      },
    );
  }

  Widget _buildEventTile(InstiAppBloc bloc, ThemeData theme, Event event) {
    return ListTile(
      title: Text(
        event.eventName ?? '',
        style: theme.textTheme.titleLarge,
      ),
      enabled: true,
      leading: NullableCircleAvatar(
        event.eventImageURL ?? event.eventBodies?[0].bodyImageURL ?? '',
        Icons.event_outlined,
        heroTag: event.eventID ?? '',
      ),
      subtitle: Text(event.getSubTitle()),
      onTap: () {
        EventPage.navigateWith(context, bloc, event);
      },
    );
  }

  Widget _buildUserTile(InstiAppBloc bloc, ThemeData theme, User u) {
    return ListTile(
      leading: NullableCircleAvatar(
        u.userProfilePictureUrl ?? '',
        Icons.person_outline_outlined,
        heroTag: u.userID ?? '',
      ),
      title: Text(
        u.userName ?? '',
        style: theme.textTheme.titleLarge,
      ),
      subtitle: Text(u.getSubTitle() ?? ''),
      onTap: () {
        UserPage.navigateWith(context, bloc, u);
      },
    );
  }
}
