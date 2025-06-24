import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/arac_model.dart';

class AracKarti extends StatelessWidget {
  final AracModel arac;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AracKarti({
    super.key,
    required this.arac,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Kartın ve taşan resmin doğru görünmesi için dışta bir boşluk bırakıyoruz.
    // 'top' marjini, resmin taşacağı miktar kadar olmalı.
    return Container(
      margin: const EdgeInsets.only(top: 30.0, bottom: 8.0),
      child: Stack(
        // Stack'in çocuklarının kendi sınırlarının dışına taşmasına izin ver.
        clipBehavior: Clip.none,
        children: [
          // 1. KATMAN: Arka Plan Kartı (Sadece bilgileri ve butonları içerir)
          Card(
            elevation: 0.0,
            color: CupertinoColors.tertiarySystemBackground,
            margin: EdgeInsets.zero, // Dış container marjini yönettiği için sıfırlıyoruz.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Container(
              height: 240,
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Sol Taraf: Bilgiler ve Butonlar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          arac.plaka,
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .navTitleTextStyle
                              .copyWith(fontWeight: FontWeight.w500, fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Center(
                    child: Column(
                      // Sola dayalı ve temiz bir görünüm için
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Satır: Güzergah
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.map_pin_ellipse, size: 16, color: CupertinoColors.secondaryLabel),
                            const SizedBox(width: 8),
                            Text(
                              arac.guzergah,
                              style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4), // Satırlar arasına boşluk

                        // 2. Satır: KM Aralığı
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.arrow_left_right_square, size: 16, color: CupertinoColors.secondaryLabel),
                            const SizedBox(width: 8),
                            Text(
                              arac.kmAralik,
                              style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        // 3. Satır: BURAYA ARAÇ MARKASI GELECEK
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.tag, size: 16, color: CupertinoColors.secondaryLabel),
                            const SizedBox(width: 8),
                            Text(
                              arac.marka.toString(),
                              style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.gauge, size: 16, color: CupertinoColors.secondaryLabel),
                            const SizedBox(width: 8),
                            Text(
                              arac.gunBasiKm.toString(),
                              style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                        const Spacer(),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoButton(
                                onPressed: onEdit,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                color: CupertinoColors.systemTeal,
                                 borderRadius: BorderRadius.circular(16.0),
                                child: Text(
                                  'Düzenle',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: CupertinoColors.systemRed,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: CupertinoButton(
                                  onPressed: onDelete,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                                   borderRadius: BorderRadius.circular(16.0),
                                  child: Text(
                                    'Sil',
                                    style: TextStyle(
                                      color: CupertinoColors.systemRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. KATMAN: Araç Resmi
          Positioned(
            top: -70, // Resmin ne kadar yukarı taşacağını belirler
            right: 5,   // Sağdan ne kadar boşluk bırakılacağını belirler
            child: SizedBox(
              width: 160,
              height: 160,
              child: Transform.scale(
                          scaleX: -1, // Yatay aynalama için bu satırı ekledik
                          child: Image.asset(
                            'assets/mercedes-sprinter.png',
                            fit: BoxFit.contain,
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}