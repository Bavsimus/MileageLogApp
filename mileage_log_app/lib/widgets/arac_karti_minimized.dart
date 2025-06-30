// arac_karti_minimized.dart dosyasının Orijinal Tasarıma Sadık Kalınarak Düzeltilmiş Hali

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/arac_model.dart';

// 1. SINIF ADI DÜZELTİLDİ
class AracKartiMinimized extends StatelessWidget {
  final AracModel arac;
  final String guzergahAdi;

  // 2. GEREKSİZ PARAMETRELER KALDIRILDI
  const AracKartiMinimized({
    super.key,
    required this.arac,
    required this.guzergahAdi,
  });

  // Bilgi satırları için yardımcı widget (TASARIMINIZA DOKUNULMADI)
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: CupertinoTheme.of(
              context,
            ).textTheme.textStyle.copyWith(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 3. RESİM YOLLARI DÜZELTİLDİ
  String _getAracResimYolu(String marka) {
    final markaLower = marka.toLowerCase();
    final String fallbackImage = 'assets/images/mercedes-sprinter.png';

    switch(markaLower) {
      case 'mercedes': return 'assets/mercedes-sprinter.png';
      case 'ford': return 'assets/ford-transit.png';
      case 'fiat': return 'assets/fiat-ducato.png';
      case 'renault': return 'assets/renault-master.png';
      case 'peugeot': return 'assets/peugeot-boxer.png';
      case 'volkswagen': return 'assets/wv-crafter.png';
      default: return fallbackImage;
    }
  }

  @override
  Widget build(BuildContext context) {
    // BURADAN İTİBAREN TASARIMINIZLA BİREBİR AYNIDIR
    return Container(
      margin: const EdgeInsets.only(top: 30.0, bottom: 8.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Card(
            elevation: 0.0,
            color: CupertinoTheme.of(context).barBackgroundColor,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: CupertinoColors.separator.resolveFrom(context),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Container(
              height: 145,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(context, icon: CupertinoIcons.map_pin_ellipse, text: guzergahAdi),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(context, icon: CupertinoIcons.tag, text: arac.marka),
                                ],
                              ),
                            ),
                            const SizedBox(width: 36),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(context, icon: CupertinoIcons.arrow_right_arrow_left_square, text: arac.kmAralik),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(context, icon: CupertinoIcons.gauge, text: arac.gunBasiKm.toString()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                    // Hata durumunda gösterilecek varsayılan resim yolu da düzeltildi.
                    // Projenizde bu isimde bir resim olduğundan emin olun.
                    return Image.asset(
                      'assets/mercedes-sprinter.png',
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