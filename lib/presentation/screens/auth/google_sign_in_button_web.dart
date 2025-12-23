import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

Widget getGoogleSignInButton() {
  final plugin = GoogleSignInPlatform.instance;
  if (plugin is GoogleSignInPlugin) {
    return plugin.renderButton();
  }
  return const SizedBox.shrink();
}
