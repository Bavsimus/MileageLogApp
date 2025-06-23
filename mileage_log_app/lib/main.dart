import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:data_table_2/data_table_2.dart'; // Yeni eklendi
import 'package:share_plus/share_plus.dart';    // Yeni eklendi
import 'dart:io';
import 'dart:convert';
import 'dart:math';

// Ana uygulama ve veri modelleri aynı kalıyor...

void main() => runApp(MileageLogApp());

class MileageLogApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mileage Log App',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: NavigationRoot(),
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


// --- Tablo Oluşturma Sayfası Güncellendi ---
class TabloOlusturPage extends StatefulWidget {
  @override
  _TabloOlusturPageState createState() => _TabloOlusturPageState();
}

class _TabloOlusturPageState extends State<TabloOlusturPage> {
  List<AracModel> tumAraclar = [];
  Set<int> seciliIndexler = {};

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

  // YENİ METOT: Veriyi hesaplar ve önizleme ekranına yönlendirir.
  // _TabloOlusturPageState sınıfının içindeki mevcut metodu bununla değiştirin.
void _raporOlusturVeGoruntule() {
    final seciliAraclar = seciliIndexler.map((i) => tumAraclar[i]).toList();
    if (seciliAraclar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lütfen en az bir araç seçin.")));
      return;
    }

    final Map<AracModel, List<List<dynamic>>> raporVerisi = {};
    final now = DateTime.now();

    for (final arac in seciliAraclar) {
      final List<List<dynamic>> aracSatirlari = [];

      // --- DÜZELTME BURADA YAPILDI: KM Aralığı formatı daha güvenli hale getirildi ---
      final kmAralikParts = arac.kmAralik.split('-');
      int kmMin = 0;
      int kmMax = 0;

      // İlk değeri al
      if (kmAralikParts.isNotEmpty) {
        kmMin = int.tryParse(kmAralikParts[0].trim()) ?? 0;
      }

      // Eğer ikinci bir değer varsa onu max olarak al, yoksa min değerini max olarak da kullan.
      if (kmAralikParts.length > 1) {
        kmMax = int.tryParse(kmAralikParts[1].trim()) ?? 0;
      } else {
        kmMax = kmMin;
      }
      
      // Kullanıcı yanlışlıkla 100-90 gibi girerse diye kontrol
      if (kmMin > kmMax) {
        final temp = kmMin;
        kmMin = kmMax;
        kmMax = temp;
      }
      // --- DÜZELTME SONU ---

      double baslangicKm = arac.gunBasiKm;
      final gunSayisi = DateTime(now.year, now.month + 1, 0).day;

      for (int day = 1; day <= gunSayisi; day++) {
        final tarih = DateTime(now.year, now.month, day);
        if (tarih.weekday >= 6 && arac.haftasonuDurumu == 'Çalışmıyor') {
          continue;
        }

        // Eğer min ve max aynıysa, yapılan km sabit olur. Farklıysa aralarından rastgele seçer.
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
      appBar: AppBar(title: Text("Tablo Oluştur")),
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
            padding: const EdgeInsets.all(8.0),
            // Butonun işlevi değiştirildi
            child: ElevatedButton(
                onPressed: _raporOlusturVeGoruntule,
                child: Text("Seçili Araçlar İçin Rapor Oluştur ve Görüntüle")),
          ),
        ],
      ),
    );
  }
}

// --- YENİ EKRAN: Rapor Önizleme Sayfası ---
// Lütfen projenizdeki mevcut RaporOnizlemePage sınıfını bununla değiştirin.

class RaporOnizlemePage extends StatelessWidget {
  final Map<AracModel, List<List<dynamic>>> raporVerisi;

  const RaporOnizlemePage({Key? key, required this.raporVerisi}) : super(key: key);

  Future<void> _paylas(BuildContext context) async {
    final excel = Excel.createExcel();

    for (var entry in raporVerisi.entries) {
      final arac = entry.key;
      final veriler = entry.value;
      final sheet = excel['${arac.plaka.replaceAll(' ', '_')}']; 
      
      sheet.appendRow([
        TextCellValue('Tarih'),
        TextCellValue('Gün Başı'),
        TextCellValue('Gün Sonu'),
        TextCellValue('Yapılan KM'),
        TextCellValue('Güzergah')
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
    final fileName = 'AracRaporu_${now.month}_${now.year}.xlsx';
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/$fileName';

    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final file = File(path);
      await file.writeAsBytes(fileBytes);
      
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
            icon: Icon(Icons.share),
            onPressed: () => _paylas(context),
            tooltip: 'Excel Olarak Paylaş',
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
                  Text(
                    'Araç: ${arac.plaka}', 
                    // --- DÜZELTME BURADA YAPILDI ---
                    style: Theme.of(context).textTheme.titleLarge, 
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 400,
                    child: DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      minWidth: 600,
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

// Diğer sayfalar (AraclarPage, GuzergahAyarPage, NavigationRoot) aynı kalabilir.
// Okunabilirlik için aşağıya tekrar ekliyorum.

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
       seciliGuzergah = arac.guzergah;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${arac.plaka} plakalı aracı düzenliyorsunuz.'))
      );
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

class GuzergahAyarPage extends StatefulWidget {
  @override
  _GuzergahAyarPageState createState() => _GuzergahAyarPageState();
}

class _GuzergahAyarPageState extends State<GuzergahAyarPage> {
  List<String> guzergahlar = [];
  final TextEditingController guzergahEkleController = TextEditingController();

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

  Future<void> _ekle(String g) async {
    if (g.isEmpty || guzergahlar.contains(g)) return;
    
    setState(() {
      guzergahlar.add(g);
      guzergahEkleController.clear();
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('guzergahlar', guzergahlar);
  }

  Future<void> _sil(String g) async {
    setState(() {
      guzergahlar.remove(g);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('guzergahlar', guzergahlar);
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
                labelText: 'Yeni Güzergah',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _ekle(guzergahEkleController.text.trim()),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: guzergahlar.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(guzergahlar[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _sil(guzergahlar[index]),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}


class NavigationRoot extends StatefulWidget {
  @override
  _NavigationRootState createState() => _NavigationRootState();
}

class _NavigationRootState extends State<NavigationRoot> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    AraclarPage(),
    TabloOlusturPage(),
    GuzergahAyarPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_car), label: 'Araçlar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.description), label: 'Tablo'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Güzergah'),
        ],
      ),
    );
  }
}