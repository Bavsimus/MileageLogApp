import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/arac_model.dart';
import 'rapor_onizleme_page.dart';
import '../widgets/arac_karti_minimized.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/services.dart';
import '../models/database_helper.dart';
import '../models/guzergah_model.dart';

// --- AY SEÇİCİ WIDGET'I ---
class AySecici extends StatelessWidget {
  final List<String> aylar;
  final int seciliAy;
  final ValueChanged<int> onAySecildi;

  const AySecici({
    super.key,
    required this.aylar,
    required this.seciliAy,
    required this.onAySecildi,
  });

  @override
  Widget build(BuildContext context) {
    final ScrollController controller = ScrollController(
      initialScrollOffset: (seciliAy - 1) * 85.0, // Kart genişliğine göre ayarlandı
    );

    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: aylar.length,
        itemBuilder: (context, index) {
          final ay = aylar[index];
          final ayNo = index + 1;
          final isSelected = ayNo == seciliAy;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: CupertinoButton(
              color: isSelected
                  ? CupertinoTheme.of(context).primaryColor
                  : CupertinoTheme.of(context).barBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              borderRadius: BorderRadius.circular(20),
              onPressed: () => onAySecildi(ayNo),
              child: Text(
                ay,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : CupertinoTheme.of(context).textTheme.textStyle.color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- YIL SEÇİCİ WIDGET'I ---
class YilSecici extends StatelessWidget {
  final int seciliYil;
  final ValueChanged<int> onYilSecildi;
  final int baslangicYili;
  final int yilSayisi;

  const YilSecici({
    super.key,
    required this.seciliYil,
    required this.onYilSecildi,
    this.baslangicYili = 2020,
    this.yilSayisi = 50,
  });

  @override
  Widget build(BuildContext context) {
    final ScrollController controller = ScrollController(
      initialScrollOffset: (seciliYil - baslangicYili) * 110.0,
    );

    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: yilSayisi,
        itemBuilder: (context, index) {
          final yil = baslangicYili + index;
          final isSelected = yil == seciliYil;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: CupertinoButton(
              color: isSelected
                  ? CupertinoTheme.of(context).primaryColor
                  : CupertinoTheme.of(context).barBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              borderRadius: BorderRadius.circular(20),
              onPressed: () => onYilSecildi(yil),
              child: Text(
                yil.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : CupertinoTheme.of(context).textTheme.textStyle.color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TabloOlusturPage extends StatefulWidget {
  const TabloOlusturPage({super.key});

  @override
  _TabloOlusturPageState createState() => _TabloOlusturPageState();
}

class _TabloOlusturPageState extends State<TabloOlusturPage> {
  List<AracModel> tumAraclar = [];
  List<GuzergahModel> tumGuzergahlar = [];
  Set<int> seciliIndexler = {};
  DateTime _seciliTarih = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /*
  Future<void> _loadAraclar() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> aracJsonList = prefs.getStringList('araclar') ?? [];
    if (mounted) {
      setState(() {
        tumAraclar = aracJsonList.map((e) => AracModel.fromJson(e)).toList();
        _isLoading = false;
      });
    }
  }
*/
  Future<void> _loadData() async {
  final dbHelper = DatabaseHelper.instance;
  // Future'ları aynı anda çalıştırıp beklemek daha performanslıdır
  final aracListesiFuture = dbHelper.getAllAraclar();
  final guzergahListesiFuture = dbHelper.getAllGuzergahlar();
  
  final aracListesi = await aracListesiFuture;
  final guzergahListesi = await guzergahListesiFuture;

  if (mounted) {
    setState(() {
      tumAraclar = aracListesi;
      tumGuzergahlar = guzergahListesi;
      _isLoading = false;
    });
  }
}

  // HATA 2: EKSİK OLAN METOT EKLENDİ
  void _ayYilSeciciGoster() {
    final now = DateTime.now();
    final List<String> aylar = List.generate(12, (index) {
      return DateFormat.MMMM('tr_TR').format(DateTime(now.year, index + 1));
    });

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Rapor Tarihini Seçin'),
        message: Column(
          children: [
            const SizedBox(height: 20),
            YilSecici(
              seciliYil: _seciliTarih.year,
              onYilSecildi: (yeniYil) {
                // Pop-up'ı kapatıp yeniden açarak state'in doğru yönetilmesini sağlıyoruz
                Navigator.of(context).pop(); 
                setState(() {
                  _seciliTarih = DateTime(yeniYil, _seciliTarih.month);
                });
                _ayYilSeciciGoster();
              },
            ),
            const SizedBox(height: 20),
            AySecici(
              aylar: aylar,
              seciliAy: _seciliTarih.month,
              onAySecildi: (yeniAy) {
                // setState'in anlık yansıması için Navigator.pop/push yerine sadece setState
                setState(() {
                  _seciliTarih = DateTime(_seciliTarih.year, yeniAy);
                });
                Navigator.of(context).pop();
                _ayYilSeciciGoster();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Bitti'),
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
        content:
            const Text('Lütfen rapor oluşturmak için en az bir araç seçin.'),
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

    if (kmAralikParts.length == 1) {
      final ortalamaKm = int.tryParse(kmAralikParts[0].trim()) ?? 0;
      kmMin = max(0, ortalamaKm - 5);
      kmMax = ortalamaKm + 5;
    } else if (kmAralikParts.length > 1) {
      kmMin = int.tryParse(kmAralikParts[0].trim()) ?? 0;
      kmMax = int.tryParse(kmAralikParts[1].trim()) ?? 0;

      if (kmMin > kmMax) {
        final temp = kmMin;
        kmMin = kmMax;
        kmMax = temp;
      }
    }

    int baslangicKm = arac.gunBasiKm;
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
      final guzergahAdi = tumGuzergahlar
          .firstWhere((g) => g.id == arac.guzergahId,
              orElse: () => GuzergahModel(id: 0, name: 'Bilinmiyor'))
          .name;

      final yapilanKm = (kmMax - kmMin <= 0)
          ? kmMin
          : Random().nextInt(kmMax - kmMin + 1) + kmMin;

      final gunSonuKm = baslangicKm + yapilanKm;
      aracSatirlari.add([
        '${tarih.day}.${tarih.month}.${tarih.year}',
        baslangicKm.toString(),
        gunSonuKm.toString(),
        yapilanKm,
        guzergahAdi,
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
    if (_isLoading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator(radius: 15)),
      );
    }
    if (tumAraclar.isEmpty) {
      return const CupertinoPageScaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.car_detailed, size: 60, color: CupertinoColors.secondaryLabel),
              SizedBox(height: 16),
              Text('Rapor oluşturmak için hiç araç bulunmuyor.'),
              SizedBox(height: 8),
              Text(
                'Lütfen "Araçlar" sekmesinden yeni bir araç ekleyin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: CupertinoColors.secondaryLabel),
              ),
            ],
          ),
        ),
      );
    }
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          AnimationLimiter(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 20, 16, seciliIndexler.isNotEmpty ? 160 : 80),
              itemCount: tumAraclar.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0, top: 40.0, left: 6.0, right: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Araç Seçin',
                              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                            ),
                            const Icon(CupertinoIcons.car_fill, color: CupertinoColors.secondaryLabel),
                          ],
                        ),
                      ),
                      const Divider(height: 0.5),
                    ],
                  );
                }
                final aracIndex = index - 1;
                final arac = tumAraclar[aracIndex];
                final bool isSelected = seciliIndexler.contains(aracIndex);
                final guzergahAdi = tumGuzergahlar
                .firstWhere((g) => g.id == arac.guzergahId, orElse: () => GuzergahModel(id: 0, name: "Bilinmiyor"))
                .name;
                return AnimationConfiguration.staggeredList(
                  position: aracIndex,
                  duration: const Duration(milliseconds: 400),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            HapticFeedback.lightImpact();
                            if (isSelected) {
                              seciliIndexler.remove(aracIndex);
                            } else {
                              seciliIndexler.add(aracIndex);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          child: // Stack içindeki kodu bununla değiştirebiliriz.
                          Stack(
                            children: [
                              AracKartiMinimized(arac: arac, guzergahAdi: guzergahAdi,),
                              // AnimatedSwitcher yerine basit bir if kontrolü
                              if (isSelected)
                                Positioned.fill(
                                  key: const ValueKey('selected_overlay'),
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 30.0, bottom: 8.0),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.systemYellow.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(24.0),
                                      border: Border.all(color: CupertinoColors.systemYellow, width: 2.5),
                                    ),
                                    child: const Center(
                                      child: Icon(CupertinoIcons.check_mark_circled, color: Colors.white, size: 50),
                                    ),
                                  ),
                                )
                            ],
                          )
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: seciliIndexler.isNotEmpty ? 0 : -200,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
                border: const Border(
                  top: BorderSide(color: CupertinoColors.systemYellow, width: 1),
                ),
                color: CupertinoTheme.of(context).barBackgroundColor.withOpacity(0.85),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      onPressed: _ayYilSeciciGoster,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rapor Ayı:',
                            style: CupertinoTheme.of(context).textTheme.textStyle,
                          ),
                          Text(
                            DateFormat.yMMMM('tr_TR').format(_seciliTarih),
                            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoButton.filled(
                        onPressed: () {
                                      HapticFeedback.lightImpact(); // Titreşim eklendi
                                      _raporOlusturVeGoruntule(_seciliTarih);
                                    },
                      child: const Text(
                        "Rapor Oluştur ve Görüntüle",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.darkBackgroundGray,
                        ),
                      ),
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