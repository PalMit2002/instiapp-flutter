import 'dart:core';

import 'package:flutter/material.dart';

import '../blocs/blog_bloc.dart';
import 'blogpage.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BlogPage(
      loginNeeded: false,
      postType: PostType.NewsArticle,
      title: 'News',
    );
  }
}
