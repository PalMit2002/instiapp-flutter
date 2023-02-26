import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:rxdart/rxdart.dart';

import '../api/model/venue.dart';
import '../bloc_provider.dart';
import '../blocs/ia_bloc.dart';
import '../blocs/map_bloc.dart';
import '../drawer.dart';
import '../utils/common_widgets.dart';

class NativeMapPage extends StatefulWidget {
  const NativeMapPage({Key? key}) : super(key: key);

  @override
  _NativeMapPageState createState() => _NativeMapPageState();
}

class _NativeMapPageState extends State<NativeMapPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  PhotoViewControllerBase<PhotoViewControllerValue> controller =
      PhotoViewController();

  StreamSubscription<List<PhotoViewControllerValue>>? scaleSubscription;

  bool firstBuild = true;

  double markerScale = 0.069;

  @override
  void initState() {
    super.initState();
    scaleSubscription = controller.outputStateStream
        .bufferTime(const Duration(milliseconds: 800))
        .listen((List<PhotoViewControllerValue> values) {
      if (values.isNotEmpty) {
        // print(values.last.scale);
        if (mounted) {
          setState(() {
            markerScale = values.last.scale ?? 0.069;
          });
        } else {
          markerScale = values.last.scale ?? 0.069;
        }
      }
      // print("Called");
    });
  }

  @override
  void dispose() {
    scaleSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    InstiAppBloc bloc = BlocProvider.of(context)!.bloc;
    ThemeData theme = Theme.of(context);
    MapBloc mapBloc = bloc.mapBloc;

    if (firstBuild) {
      mapBloc.updateLocations();
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const NavDrawer(),
      bottomNavigationBar: MyBottomAppBar(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.menu_outlined,
                semanticLabel: 'Show bottom sheet',
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: PhotoView.customChild(
          childSize: const Size(5430, 3575),
          backgroundDecoration: BoxDecoration(color: bloc.brightness.toColor()),
          minScale: PhotoViewComputedScale.contained,
          controller: controller,
          child: Container(
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/map/assets/map.webp'))),
            child: StreamBuilder(
              stream: mapBloc.locations,
              builder: (BuildContext context,
                  AsyncSnapshot<UnmodifiableListView<Venue>> snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Stack(
                    children: snapshot.data!
                        .map((Venue v) => _buildMarker(bloc, theme, v))
                        .toList(),
                  );
                } else {
                  return Container();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarker(InstiAppBloc bloc, ThemeData theme, Venue v) {
    return Positioned(
        left: v.venuePixelX?.toDouble(),
        top: v.venuePixelY?.toDouble(),
        child: Column(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: theme.canvasColor,
              ),
              child: Text(
                v.venueName ?? '',
                style: theme.textTheme.headlineMedium,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: theme.canvasColor,
              ),
              child: IconButton(
                iconSize: 96,
                onPressed: () {
                  // print(v.venueName);
                },
                icon: const Icon(
                  Icons.location_on_outlined,
                  size: 96,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ));
  }
}
