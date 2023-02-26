import 'dart:core';

import 'package:flutter/material.dart';

import '../blocs/blog_bloc.dart';
import 'blogpage.dart';

class TrainingBlogPage extends StatelessWidget {
  const TrainingBlogPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BlogPage(
      postType: PostType.Training,
      title: 'Internship Blog',
    );
  }
}
