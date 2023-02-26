import 'dart:core';

import 'package:flutter/material.dart';

import '../blocs/blog_bloc.dart';
import 'blogpage.dart';

class PlacementBlogPage extends StatelessWidget {
  const PlacementBlogPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BlogPage(
      postType: PostType.Placement,
      title: 'Placement Blog',
    );
  }
}
