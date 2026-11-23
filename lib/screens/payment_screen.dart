import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/subscription_service.dart';

class PaymentScreen extends StatefulWidget {
  final VoidCallback onPaymentSuccess;
  const PaymentScreen({super.key, required this.onPaymentSuccess});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final SubscriptionService _subService = SubscriptionService();
  String _selectedTier = 'go';
  String _selectedPayment = 'Stripe';
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _tiers = [
    {'id': 'go', 'name': 'GO', 'price': 'Rp 29.000', 'color': Colors.blueAccent, 'benefits': ['Unlimited Token', 'Akses Model Go', 'Bebas Iklan']},
    {'id': 'plus', 'name': 'PLUS', 'price': 'Rp 59.000', 'color': Colors.greenAccent, 'benefits': ['Semua Fitur Go', 'Akses Model Plus', 'Kustom Persona', 'History Panjang']},
    {'id': 'pro', 'name': 'PRO', 'price': 'Rp 129.000', 'color': Colors.orangeAccent, 'benefits': ['Semua Fitur Plus', 'Akses Model Pro', 'AI Vision (Image)', 'Kustom API Key']},
    {'id': 'max', 'name': 'MAX', 'price': 'Rp 299.000', 'color': Colors.redAccent, 'benefits': ['Semua Fitur Pro', 'Akses Model Ultra', 'Pemrosesan Prioritas', 'Custom System Prompt']},
  ];

  void _processPayment() async {
    setState(() => _isProcessing = true);
    bool success = await _subService.processPayment(_selectedTier, _selectedPayment);
    setState(() => _isProcessing = false);
    
    if (success && mounted) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text('Pembayaran Berhasil', style: TextStyle(color: Colors.greenAccent)),
          content: Text('Selamat! Anda sekarang berlangganan paket ${_selectedTier.toUpperCase()}.', style: const TextStyle(color: Colors.white)),
          actions: [TextButton(onPressed: () { Navigator.pop(c); widget.onPaymentSuccess(); }, child: const Text('Mulai Gunakan'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Upgrade Premium', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Pilih Paket Langganan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                ..._tiers.map((tier) {
                  bool isSelected = _selectedTier == tier['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTier = tier['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? tier['color'].withOpacity(0.15) : Colors.white.withOpacity(0.05),
                        border: Border.all(color: isSelected ? tier['color'] : Colors.white12, width: 2),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected ? [BoxShadow(color: tier['color'].withOpacity(0.3), blurRadius: 10, spreadRadius: 2)] : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Wenkikly ${tier['name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: isSelected ? tier['color'] : Colors.white)),
                              Text(tier['price'], style: TextStyle(fontWeight: FontWeight.bold, color: tier['color'])),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...(tier['benefits'] as List<String>).map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(children: [Icon(Icons.check_circle, size: 14, color: tier['color']), const SizedBox(width: 8), Text(b, style: const TextStyle(fontSize: 12, color: Colors.white70))]),
                          )),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                const Text('Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPayment,
                  dropdownColor: const Color(0xFF1E1E2C),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(filled: true, fillColor: Colors.white12, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: const [
                    DropdownMenuItem(value: 'Stripe', child: Text('Stripe (Kartu Kredit)')),
                    DropdownMenuItem(value: 'PayPal', child: Text('PayPal')),
                    DropdownMenuItem(value: 'QRIS', child: Text('QRIS (Indonesia)')),
                    DropdownMenuItem(value: 'GooglePlay', child: Text('Google Play Billing')),
                  ],
                  onChanged: (v) => setState(() => _selectedPayment = v!),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('BAYAR SEKARANG', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
