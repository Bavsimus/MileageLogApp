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
        Expanded(
          child: Text(
            text,
            // --- DEĞİŞİKLİK BURADA: Daha belirgin bir metin stili kullanıldı ---
            style: CupertinoTheme.of(
              context,
            ).textTheme.textStyle.copyWith(fontSize: 16), // tabLabelTextStyle -> textStyle
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // YARDIMCI FONKSİYON
  String _getAracResimYolu(String marka) {
    final markaLower = marka.toLowerCase();
    if (markaLower.contains('mercedes')) {
      return 'assets/mercedes-sprinter.png';
    } else if (markaLower.contains('ford')) {
      return 'assets/ford-transit.png';
    } else if (markaLower.contains('fiat')) {
      return 'assets/fiat-ducato.png';
    } else if (markaLower.contains('renault')) {
      return 'assets/renault-master.png';
    } else if (markaLower.contains('peugeot')) {
      return 'assets/peugeot-boxer.png';
    } else if (markaLower.contains('volkswagen')) {
      return 'assets/wv-crafter.png';
    }
    return 'assets/mercedes-sprinter.png';
  }

  @override
  Widget build(BuildContext context) {
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
              height: 220,
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
                                  _buildInfoRow(context, icon: CupertinoIcons.map_pin_ellipse, text: arac.guzergah),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(context, icon: CupertinoIcons.tag, text: arac.marka),
                                ],
                              ),
                            ),
                            SizedBox(width: 36),
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
                        SizedBox(height: 26),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [ Expanded(child: 
                              CupertinoButton(
                                onPressed: onEdit,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                color: CupertinoTheme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(16.0),
                                child: const Text(
                                  'Düzenle',
                                  style: TextStyle(
                                    color: CupertinoColors.darkBackgroundGray,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: CupertinoColors.destructiveRed,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: CupertinoButton(
                                  onPressed: onDelete,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                                  borderRadius: BorderRadius.circular(16.0),
                                  child: const Text(
                                    'Sil',
                                    style: TextStyle(
                                      color: CupertinoColors.destructiveRed,
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
