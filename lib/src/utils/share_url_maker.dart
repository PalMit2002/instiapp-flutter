import '../api/model/body.dart';
import '../api/model/community.dart';
import '../api/model/communityPost.dart';
import '../api/model/event.dart';
import '../api/model/user.dart';

class ShareURLMaker {
  // static final String webHost = "http://10.105.177.150/";
  static const String webHost = 'https://www.insti.app/';

  static String getEventURL(Event event) {
    return '${webHost}event/${event.eventStrID!}';
  }

  static String getBodyURL(Body body) {
    return '${webHost}org/${body.bodyStrID!}';
  }

  static String getUserURL(User user) {
    return "${webHost}user/${user.userLDAPId ?? ''}";
  }

  static String getCommunityURL(Community community) {
    return '${webHost}group-feed/${community.strId!}';
  }

  static String getCommunityPostURL(CommunityPost communityPost) {
    return '${webHost}view-post/${communityPost.communityPostStrId!}';
  }
}
