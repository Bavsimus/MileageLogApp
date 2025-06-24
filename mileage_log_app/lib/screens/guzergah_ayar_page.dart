import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/arac_model.dart';

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
      showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
          title: Text('Güzergahı Sil'),
          content: Text('"$guzergahToDelete" güzergahını silmek istediğinizden emin misiniz?'),
          actions: [
            CupertinoDialogAction(child: Text('İptal'), onPressed: () => Navigator.of(context).pop()),
            CupertinoDialogAction(isDestructiveAction: true, child: Text('Sil'), onPressed: () {
              Navigator.of(context).pop();
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Güzergah Ayarları'),
      ),
      // SafeArea ekleyerek içeriğin başlığın altında kalmasını engelliyoruz
      child: SafeArea(
        top: true, // Üstten boşluk bırak
        bottom: false, // Alt boşluk ana TabBar tarafından yönetiliyor
        child: Column(
          children: [
            Padding(
              // EdgeInsets.fromLTRB ile boşlukları tek tek kontrol ediyoruz
              // Üst boşluğu kaldırdık, çünkü SafeArea zaten boşluk bırakıyor.
              // Alt boşluğu azalttık.
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: CupertinoTextField(
                controller: guzergahEkleController,
                placeholder: _duzenlenenGuzergah == null ? 'Yeni Güzergah Ekle' : 'Güzergahı Düzenle',
                suffix: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(_duzenlenenGuzergah == null ? CupertinoIcons.add_circled_solid : CupertinoIcons.check_mark_circled_solid),
                  onPressed: _kaydetVeyaGuncelle,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: guzergahlar.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final guzergah = guzergahlar[index];
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
