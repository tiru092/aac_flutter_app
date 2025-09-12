// Simple test version
class DataServicesInitializer {
  /// Initialize all data services with Firebase UID as single source of truth
  Future<void> initialize() async {
    print('DataServicesInitializer: initialize called');
  }

  /// Log status of all services for debugging
  void logServiceStatus() {
    print('DataServicesInitializer: logServiceStatus called');
  }
}
