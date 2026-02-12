import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AdaptiveScaffold extends StatelessWidget {
  final String title;
  final List<Widget> slivers;
  final Widget? body; // Optional: If provided, wraps in SliverToBoxAdapter
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.title,
    this.slivers = const [],
    this.body,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
  });

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final theme = Theme.of(context);

    // Combine custom slivers with body if provided
    final allSlivers = [
      if (isIos)
        CupertinoSliverNavigationBar(
          largeTitle: Text(title),
          backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.85),
          border: null, // Clean look without bottom border
          trailing: actions != null && actions!.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                )
              : null,
        )
      else
        SliverAppBar.medium(
          title: Text(title),
          centerTitle: false,
          actions: actions,
          floating: true,
          snap: true,
          surfaceTintColor: Colors.transparent,
          backgroundColor: theme.scaffoldBackgroundColor,
        ),
        
      ...slivers,
      
      if (body != null)
        SliverToBoxAdapter(child: body ?? const SizedBox.shrink()),
        
      // Add padding at bottom for scrolling past FAB
      const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
    ];

    if (isIos) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: allSlivers,
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(), // Nice feel on Android too
          slivers: allSlivers,
        ),
        floatingActionButton: floatingActionButton,
      );
    }
  }
}
