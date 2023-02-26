import 'package:flutter/material.dart';

import '../bloc_provider.dart';
import '../blocs/ia_bloc.dart';

class TitleWithBackButton extends StatefulWidget {
  final Widget child;
  final bool hasBackButton;
  final EdgeInsets contentPadding;

  const TitleWithBackButton(
      {Key? key, required this.child,
      this.hasBackButton = true,
      this.contentPadding = const EdgeInsets.all(28.0)}) : super(key: key);

  @override
  _TitleWithBackButtonState createState() => _TitleWithBackButtonState();
}

class _TitleWithBackButtonState extends State<TitleWithBackButton> {
  @override
  Widget build(BuildContext context) {
    InstiAppBloc? bloc = BlocProvider.of(context)?.bloc;
    ThemeData theme = Theme.of(context);

    return StreamBuilder(
      stream: bloc?.navigatorObserver.secondTopRouteName,
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        bool currHasBackButton = (theme.platform == TargetPlatform.iOS ||
                theme.platform == TargetPlatform.macOS) &&
            widget.hasBackButton &&
            snapshot.data != null &&
            Navigator.of(context).canPop();
        return Stack(
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: widget.contentPadding
                  .add(EdgeInsets.only(top: currHasBackButton ? 8 : 0)),
              child: widget.child,
            ),
            if (currHasBackButton) InkWell(
                    borderRadius: BorderRadius.circular(6.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const BackButtonIcon(),
                        Text('${snapshot.data}'),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).maybePop();
                    },
                  ) else const SizedBox(
                    height: 0,
                    width: 0,
                  ),
          ],
        );
      },
    );
  }
}
