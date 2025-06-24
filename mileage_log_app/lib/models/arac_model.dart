import 'dart:convert';

class AracModel {
  final String plaka;
  final String guzergah;
  final double gunBasiKm;
  final String kmAralik;
  final String haftasonuDurumu;

  AracModel({
    required this.plaka,
    required this.guzergah,
    required this.gunBasiKm,
    required this.kmAralik,
    required this.haftasonuDurumu,
  });

  Map<String, dynamic> toMap() => {
        'plaka': plaka,
        'guzergah': guzergah,
        'gunBasiKm': gunBasiKm,
        'kmAralik': kmAralik,
        'haftasonuDurumu': haftasonuDurumu,
      };

  factory AracModel.fromMap(Map<String, dynamic> map) => AracModel(
        plaka: map['plaka'] ?? '',
        guzergah: map['guzergah'] ?? '',
        gunBasiKm: (map['gunBasiKm'] as num?)?.toDouble() ?? 0.0,
        kmAralik: map['kmAralik'] ?? '',
        haftasonuDurumu: map['haftasonuDurumu'] ?? '',
      );

  String toJson() => json.encode(toMap());
  factory AracModel.fromJson(String source) =>
      AracModel.fromMap(json.decode(source));
}
