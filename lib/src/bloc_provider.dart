import 'package:flutter/material.dart';
import 'blocs/ia_bloc.dart';

class BlocProvider extends InheritedWidget {
  final InstiAppBloc bloc;

  const BlocProvider(this.bloc, {required Widget child, Key? key})
      : super(child: child, key: key);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }

  static BlocProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BlocProvider>();
  }
}
