import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Screen Views
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Task Events
  Future<void> logTaskViewed({
    required String taskId,
    required String slot,
  }) async {
    await _analytics.logEvent(
      name: 'task_viewed',
      parameters: {'task_id': taskId, 'slot': slot},
    );
  }

  Future<void> logTaskCompleted({
    required String taskId,
    required String slot,
    required String nickname,
  }) async {
    await _analytics.logEvent(
      name: 'task_completed',
      parameters: {'task_id': taskId, 'slot': slot, 'nickname': nickname},
    );
  }

  // Idea Events
  Future<void> logIdeaSubmitted({
    required String nickname,
    required String location,
  }) async {
    await _analytics.logEvent(
      name: 'idea_submitted',
      parameters: {'nickname': nickname, 'location': location},
    );
  }

  // Support Events
  Future<void> logSupportModalOpened() async {
    await _analytics.logEvent(name: 'support_modal_opened');
  }

  Future<void> logPurchaseAttempt(String productId) async {
    await _analytics.logEvent(
      name: 'purchase_attempt',
      parameters: {'product_id': productId},
    );
  }

  Future<void> logPurchaseSuccess(String productId) async {
    await _analytics.logEvent(
      name: 'purchase_success',
      parameters: {'product_id': productId},
    );
  }

  Future<void> logPurchaseFailed(String productId) async {
    await _analytics.logEvent(
      name: 'purchase_failed',
      parameters: {'product_id': productId},
    );
  }

  // User Properties
  Future<void> setUserNickname(String nickname) async {
    await _analytics.setUserId(id: nickname);
  }

  Future<void> setUserLocation(String location) async {
    await _analytics.setUserProperty(name: 'location', value: location);
  }

  // App Events
  Future<void> logAppOpened() async {
    await _analytics.logAppOpen();
  }

  Future<void> logOnboardingCompleted() async {
    await _analytics.logEvent(name: 'onboarding_completed');
  }
}
