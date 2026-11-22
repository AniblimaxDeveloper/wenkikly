import 'package:flutter/material.dart';
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
    {'id': 'go', 'name': 'GO', 'price': 'Rp 29.000', 'benefits': ['Unlimited Token', 'Akses Model Go 1.0-3.0', 'Bebas Iklan']},
    {'id': 'plus', 'name': 'PLUS', 'price': 'Rp 59.000', 'benefits': ['Semua Fitur Go', 'Akses Model Plus 1.0-4.0', 'Kustom Persona', 'History Panjang']},
    {'id': 'pro', 'name': 'PRO', 'price': 'Rp 129.000', 'benefits': ['Semua Fitur Plus', 'Akses Model Pro 1.0-4.0', 'AI Vision (Image)', 'Kustom API Key']},
    {'id': 'max', 'name': 'MAX', 'price': 'Rp 299.000', 'benefits': ['Semua Fitur Pro', 'Akses Model Ultra 1.0-4.0', 'Pemrosesan Prioritas', 'Custom System Prompt']},
  ];

  void _processPayment() async {
    setState(() => _isProcessing = true);
    bool success = await _subService.processPayment(_selectedTier, _selectedPayment);
    setState(() => _isProcessing = false);
    
    if (success) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Pembayaran Berhasil'),
            content: Text('Selamat! Anda sekarang berlangganan paket ${_selectedTier.toUpperCase()}.'),
            actions: [TextButton(onPressed: () { Navigator.pop(c); widget.onPaymentSuccess(); }, child: const Text('Mulai Gunakan'))],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade ke Premium')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Pilih Paket Langganan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ..._tiers.map((tier) => Card(
                  color: _selectedTier == tier['id'] ? Colors.deepPurple.withOpacity(0.3) : null,
                  child: ListTile(
                    title: Text('Wenkikly ${tier['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (tier['benefits'] as List<String>).map((b) => Text('• $b', style: const TextStyle(fontSize: 12))).toList(),
                    ),
                    trailing: Text(tier['price'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    onTap: () => setState(() => _selectedTier = tier['id']),
                  ),
                )),
                const SizedBox(height: 24),
                const Text('Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPayment,
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('BAYAR SEKARANG', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
