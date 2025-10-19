import 'package:flutter/widgets.dart';
import 'loading_overlay.dart';

class LoaderNavigatorObserver extends NavigatorObserver {
  void _hideIfShowing() {
    if (LoadingOverlay.isShowing) {
      LoadingOverlay.hide();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _hideIfShowing();
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _hideIfShowing();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
