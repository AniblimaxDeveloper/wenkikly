import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  // Tier: 'free', 'go', 'plus', 'pro', 'max'
  
  Future<String> getCurrentTier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_tier') ?? 'free';
  }

  Future<void> setTier(String tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_tier', tier);
  }

  Future<bool> isPremium() async {
    final tier = await getCurrentTier();
    return tier != 'free';
  }

  // Simulasi Pembayaran Berhasil (Di aplikasi nyata, ini dipanggil setelah validasi Stripe/Google Play)
  Future<bool> processPayment(String tier, String paymentMethod) async {
    // Simulasi delay jaringan
    await Future.delayed(const Duration(seconds: 2));
    
    // Di sini logikanya: jika pembayaran sukses, set tier
    await setTier(tier);
    return true;
  }
}
