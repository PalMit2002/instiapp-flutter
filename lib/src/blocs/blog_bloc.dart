import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:markdown/markdown.dart' as markdown;
import 'package:rxdart/rxdart.dart';

import '../api/model/post.dart';
import '../api/request/chatbotlog_request.dart';
import '../api/response/chat_bot_response.dart';
import '../utils/demo_data.dart';
import 'ia_bloc.dart';

enum PostType { Placement, Training, NewsArticle, External, Query, ChatBot }

class PostBloc {
  // Streams
  ValueStream<UnmodifiableListView<Post>> get blog => _blogSubject.stream;
  final BehaviorSubject<UnmodifiableListView<Post>> _blogSubject =
      BehaviorSubject<UnmodifiableListView<Post>>();

  ValueStream<UnmodifiableListView<Map<String, String>>> get categories =>
      _blogSubject1.stream;
  final BehaviorSubject<UnmodifiableListView<Map<String, String>>>
      _blogSubject1 =
      BehaviorSubject<UnmodifiableListView<Map<String, String>>>();

  Sink<int> get inPostIndex => _indexController.sink;
  PublishSubject<int> _indexController = PublishSubject<int>();

  // Params
  final int _noOfPostsPerPage = 20;
  String query = '';

  // parent bloc
  InstiAppBloc bloc;

  // Training or Placement or News Article or External
  PostType postType;

  // For categories
  String category = '';

  PostBloc(this.bloc, {required this.postType}) {
    // if (postType == PostType.Query) {
    //   _setCategories();
    // }
    _setIndexListener();
  }

  void get context => null;

  void _setIndexListener() {
    _indexController.stream
        .bufferTime(const Duration(milliseconds: 500))
        .where((List<int> batch) => batch.isNotEmpty)
        .listen(_handleIndexes);
  }

  final Map<int, List<Post>> _fetchPages = <int, List<Post>>{};
  final Set<int> _pagesBeingFetched = <int>{};

  final Map<int, List<Post>> _searchFetchPages = <int, List<Post>>{};
  final Set<int> _searchPagesBeingFetched = <int>{};

  static final List<String> month = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sept',
    'Oct',
    'Nov',
    'Dec'
  ];
  static final List<String> week = [
    'Mon',
    'Tue',
    'Wed',
    'Thur',
    'Fri',
    'Sat',
    'Sun'
  ];
  String dateTimeFormatter(String pub) {
    final DateTime dt = DateTime.parse(pub).toLocal();
    return "${week[dt.weekday - 1]}, ${month[dt.month - 1]} ${dt.day.toString()}${dt.year == DateTime.now().year ? "" : (" ${dt.year}")}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }

  Future<List<Post>> getBlogPage(int page) async {
    final Function? httpGetFunc = <PostType, Function?>{
      PostType.Placement: bloc.client.getPlacementBlogFeed,
      PostType.External: bloc.client.getExternalBlogFeed,
      PostType.Training: bloc.client.getTrainingBlogFeed,
      PostType.NewsArticle: bloc.client.getNews,
      PostType.Query: bloc.client.getQueries,
      PostType.ChatBot: bloc.clientChatBot.getAnswers,
    }[postType];
    List<Post> posts;
    if (bloc.currSession?.user != 'demouser') {
      if (postType == PostType.Query) {
        posts = await httpGetFunc!(bloc.getSessionIdHeader(), query, category)
            as List<Query>;
      } else if (postType == PostType.ChatBot) {
        if (query.isEmpty) {
          posts = List<ChatBot>.generate(
              1,
              (int index) => ChatBot(
                  '0', '0', null, 'ChatBot', 'Ask your queries here!', null,
                  body: 'Ask your queries here!'));
        } else {
          ChatBotResponse res = await httpGetFunc!(query) as ChatBotResponse;
          posts = List<ChatBot>.generate(
              2,
              (int index) => ChatBot(
                  index.toString(),
                  '',
                  res.data?[2 * index + 1],
                  'Answer $index',
                  res.data?[2 * index],
                  null,
                  body: query));
        }
      } else {
        posts = await httpGetFunc!(bloc.getSessionIdHeader(),
            page * _noOfPostsPerPage, _noOfPostsPerPage, query) as List<Post>;
      }
    } else {
      posts = await _getDemoPosts(page, httpGetFunc);
    }
    const markdown.TableSyntax tableParse = markdown.TableSyntax();

    for (final Post p in posts) {
      if (postType == PostType.ChatBot) {
        p.content = markdown.markdownToHtml(
            p.content
                    ?.split('\n')
                    .map((String s) => s.trimRight())
                    .toList()
                    .join('\n') ??
                '',
            blockSyntaxes: [tableParse]);
      } else {
        p.content = markdown.markdownToHtml(
            p.content
                    ?.split('\n')
                    .map((String s) => s.trimRight())
                    .toList()
                    .join('\n') ??
                '',
            blockSyntaxes: [tableParse]);
      }
      if (postType != PostType.Query && postType != PostType.ChatBot) {
        p.published = dateTimeFormatter(p.published ?? '');
      }
    }
    return posts;
  }

  Future<List<Post>> _getDemoPosts(int page, Function? httpGetFunc) async {
    List<Post> posts = [];
    switch (postType) {
      case PostType.Placement:
        posts = placementPosts();
        break;
      case PostType.Training:
        posts = trainingPosts();
        break;
      case PostType.NewsArticle:
        posts = await httpGetFunc!(
            bloc.getSessionIdHeader(),
            page * _noOfPostsPerPage,
            _noOfPostsPerPage,
            query) as List<NewsArticle>;
        break;
      case PostType.External:
        posts = externalBlogPosts();
        break;
      case PostType.Query:
        posts = queryPosts();
        break;
      case PostType.ChatBot:
        posts = queryPosts();
        break;
    }
    return posts;
  }

  Future<void> setCategories() async {
    List<String?> listCategories;
    listCategories =
        await bloc.client.getQueryCategories(bloc.getSessionIdHeader());

    List<Map<String, String>> categories = [];
    for (final String? val in listCategories) {
      if (val != null) {
        categories.add({'value': val, 'name': val});
      }
    }
    _blogSubject1.add(UnmodifiableListView<Map<String, String>>(categories));
  }

  void _handleIndexes(List<int> indexes) {
    final Map<int, List<Post>> pages =
        (query.isEmpty && category.isEmpty) ? _fetchPages : _searchFetchPages;
    final Set<int> pagesBeingFetched = (query.isEmpty && category.isEmpty)
        ? _pagesBeingFetched
        : _searchPagesBeingFetched;
    for (final int index in indexes) {
      final int pageIndex = (index + 1) ~/ _noOfPostsPerPage;

      // check if the page has already been fetched
      if (!pages.containsKey(pageIndex)) {
        // the page has NOT yet been fetched, so we need to
        // fetch it from Internet
        // (except if we are already currently fetching it)
        if (!pagesBeingFetched.contains(pageIndex)) {
          // Remember that we are fetching it
          pagesBeingFetched.add(pageIndex);
          // Fetch it
          getBlogPage(pageIndex).then((List<Post> fetchedPage) =>
              _handleFetchedPage(fetchedPage, pageIndex));
        }
      }
    }
  }

  ///
  /// Once a page has been fetched from Internet, we need to
  /// 1) record it
  /// 2) notify everyone who might be interested in knowing it
  ///
  void _handleFetchedPage(List<Post> page, int pageIndex) {
    Map<int, List<Post>> pages =
        (query.isEmpty && category.isEmpty) ? _fetchPages : _searchFetchPages;
    final Set<int> pagesBeingFetched = (query.isEmpty && category.isEmpty)
        ? _pagesBeingFetched
        : _searchPagesBeingFetched;

    // Remember the page
    pages[pageIndex] = page;
    // Remove it from the ones being fetched
    pagesBeingFetched.remove(pageIndex);

    // Notify anyone interested in getting access to the content
    // of all pages... however, we need to only return the pages
    // which respect the sequence (since MovieCard are in sequence)
    // therefore, we need to iterate through the pages that are
    // actually fetched and stop if there is a gap.
    List<Post> posts = <Post>[];
    List<int> pageIndexes = pages.keys.toList();

    final int minPageIndex = pageIndexes.reduce(min);
    final int maxPageIndex = pageIndexes.reduce(max);

    // If the first page being fetched does not correspond to the first one, skip
    // and as soon as it will become available, it will be time to notify
    if (minPageIndex == 0) {
      for (int i = 0; i <= maxPageIndex; i++) {
        if (!pages.containsKey(i)) {
          // As soon as there is a hole, stop
          break;
        }
        // Add the list of fetched posts to the list
        List<Post>? temp = pages[i];
        if (temp != null) {
          posts.addAll(temp);
        }
      }
    }

    if (pages[maxPageIndex]!.length < _noOfPostsPerPage) {
      posts.add(Post());
    }

    // Only notify when there are posts
    if (posts.isNotEmpty) {
      _blogSubject.add(UnmodifiableListView<Post>(posts));
    }
  }

  Future refresh({bool force = false}) async {
    await _indexController.close();

    _searchFetchPages.clear();
    _searchPagesBeingFetched.clear();

    List<Post> posts = <Post>[];
    if (force) {
      _fetchPages.clear();
      _pagesBeingFetched.clear();
    } else if (_fetchPages.isNotEmpty && (query.isEmpty && category.isEmpty)) {
      List<int> pageIndexes = _fetchPages.keys.toList();

      final int minPageIndex = pageIndexes.reduce(min);
      final int maxPageIndex = pageIndexes.reduce(max);

      if (minPageIndex == 0) {
        for (int i = 0; i <= maxPageIndex; i++) {
          if (!_fetchPages.containsKey(i)) {
            // As soon as there is a hole, stop
            break;
          }
          posts.addAll(_fetchPages[i]!);
        }
      }
      if (postType == PostType.Query) {
        posts.add(Post());
      }
    }

    _blogSubject.add(UnmodifiableListView(posts));

    _indexController = PublishSubject<int>();
    _setIndexListener();
  }

  Future updateUserReaction(NewsArticle article, int reaction) async {
    String sel = '$reaction';
    int sendReaction = article.userReaction == reaction ? -1 : reaction;
    await bloc.client.updateUserNewsReaction(
        bloc.getSessionIdHeader(), article.id!, sendReaction);
    if (article.userReaction == -1) {
      article.userReaction = sendReaction;
      int? x = article.reactionCount![sel];
      if (x != null) {
        x += 1;
        article.reactionCount![sel] = x;
      }
    } else if (article.userReaction != reaction) {
      int? x = article.reactionCount!['${article.userReaction}'];
      int? y = article.reactionCount![sel];
      if (x != null && y != null) {
        x -= 1;
        y += 1;
        article.reactionCount!['${article.userReaction}'] = x;
        article.userReaction = sendReaction;
        article.reactionCount![sel] = y;
      }
    } else {
      article.userReaction = -1;
      int? x = article.reactionCount![sel];
      if (x != null) {
        x -= 1;
        article.reactionCount![sel] = x;
      }
    }
    return Future.delayed(const Duration(milliseconds: 0));
  }

  Future updateUserReactionChatBot(ChatBot article, int reaction) async {
    // int sendReaction = article.userReaction == reaction ? -1 : reaction;
    await bloc.client.updateUserChatBotReaction(bloc.getSessionIdHeader(),
        ChatBotLogRequest(article.body!, article.content!, reaction));
    return Future.delayed(const Duration(milliseconds: 0));
  }

  void setState(Null Function() param0) {}
}
