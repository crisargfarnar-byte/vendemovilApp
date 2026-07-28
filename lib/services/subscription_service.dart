import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum PlanType { trial, local, nube }

class SubscriptionService {
  static const String _keyStartDate = 'app_start_date';
  static const String _keyPlanType = 'app_plan_type';
  static const int _trialDays = 14;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyStartDate)) {
      await prefs.setString(_keyStartDate, DateTime.now().toIso8601String());
    }
    if (!prefs.containsKey(_keyPlanType)) {
      await prefs.setString(_keyPlanType, PlanType.trial.name);
    }
  }

  static Future<DateTime> getStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_keyStartDate);
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return DateTime.now();
  }

  static Future<PlanType> getCurrentPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final planStr = prefs.getString(_keyPlanType) ?? PlanType.trial.name;
    return PlanType.values.firstWhere((e) => e.name == planStr, orElse: () => PlanType.trial);
  }

  static Future<void> setPlan(PlanType plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlanType, plan.name);
  }

  static Future<int> getRemainingTrialDays() async {
    final startDate = await getStartDate();
    final now = DateTime.now();
    final difference = now.difference(startDate).inDays;
    final remaining = _trialDays - difference;
    return remaining < 0 ? 0 : remaining;
  }

  static Future<bool> hasValidAccess() async {
    final currentPlan = await getCurrentPlan();
    if (currentPlan == PlanType.local || currentPlan == PlanType.nube) {
      return true; // Active subscription
    }
    // Trial plan check
    final remainingDays = await getRemainingTrialDays();
    return remainingDays > 0;
  }

  static Future<void> openWhatsApp(String name, String email, PlanType requestedPlan) async {
    final planName = requestedPlan == PlanType.local ? 'Plan Local Anual' : 'Plan Nube Mensual';
    final message = 'Hola, deseo activar mi cuenta en Vende Móvil.\\nNombre: $name\\nCorreo: $email\\nPlan: $planName';
    final url = Uri.parse('https://wa.me/51973282798?text=${Uri.encodeComponent(message)}');
    
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Could not launch WhatsApp: $e');
    }
  }
}
