import 'package:flutter/material.dart';

class AIModel {
  final String id;
  final String name;
  final String tier;
  final String description;
  final bool isUnlimited;
  final int maxTokens;
  final IconData icon;

  AIModel({
    required this.id,
    required this.name,
    required this.tier,
    required this.description,
    required this.isUnlimited,
    required this.maxTokens,
    required this.icon,
  });
}

// Daftar 25 Model WHEN
final List<AIModel> wenkiklyModels = [
  // --- FREE TIER ---
  AIModel(id: 'when-1.0', name: 'WHEN 1.0', tier: 'Free', description: 'Model dasar untuk obrolan santai. Cepat & ringan.', isUnlimited: false, maxTokens: 2000, icon: Icons.speed),
  AIModel(id: 'when-1.5', name: 'WHEN 1.5', tier: 'Free', description: 'Peningkatan akurasi untuk tanya jawab umum.', isUnlimited: false, maxTokens: 3000, icon: Icons.question_answer),
  AIModel(id: 'when-2.0', name: 'WHEN 2.0', tier: 'Free', description: 'Mampu menulis paragraf pendek dan merangkum teks.', isUnlimited: false, maxTokens: 4000, icon: Icons.short_text),
  AIModel(id: 'when-2.5', name: 'WHEN 2.5', tier: 'Free', description: 'Spesialis tugas dasar matematika dan terjemahan.', isUnlimited: false, maxTokens: 4000, icon: Icons.calculate),
  AIModel(id: 'when-3.0', name: 'WHEN 3.0', tier: 'Free', description: 'Paham konteks percakapan yang lebih panjang.', isUnlimited: false, maxTokens: 5000, icon: Icons.forum),
  AIModel(id: 'when-3.5', name: 'WHEN 3.5', tier: 'Free', description: 'Model gratis tercanggih. Cocok untuk belajar.', isUnlimited: false, maxTokens: 6000, icon: Icons.school),

  // --- GO TIER ---
  AIModel(id: 'when-go-1.0', name: 'WHEN Go 1.0', tier: 'Go', description: 'Asisten harian tanpa batas token. Cepat & responsif.', isUnlimited: true, maxTokens: 999999, icon: Icons.directions_run),
  AIModel(id: 'when-go-1.5', name: 'WHEN Go 1.5', tier: 'Go', description: 'Peningkatan logika untuk tugas perkantoran ringan.', isUnlimited: true, maxTokens: 999999, icon: Icons.work),
  AIModel(id: 'when-go-2.0', name: 'WHEN Go 2.0', tier: 'Go', description: 'Mampu membuat email profesional dan esai pendek.', isUnlimited: true, maxTokens: 999999, icon: Icons.email),
  AIModel(id: 'when-go-3.0', name: 'WHEN Go 3.0', tier: 'Go', description: 'Model Go terbaik untuk brainstorming ide.', isUnlimited: true, maxTokens: 999999, icon: Icons.lightbulb),

  // --- PLUS TIER ---
  AIModel(id: 'when-plus-1.0', name: 'WHEN Plus 1.0', tier: 'Plus', description: 'Penalaran kritis mendalam untuk pemecahan masalah.', isUnlimited: true, maxTokens: 999999, icon: Icons.psychology),
  AIModel(id: 'when-plus-2.0', name: 'WHEN Plus 2.0', tier: 'Plus', description: 'Spesialis penulisan kreatif (cerita, puisi, script).', isUnlimited: true, maxTokens: 999999, icon: Icons.create),
  AIModel(id: 'when-plus-3.0', name: 'WHEN Plus 3.0', tier: 'Plus', description: 'Analisis teks kompleks dan pembuatan laporan.', isUnlimited: true, maxTokens: 999999, icon: Icons.analytics),
  AIModel(id: 'when-plus-4.0', name: 'WHEN Plus 4.0', tier: 'Plus', description: 'Model Plus tercerdas. Pemahaman konteks luar biasa.', isUnlimited: true, maxTokens: 999999, icon: Icons.auto_awesome),

  // --- PRO TIER ---
  AIModel(id: 'when-pro-1.0', name: 'WHEN Pro 1.0', tier: 'Pro', description: 'Spesialis pemrograman (Python, Dart, JS, dll).', isUnlimited: true, maxTokens: 999999, icon: Icons.code),
  AIModel(id: 'when-pro-2.0', name: 'WHEN Pro 2.0', tier: 'Pro', description: 'Debugging kode tingkat lanjut dan arsitektur software.', isUnlimited: true, maxTokens: 999999, icon: Icons.bug_report),
  AIModel(id: 'when-pro-3.0', name: 'WHEN Pro 3.0', tier: 'Pro', description: 'Penalaran matematika dan logika algoritma kompleks.', isUnlimited: true, maxTokens: 999999, icon: Icons.functions),
  AIModel(id: 'when-pro-4.0', name: 'WHEN Pro 4.0', tier: 'Pro', description: 'Model Pro terkuat. Mampu menulis framework dari nol.', isUnlimited: true, maxTokens: 999999, icon: Icons.terminal),

  // --- BUSINESS TIER ---
  AIModel(id: 'when-biz-1.0', name: 'WHEN Business 1.0', tier: 'Business', description: 'Analisis data bisnis, SWOT, dan strategi pasar.', isUnlimited: true, maxTokens: 999999, icon: Icons.business_center),
  AIModel(id: 'when-biz-2.0', name: 'WHEN Business 2.0', tier: 'Business', description: 'Pembuatan dokumen legal, kontrak, dan NDA.', isUnlimited: true, maxTokens: 999999, icon: Icons.gavel),
  AIModel(id: 'when-biz-3.0', name: 'WHEN Business 3.0', tier: 'Business', description: 'Asisten keuangan, analisis saham, dan akuntansi.', isUnlimited: true, maxTokens: 999999, icon: Icons.trending_up),

  // --- ULTRA TIER ---
  AIModel(id: 'when-ultra-1.0', name: 'WHEN Ultra 1.0', tier: 'Ultra', description: 'Model All-Rounder. Bisa melakukan apa saja tanpa batas.', isUnlimited: true, maxTokens: 999999, icon: Icons.diamond),
  AIModel(id: 'when-ultra-2.0', name: 'WHEN Ultra 2.0', tier: 'Ultra', description: 'Kecepatan maksimal dengan akurasi tingkat dewa.', isUnlimited: true, maxTokens: 999999, icon: Icons.flash_on),
  AIModel(id: 'when-ultra-3.0', name: 'WHEN Ultra 3.0', tier: 'Ultra', description: 'Mampu memproses input teks sepanjang novel dalam 1x chat.', isUnlimited: true, maxTokens: 999999, icon: Icons.menu_book),
  AIModel(id: 'when-ultra-4.0', name: 'WHEN Ultra 4.0', tier: 'Ultra', description: 'Tingkat kecerdasan tertinggi. Jawaban sangat mendalam & kritis.', isUnlimited: true, maxTokens: 999999, icon: Icons.workspace_premium),
];
