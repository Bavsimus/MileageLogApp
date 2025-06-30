import '../models/database_helper.dart';

class AracModel {
  final int? id;
  final String plaka;
  final int guzergahId;
  final double gunBasiKm;
  final String kmAralik;
  final String haftasonuDurumu;
  final String marka;
  final DateTime? muayeneTarihi; // YENİ EKLENDİ
  final DateTime? kaskoTarihi;   // YENİ EKLENDİ

  AracModel({
    this.id,
    required this.plaka,
    required this.guzergahId,
    required this.gunBasiKm,
    required this.kmAralik,
    required this.haftasonuDurumu,
    required this.marka,
    this.muayeneTarihi, // YENİ EKLENDİ
    this.kaskoTarihi,   // YENİ EKLENDİ
  });

  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnId: id,
      DatabaseHelper.columnPlaka: plaka,
      DatabaseHelper.columnMarka: marka,
      DatabaseHelper.columnAracGuzergahId: guzergahId,
      DatabaseHelper.columnKmAralik: kmAralik,
      DatabaseHelper.columnGunBasiKm: gunBasiKm,
      DatabaseHelper.columnHaftasonuDurumu: haftasonuDurumu,
      // Tarihleri veritabanına metin olarak kaydetmek için ISO formatına çeviriyoruz.
      DatabaseHelper.columnMuayeneTarihi: muayeneTarihi?.toIso8601String(),
      DatabaseHelper.columnKaskoTarihi: kaskoTarihi?.toIso8601String(),
    };
  }

  factory AracModel.fromMap(Map<String, dynamic> map) {
    return AracModel(
      id: map[DatabaseHelper.columnId],
      plaka: map[DatabaseHelper.columnPlaka] ?? '',
      marka: map[DatabaseHelper.columnMarka] ?? 'Belirtilmemiş',
      guzergahId: map[DatabaseHelper.columnAracGuzergahId] ?? 0,
      gunBasiKm: (map[DatabaseHelper.columnGunBasiKm] as num?)?.toDouble() ?? 0.0,
      kmAralik: map[DatabaseHelper.columnKmAralik] ?? '',
      haftasonuDurumu: map[DatabaseHelper.columnHaftasonuDurumu] ?? '',
      // Veritabanından gelen metni tekrar DateTime nesnesine çeviriyoruz.
      muayeneTarihi: map[DatabaseHelper.columnMuayeneTarihi] != null
          ? DateTime.tryParse(map[DatabaseHelper.columnMuayeneTarihi])
          : null,
      kaskoTarihi: map[DatabaseHelper.columnKaskoTarihi] != null
          ? DateTime.tryParse(map[DatabaseHelper.columnKaskoTarihi])
          : null,
    );
  }
}