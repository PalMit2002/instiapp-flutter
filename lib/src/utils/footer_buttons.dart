import 'package:flutter/material.dart';

class FooterButtons extends StatelessWidget {
  final List<Widget> footerButtons;
  const FooterButtons({Key? key, required this.footerButtons})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: footerButtons.map((Widget e) {
          return Container(
            margin: const EdgeInsets.only(right: 10),
            child: e,
          );
        }).toList(),
      ),
    );
  }
}
