import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

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

class AraclarPage extends StatefulWidget {
  @override
  _AraclarPageState createState() => _AraclarPageState();
}

class _AraclarPageState extends State<AraclarPage> {
  List<String> guzergahlar = [];
  List<AracModel> araclar = [];

  final TextEditingController plakaController = TextEditingController();
  final TextEditingController kmBaslangicController = TextEditingController();
  final TextEditingController kmAralikController = TextEditingController();
  String seciliGuzergah = '';
  String haftasonuDurumu = 'Çalışıyor';

  @override
  void initState() {
    super.initState();
    _loadGuzergahlar();
    _loadAraclar();
  }

  Future<void> _loadGuzergahlar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      guzergahlar = prefs.getStringList('guzergahlar') ?? [];
      if (guzergahlar.isNotEmpty) seciliGuzergah = guzergahlar.first;
    });
  }

  Future<void> _loadAraclar() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> aracJsonList = prefs.getStringList('araclar') ?? [];
    setState(() {
      araclar = aracJsonList.map((e) => AracModel.fromJson(e)).toList();
    });
  }

  Future<void> _saveArac() async {
    if (plakaController.text.isEmpty ||
        kmBaslangicController.text.isEmpty ||
        kmAralikController.text.isEmpty ||
        seciliGuzergah.isEmpty) return;

    final yeniArac = AracModel(
      plaka: plakaController.text.trim(),
      guzergah: seciliGuzergah,
      gunBasiKm: double.tryParse(kmBaslangicController.text.trim()) ?? 0,
      kmAralik: kmAralikController.text.trim(),
      haftasonuDurumu: haftasonuDurumu,
    );

    final prefs = await SharedPreferences.getInstance();
    araclar.add(yeniArac);
    final jsonList = araclar.map((e) => e.toJson()).toList();
    await prefs.setStringList('araclar', jsonList);

    plakaController.clear();
    kmBaslangicController.clear();
    kmAralikController.clear();

    _loadAraclar();
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
            DropdownButton<String>(
              value: seciliGuzergah,
              isExpanded: true,
              onChanged: (val) => setState(() => seciliGuzergah = val!),
              items: guzergahlar
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
            ElevatedButton(onPressed: _saveArac, child: Text('Kaydet')),
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
                  onPressed: () async {
                    plakaController.text = a.plaka;
                    kmBaslangicController.text = a.gunBasiKm.toString();
                    kmAralikController.text = a.kmAralik;
                    haftasonuDurumu = a.haftasonuDurumu;
                    seciliGuzergah = a.guzergah;
                    setState(() {});
                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Araç Güncelle'),
                        content: Text(
                            'Değişiklikleri yaptıktan sonra tekrar Kaydet\'e basın.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Tamam'))
                        ],
                      ),
                    );
                    araclar.removeAt(index);
                    final prefs = await SharedPreferences.getInstance();
                    final jsonList = araclar.map((e) => e.toJson()).toList();
                    await prefs.setStringList('araclar', jsonList);
                  },
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

  Future<void> _excelOlustur() async {
    if (Platform.isAndroid) {
      if (!await Permission.storage.isGranted) {
        await Permission.storage.request();
      }
      if (!await Permission.storage.isGranted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Depolama izni gerekli.")));
        return;
      }
    }

    final seciliAraclar = seciliIndexler.map((i) => tumAraclar[i]).toList();
    if (seciliAraclar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lütfen en az bir araç seçin.")));
      return;
    }

    final excel = Excel.createExcel();
    final now = DateTime.now();
    final sheet = excel['${now.month}_${now.year}'];
    int currentRow = 0;

    for (final arac in seciliAraclar) {
      final kmAralik = arac.kmAralik.split('-');
      final kmMin = int.tryParse(kmAralik[0]) ?? 0;
      final kmMax = int.tryParse(kmAralik[1]) ?? 0;
      double baslangicKm = arac.gunBasiKm;
      final gunSayisi = DateTime(now.year, now.month + 1, 0).day;

      sheet
          .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = 'Tarih';
      sheet
          .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = 'Gün Başı';
      sheet
          .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
          .value = 'Gün Sonu';
      sheet
          .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow))
          .value = 'Yapılan KM';
      sheet
          .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow))
          .value = 'Güzergah';
      sheet
          .cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow))
          .value = 'Araç: ${arac.plaka}';
      currentRow++;

      for (int day = 1; day <= gunSayisi; day++) {
        final tarih = DateTime(now.year, now.month, day);
        if (tarih.weekday >= 6 && arac.haftasonuDurumu == 'Çalışmıyor') {
          currentRow++;
          continue;
        }

        final yapilanKm = Random().nextInt(kmMax - kmMin + 1) + kmMin;
        final gunSonuKm = baslangicKm + yapilanKm;

        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: currentRow))
            .value = '${tarih.day}.${tarih.month}.${tarih.year}';
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 1, rowIndex: currentRow))
            .value = baslangicKm;
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 2, rowIndex: currentRow))
            .value = gunSonuKm;
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 3, rowIndex: currentRow))
            .value = yapilanKm;
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 4, rowIndex: currentRow))
            .value = arac.guzergah;

        baslangicKm = gunSonuKm;
        currentRow++;
      }

      currentRow += 2;
    }

    final downloadDir = Directory('/storage/emulated/0/Download');
    final path = '${downloadDir.path}/AracRaporu_${now.month}_${now.year}.xlsx';
    final file = File(path);
    await file.writeAsBytes(excel.encode()!);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Dosya oluşturuldu: $path")));
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
          ElevatedButton(
              onPressed: _excelOlustur, child: Text("Excel Oluştur")),
        ],
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
    final prefs = await SharedPreferences.getInstance();
    guzergahlar.add(g);
    await prefs.setStringList('guzergahlar', guzergahlar);
    guzergahEkleController.clear();
    _load();
  }

  Future<void> _sil(String g) async {
    final prefs = await SharedPreferences.getInstance();
    guzergahlar.remove(g);
    await prefs.setStringList('guzergahlar', guzergahlar);
    _load();
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
