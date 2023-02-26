import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/model/body.dart';
import '../api/model/community.dart';
import '../api/model/communityPost.dart';
import '../api/model/user.dart';
import '../api/response/image_upload_response.dart';
import '../bloc_provider.dart';
import '../blocs/ia_bloc.dart';
import '../drawer.dart';
import '../utils/common_widgets.dart';

class NavigateArguments {
  final Community? community;
  final CommunityPost? post;

  NavigateArguments({this.community, this.post});
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  // initiate widgetstate Form
  @override
  _CreatePostPage createState() => _CreatePostPage();
}

class _CreatePostPage extends State<CreatePostPage> {
  int number = 0;
  bool selectedE = false;
  bool selectedB = false;
  bool selectedS = false;
  bool click = true;

  List<File> imageFiles = [];

  // List<CreatePost>? posts;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final GlobalKey<FormState> _formKey1 = GlobalKey<FormState>();

  CommunityPost currRequest1 = CommunityPost();

  @override
  void initState() {
    super.initState();
  }

  bool firstBuild = true;
  bool isEditing = false;

  @override
  Widget build(BuildContext context) {
    // print(_selectedBody);
    InstiAppBloc bloc = BlocProvider.of(context)!.bloc;
    ThemeData theme = Theme.of(context);
    final User? profile = bloc.currSession?.profile;
    if (firstBuild) {
      currRequest1.featured = false;
      final NavigateArguments? args =
          ModalRoute.of(context)!.settings.arguments as NavigateArguments?;
      if (args != null) {
        if (args.post != null) {
          isEditing = true;
          currRequest1 = args.post!;
        } else {
          currRequest1.community = args.community;
        }
      }
      firstBuild = false;
    }
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
                  _scaffoldKey.currentState!.openDrawer();
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
                        'Login To Make Post',
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => bloc.updateEvents(),
                  child: Padding(
                    padding: const EdgeInsets.all(7.0),
                    child: Form(
                      key: _formKey1,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 50,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.black,
                                        backgroundColor: theme.canvasColor,
                                        disabledForegroundColor: Colors.grey,
                                        elevation: 0.0),
                                    child: const Icon(Icons.close),
                                  ),
                                ),
                                Container(
                                    child: const Text('Create Post',
                                        style: TextStyle(
                                          fontSize: 24.0,
                                          fontWeight: FontWeight.bold,
                                        ))),
                                SizedBox(
                                  width: 65,
                                  child: TextButton(
                                    onPressed: () async {
                                      // CommunityPost post = )
                                      currRequest1.imageUrl ??= [];
                                      for (int i = 0;
                                          i < imageFiles.length;
                                          i++) {
                                        ImageUploadResponse resp =
                                            await bloc.client.uploadImage(
                                                bloc.getSessionIdHeader(),
                                                imageFiles[i]);
                                        currRequest1.imageUrl!
                                            .add(resp.pictureURL!);
                                      }
                                      currRequest1.deleted = false;
                                      currRequest1.anonymous ??= false;
                                      currRequest1.hasUserReported = false;
                                      if (isEditing) {
                                        await bloc.communityPostBloc
                                            .updateCommunityPost(currRequest1);
                                      } else {
                                        await bloc.communityPostBloc
                                            .createCommunityPost(currRequest1);
                                      }

                                      Navigator.of(context).pop(currRequest1);
                                    },
                                    style: ButtonStyle(
                                        foregroundColor: MaterialStateProperty
                                            .all(Colors.white),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                const Color.fromARGB(
                                                    255, 72, 115, 235)),
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                        ))),
                                    child: Text(
                                      isEditing ? 'EDIT' : 'POST',
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          width: 1,
                                          color: theme
                                              .colorScheme.surfaceVariant))),
                              child: ListTile(
                                leading: NullableCircleAvatar(
                                  (click == true)
                                      ? profile?.userProfilePictureUrl ?? ''
                                      : 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSM9q9XJKxlskry5gXTz1OXUyem5Ap59lcEGg&usqp=CAU',
                                  Icons.person,
                                  radius: 22,
                                ),
                                title: Text(
                                  (click == true)
                                      ? profile?.userName ?? ' '
                                      : 'Anonymous',
                                  style: const TextStyle(
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                subtitle: ElevatedButton.icon(
                                  label: Text(
                                    (click == true) ? 'Public' : 'anonymous',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      click = !click;
                                      currRequest1.anonymous = !click;
                                    });
                                  },
                                  icon: Icon((click == true)
                                      ? Icons.public
                                      : Icons.sentiment_neutral),
                                  style: ButtonStyle(
                                      foregroundColor: (click == true)
                                          ? MaterialStateProperty.all(
                                              Colors.grey)
                                          : MaterialStateProperty.all(
                                              Colors.white),
                                      backgroundColor: (click == true)
                                          ? MaterialStateProperty.all(
                                              Colors.white)
                                          : MaterialStateProperty.all(
                                              Colors.black),
                                      shape: MaterialStateProperty.all<
                                              RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              side: const BorderSide(
                                                  color: Colors.grey)))),
                                ),
                              ),
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height / 3,
                              ),
                              child: SingleChildScrollView(
                                child: Container(
                                  child: TextFormField(
                                    initialValue: currRequest1.content,
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null,
                                    decoration: const InputDecoration(
                                      hintText: 'Write your Post..',
                                    ),
                                    autocorrect: true,
                                    onChanged: (String value) {
                                      setState(() {
                                        currRequest1.content = value;
                                        currRequest1.postedBy = profile;
                                      });
                                    },
                                    validator: (String? value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Post content should not be empty';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ...(currRequest1.imageUrl ?? [])
                                        .asMap()
                                        .entries
                                        .map((MapEntry<int, String> e) => _buildImageUrl(
                                              e.value,
                                              e.key,
                                            )),
                                    ...imageFiles
                                        .asMap()
                                        .entries
                                        .map((MapEntry<int, File> e) => _buildImageFile(
                                              e.value,
                                              e.key,
                                            )),
                                  ],
                                ))
                          ]),
                    ),
                  ),
                ),
        ),
        persistentFooterButtons: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height / 5,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    title: const Text('Attach Photos/Videos'),
                    leading: const Icon(Icons.attach_file),
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? pi =
                          await picker.pickImage(source: ImageSource.gallery);

                      if (pi != null) {
                        // ImageUploadResponse resp = await bloc.client
                        //     .uploadImage(
                        //         bloc.getSessionIdHeader(), File(pi.path));
                        // print(resp.pictureURL);
                        if (await pi.length() / 1000000 <= 10) {
                          setState(() {
                            imageFiles.add(File(pi.path));
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content:
                                Text('Image size should be less than 10MB'),
                          ));
                        }
                      }
                    },
                  ),
                  DropdownMultiSelect<dynamic>(
                    load: Future.value([
                      ...currRequest1.bodies ?? [],
                      ...currRequest1.users ?? []
                    ]),
                    update: (List? tags) {
                      currRequest1.bodies = tags
                          ?.where((element) => element.runtimeType == Body)
                          .map((e) => e as Body)
                          .toList();
                      currRequest1.users = tags
                          ?.where((element) => element.runtimeType == User)
                          .map((e) => e as User)
                          .toList();
                    },
                    onFind: (String? query) async {
                      List<Body> list1 =
                          await bloc.achievementBloc.searchForBody(query);
                      List<User> list2 =
                          await bloc.achievementBloc.searchForUser(query);
                      List<dynamic> list = [...list1, ...list2];
                      return list;
                    },
                    singularObjectName: 'Tag',
                    pluralObjectName: 'Tags',
                  ),
                  DropdownMultiSelect<Interest>(
                    update: (List<Interest>? interests) {
                      currRequest1.interests = interests;
                    },
                    load: Future.value(currRequest1.interests ?? []),
                    onFind: bloc.achievementBloc.searchForInterest,
                    singularObjectName: 'interest',
                    pluralObjectName: 'interests',
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildImageUrl(String url, int index) {
    return Stack(
      children: [
        Image.network(
          url,
          height: MediaQuery.of(context).size.height / 7.5,
          width: MediaQuery.of(context).size.height / 7.5,
          fit: BoxFit.scaleDown,
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  currRequest1.imageUrl!.removeAt(index);
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageFile(File file, int index) {
    return Stack(
      children: [
        Image.file(
          file,
          height: MediaQuery.of(context).size.height / 7.5,
          width: MediaQuery.of(context).size.height / 7.5,
          fit: BoxFit.scaleDown,
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  imageFiles.removeAt(index);
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
