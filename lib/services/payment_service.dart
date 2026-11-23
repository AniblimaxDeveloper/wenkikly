import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  Future<String> getCurrentTier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_tier') ?? 'free';
  }

  Future<void> setTier(String tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_tier', tier);
  }

  // PROSES PEMBAYARAN ASLI (Stripe Connect / Google Play Billing)
  Future<bool> processRealPayment(String tier, String paymentMethod) async {
    // Di sini lu harus naruh backend URL lu buat nembak API Stripe
    // Contoh: await http.post(Uri.parse('https://api.wenkikly.com/create-payment-intent'), body: {'tier': tier, 'amount': getPrice(tier)});
    
    await Future.delayed(const Duration(seconds: 2)); // Simulasi loading Stripe SDK
    
    // Jika pembayaran sukses di backend, set tier
    await setTier(tier);
    return true;
  }

  // LOGIKA PENDAPATAN DEVELOPER (Payout)
  Future<double> getDeveloperRevenue() async {
    // Ini fungsi backend buat narik dana ke rekening bank lu
    // Mock: Anggap ada 100 user yang beli paket Pro
    return 129000.0 * 100; 
  }
}
