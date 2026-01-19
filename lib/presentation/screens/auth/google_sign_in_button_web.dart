import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:google_sign_in_web/google_sign_in_web.dart';

Widget getGoogleSignInButton() {
  final plugin = GoogleSignInPlatform.instance;
  if (plugin is GoogleSignInPlugin) {
    return plugin.renderButton(
      configuration: GSIButtonConfiguration(
        theme: GSIButtonTheme.filledBlack,
        shape: GSIButtonShape.pill,
        size: GSIButtonSize.large,
      ),
    );
  }
  return const SizedBox.shrink();
}
