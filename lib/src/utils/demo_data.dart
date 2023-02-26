import '../api/model/post.dart';

List<Post> Function() placementPosts = () => List.generate(
      20,
      (int i) => PlacementBlogPost(
          i.toString(),
          i.toString(),
          '',
          'Demo Placement Title $i',
          'Demo Placement Content $i',
          '2022-01-01T00:00:00+05:30'),
    );

List<Post> Function() trainingPosts = () => List.generate(
      20,
      (int i) => TrainingBlogPost(
          i.toString(),
          i.toString(),
          '',
          'Demo Internship Title $i',
          'Demo Internship Content $i',
          '2022-01-01T00:00:00+05:30'),
    );

List<Post> Function() externalBlogPosts = () => List.generate(
      20,
      (int i) => ExternalBlogPost(
          i.toString(),
          i.toString(),
          '',
          'Demo External Blog Title $i',
          'Demo External Blog Content $i',
          '2022-01-01T00:00:00+05:30',
          body: 'Someone'),
    );

List<Post> Function() queryPosts = () => List.generate(
      20,
      (int i) => Query(
          content: 'Demo Answer $i',
          link: '',
          guid: i.toString(),
          title: 'Demo Question $i',
          published: '2022-01-01T00:00:00+05:30',
          subCategory: 'Demo Sub Category '),
    );
