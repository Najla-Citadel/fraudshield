import 'package:flutter/material.dart';
import '../tokens/design_tokens.dart';
import '../components/app_back_button.dart';

class ScreenScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final bool centerTitle;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;
  final List<Color>? backgroundColors;
  final bool useSafeArea;
  final bool extendBodyBehindAppBar;

  const ScreenScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showBackButton = true,
    this.centerTitle = true,
    this.appBar,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColors,
    this.useSafeArea = true,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;
    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundColors ?? DesignTokens.colors.mainGradient,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: appBar ?? (title != null ? AppBar(
          title: Text(
            title!,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: centerTitle,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: showBackButton ? const AppBackButton() : null,
          actions: actions,
        ) : null),
        body: content,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
