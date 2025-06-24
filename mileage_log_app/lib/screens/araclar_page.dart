import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/arac_model.dart';
import '../widgets/arac_karti.dart';
import '../widgets/custom_cupertino_list_tile.dart';

class AraclarPage extends StatefulWidget {
  const AraclarPage({super.key});

  @override
  _AraclarPageState createState() => _AraclarPageState();
}

class _AraclarPageState extends State<AraclarPage> {
  // ... Bu sınıfın içindeki tüm metotlar aynı kalıyor ...
  List<String> guzergahlar = [];
  List<AracModel> araclar = [];
  int? _duzenlenenIndex;

  final TextEditingController plakaController = TextEditingController();
  final TextEditingController kmBaslangicController = TextEditingController();
  final TextEditingController kmAralikController = TextEditingController();
  String seciliGuzergah = '';
  String haftasonuDurumu = 'Çalışıyor';
  final List<String> _markalar = [
    'Mercedes',
    'Ford',
    'Fiat',
    'Renault',
    'Volkswagen',
    'Peugeot',
    'Diğer',
  ];
  String seciliMarka = 'Mercedes';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadGuzergahlar();
    await _loadAraclar();
  }

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
        if (seciliGuzergah.isEmpty || !guzergahlar.contains(seciliGuzergah)) {
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
        (guzergahlar.isNotEmpty && seciliGuzergah.isEmpty)) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Eksik Bilgi'),
          content: const Text('Lütfen tüm alanları doldurun.'),
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

    // Pop-up mesajını belirlemek için işlem türünü saklayalım
    final bool isUpdating = _duzenlenenIndex != null;

    final arac = AracModel(
      plaka: plakaController.text.trim(),
      guzergah: seciliGuzergah,
      gunBasiKm: double.tryParse(kmBaslangicController.text.trim()) ?? 0,
      kmAralik: kmAralikController.text.trim(),
      haftasonuDurumu: haftasonuDurumu,
      marka: seciliMarka,
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

    await _saveAracList();

    if (mounted) {
      // Widget'ın hala ekranda olduğundan emin ol
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            isUpdating ? 'Başarıyla Güncellendi' : 'Başarıyla Kaydedildi',
          ),
          content: Text(
            isUpdating
                ? 'Araç bilgileri güncellendi.'
                : 'Yeni araç başarıyla eklendi.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  void _editArac(int index) {
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
            const SnackBar(
              content: Text(
                'Aracın eski güzergahı bulunamadı. Lütfen yeni bir tane seçin.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        });
      }
    });
  }

  Future<void> _aracSil(int index) async {
    final arac = araclar[index];
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Aracı Sil'),
        content: Text(
          '"${arac.plaka}" plakalı aracı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Sil'),
            onPressed: () {
              setState(() {
                araclar.removeAt(index);
              });
              _saveAracList();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showPicker(
    BuildContext context,
    List<String> items,
    String currentValue,
    ValueChanged<String> onChanged,
  ) {
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
            scrollController: FixedExtentScrollController(
              initialItem: selectedIndex > -1 ? selectedIndex : 0,
            ),
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
    // CupertinoPageScaffold, içeriğin üst ve alt barların arkasında kalmaması için
    // otomatik olarak bir padding uygular. Bu padding'i alıyoruz.
    final EdgeInsets mediaQueryPadding = MediaQuery.of(context).padding;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Araçlarım')),
      child: SafeArea(
        // SafeArea'yı kullanmak, içeriğin her zaman görünür alanda kalmasını garantiler.
        // top: false, çünkü NavigationBar zaten üst boşluğu yönetiyor.
        top: false,
        child: ListView(
          // DEĞİŞİKLİK BURADA:
          // Artık sabit bir padding vermek yerine, sayfanın kendi padding'ini
          // bizim istediğimiz boşluklarla birleştiriyoruz.
          padding: EdgeInsets.fromLTRB(
            16, // Sol boşluk
            100, // Üst boşluk
            16, // Sağ boşluk
            mediaQueryPadding.bottom +
                16, // Telefonun alt sistem boşluğu + kendi boşluğumuz
          ),
          children: [
            // ... sayfanın geri kalan içeriği tamamen aynı ...
            CupertinoTextField(
              controller: plakaController,
              placeholder: 'Plaka',
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: kmBaslangicController,
              keyboardType: TextInputType.number,
              placeholder: 'Gün Başı KM',
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: kmAralikController,
              placeholder: 'KM Aralığı (örn: 90-100)',
            ),
            const SizedBox(height: 16),
            CustomCupertinoListTile(
              title: const Text('Marka'),
              additionalInfo: Text(seciliMarka),
              onTap: () {
                _showPicker(context, _markalar, seciliMarka, (newValue) {
                  setState(() => seciliMarka = newValue);
                });
              },
            ),
            const Divider(height: 1),
            CustomCupertinoListTile(
              title: const Text('Hafta Sonu Durumu'),
              additionalInfo: Text(haftasonuDurumu),
              onTap: () {
                _showPicker(
                  context,
                  ['Çalışıyor', 'Çalışmıyor'],
                  haftasonuDurumu,
                  (newValue) {
                    setState(() => haftasonuDurumu = newValue);
                  },
                );
              },
            ),
            const Divider(height: 1),
            if (guzergahlar.isNotEmpty)
              CustomCupertinoListTile(
                title: const Text('Güzergah'),
                additionalInfo: Text(seciliGuzergah),
                onTap: () {
                  _showPicker(context, guzergahlar, seciliGuzergah, (newValue) {
                    setState(() => seciliGuzergah = newValue);
                  });
                },
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  "Önce bir güzergah ekleyin.",
                  style: TextStyle(color: CupertinoColors.systemRed),
                ),
              ),
            const SizedBox(height: 15),
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(16.0),
              onPressed: _saveOrUpdateArac,
              child: Text(_duzenlenenIndex == null ? 'Kaydet' : 'Güncelle'),
            ),
            const SizedBox(height: 30),
            Text(
              'Kayıtlı Araçlar',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: 1),
            if (araclar.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        CupertinoIcons.car_detailed,
                        size: 60,
                        color: CupertinoColors.secondaryLabel,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Henüz araç eklenmedi.',
                        style: CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: araclar.length,
                itemBuilder: (context, index) {
                  final a = araclar[index];
                  return AracKarti(
                    arac: a,
                    onEdit: () => _editArac(index),
                    onDelete: () => _aracSil(index),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
