import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final EdgeInsets? padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.contentMaxWidth(context),
        ),
        child: Padding(
          padding: padding ?? Responsive.pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}
