import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' hide Border ; 
import 'package:path_provider/path_provider.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(MileageLogApp());
}

class MileageLogApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Mileage Log App',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        scaffoldBackgroundColor: CupertinoColors.systemGrey6,
        primaryColor: CupertinoColors.systemTeal,
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('tr', 'TR'),
        const Locale('en', 'US'),
      ],
      home: NavigationRoot(),
    );
  }
}

// Lütfen projenizdeki mevcut (Stateless) NavigationRoot'u 
// aşağıdaki (Stateful) versiyonuyla değiştirin.

class NavigationRoot extends StatefulWidget {
  const NavigationRoot({super.key});

  @override
  State<NavigationRoot> createState() => _NavigationRootState();
}

// Mevcut _NavigationRootState sınıfını bununla tamamen değiştir.

class _NavigationRootState extends State<NavigationRoot> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<String> _pageTitles = [
    'Araçlarım',
    'Rapor Oluştur',
    'Kaydedilmiş Raporlar',
    'Güzergah Ayarları'
  ];

  final List<Widget> _pages = [
    AraclarPage(),
    TabloOlusturPage(),
    TablolarPage(),
    GuzergahAyarPage(),
  ];

  // _NavigationRootState sınıfının içindeki mevcut build metodunu bununla değiştirin.
// _NavigationRootState sınıfının içindeki mevcut build metodunu bununla değiştir.
@override
Widget build(BuildContext context) {
  // Sekme verilerini (ikon ve başlık) bir liste olarak tanımlayalım.
  // Bu, kodu daha yönetilebilir kılar.
  final List<Map<String, dynamic>> tabItems = [
    {'icon': CupertinoIcons.car_detailed, 'label': 'Araçlar'},
    {'icon': CupertinoIcons.add_circled, 'label': 'Tablo Oluştur'},
    {'icon': CupertinoIcons.folder_fill, 'label': 'Tablolar'},
    {'icon': CupertinoIcons.map_fill, 'label': 'Güzergah'},
  ];

  return CupertinoPageScaffold(
    backgroundColor: CupertinoColors.systemGrey6,
    child: Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            children: _pages,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        CupertinoTabBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          
          // --- DEĞİŞİKLİK BURADA BAŞLIYOR ---
          // 'items' listesini artık sabit bir liste olarak değil, dinamik olarak oluşturuyoruz.
          items: tabItems.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> item = entry.value;

            return BottomNavigationBarItem(
              icon: Icon(item['icon']),
              // Koşullu ifade: Eğer bu sekmenin indeksi, seçili olan indekse eşitse
              // label'ı göster, değilse boş bir string ata (gösterme).
              label: index == _currentIndex ? item['label'] : '',
            );
          }).toList(), // .map() sonucunu bir listeye çeviriyoruz.
          // --- DEĞİŞİKLİK BURADA BİTİYOR ---
        ),
      ],
    ),
  );
}
}

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
        plaka: map['plaka'],
        guzergah: map['guzergah'],
        gunBasiKm: map['gunBasiKm'],
        kmAralik: map['kmAralik'],
        haftasonuDurumu: map['haftasonuDurumu'],
      );

  String toJson() => json.encode(toMap());
  factory AracModel.fromJson(String source) =>
      AracModel.fromMap(json.decode(source));
}

// Mevcut AracKarti widget'ını bununla değiştirin.
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
    // Kartın dışına taşma olacağı için, karta biraz boşluk vermek amacıyla bir dış Container kullanıyoruz.
    return Container(
      margin: const EdgeInsets.only(top: 30.0, bottom: 8.0, left: 16.0, right: 16.0),
      child: Stack(
        // clipBehavior.none, çocukların Stack sınırlarının dışına taşmasına izin verir.
        clipBehavior: Clip.none,
        children: [
          // 1. Katman: Arka Plan Kartı
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Row(
              children: [
                // Sol Taraf: Bilgiler ve Buton
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Plaka yazısı solda kalıyor
                        Text(
                          arac.plaka,
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .navTitleTextStyle
                              .copyWith(fontWeight: FontWeight.bold, fontSize: 32),
                        ),
                        const SizedBox(height: 18),

                        // --- DEĞİŞİKLİK 1: Güzergah/KM satırı Center ile ortalandı ---
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(child: Text(arac.guzergah, style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.copyWith(fontSize: 16), overflow: TextOverflow.ellipsis)),
                              const VerticalDivider(width: 12, thickness: 1, color: CupertinoColors.separator),
                              Text(arac.kmAralik, style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.copyWith(fontSize: 16)),
                            ],
                          ),
                        ),
                        
                        const Spacer(), // Butonları en alta iter

                        // --- DEĞİŞİKLİK 2: Butonlar Center ile ortalandı ve Sil butonu eklendi ---
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
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Butonu, kenarlık vermek için bir Container ile sarmalıyoruz
                              Container(
                                decoration: BoxDecoration(
                                  // Kenarlık rengini ve kalınlığını belirliyoruz
                                  border: Border.all(
                                    color: CupertinoColors.systemRed,
                                    width: 1.0,
                                  ),
                                  // Kenarlıkları butonun kendi şekli gibi yuvarlak yapıyoruz
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: CupertinoButton(
                                  onPressed: onDelete,
                                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 8),
                                  child: Text(
                                    'Sil',
                                    style: TextStyle(
                                      // Yazı rengini de kenarlıkla aynı yapıyoruz
                                      color: CupertinoColors.systemRed,
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
                ),
                // Sağ Taraf: Sadece boşluk bırakır, resim bunun üzerine gelecek
                const Expanded(flex: 0, child: SizedBox()),
              ],
            ),
          ),

          // 2. Katman: Araç Resmi
          Positioned(
                      top: -85,
                      right: 5,
                      child: SizedBox(
                        width: 180,
                        height: 180,
                        // Resmi yatayda aynalamak için Transform.scale ile sarmalıyoruz
                        child: Transform.scale(
                          scaleX: -1, // Yatay aynalama için bu satırı ekledik
                          child: Image.asset(
                            'assets/mercedes-sprinter.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
          )
        ],
      ),
    );
  }
}


// Mevcut AraclarPage ve _AraclarPageState'i bununla değiştirin.
class AraclarPage extends StatefulWidget {
  @override
  _AraclarPageState createState() => _AraclarPageState();
}

class _AraclarPageState extends State<AraclarPage> {
  List<String> guzergahlar = [];
  List<AracModel> araclar = [];
  int? _duzenlenenIndex;

  final TextEditingController plakaController = TextEditingController();
  final TextEditingController kmBaslangicController = TextEditingController();
  final TextEditingController kmAralikController = TextEditingController();
  String seciliGuzergah = '';
  String haftasonuDurumu = 'Çalışıyor';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    await _loadGuzergahlar();
    await _loadAraclar();
  }

  // Bu metot, silme butonuna basıldığında çalışır ve onay penceresi gösterir.
  Future<void> _aracSil(int index) async {
    final arac = araclar[index];
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Aracı Sil'),
        content: Text('"${arac.plaka}" plakalı aracı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          CupertinoDialogAction(
            child: Text('İptal'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Sil'),
            onPressed: () {
              setState(() {
                araclar.removeAt(index);
              });
              _saveAracList(); // Güncel listeyi kaydetmek için bu yardımcı metodu çağırır.
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // Bu yardımcı metot, güncel araç listesini telefona kaydeder.
  Future<void> _saveAracList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = araclar.map((e) => e.toJson()).toList();
    await prefs.setStringList('araclar', jsonList);
  }

  Future<void> _loadGuzergahlar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      guzergahlar = prefs.getStringList('guzergahlar') ?? [];
      if (guzergahlar.isNotEmpty) {
        if (seciliGuzergah.isEmpty || !guzergahlar.contains(seciliGuzergah)){
           seciliGuzergah = guzergahlar.first;
        }
      } else {
        seciliGuzergah = '';
      }
    });
  }

  Future<void> _loadAraclar() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> aracJsonList = prefs.getStringList('araclar') ?? [];
    setState(() {
      araclar = aracJsonList.map((e) => AracModel.fromJson(e)).toList();
    });
  }

  Future<void> _saveOrUpdateArac() async {
    if (plakaController.text.isEmpty ||
        kmBaslangicController.text.isEmpty ||
        kmAralikController.text.isEmpty ||
        (guzergahlar.isNotEmpty && seciliGuzergah.isEmpty) ) {
          // Hata mesajını Cupertino stiliyle gösterelim
          showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
            title: Text('Eksik Bilgi'),
            content: Text('Lütfen tüm alanları doldurun.'),
            actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('Tamam'), onPressed: () => Navigator.of(context).pop())],
          ));
          return;
        }

    final arac = AracModel(
      plaka: plakaController.text.trim(),
      guzergah: seciliGuzergah,
      gunBasiKm: double.tryParse(kmBaslangicController.text.trim()) ?? 0,
      kmAralik: kmAralikController.text.trim(),
      haftasonuDurumu: haftasonuDurumu,
    );

    setState(() {
      if (_duzenlenenIndex != null) {
        araclar[_duzenlenenIndex!] = arac;
      } else {
        araclar.add(arac);
      }
      _duzenlenenIndex = null;
      plakaController.clear();
      kmBaslangicController.clear();
      kmAralikController.clear();
      if (guzergahlar.isNotEmpty) {
        seciliGuzergah = guzergahlar.first;
      }
    });

    final prefs = await SharedPreferences.getInstance();
    final jsonList = araclar.map((e) => e.toJson()).toList();
    await prefs.setStringList('araclar', jsonList);
  }
  
  void _editArac(int index){
    final arac = araclar[index];
    setState(() {
       _duzenlenenIndex = index;
       plakaController.text = arac.plaka;
       kmBaslangicController.text = arac.gunBasiKm.toString();
       kmAralikController.text = arac.kmAralik;
       haftasonuDurumu = arac.haftasonuDurumu;

       if (guzergahlar.contains(arac.guzergah)) {
         seciliGuzergah = arac.guzergah;
       } else {
         seciliGuzergah = guzergahlar.isNotEmpty ? guzergahlar.first : '';
         WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Aracın eski güzergahı bulunamadı. Lütfen yeni bir tane seçin.'),
                backgroundColor: Colors.orange,
              ),
            );
         });
       }
    });
  }

  // Cupertino Picker'ı göstermek için yardımcı metot
  void _showPicker(BuildContext context, List<String> items, String currentValue, ValueChanged<String> onChanged) {
    final selectedIndex = items.indexOf(currentValue);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32.0,
            scrollController: FixedExtentScrollController(initialItem: selectedIndex),
            onSelectedItemChanged: (int selectedIndex) {
              onChanged(items[selectedIndex]);
            },
            children: List<Widget>.generate(items.length, (int index) {
              return Center(child: Text(items[index]));
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold -> CupertinoPageScaffold
    return CupertinoPageScaffold(
      // AppBar -> CupertinoNavigationBar
      navigationBar: CupertinoNavigationBar(
        middle: Text('Araçlar'),
      ),
      child: SafeArea( // İçeriğin sistem alanlarına taşmasını önler
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('Yeni Araç', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
            Divider(thickness: 0,),
            // TextField -> CupertinoTextField
            CupertinoTextField(
                controller: plakaController,
                placeholder: 'Plaka'),
            SizedBox(height: 8),
            CupertinoTextField(
                controller: kmBaslangicController,
                keyboardType: TextInputType.number,
                placeholder: 'Gün Başı KM'),
            SizedBox(height: 8),
            CupertinoTextField(
                controller: kmAralikController,
                placeholder: 'KM Aralığı (örn: 90-100)'),
            SizedBox(height: 16),
            
            // DropdownButton -> Cupertino-stili butonlar
            CupertinoListTile(title: Text('Hafta Sonu Durumu'), additionalInfo: Text(haftasonuDurumu), onTap: () {
               _showPicker(context, ['Çalışıyor', 'Çalışmıyor'], haftasonuDurumu, (newValue) {
                  setState(() => haftasonuDurumu = newValue);
               });
            }),
            if (guzergahlar.isNotEmpty)
              CupertinoListTile(title: Text('Güzergah'), additionalInfo: Text(seciliGuzergah), onTap: (){
                _showPicker(context, guzergahlar, seciliGuzergah, (newValue) {
                  setState(() => seciliGuzergah = newValue);
                });
              })
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text("Lütfen önce Güzergah sekmesinden bir güzergah ekleyin.", style: TextStyle(color: CupertinoColors.systemRed)),
              ),
            
            SizedBox(height: 20),
            // ElevatedButton -> CupertinoButton.filled
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(16.0),
                onPressed: _saveOrUpdateArac, 
                child: Text(_duzenlenenIndex == null ? 'Kaydet' : 'Güncelle')
            ),
            SizedBox(height: 20),
            
            // Liste başlığı
            Text('Kayıtlı Araçlar', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),

            // Liste artık yeni AracKarti widget'ını kullanıyor
            if (araclar.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.car_detailed, size: 60, color: CupertinoColors.secondaryLabel),
                      SizedBox(height: 10),
                      Text('Henüz araç eklenmedi.', style: CupertinoTheme.of(context).textTheme.textStyle)
                    ],
                  ),
                ),
              )
            else
              ...araclar.asMap().entries.map((entry) {
                final index = entry.key;
                final a = entry.value;
                // ListTile yerine özel AracKarti widget'ımızı kullanıyoruz
                return AracKarti(
                  arac: a,
                  onEdit: () => _editArac(index),
                  onDelete: () => _aracSil(index),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// Bu yardımcı widget, CupertinoListTile'a benzer bir yapı sunar
class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget additionalInfo;
  final VoidCallback onTap;

  const CupertinoListTile({super.key, required this.title, required this.additionalInfo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DefaultTextStyle(style: CupertinoTheme.of(context).textTheme.textStyle, child: title),
            Row(
              children: [
                DefaultTextStyle(
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(color: CupertinoColors.secondaryLabel), 
                  child: additionalInfo
                ),
                SizedBox(width: 6),
                Icon(CupertinoIcons.chevron_up_chevron_down, size: 16, color: CupertinoColors.tertiaryLabel)
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Mevcut TabloOlusturPage ve State'ini bununla değiştirin.
class TabloOlusturPage extends StatefulWidget {
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

  // showDatePicker -> showCupertinoModalPopup + CupertinoDatePicker
  void _aySeciciGoster() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        padding: const EdgeInsets.only(top: 6.0),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            // "Bitti" butonu ekleyerek kullanıcının seçimini onaylamasını sağlıyoruz.
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: Text('Bitti'),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: _seciliTarih,
                mode: CupertinoDatePickerMode.monthYear, // Sadece ay ve yıl seçimi
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
      showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
        title: Text('Araç Seçilmedi'),
        content: Text('Lütfen rapor oluşturmak için en az bir araç seçin.'),
        actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('Tamam'), onPressed: () => Navigator.of(context).pop())],
      ));
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
            '-', '-', 0, 'Hafta Sonu Tatil'
          ]);
          continue; 
        }

        final yapilanKm = (kmMax - kmMin == 0) ? kmMin : Random().nextInt(kmMax - kmMin + 1) + kmMin;
        final gunSonuKm = baslangicKm + yapilanKm;

        aracSatirlari.add([
          '${tarih.day}.${tarih.month}.${tarih.year}',
          baslangicKm.toStringAsFixed(2),
          gunSonuKm.toStringAsFixed(2),
          yapilanKm,
          arac.guzergah
        ]);
        
        baslangicKm = gunSonuKm;
      }
      raporVerisi[arac] = aracSatirlari;
    }

    Navigator.push(
      context,
      // Cupertino stili sayfa geçiş animasyonu için
      CupertinoPageRoute(
        builder: (context) => RaporOnizlemePage(raporVerisi: raporVerisi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Rapor Oluştur"),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              // CheckboxListTile yerine özel bir liste elemanı
              child: ListView.separated(
                itemCount: tumAraclar.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      color: isSelected ? CupertinoColors.systemTeal.withOpacity(0.2) : Colors.transparent,
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                            color: isSelected ? CupertinoColors.systemTeal : CupertinoColors.secondaryLabel,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(arac.plaka, style: CupertinoTheme.of(context).textTheme.textStyle),
                                Text(arac.guzergah, style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CupertinoButton(
                    onPressed: _aySeciciGoster,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rapor Ayı:', style: CupertinoTheme.of(context).textTheme.textStyle),
                        Text(
                          DateFormat.yMMMM('tr_TR').format(_seciliTarih),
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  CupertinoButton.filled(
                      onPressed: () => _raporOlusturVeGoruntule(_seciliTarih),
                      child: Text("Rapor Oluştur ve Görüntüle"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mevcut RaporOnizlemePage sınıfını bununla değiştirin.

class RaporOnizlemePage extends StatelessWidget {
  final Map<AracModel, List<List<dynamic>>> raporVerisi;

  const RaporOnizlemePage({Key? key, required this.raporVerisi}) : super(key: key);

  Future<void> _kaydetVePaylas(BuildContext context) async {
    final excel = Excel.createExcel();

    for (var entry in raporVerisi.entries) {
      final arac = entry.key;
      final veriler = entry.value;
      final sheet = excel['${arac.plaka.replaceAll(' ', '_')}']; 
      
      sheet.appendRow([
        TextCellValue('Tarih'), TextCellValue('Gün Başı'), TextCellValue('Gün Sonu'),
        TextCellValue('Yapılan KM'), TextCellValue('Güzergah')
      ]);

      for (final satir in veriler) {
         sheet.appendRow([
            TextCellValue(satir[0].toString()),
            DoubleCellValue(double.tryParse(satir[1].toString()) ?? 0),
            DoubleCellValue(double.tryParse(satir[2].toString()) ?? 0),
            IntCellValue(int.tryParse(satir[3].toString()) ?? 0),
            TextCellValue(satir[4].toString()),
         ]);
      }
    }

    final now = DateTime.now();
    final fileName = 'AracRaporu_${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}.xlsx';
    
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';

    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final file = File(path);
      await file.writeAsBytes(fileBytes);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rapor, "Tablolar" sekmesine kaydedildi: $fileName')),
      );

      await Share.shareXFiles([XFile(path)], text: 'Araç Raporu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Rapor Önizleme"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.share),
          onPressed: () => _kaydetVePaylas(context),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: raporVerisi.keys.length,
        itemBuilder: (context, index) {
          final arac = raporVerisi.keys.elementAt(index);
          final dataRows = raporVerisi[arac]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Text('Araç: ${arac.plaka}', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
                ),
                SizedBox(
                  height: 400,
                  // --- DEĞİŞİKLİK BURADA BAŞLIYOR ---
                  // DataTable2'yi Material widget'ı ile sarmalıyoruz.
                  child: Material(
                    // Arka plan renginin Cupertino temasıyla uyumlu olmasını sağlıyoruz.
                    color: Colors.transparent,
                    child: DataTable2(
                      columnSpacing: 12, horizontalMargin: 12, minWidth: 600,
                      columns: [
                        DataColumn2(label: Text('Tarih'), size: ColumnSize.L),
                        DataColumn2(label: Text('Gün Başı'), numeric: true),
                        DataColumn2(label: Text('Gün Sonu'), numeric: true),
                        DataColumn2(label: Text('Yapılan KM'), numeric: true),
                        DataColumn2(label: Text('Güzergah'), size: ColumnSize.L),
                      ],
                      rows: dataRows.map((row) {
                        return DataRow(cells: [
                          DataCell(Text(row[0].toString())),
                          DataCell(Text(row[1].toString())),
                          DataCell(Text(row[2].toString())),
                          DataCell(Text(row[3].toString())),
                          DataCell(Text(row[4].toString())),
                        ]);
                      }).toList(),
                    ),
                  ),
                  // --- DEĞİŞİKLİK BURADA BİTİYOR ---
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Mevcut TablolarPage ve State'ini bununla değiştirin.

class TablolarPage extends StatefulWidget {
  @override
  _TablolarPageState createState() => _TablolarPageState();
}

class _TablolarPageState extends State<TablolarPage> {
  List<File> _savedFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedReports();
  }

  Future<void> _loadSavedReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      setState(() {
        _savedFiles = files
            .where((file) => file.path.endsWith('.xlsx'))
            .map((file) => File(file.path))
            // Dosyaları oluşturulma tarihine göre en yeniden eskiye doğru sırala
            .toList()
              ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
       showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
        title: Text('Hata'),
        content: Text('Kaydedilmiş raporlar okunurken bir sorun oluştu.'),
        actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('Tamam'), onPressed: () => Navigator.of(context).pop())],
      ));
    }
  }

  Future<void> _openFile(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
        title: Text('Dosya Açılamadı'),
        content: Text('Bu dosyayı açacak bir uygulama bulunamadı.\n\nHata: ${result.message}'),
        actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('Tamam'), onPressed: () => Navigator.of(context).pop())],
      ));
    }
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      // SnackBar yerine daha geçici bir Cupertino bildirimi kullanalım.
      // Ya da direkt listeyi yenileyelim. Kullanıcı silindiğini görecektir.
      _loadSavedReports();
    } catch (e) {
      showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
        title: Text('Hata'),
        content: Text('Dosya silinirken bir sorun oluştu.'),
        actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('Tamam'), onPressed: () => Navigator.of(context).pop())],
      ));
    }
  }
  
  String _getFileName(String path) {
    return path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold -> CupertinoPageScaffold
    return CupertinoPageScaffold(
      // AppBar -> CupertinoNavigationBar
      navigationBar: CupertinoNavigationBar(
        middle: Text("Kaydedilmiş Raporlar"),
        // actions -> trailing
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.refresh),
          onPressed: _loadSavedReports,
        ),
      ),
      child: _isLoading
          // CircularProgressIndicator -> CupertinoActivityIndicator
          ? Center(child: CupertinoActivityIndicator(radius: 15))
          : _savedFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.folder_open, size: 60, color: CupertinoColors.secondaryLabel),
                      SizedBox(height: 16),
                      Text(
                        "Henüz kaydedilmiş bir rapor bulunmuyor.",
                        style: CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _savedFiles.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
                  itemBuilder: (context, index) {
                    final file = _savedFiles[index];
                    final fileName = _getFileName(file.path);

                    return Dismissible(
                      key: Key(fileName),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteFile(file);
                      },
                      background: Container(
                        color: CupertinoColors.systemRed,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Icon(CupertinoIcons.delete_solid, color: CupertinoColors.white),
                      ),
                      // ListTile yerine özel bir yapı kullanıyoruz
                      child: GestureDetector(
                        onTap: () => _openFile(file.path),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.doc_chart_fill, color: CupertinoColors.systemTeal),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(fileName, style: CupertinoTheme.of(context).textTheme.textStyle, maxLines: 1, overflow: TextOverflow.ellipsis,),
                                    SizedBox(height: 2),
                                    Text("Oluşturulma: ${DateFormat.yMd('tr_TR').add_Hm().format(file.lastModifiedSync())}", style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(CupertinoIcons.right_chevron, color: CupertinoColors.tertiaryLabel),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// Mevcut GuzergahAyarPage ve State'ini bununla değiştir.

class GuzergahAyarPage extends StatefulWidget {
  @override
  _GuzergahAyarPageState createState() => _GuzergahAyarPageState();
}

class _GuzergahAyarPageState extends State<GuzergahAyarPage> {
  List<String> guzergahlar = [];
  final TextEditingController guzergahEkleController = TextEditingController();
  String? _duzenlenenGuzergah;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      guzergahlar = prefs.getStringList('guzergahlar') ?? [];
    });
  }

  Future<void> _kaydetVeyaGuncelle() async {
    final yeniGuzergahAdi = guzergahEkleController.text.trim();
    if (yeniGuzergahAdi.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    if (_duzenlenenGuzergah != null) {
      if (guzergahlar.contains(yeniGuzergahAdi) && yeniGuzergahAdi != _duzenlenenGuzergah) {
        // Cupertino stili uyarı
        showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
          title: Text('Hata'),
          content: Text('Bu güzergah adı zaten mevcut.'),
          actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('Tamam'), onPressed: () => Navigator.of(context).pop())],
        ));
        return;
      }

      final List<String> aracJsonList = prefs.getStringList('araclar') ?? [];
      List<AracModel> araclar = aracJsonList.map((e) => AracModel.fromJson(e)).toList();

      for (int i = 0; i < araclar.length; i++) {
        if (araclar[i].guzergah == _duzenlenenGuzergah) {
          araclar[i] = AracModel(
              plaka: araclar[i].plaka,
              guzergah: yeniGuzergahAdi,
              gunBasiKm: araclar[i].gunBasiKm,
              kmAralik: araclar[i].kmAralik,
              haftasonuDurumu: araclar[i].haftasonuDurumu);
        }
      }
      await prefs.setStringList('araclar', araclar.map((e) => e.toJson()).toList());
      
      final index = guzergahlar.indexOf(_duzenlenenGuzergah!);
      if (index != -1) {
        setState(() {
          guzergahlar[index] = yeniGuzergahAdi;
        });
      }

    } else {
      if (guzergahlar.contains(yeniGuzergahAdi)) {
        showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
          title: Text('Hata'),
          content: Text('Bu güzergah adı zaten mevcut.'),
          actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('Tamam'), onPressed: () => Navigator.of(context).pop())],
        ));
        return;
      }
      setState(() {
        guzergahlar.add(yeniGuzergahAdi);
      });
    }

    await prefs.setStringList('guzergahlar', guzergahlar);
    setState(() {
      guzergahEkleController.clear();
      _duzenlenenGuzergah = null;
    });
  }
  
  void _duzenlemeModunuBaslat(String guzergah) {
    setState(() {
      _duzenlenenGuzergah = guzergah;
      guzergahEkleController.text = guzergah;
    });
  }

  Future<void> _sil(String guzergahToDelete) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> aracJsonList = prefs.getStringList('araclar') ?? [];
    final List<AracModel> araclar = aracJsonList.map((e) => AracModel.fromJson(e)).toList();
    final bool isRouteInUse = araclar.any((arac) => arac.guzergah == guzergahToDelete);

    if (isRouteInUse) {
      showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
          title: Text('Silinemez'),
          content: Text('Bu güzergah bir veya daha fazla araç tarafından kullanıldığı için silinemez.'),
          actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('Anladım'), onPressed: () => Navigator.of(context).pop())],
        ));
    } else {
      // Silme işlemi için onay alalım
      showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
          title: Text('Güzergahı Sil'),
          content: Text('"$guzergahToDelete" güzergahını silmek istediğinizden emin misiniz?'),
          actions: [
            CupertinoDialogAction(child: Text('İptal'), onPressed: () => Navigator.of(context).pop()),
            CupertinoDialogAction(isDestructiveAction: true, child: Text('Sil'), onPressed: () {
              Navigator.of(context).pop(); // Diyaloğu kapat
              setState(() {
                guzergahlar.remove(guzergahToDelete);
              });
              prefs.setStringList('guzergahlar', guzergahlar);
            }),
          ],
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold -> CupertinoPageScaffold
    return CupertinoPageScaffold(
      // AppBar -> CupertinoNavigationBar
      navigationBar: CupertinoNavigationBar(
        middle: Text('Güzergah Ayarları'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoTextField(
                controller: guzergahEkleController,
                placeholder: _duzenlenenGuzergah == null ? 'Yeni Güzergah Ekle' : 'Güzergahı Düzenle',
                // Butonu suffix (son ek) olarak ekliyoruz
                suffix: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(_duzenlenenGuzergah == null ? CupertinoIcons.add_circled_solid : CupertinoIcons.check_mark_circled_solid),
                  onPressed: _kaydetVeyaGuncelle,
                ),
              ),
            ),
            // ListView'i Expanded ile sarmalayarak kalan tüm alanı kaplamasını sağlıyoruz
            Expanded(
              child: ListView.separated(
                itemCount: guzergahlar.length,
                separatorBuilder: (context, index) => Divider(height: 1), // Her eleman arasına çizgi
                itemBuilder: (context, index) {
                  final guzergah = guzergahlar[index];
                  // ListTile yerine daha sade bir yapı
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(guzergah, style: CupertinoTheme.of(context).textTheme.textStyle),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Icon(CupertinoIcons.pencil),
                              onPressed: () => _duzenlemeModunuBaslat(guzergah),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Icon(CupertinoIcons.trash, color: CupertinoColors.systemRed),
                              onPressed: () => _sil(guzergah),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}