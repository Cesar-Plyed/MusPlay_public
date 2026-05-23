import 'package:flutter/foundation.dart';
import '../../models/subscription_plan.dart';
import '../../services/firestore_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  String? _userId;
  String? get userId => _userId;

  String _currentPlanId = 'free';
  SubscriptionPlan? _currentPlan;
  List<SubscriptionPlan> _availablePlans = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _subscriptionEndDate;

  String get currentPlanId => _currentPlanId;
  SubscriptionPlan? get currentPlan => _currentPlan;
  List<SubscriptionPlan> get availablePlans => _availablePlans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get subscriptionEndDate => _subscriptionEndDate;

  bool get isPremium => _currentPlanId == 'premium';
  bool get isFree => _currentPlanId == 'free';
  bool get canUploadSongs => _currentPlan?.canUploadSongs ?? false;
  bool get canListenCloud => _currentPlan?.canListenCloud ?? false;
  // Compatibilidad con código antiguo
  bool get canDownloadOffline => _currentPlan?.canDownloadOffline ?? false;
  bool get canListenOffline => canListenCloud;
  int get maxSongs => _currentPlan?.maxSongs ?? 20;
  int get maxUploadSongs => _currentPlan?.maxUploadSongs ?? 20;
  int get maxDownloadSongs => _currentPlan?.maxDownloadSongs ?? 20;

  Future<void> initialize(String userId, String userPlan) async {
    _userId = userId;
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _availablePlans = SubscriptionPlan.getAllPlans();
      // Si el plan guardado es 'pro' (plan eliminado), bajar a free
      final planId = userPlan == 'pro' ? 'free' : userPlan;
      _currentPlanId = planId;
      _currentPlan = SubscriptionPlan.getPlanById(planId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePlan(String userId, String newPlanId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestoreService.updateUser(userId, {'plan': newPlanId});

      final plan = SubscriptionPlan.getPlanById(newPlanId);
      _currentPlanId = newPlanId;
      _currentPlan = plan;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  bool canPerformAction(String actionKey) {
    switch (actionKey) {
      case 'download_offline': return canDownloadOffline;
      case 'listen_cloud': return canListenCloud;
      case 'listen_offline': return canListenCloud;
      case 'upload_songs': return canUploadSongs;
      default: return false;
    }
  }

  SubscriptionPlan? getRecommendedPlan() {
    if (isFree) return SubscriptionPlan.getPlanById('premium');
    return null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _currentPlanId = 'free';
    _currentPlan = null;
    _availablePlans = [];
    _isLoading = false;
    _error = null;
    _subscriptionEndDate = null;
    notifyListeners();
  }
}
