import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/arac_model.dart';
import '../widgets/arac_karti.dart';
import '../widgets/custom_cupertino_list_tile.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/services.dart';
import '../models/database_helper.dart';
import 'package:mileage_log_app/models/guzergah_model.dart';

// --- YENİ WIDGET: Güzergah Yönetim Diyaloğu ---
// araclar_page.dart dosyasının en üstlerine, _AraclarPageState'ten önceye

class GuzergahYonetimDialog extends StatefulWidget {
  // Diyalog kapandığında ana sayfanın listeyi yenilemesi için bir callback
  final VoidCallback onGuzergahlarChanged;

  const GuzergahYonetimDialog({
    Key? key,
    required this.onGuzergahlarChanged,
  }) : super(key: key);

  @override
  _GuzergahYonetimDialogState createState() => _GuzergahYonetimDialogState();
}

class _GuzergahYonetimDialogState extends State<GuzergahYonetimDialog> {
  List<GuzergahModel> guzergahlar = [];
  final TextEditingController textController = TextEditingController();
  final dbHelper = DatabaseHelper.instance;
  
  @override
  void initState() {
    super.initState();
    _refreshGuzergahList();
  }
  
  Future<void> _refreshGuzergahList() async {
    final guzergahListesi = await dbHelper.getAllGuzergahlar();
    setState(() {
      guzergahlar = guzergahListesi;
    });
  }
  
  // araclar_page.dart -> _GuzergahYonetimDialogState sınıfının içi

  void _kaydet() async {
    final yeniGuzergahAdi = textController.text.trim();
    if (yeniGuzergahAdi.isEmpty) return;

    // Aynı isimde güzergah var mı kontrol et
    if (guzergahlar.any((g) => g.name.toLowerCase() == yeniGuzergahAdi.toLowerCase())) {
      // EĞER VARSA, KULLANICIYI UYAR
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Güzergah Mevcut'),
          content: Text('"${yeniGuzergahAdi}" adında bir güzergah zaten var.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Tamam'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
      return; // Fonksiyondan çık
    }

    // Eğer yoksa, ekleme işlemine devam et
    await dbHelper.insertGuzergah(yeniGuzergahAdi);
    textController.clear();
    await _refreshGuzergahList();
    widget.onGuzergahlarChanged(); // Ana sayfayı bilgilendir
  }

  void _sil(int id) async {
    // Bu güzergahın herhangi bir araç tarafından kullanılıp kullanılmadığını kontrol etmeliyiz.
    // Şimdilik bu kontrolü basitleştirip direkt silelim. İleri seviyede bu kontrol eklenebilir.
    await dbHelper.deleteGuzergah(id);
    await _refreshGuzergahList();
    widget.onGuzergahlarChanged(); // Ana sayfayı bilgilendir
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4, // Yüksekliği biraz artırdık
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoTextField(
              controller: textController,
              placeholder: 'Yeni Güzergah Ekle',
              suffix: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(CupertinoIcons.add_circled),
                onPressed: _kaydet,
              ),
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: guzergahlar.isEmpty
                ? Center(child: Text("Henüz güzergah eklenmedi."))
                : ListView.separated(
                    itemCount: guzergahlar.length,
                    separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final guzergah = guzergahlar[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(guzergah.name),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Icon(CupertinoIcons.trash, size: 20, color: CupertinoColors.systemRed),
                              onPressed: () => _sil(guzergah.id),
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
// araclar_page.dart dosyasının en üstlerine, diğer widget'ların yanına

class GuzergahSecici extends StatelessWidget {
  final List<GuzergahModel> guzergahlar;
  final int? seciliGuzergahId; // Artık ID alıyor
  final ValueChanged<int> onGuzergahSecildi; // Artık ID döndürüyor
  final bool isEditing;

  const GuzergahSecici({
    Key? key,
    required this.guzergahlar,
    required this.seciliGuzergahId,
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
          style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context)),
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
          final isSelected = guzergah.id == seciliGuzergahId; // Karşılaştırma ID ile yapılıyor

          return GestureDetector(
            onTap: () => onGuzergahSecildi(guzergah.id), // Geriye ID döndürülüyor
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 130,
              margin: const EdgeInsets.symmetric(horizontal: 6.0),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              transform: isSelected
                  ? (Matrix4.identity()..scale(1.01))
                  : Matrix4.identity(),
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
                    guzergah.name, // İsim gösteriliyor
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
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
  List<GuzergahModel> guzergahlar = []; // Artık GuzergahModel listesi tutuyoruz
  int? seciliGuzergahId; // Artık seçili güzergahın ID'sini tutuyoruz
  List<AracModel> araclar = [];
  int? _duzenlenenIndex;

  final TextEditingController plakaController = TextEditingController();
  final TextEditingController kmBaslangicController = TextEditingController();
  final TextEditingController kmAralikController = TextEditingController();
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

  Future<void> _loadGuzergahlar() async {
  final dbHelper = DatabaseHelper.instance;
  final guzergahListesi = await dbHelper.getAllGuzergahlar();
  setState(() {
    guzergahlar = guzergahListesi;
    // Eğer seçili bir güzergah yoksa veya seçili olan ID listede yoksa, listenin ilk elemanını seç
    if (guzergahlar.isNotEmpty) {
      if (seciliGuzergahId == null || !guzergahlar.any((g) => g.id == seciliGuzergahId)) {
        seciliGuzergahId = guzergahlar.first.id;
      }
    } else {
      seciliGuzergahId = null;
    }
  });
  }

  Future<void> _loadAraclar() async {
  final dbHelper = DatabaseHelper.instance;
  final aracListesi = await dbHelper.getAllAraclar(); // Veritabanından oku
  if (mounted) {
    setState(() {
      araclar = aracListesi;
    });
  }
  }

  // araclar_page.dart

  // araclar_page.dart -> _AraclarPageState sınıfının içi

Future<void> _saveOrUpdateArac() async {
  HapticFeedback.lightImpact();
  // GÜNCELLENDİ: seciliGuzergah.isEmpty yerine seciliGuzergahId == null kontrolü
  if (plakaController.text.isEmpty ||
      kmBaslangicController.text.isEmpty ||
      kmAralikController.text.isEmpty ||
      (guzergahlar.isNotEmpty && seciliGuzergahId == null)) {
    showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
              title: Text('Eksik Bilgi'),
              content: Text('Lütfen tüm alanları doldurun.'),
              actions: [
                CupertinoDialogAction(
                    isDefaultAction: true,
                    child: Text('Tamam'),
                    onPressed: () => Navigator.of(context).pop())
              ],
            ));
    return;
  }

  final bool isUpdating = _duzenlenenIndex != null;
  final dbHelper = DatabaseHelper.instance;

  if (isUpdating) {
    // GÜNCELLEME
    final aracToUpdate = araclar[_duzenlenenIndex!];
    final guncellenmisArac = AracModel(
      id: aracToUpdate.id,
      plaka: plakaController.text.trim(),
      guzergahId: seciliGuzergahId!, // GÜNCELLENDİ
      gunBasiKm: double.tryParse(kmBaslangicController.text.trim()) ?? 0,
      kmAralik: kmAralikController.text.trim(),
      haftasonuDurumu: haftasonuDurumu,
      marka: seciliMarka,
    );
    await dbHelper.update(guncellenmisArac);
  } else {
    // YENİ EKLEME
    final yeniArac = AracModel(
      plaka: plakaController.text.trim(),
      guzergahId: seciliGuzergahId!, // GÜNCELLENDİ
      gunBasiKm: double.tryParse(kmBaslangicController.text.trim()) ?? 0,
      kmAralik: kmAralikController.text.trim(),
      haftasonuDurumu: haftasonuDurumu,
      marka: seciliMarka,
    );
    await dbHelper.insert(yeniArac);
  }

  // Formu temizle
  setState(() {
    _duzenlenenIndex = null;
    plakaController.clear();
    kmBaslangicController.clear();
    kmAralikController.clear();
    if (guzergahlar.isNotEmpty) seciliGuzergahId = guzergahlar.first.id;
    if (_markalar.isNotEmpty) seciliMarka = _markalar.first;
    haftasonuDurumu = 'Çalışıyor';
  });

  // Listeyi veritabanından yeniden yükle
  await _loadAraclar();

  // Başarı mesajını göster
  if (mounted) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title:
            Text(isUpdating ? 'Başarıyla Güncellendi' : 'Başarıyla Kaydedildi'),
        content: Text(isUpdating
            ? 'Araç bilgileri güncellendi.'
            : 'Yeni araç başarıyla eklendi.'),
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
  
  // araclar_page.dart -> _AraclarPageState sınıfının içi

void _editArac(int index) {
  final arac = araclar[index];
  setState(() {
    _duzenlenenIndex = index;
    plakaController.text = arac.plaka;
    kmBaslangicController.text = arac.gunBasiKm.toString();
    kmAralikController.text = arac.kmAralik;
    haftasonuDurumu = arac.haftasonuDurumu;
    seciliMarka = arac.marka;

    // ESKİ: seciliGuzergah = arac.guzergah;
    // YENİ:
    seciliGuzergahId = arac.guzergahId;

    // Aracın eski güzergahının ID'si mevcut güzergahlar listesinde var mı diye kontrol et.
    // Eğer silinmişse, kullanıcıyı uyar ve ilk sıradakini seç.
    if (!guzergahlar.any((g) => g.id == arac.guzergahId)) {
      seciliGuzergahId = guzergahlar.isNotEmpty ? guzergahlar.first.id : null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Aracın eski güzergahı bulunamadı. Lütfen yeni bir tane seçin.'),
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

  // BU METODU GÜNCELLE
  void _cancelEditing() {
    HapticFeedback.lightImpact();
    setState(() {
      _duzenlenenIndex = null;
      plakaController.clear();
      kmBaslangicController.clear();
      kmAralikController.clear();
      if (guzergahlar.isNotEmpty) {
        seciliGuzergahId = guzergahlar.first.id; // DOĞRUSU BU
      }
      if (_markalar.isNotEmpty) {
        seciliMarka = _markalar.first;
      }
      haftasonuDurumu = 'Çalışıyor';
    });
  }

  // araclar_page.dart

  Future<void> _aracSil(int index) async {
    final arac = araclar[index];
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Aracı Sil'),
        content: Text(
            '"${arac.plaka}" plakalı aracı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          CupertinoDialogAction(
            child: Text('İptal'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Sil'),
            onPressed: () async {
              final dbHelper = DatabaseHelper.instance;
              await dbHelper.delete(arac.id!); // Veritabanından sil
              Navigator.of(context).pop();     // Diyaloğu kapat
              await _loadAraclar();             // Listeyi yenile
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
  // araclar_page.dart -> _AraclarPageState sınıfının içi

Future<void> _guzergahYonetimDialogGoster() async {
  await showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text('Güzergahları Yönet'),
        content: GuzergahYonetimDialog(
          onGuzergahlarChanged: () {
            // Diyalog içinde bir değişiklik olduğunda bu metot tetiklenecek
            // ve ana sayfadaki güzergah listesini yenileyecek.
            _loadGuzergahlar();
          },
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Bitti'),
            onPressed: () {
              Navigator.of(context).pop();
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
                          seciliGuzergahId: seciliGuzergahId,
                          isEditing: _duzenlenenIndex != null,
                          onGuzergahSecildi: (yeniGuzergahId) { // Gelen değer artık int (ID)
                            setState(() {
                              seciliGuzergahId = yeniGuzergahId; // State'i yeni ID ile güncelle
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
                    final arac = araclar[index];
                    final guzergah = guzergahlar.firstWhere(
                      (g) => g.id == arac.guzergahId, 
                      orElse: () => GuzergahModel(id: 0, name: "Bilinmiyor"),
                      );
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: AracKarti(
                            arac: arac,
                            guzergahAdi: guzergah.name,
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
