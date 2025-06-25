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

  // BİLGİ SATIRLARI İÇİN YARDIMCI WIDGET
  @override
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: CupertinoColors.secondaryLabel),
        const SizedBox(width: 8),
        // Metnin uzun olması durumunda taşmasını önlemek için Expanded ekliyoruz.
        Expanded(
          child: Text(
            text,
            style: CupertinoTheme.of(
              context,
            ).textTheme.tabLabelTextStyle.copyWith(fontSize: 16),
            overflow: TextOverflow.ellipsis, // Uzun metinler için ... koyar
          ),
        ),
      ],
    );
  }

  // YARDIMCI FONKSİYON
  String _getAracResimYolu(String marka) {
    // Büyük/küçük harf duyarlılığını ortadan kaldırmak için
    final markaLower = marka.toLowerCase();

    // Örnek marka isimleri. Kendi marka isimlerinize göre düzenleyin.
    if (markaLower.contains('mercedes')) {
      return 'assets/mercedes-sprinter.png';
    } else if (markaLower.contains('ford')) {
      return 'assets/ford-transit.png'; // Bu dosyanın assets klasöründe olduğundan emin olun
    } else if (markaLower.contains('fiat')) {
      return 'assets/fiat-ducato.png'; // Bu dosyanın assets klasöründe olduğundan emin olun
    } else if (markaLower.contains('renault')) {
      return 'assets/renault-master.png'; // Bu dosyanın assets klasöründe olduğundan emin olun
    } else if (markaLower.contains('peugeot')) {
      return 'assets/peugeot-boxer.png'; // Bu dosyanın assets klasöründe olduğundan emin olun
    } else if (markaLower.contains('volkswagen')) {
      return 'assets/wv-crafter.png'; // Bu dosyanın assets klasöründe olduğundan emin olun
    }
    // Eşleşen bir marka bulunamazsa
    return 'assets/mercedes-sprinter.png'; // Bu dosyanın assets klasöründe olduğundan emin olun
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 30.0, bottom: 8.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. KATMAN: Arka Plan Kartı
          Card(
            elevation: 0.0,
            color: CupertinoColors.tertiarySystemBackground,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: CupertinoColors.systemGrey5.resolveFrom(context),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(
                12,
                12,
                12,
                8,
              ), // Padding'i ayarlayabiliriz
              child: Row(
                children: [
                  // Sol Taraf: Bilgiler ve Butonlar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            arac.plaka,
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .navTitleTextStyle
                                .copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 32,
                                ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Dört bilgiyi iki sütuna ayırmak için bir Row kullanıyoruz.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // sol SÜTUN
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    context,
                                    icon: CupertinoIcons.map_pin_ellipse,
                                    text: arac.guzergah,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    context,
                                    icon: CupertinoIcons.tag,
                                    text: arac.marka,
                                  ),
                                ],
                              ),
                            ),
                            // sağ SÜTUN
                            SizedBox(width: 36), // Sütunlar arasında boşluk
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    context,
                                    icon:
                                        CupertinoIcons.arrow_left_right_square,
                                    text: arac.kmAralik,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    context,
                                    icon: CupertinoIcons.gauge,
                                    text: arac.gunBasiKm.toString(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 26),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [ Expanded(child: 
                              // Düzenle Butonu
                              CupertinoButton(
                                onPressed: onEdit,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                color: CupertinoColors.systemTeal,
                                borderRadius: BorderRadius.circular(16.0),
                                child: const Text(
                                  'Düzenle',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ),
                              const SizedBox(width: 8),
                              // Sil Butonu
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 8,
                                  ),
                                  borderRadius: BorderRadius.circular(16.0),
                                  child: const Text(
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
            top: -70,
            right: 5,
            child: SizedBox(
              width: 160,
              height: 160,
              child: Transform.scale(
                scaleX: -1,
                child: Image.asset(
                  _getAracResimYolu(arac.marka),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/default-van.png',
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
