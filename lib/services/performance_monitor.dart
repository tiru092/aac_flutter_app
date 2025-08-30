import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class PerformanceMonitor {
  static final FirebasePerformance _performance = FirebasePerformance.instance;
  
  // Screen transition monitoring
  static Trace? _screenTrace;
  
  static Future<void> startScreenTrace(String screenName) async {
    try {
      _screenTrace = _performance.newTrace('screen_$screenName');
      await _screenTrace?.start();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, null);
    }
  }
  
  static Future<void> stopScreenTrace() async {
    try {
      await _screenTrace?.stop();
      _screenTrace = null;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, null);
    }
  }
  
  // Custom performance metrics
  static Future<void> recordCustomMetric(String name, int value) async {
    try {
      final trace = _performance.newTrace('custom_$name');
      await trace.start();
      trace.setMetric(name, value);
      await trace.stop();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, null);
    }
  }
  
  // HTTP request monitoring
  static HttpMetric createHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }
  
  // Symbol loading performance
  static Future<void> trackSymbolLoadTime(int symbolCount, int loadTimeMs) async {
    try {
      final trace = _performance.newTrace('symbol_load');
      await trace.start();
      trace.setMetric('symbol_count', symbolCount);
      trace.setMetric('load_time_ms', loadTimeMs);
      await trace.stop();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, null);
    }
  }
  
  // TTS performance tracking
  static Future<void> trackTTSPerformance(String text, int speakTimeMs) async {
    try {
      final trace = _performance.newTrace('tts_performance');
      await trace.start();
      trace.setMetric('text_length', text.length);
      trace.setMetric('speak_time_ms', speakTimeMs);
      await trace.stop();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, null);
    }
  }
  
  // App startup performance
  static Future<void> trackAppStartup(int startupTimeMs) async {
    try {
      final trace = _performance.newTrace('app_startup');
      await trace.start();
      trace.setMetric('startup_time_ms', startupTimeMs);
      await trace.stop();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, null);
    }
  }
}
