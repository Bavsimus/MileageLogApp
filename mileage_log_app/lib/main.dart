import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
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

  // Sayfalarımız aynı
  final List<Widget> _pages = [
    AraclarPage(),
    TabloOlusturPage(),
    TablolarPage(),
    GuzergahAyarPage(),
  ];

  // _NavigationRootState sınıfının içindeki mevcut build metodunu bununla değiştirin.
@override
Widget build(BuildContext context) {
  // CupertinoPageScaffold, sayfanın genel arkaplanını ve üst barını yönetir.
  return CupertinoPageScaffold(
    // Arka plan rengini belirliyoruz. Bu, sistemin temasına göre (açık/koyu)
    // uygun bir arkaplan rengi seçer. Beyaz şeritleri bu renk dolduracak.
    backgroundColor: CupertinoTheme.of(context).scaffoldBackgroundColor,

    // Dışarıdaki SafeArea'yı kaldırdık.
    // İçerik artık doğrudan Scaffold'un çocuğu.
    child: Column(
      children: [
        // Sayfaların görüneceği ve kaydırılacağı alan
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
        // Alttaki navigasyon barımız
        // CupertinoTabBar, alttaki sistem çubuğu için gerekli boşluğu genellikle
        // kendisi otomatik olarak ayarlar.
        CupertinoTabBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.car_detailed), label: 'Araçlar'),
            BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.add_circled), label: 'Tablo Oluştur'),
            BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.folder_fill), label: 'Tablolar'),
            BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.map_fill), label: 'Güzergah'),
            ],
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lütfen tüm alanları doldurun.')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Araçlar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
                controller: plakaController,
                decoration: InputDecoration(labelText: 'Plaka')),
            TextField(
                controller: kmBaslangicController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Gün Başı KM')),
            TextField(
                controller: kmAralikController,
                decoration:
                    InputDecoration(labelText: 'KM Aralığı (örn: 90-100)')),
            DropdownButton<String>(
              value: haftasonuDurumu,
              isExpanded: true,
              onChanged: (val) => setState(() => haftasonuDurumu = val!),
              items: ['Çalışıyor', 'Çalışmıyor']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
            if (guzergahlar.isNotEmpty)
              DropdownButton<String>(
                value: seciliGuzergah,
                isExpanded: true,
                onChanged: (val) => setState(() => seciliGuzergah = val!),
                items: guzergahlar
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text("Lütfen önce Güzergah sekmesinden bir güzergah ekleyin.", style: TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
                onPressed: _saveOrUpdateArac, 
                child: Text(_duzenlenenIndex == null ? 'Kaydet' : 'Güncelle')
            ),
            Divider(),
            ...araclar.asMap().entries.map((entry) {
              final index = entry.key;
              final a = entry.value;
              return ListTile(
                title: Text(a.plaka),
                subtitle: Text(
                    '${a.gunBasiKm} km - ${a.kmAralik} - ${a.haftasonuDurumu}\n${a.guzergah}'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editArac(index),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

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

  Future<void> _aySeciciGoster(BuildContext context) async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: _seciliTarih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      locale: const Locale('tr', 'TR'),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (secilen != null && secilen != _seciliTarih) {
      setState(() {
        _seciliTarih = secilen;
      });
    }
  }

  void _raporOlusturVeGoruntule(DateTime secilenAy) {
    final seciliAraclar = seciliIndexler.map((i) => tumAraclar[i]).toList();
    if (seciliAraclar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lütfen en az bir araç seçin.")));
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
      MaterialPageRoute(
        builder: (context) => RaporOnizlemePage(raporVerisi: raporVerisi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rapor Oluştur")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: tumAraclar.length,
              itemBuilder: (context, index) {
                final arac = tumAraclar[index];
                return CheckboxListTile(
                  value: seciliIndexler.contains(index),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        seciliIndexler.add(index);
                      } else {
                        seciliIndexler.remove(index);
                      }
                    });
                  },
                  title: Text(arac.plaka),
                  subtitle: Text(
                      '${arac.kmAralik} | ${arac.haftasonuDurumu} | ${arac.guzergah}'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Rapor Ayı Seçimi:", style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: Icon(Icons.calendar_today),
                  label: Text(
                    DateFormat.yMMMM('tr_TR').format(_seciliTarih),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _aySeciciGoster(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
                onPressed: () => _raporOlusturVeGoruntule(_seciliTarih),
                child: Text("Rapor Oluştur"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 144),
                ),
            ),
          ),
        ],
      ),
    );
  }
}

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

    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    setState(() {
      _savedFiles = files
          .where((file) => file.path.endsWith('.xlsx'))
          .map((file) => File(file.path))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _openFile(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bu dosyayı açacak bir uygulama bulunamadı: ${result.message}')),
      );
    }
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_getFileName(file.path)} silindi.')),
      );
      _loadSavedReports();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya silinirken bir hata oluştu.')),
      );
    }
  }
  
  String _getFileName(String path) {
    return path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kaydedilmiş Raporlar"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSavedReports,
            tooltip: 'Listeyi Yenile',
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _savedFiles.isEmpty
              ? Center(
                  child: Text(
                    "Henüz kaydedilmiş bir rapor bulunmuyor.",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: _savedFiles.length,
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
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.description, color: Theme.of(context).primaryColor),
                        title: Text(fileName),
                        subtitle: Text("Açmak için dokunun, silmek için sola kaydırın."),
                        onTap: () => _openFile(file.path),
                      ),
                    );
                  },
                ),
    );
  }
}

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bu güzergah adı zaten mevcut.'), backgroundColor: Colors.red));
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
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bu güzergah adı zaten mevcut.'), backgroundColor: Colors.red));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bu güzergah bir araç tarafından kullanıldığı için silinemez.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      setState(() {
        guzergahlar.remove(guzergahToDelete);
      });
      await prefs.setStringList('guzergahlar', guzergahlar);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$guzergahToDelete" güzergahı silindi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Güzergah Ayarları')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: guzergahEkleController,
              decoration: InputDecoration(
                labelText: _duzenlenenGuzergah == null ? 'Yeni Güzergah' : 'Güzergahı Düzenle',
                suffixIcon: IconButton(
                  icon: Icon(_duzenlenenGuzergah == null ? Icons.add : Icons.check),
                  onPressed: _kaydetVeyaGuncelle,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: guzergahlar.length,
                itemBuilder: (context, index) {
                  final guzergah = guzergahlar[index];
                  return ListTile(
                    title: Text(guzergah),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                          onPressed: () => _duzenlemeModunuBaslat(guzergah),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _sil(guzergah),
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Rapor Önizleme"),
        actions: [
          IconButton(
            icon: Icon(Icons.save_alt),
            onPressed: () => _kaydetVePaylas(context),
            tooltip: 'Kaydet ve Paylaş',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: raporVerisi.keys.length,
        itemBuilder: (context, index) {
          final arac = raporVerisi.keys.elementAt(index);
          final dataRows = raporVerisi[arac]!;

          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Araç: ${arac.plaka}', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 400,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}