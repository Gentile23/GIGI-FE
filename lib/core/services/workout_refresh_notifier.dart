import 'package:flutter/foundation.dart';

class WorkoutRefreshNotifier extends ChangeNotifier {
  int _version = 0;

  int get version => _version;

  void notifyWorkoutCompleted() {
    _version++;
    debugPrint('WorkoutRefreshNotifier: workout completed, version=$_version');
    notifyListeners();
  }
}
