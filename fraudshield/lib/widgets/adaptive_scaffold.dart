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


    if (isIos) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(title, style: TextStyle(color: (backgroundColor != null && backgroundColor!.computeLuminance() < 0.5) ? Colors.white : theme.textTheme.titleLarge?.color)),
              backgroundColor: (backgroundColor ?? theme.scaffoldBackgroundColor).withOpacity(0.85),
              border: null,
              trailing: actions != null && actions!.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    )
                  : null,
            ),
            ...slivers,
             if (body != null)
              SliverToBoxAdapter(child: body ?? const SizedBox.shrink()),
             const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar.medium(
              title: Text(
                title,
                style: TextStyle(
                  color: (backgroundColor != null && backgroundColor!.computeLuminance() < 0.5) 
                      ? Colors.white 
                      : theme.textTheme.titleLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              actions: actions,
              floating: true,
              snap: true,
              surfaceTintColor: Colors.transparent,
              backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
              iconTheme: IconThemeData(
                color: (backgroundColor != null && backgroundColor!.computeLuminance() < 0.5) 
                    ? Colors.white 
                    : theme.iconTheme.color,
              ),
            ),
            ...slivers,
            if (body != null)
              SliverToBoxAdapter(child: body ?? const SizedBox.shrink()),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }
  }
}
