import 'package:flutter/material.dart';

/// Global navigator key passed to [MaterialApp.navigatorKey].
/// Lets non-widget code (providers, background handlers) push routes.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
