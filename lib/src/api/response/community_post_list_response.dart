import 'package:json_annotation/json_annotation.dart';

import '../model/communityPost.dart';

part 'community_post_list_response.g.dart';

@JsonSerializable()
class CommunityPostListResponse {
  int? count;
  List<CommunityPost>? data;

  CommunityPostListResponse({
    this.count,
    this.data,
  });
  factory CommunityPostListResponse.fromJson(Map<String, dynamic> json) =>
      _$CommunityPostListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityPostListResponseToJson(this);
}
