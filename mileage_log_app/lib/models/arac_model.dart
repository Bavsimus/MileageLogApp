import '../models/database_helper.dart';

class AracModel {
  final int? id;
  final String plaka;
  final int guzergahId;
  final double gunBasiKm;
  final String kmAralik;
  final String haftasonuDurumu;
  final String marka;

  AracModel({
    this.id,
    required this.plaka,
    required this.guzergahId,
    required this.gunBasiKm,
    required this.kmAralik,
    required this.haftasonuDurumu,
    required this.marka,
  });

  Map<String, dynamic> toMap() => {
        DatabaseHelper.columnId: id,
        DatabaseHelper.columnPlaka: plaka,
        DatabaseHelper.columnMarka: marka,
        DatabaseHelper.columnAracGuzergahId: guzergahId, // DÜZELTİLDİ
        DatabaseHelper.columnKmAralik: kmAralik,
        DatabaseHelper.columnGunBasiKm: gunBasiKm,
        DatabaseHelper.columnHaftasonuDurumu: haftasonuDurumu,
      };

  factory AracModel.fromMap(Map<String, dynamic> map) => AracModel(
        id: map[DatabaseHelper.columnId],
        plaka: map[DatabaseHelper.columnPlaka] ?? '',
        marka: map[DatabaseHelper.columnMarka] ?? 'Belirtilmemiş',
        guzergahId: map[DatabaseHelper.columnAracGuzergahId] ?? 0, // DÜZELTİLDİ
        gunBasiKm: (map[DatabaseHelper.columnGunBasiKm] as num?)?.toDouble() ?? 0.0,
        kmAralik: map[DatabaseHelper.columnKmAralik] ?? '',
        haftasonuDurumu: map[DatabaseHelper.columnHaftasonuDurumu] ?? '',
      );
}