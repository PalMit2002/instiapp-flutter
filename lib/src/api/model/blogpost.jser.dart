// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blogpost.dart';

// **************************************************************************
// JaguarSerializerGenerator
// **************************************************************************

abstract class _$PlacementBlogPostSerializer
    implements Serializer<PlacementBlogPost> {
  @override
  Map<String, dynamic> toMap(PlacementBlogPost model) {
    if (model == null) return null;
    Map<String, dynamic> ret = <String, dynamic>{};
    setMapValue(ret, 'postID', model.postID);
    setMapValue(ret, 'link', model.link);
    setMapValue(ret, 'title', model.title);
    setMapValue(ret, 'content', model.content);
    setMapValue(ret, 'published', model.published);
    return ret;
  }

  @override
  PlacementBlogPost fromMap(Map map) {
    if (map == null) return null;
    final obj = new PlacementBlogPost();
    obj.postID = map['postID'] as String;
    obj.link = map['link'] as String;
    obj.title = map['title'] as String;
    obj.content = map['content'] as String;
    obj.published = map['published'] as String;
    return obj;
  }
}

abstract class _$TrainingBlogPostSerializer
    implements Serializer<TrainingBlogPost> {
  @override
  Map<String, dynamic> toMap(TrainingBlogPost model) {
    if (model == null) return null;
    Map<String, dynamic> ret = <String, dynamic>{};
    setMapValue(ret, 'postID', model.postID);
    setMapValue(ret, 'link', model.link);
    setMapValue(ret, 'title', model.title);
    setMapValue(ret, 'content', model.content);
    setMapValue(ret, 'published', model.published);
    return ret;
  }

  @override
  TrainingBlogPost fromMap(Map map) {
    if (map == null) return null;
    final obj = new TrainingBlogPost();
    obj.postID = map['postID'] as String;
    obj.link = map['link'] as String;
    obj.title = map['title'] as String;
    obj.content = map['content'] as String;
    obj.published = map['published'] as String;
    return obj;
  }
}