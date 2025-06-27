import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/arac_model.dart';
import '../widgets/arac_karti.dart';
import '../widgets/custom_cupertino_list_tile.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/services.dart';

// --- YENİ WIDGET: Güzergah Yönetim Diyaloğu ---
class GuzergahYonetimDialog extends StatefulWidget {
  final List<String> initialGuzergahlar;
  final List<AracModel> aracListesi;

  const GuzergahYonetimDialog({
    Key? key,
    required this.initialGuzergahlar,
    required this.aracListesi,
  }) : super(key: key);

  @override
  _GuzergahYonetimDialogState createState() => _GuzergahYonetimDialogState();
}

class _GuzergahYonetimDialogState extends State<GuzergahYonetimDialog> {
  late List<String> guzergahlar;
  final TextEditingController textController = TextEditingController();
  String? _duzenlenenGuzergah;

  @override
  void initState() {
    super.initState();
    // Başlangıç değerini state'e kopyalıyoruz
    guzergahlar = List.from(widget.initialGuzergahlar);
  }

  Future<void> _saveGuzergahlar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('guzergahlar', guzergahlar);
  }

  void _kaydetVeyaGuncelle() {
    final yeniGuzergahAdi = textController.text.trim();
    if (yeniGuzergahAdi.isEmpty) return;

    if (_duzenlenenGuzergah != null) {
      // Güncelleme modu
      if (guzergahlar.contains(yeniGuzergahAdi) && yeniGuzergahAdi != _duzenlenenGuzergah) return; // Zaten var

      final index = guzergahlar.indexOf(_duzenlenenGuzergah!);
      if (index != -1) {
        setState(() {
          guzergahlar[index] = yeniGuzergahAdi;
        });
      }
    } else {
      // Ekleme modu
      if (guzergahlar.contains(yeniGuzergahAdi)) return; // Zaten var
      setState(() {
        guzergahlar.add(yeniGuzergahAdi);
      });
    }

    _saveGuzergahlar();
    textController.clear();
    setState(() {
      _duzenlenenGuzergah = null;
    });
  }

  void _sil(String guzergahToDelete) {
    final bool isRouteInUse = widget.aracListesi.any((arac) => arac.guzergah == guzergahToDelete);

    if (isRouteInUse) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Silinemez'),
          content: Text('Bu güzergah bir araç tarafından kullanıldığı için silinemez.'),
          actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('Anladım'), onPressed: () => Navigator.of(context).pop())],
        ),
      );
    } else {
      setState(() {
        guzergahlar.remove(guzergahToDelete);
      });
      _saveGuzergahlar();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Diyalog içeriğini oluşturan widget
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: CupertinoTextField(
              controller: textController,
              placeholder: _duzenlenenGuzergah == null ? 'Yeni Güzergah Ekle' : 'Güzergahı Düzenle',
              suffix: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(_duzenlenenGuzergah == null ? CupertinoIcons.add_circled : CupertinoIcons.check_mark),
                onPressed: _kaydetVeyaGuncelle,
              ),
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: guzergahlar.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final guzergah = guzergahlar[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(guzergah),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Icon(CupertinoIcons.trash, size: 20, color: CupertinoColors.systemRed),
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
    );
  }
}
class MarkaSecici extends StatelessWidget {
  final List<String> markalar;
  final String seciliMarka;
  final ValueChanged<String> onMarkaSecildi;
  final bool isEditing;

  const MarkaSecici({
    Key? key,
    required this.markalar,
    required this.seciliMarka,
    required this.onMarkaSecildi,
    required this.isEditing,
  }) : super(key: key);

  String _getLogoPathForMarka(String marka) {
    switch (marka.toLowerCase()) {
      case 'mercedes':
        return 'assets/mercedes_logo.png';
      case 'ford':
        return 'assets/ford_logo.png';
      case 'fiat':
        return 'assets/fiat_logo.png';
      case 'renault':
        return 'assets/renault_logo.png';
      case 'volkswagen':
        return 'assets/vw_logo.png';
      case 'peugeot':
        return 'assets/peugeot_logo.png';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isEditing 
        ? CupertinoColors.systemOrange 
        : CupertinoTheme.of(context).primaryColor;

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: markalar.length,
        itemBuilder: (context, index) {
          final marka = markalar[index];
          final isSelected = marka == seciliMarka;
          final logoPath = _getLogoPathForMarka(marka);

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact(); // Titreşim eklendi
              onMarkaSecildi(marka);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 90,
              margin: const EdgeInsets.symmetric(horizontal: 6.0),
              transform: isSelected ? (Matrix4.identity()..scale(1.01)) : Matrix4.identity(),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).barBackgroundColor,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : CupertinoColors.systemGrey5.resolveFrom(context),
                  width: isSelected ? 1.5 : 1.5,
                ),
              ),
              // --- DÜZELTME: Kaybolan içerik geri eklendi ---
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  logoPath.isEmpty
                      ? CircleAvatar(
                          radius: 26,
                          backgroundColor: CupertinoColors.systemGrey5.resolveFrom(context),
                          child: Icon(
                            CupertinoIcons.car_detailed,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                            size: 28,
                          ),
                        )
                      : Image.asset(
                          logoPath,
                          height: 52,
                          width: 52,
                          errorBuilder: (context, error, stackTrace) {
                             return CircleAvatar(
                                radius: 26,
                                backgroundColor: CupertinoColors.systemGrey5.resolveFrom(context),
                                child: Icon(
                                  CupertinoIcons.exclamationmark_triangle,
                                  color: CupertinoColors.systemRed,
                                  size: 28,
                                ),
                              );
                          },
                        ),
                  const SizedBox(height: 8),
                  Text(
                    marka,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? activeColor
                          : CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                    overflow: TextOverflow.ellipsis,
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

// --- HAFTA SONU DURUMU SEÇİM WIDGET'I ---
// --- HAFTA SONU DURUMU SEÇİM WIDGET'I ---
class HaftasonuSecici extends StatelessWidget {
  final String seciliDurum;
  final ValueChanged<String> onDurumSecildi;
  final bool isEditing;
  final List<String> durumlar = const ['Çalışıyor', 'Çalışmıyor'];

  const HaftasonuSecici({
    Key? key,
    required this.seciliDurum,
    required this.onDurumSecildi,
    required this.isEditing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isEditing 
        ? CupertinoColors.systemOrange 
        : CupertinoTheme.of(context).primaryColor;

    return Row(
      children: durumlar.map((durum) {
        final isSelected = durum == seciliDurum;
        final iconData = durum == 'Çalışıyor' 
            ? CupertinoIcons.sun_max_fill 
            : CupertinoIcons.moon_stars_fill;

        return Expanded(
          child: GestureDetector(
            onTap: () => onDurumSecildi(durum),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              transform: isSelected ? (Matrix4.identity()..scale(1.01)) : Matrix4.identity(),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).barBackgroundColor,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : CupertinoColors.systemGrey5.resolveFrom(context),
                  width: isSelected ? 1.5 : 1.5,
                ),
              ),
              // --- DÜZELTME: Kaybolan içerik geri eklendi ---
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    iconData,
                    size: 28,
                    color: isSelected
                        ? activeColor
                        : CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    durum,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? activeColor
                          : CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// --- GÜZERGAH SEÇİM WIDGET'I ---
class GuzergahSecici extends StatelessWidget {
  final List<String> guzergahlar;
  final String seciliGuzergah;
  final ValueChanged<String> onGuzergahSecildi;
  final bool isEditing;

  const GuzergahSecici({
    Key? key,
    required this.guzergahlar,
    required this.seciliGuzergah,
    required this.onGuzergahSecildi,
    required this.isEditing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isEditing 
        ? CupertinoColors.systemOrange 
        : CupertinoTheme.of(context).primaryColor;
        
    if (guzergahlar.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          'Lütfen önce güzergah ekleyin.',
          style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        controller: ScrollController(),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: guzergahlar.length,
        itemBuilder: (context, index) {
          final guzergah = guzergahlar[index];
          final isSelected = guzergah == seciliGuzergah;

          return GestureDetector(
            onTap: () => onGuzergahSecildi(guzergah),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 130,
              margin: const EdgeInsets.symmetric(horizontal: 6.0),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              transform: isSelected ? (Matrix4.identity()..scale(1.01)) : Matrix4.identity(),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).barBackgroundColor,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : CupertinoColors.systemGrey5.resolveFrom(context),
                  width: isSelected ? 1.5 : 1.5,
                ),
              ),
              // --- DÜZELTME: Kaybolan içerik geri eklendi ---
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.map_pin_ellipse,
                    size: 28,
                    color: isSelected
                        ? activeColor
                        : CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    guzergah,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? activeColor
                          : CupertinoTheme.of(context).textTheme.textStyle.color,
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


class AraclarPage extends StatefulWidget {
  @override
  _AraclarPageState createState() => _AraclarPageState();
}

class _AraclarPageState extends State<AraclarPage> {
  // ... diğer değişkenler ...
  List<String> guzergahlar = [];
  List<AracModel> araclar = [];
  int? _duzenlenenIndex;

  final TextEditingController plakaController = TextEditingController();
  final TextEditingController kmBaslangicController = TextEditingController();
  final TextEditingController kmAralikController = TextEditingController();
  String seciliGuzergah = '';
  String haftasonuDurumu = 'Çalışıyor';
  
  final List<String> _markalar = ['Mercedes', 'Ford', 'Fiat', 'Renault', 'Volkswagen', 'Peugeot', 'Diğer'];
  String seciliMarka = 'Mercedes';

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    seciliMarka = _markalar.first;
    _scrollController = ScrollController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    HapticFeedback.lightImpact();
    if (plakaController.text.isEmpty ||
        kmBaslangicController.text.isEmpty ||
        kmAralikController.text.isEmpty ||
        (guzergahlar.isNotEmpty && seciliGuzergah.isEmpty) ) {
          showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
            title: Text('Eksik Bilgi'),
            content: Text('Lütfen tüm alanları doldurun.'),
            actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('Tamam'), onPressed: () => Navigator.of(context).pop())],
          ));
          return;
        }

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
      if (isUpdating) {
        araclar[_duzenlenenIndex!] = arac;
      } else {
        araclar.add(arac);
      }
      _duzenlenenIndex = null;
      plakaController.clear();
      kmBaslangicController.clear();
      kmAralikController.clear();
      if (guzergahlar.isNotEmpty) seciliGuzergah = guzergahlar.first;
      if (_markalar.isNotEmpty) seciliMarka = _markalar.first;
    });

    await _saveAracList();

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(isUpdating ? 'Başarıyla Güncellendi' : 'Başarıyla Kaydedildi'),
          content: Text(isUpdating ? 'Araç bilgileri güncellendi.' : 'Yeni araç başarıyla eklendi.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        ),
      );
    }
  }
  
  void _editArac(int index){
    final arac = araclar[index];
    setState(() {
       _duzenlenenIndex = index;
       plakaController.text = arac.plaka;
       kmBaslangicController.text = arac.gunBasiKm.toString();
       kmAralikController.text = arac.kmAralik;
       haftasonuDurumu = arac.haftasonuDurumu;
       seciliMarka = arac.marka;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _cancelEditing() {
    HapticFeedback.lightImpact();
    setState(() {
      _duzenlenenIndex = null;
      plakaController.clear();
      kmBaslangicController.clear();
      kmAralikController.clear();
      if (guzergahlar.isNotEmpty) seciliGuzergah = guzergahlar.first;
      if (_markalar.isNotEmpty) seciliMarka = _markalar.first;
      haftasonuDurumu = 'Çalışıyor';
    });
  }

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
              _saveAracList();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context, List<String> items, String currentValue, ValueChanged<String> onChanged) {
    final selectedIndex = items.indexOf(currentValue);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        color: CupertinoColors.systemBackground,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            backgroundColor: CupertinoColors.tertiarySystemBackground,
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32.0,
            scrollController: FixedExtentScrollController(initialItem: selectedIndex > -1 ? selectedIndex : 0),
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

  // --- METOT GÜNCELLENDİ: Yeni ve güçlü diyaloğu gösterir ---
  Future<void> _guzergahYonetimDialogGoster() async {
    // Diyalog kapandığında güncellenmiş listeyi geri al
    await showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Güzergahları Yönet'),
          content: GuzergahYonetimDialog(
            initialGuzergahlar: guzergahlar,
            aracListesi: araclar,
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Bitti'),
              onPressed: () {
                Navigator.of(context).pop();
                // Diyalog kapandıktan sonra ana sayfadaki güzergah listesini yenile
                _loadGuzergahlar();
              },
            )
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: AnimationLimiter(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          children: [
            SizedBox(height: 40),
            AnimationConfiguration.staggeredList(
              position: 0,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 10.0,
                child: FadeInAnimation(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _duzenlenenIndex == null ? 'Yeni Araç' : 'Aracı Düzenle',
                        style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                      ),
                      Icon(
                        _duzenlenenIndex == null ? CupertinoIcons.add : CupertinoIcons.pencil_circle_fill,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Divider(height: 1, color: CupertinoColors.systemGrey5),
            SizedBox(height: 16),
            AnimationConfiguration.staggeredList(
              position: 1,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: CupertinoTheme.of(context).barBackgroundColor,
                      borderRadius: BorderRadius.circular(24.0),
                      border: _duzenlenenIndex != null
                          ? Border.all(
                              color: CupertinoColors.systemOrange,
                              width: 2.0,
                            )
                          : Border.all(
                              color: CupertinoColors.systemGrey5.resolveFrom(context),
                              width: 1.0,
                            ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 4),
                        CupertinoTextField(controller: plakaController, placeholder: 'Plaka',
                                prefix: Padding(
                                    // İkonun kutunun kenarına yapışmaması için soluna boşluk veriyoruz.
                                    padding: const EdgeInsets.only(left: 12.0), 
                                    child: Icon(
                                      CupertinoIcons.pano,
                                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                    ),
                                  ),
                              padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                              decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5.resolveFrom(context),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                        ),
                        SizedBox(height: 10),
                        CupertinoTextField(
                            controller: kmBaslangicController,
                            keyboardType: TextInputType.number,
                            placeholder: 'Gün Başı KM',
                            prefix: Padding(
                                    // İkonun kutunun kenarına yapışmaması için soluna boşluk veriyoruz.
                                    padding: const EdgeInsets.only(left: 12.0), 
                                    child: Icon(
                                      CupertinoIcons.gauge,
                                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                    ),
                                  ),
                            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5.resolveFrom(context),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                        ),
                        SizedBox(height: 10),
                        CupertinoTextField(
                            controller: kmAralikController,
                            placeholder: 'KM Aralığı (örn: 90-100)',
                            prefix: Padding(
                                    // İkonun kutunun kenarına yapışmaması için soluna boşluk veriyoruz.
                                    padding: const EdgeInsets.only(left: 12.0), 
                                    child: Icon(
                                      CupertinoIcons.arrow_right_arrow_left_square,
                                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                    ),
                                  ),
                            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                              decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5.resolveFrom(context),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            ),
                        
                        // --- YENİ KOD ---
// ...
                        SizedBox(height: 12),
                        // Başlık
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                          child: Text(
                            'Marka',
                            style: TextStyle(
                              fontSize: 17.0,
                              color: CupertinoTheme.of(context).textTheme.textStyle.color,
                            ),
                          ),
                        ),
                        // Yeni Marka Seçim Widget'ımız
                        MarkaSecici(
                        markalar: _markalar,
                        seciliMarka: seciliMarka,
                        isEditing: _duzenlenenIndex != null, // <-- EKLENDİ
                        onMarkaSecildi: (yeniMarka) {
                          setState(() {
                            seciliMarka = yeniMarka;
                          });
                        },
                      ),
                        
                        SizedBox(height: 0), // Marka seçici ile altındaki eleman arasına boşluk
                        // ...
                        // --- YENİ KOD ---
                        SizedBox(height: 16),
                        // Hafta Sonu Durumu Başlığı
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                          child: Text(
                            'Hafta Sonu Durumu',
                            style: TextStyle(
                              fontSize: 17.0,
                              color: CupertinoTheme.of(context).textTheme.textStyle.color,
                            ),
                          ),
                        ),
                        // Yeni Hafta Sonu Seçim Widget'ı
                        HaftasonuSecici(
                        seciliDurum: haftasonuDurumu,
                        isEditing: _duzenlenenIndex != null, // <-- EKLENDİ
                        onDurumSecildi: (yeniDurum) {
                          setState(() {
                            haftasonuDurumu = yeniDurum;
                          });
                        },
                      ),
                        // Güzergah Başlığı ve Yönetim Butonu
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                'Güzergah',
                                style: TextStyle(
                                  fontSize: 17.0,
                                  color: CupertinoTheme.of(context).textTheme.textStyle.color,
                                ),
                              ),
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.settings, size: 20),
                                  SizedBox(width: 4),
                                  Text("Yönet"),
                                ],
                              ),
                              onPressed: _guzergahYonetimDialogGoster,
                            )
                          ],
                        ),
                        SizedBox(height: 0),

                        // Yeni Güzergah Seçim Widget'ı
                        // Yeni Güzergah Seçim Widget'ı
                        GuzergahSecici(
                          guzergahlar: guzergahlar,
                          seciliGuzergah: seciliGuzergah,
                          isEditing: _duzenlenenIndex != null, // <-- EKLENDİ
                          onGuzergahSecildi: (yeniGuzergah) {
                            setState(() {
                              seciliGuzergah = yeniGuzergah;
                            });
                          },
                        ),
                        SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: CupertinoButton(
                                borderRadius: BorderRadius.circular(16.0),
                                color: _duzenlenenIndex == null 
                                  ? CupertinoTheme.of(context).primaryColor
                                  : CupertinoColors.systemOrange,
                                onPressed: _saveOrUpdateArac,
                                child: Text(
                                  _duzenlenenIndex == null ? 'Kaydet' : 'Güncelle',
                                   style: TextStyle(
                                    color: CupertinoColors.darkBackgroundGray,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (_duzenlenenIndex != null)
                              SizedBox(width: 8),
                            if (_duzenlenenIndex != null)
                              CupertinoButton(
                                borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                color: CupertinoColors.secondaryLabel,
                                onPressed: _cancelEditing,
                                child: Text(
                                  'Vazgeç',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            AnimationConfiguration.staggeredList(
              position: 2,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 10.0,
                child: FadeInAnimation(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Araçlarım',
                        style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                      ),
                      Icon(
                        CupertinoIcons.car,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Divider(height: 1, color: CupertinoColors.systemGrey5),
            SizedBox(height: 8),
            if (araclar.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.car_detailed,
                          size: 60, color: CupertinoColors.secondaryLabel),
                      SizedBox(height: 10),
                      Text('Henüz araç eklenmedi.',
                          style: CupertinoTheme.of(context).textTheme.textStyle)
                    ],
                  ),
                ),
              )
            else
              AnimationLimiter(
                child: ListView.builder(
                  clipBehavior: Clip.antiAlias,
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: araclar.length,
                  itemBuilder: (context, index) {
                    final a = araclar[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: AracKarti(
                            arac: a,
                            onEdit: () => _editArac(index),
                            onDelete: () => _aracSil(index),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
