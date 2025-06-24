import 'dart:convert';

class AracModel {
  final String plaka;
  final String guzergah;
  final double gunBasiKm;
  final String kmAralik;
  final String haftasonuDurumu;
  final String marka; // YENİ EKLENEN ALAN

  AracModel({
    required this.plaka,
    required this.guzergah,
    required this.gunBasiKm,
    required this.kmAralik,
    required this.haftasonuDurumu,
    required this.marka, // YENİ EKLENDİ
  });

  Map<String, dynamic> toMap() => {
        'plaka': plaka,
        'guzergah': guzergah,
        'gunBasiKm': gunBasiKm,
        'kmAralik': kmAralik,
        'haftasonuDurumu': haftasonuDurumu,
        'marka': marka, // YENİ EKLENDİ
      };

  factory AracModel.fromMap(Map<String, dynamic> map) => AracModel(
        plaka: map['plaka'] ?? '',
        guzergah: map['guzergah'] ?? '',
        gunBasiKm: (map['gunBasiKm'] as num?)?.toDouble() ?? 0.0,
        kmAralik: map['kmAralik'] ?? '',
        haftasonuDurumu: map['haftasonuDurumu'] ?? '',
        // YENİ EKLENDİ: Eski verilerde bu alan olmayabileceği için varsayılan değer atıyoruz.
        marka: map['marka'] ?? 'Belirtilmemiş', 
      );

  String toJson() => json.encode(toMap());
  factory AracModel.fromJson(String source) =>
      AracModel.fromMap(json.decode(source));
}
