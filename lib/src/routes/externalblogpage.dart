import 'dart:core';

import 'package:flutter/material.dart';

import '../blocs/blog_bloc.dart';
import 'blogpage.dart';

class ExternalBlogPage extends StatelessWidget {
  const ExternalBlogPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BlogPage(
      postType: PostType.External,
      title: 'External Blog',
      loginNeeded: true,
    );
  }
}
