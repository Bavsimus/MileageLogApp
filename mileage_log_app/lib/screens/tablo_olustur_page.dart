import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/arac_model.dart';
import 'rapor_onizleme_page.dart';
import '../widgets/arac_karti_minimized.dart';

class TabloOlusturPage extends StatefulWidget {
  const TabloOlusturPage({super.key});

  @override
  _TabloOlusturPageState createState() => _TabloOlusturPageState();
}

class _TabloOlusturPageState extends State<TabloOlusturPage> {
  List<AracModel> tumAraclar = [];
  Set<int> seciliIndexler = {};
  DateTime _seciliTarih = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAraclar();
  }

  Future<void> _loadAraclar() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> aracJsonList = prefs.getStringList('araclar') ?? [];
    setState(() {
      tumAraclar = aracJsonList.map((e) => AracModel.fromJson(e)).toList();
    });
  }

  void _aySeciciGoster() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        padding: const EdgeInsets.only(top: 6.0),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text('Bitti'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: _seciliTarih,
                mode: CupertinoDatePickerMode.monthYear,
                onDateTimeChanged: (DateTime newDate) {
                  setState(() {
                    _seciliTarih = newDate;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _raporOlusturVeGoruntule(DateTime secilenAy) {
    final seciliAraclar = seciliIndexler.map((i) => tumAraclar[i]).toList();
    if (seciliAraclar.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Araç Seçilmedi'),
          content: const Text(
            'Lütfen rapor oluşturmak için en az bir araç seçin.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Tamam'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    final Map<AracModel, List<List<dynamic>>> raporVerisi = {};

    for (final arac in seciliAraclar) {
      final List<List<dynamic>> aracSatirlari = [];
      final kmAralikParts = arac.kmAralik.split('-');
      int kmMin = 0;
      int kmMax = 0;

      if (kmAralikParts.isNotEmpty) {
        kmMin = int.tryParse(kmAralikParts[0].trim()) ?? 0;
      }
      if (kmAralikParts.length > 1) {
        kmMax = int.tryParse(kmAralikParts[1].trim()) ?? 0;
      } else {
        kmMax = kmMin;
      }
      if (kmMin > kmMax) {
        final temp = kmMin;
        kmMin = kmMax;
        kmMax = temp;
      }

      double baslangicKm = arac.gunBasiKm;
      final gunSayisi = DateTime(secilenAy.year, secilenAy.month + 1, 0).day;

      for (int day = 1; day <= gunSayisi; day++) {
        final tarih = DateTime(secilenAy.year, secilenAy.month, day);

        if (tarih.weekday >= 6 && arac.haftasonuDurumu == 'Çalışmıyor') {
          aracSatirlari.add([
            '${tarih.day}.${tarih.month}.${tarih.year}',
            '-',
            '-',
            0,
            'Hafta Sonu Tatil',
          ]);
          continue;
        }

        final yapilanKm = (kmMax - kmMin == 0)
            ? kmMin
            : Random().nextInt(kmMax - kmMin + 1) + kmMin;
        final gunSonuKm = baslangicKm + yapilanKm;

        aracSatirlari.add([
          '${tarih.day}.${tarih.month}.${tarih.year}',
          baslangicKm.toStringAsFixed(2),
          gunSonuKm.toStringAsFixed(2),
          yapilanKm,
          arac.guzergah,
        ]);

        baslangicKm = gunSonuKm;
      }
      raporVerisi[arac] = aracSatirlari;
    }

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => RaporOnizlemePage(raporVerisi: raporVerisi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Rapor İçin Araç Seç"),
      ),
      // DEĞİŞİKLİK: En dıştaki SafeArea kaldırıldı, child doğrudan Stack oldu.
      child: Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 120, 0, 160), 
              itemCount: tumAraclar.length,
              itemBuilder: (context, index) {
                final arac = tumAraclar[index];
                final bool isSelected = seciliIndexler.contains(index);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        seciliIndexler.remove(index);
                      } else {
                        seciliIndexler.add(index);
                      }
                    });
                  },
                  child: Stack(
                    children: [
                      // AracKarti'nın kenarlarında kendi boşluğu olmaması için
                      // onu bir Padding ile sarmalıyoruz.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: AracKarti(
                          arac: arac,
                          onEdit: () {},
                          onDelete: () {},
                        ),
                      ),
                      if (isSelected)
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemTeal.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: CupertinoColors.systemTeal,
                                width: 2.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.check_mark_circled,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border(
                    top: BorderSide(
                      color: CupertinoColors.systemGrey5,
                      width: 1.0,
                    ),
                  ),
                  color: CupertinoTheme.of(context).barBackgroundColor.withOpacity(0.9),
                ),
                child: Padding(
                  // Telefonun altındaki sistem boşluğunu da hesaba katıyoruz
                  padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        onPressed: _aySeciciGoster,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rapor Ayı:',
                              style: CupertinoTheme.of(context).textTheme.textStyle,
                            ),
                            Text(
                              DateFormat.yMMMM('tr_TR').format(_seciliTarih),
                              style: CupertinoTheme.of(context).textTheme.textStyle
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      CupertinoButton.filled(
                        onPressed: () => _raporOlusturVeGoruntule(_seciliTarih),
                        child: const Text("Rapor Oluştur ve Görüntüle"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}
