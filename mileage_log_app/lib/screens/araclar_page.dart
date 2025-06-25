import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/arac_model.dart';
import '../widgets/arac_karti.dart';
import '../widgets/custom_cupertino_list_tile.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AraclarPage extends StatefulWidget {
  @override
  _AraclarPageState createState() => _AraclarPageState();
}

class _AraclarPageState extends State<AraclarPage> {
  // ... Bu sınıfın içindeki tüm metotlar ve değişkenler aynı kalıyor ...
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

    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  void _cancelEditing() {
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
  
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Araçlarım'),
      ),
      // --- DEĞİŞİKLİK BURADA: ListView'ın kendisi AnimationLimiter ile sarmalandı ---
      child: AnimationLimiter(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          children: [
            SizedBox(height: 88),
            // --- DEĞİŞİKLİK BURADA: Başlık animasyon için sarmalandı ---
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
                        _duzenlenenIndex == null ? CupertinoIcons.add_circled : CupertinoIcons.pencil_circle_fill,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Divider(height: 1, color: CupertinoColors.systemGrey5),
            SizedBox(height: 16),
            // --- DEĞİŞİKLİK BURADA: Form kartı animasyon için sarmalandı ---
            AnimationConfiguration.staggeredList(
              position: 1,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: CupertinoColors.tertiarySystemBackground,
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
                        // ... form içeriği aynı ...
                        SizedBox(height: 4),
                        CupertinoTextField(controller: plakaController, placeholder: 'Plaka',
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
                            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                              decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5.resolveFrom(context),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            ),
                        
                        SizedBox(height: 24),
                        CustomCupertinoListTile(title: Text('Marka'), additionalInfo: Text(seciliMarka), onTap: () {
                           _showPicker(context, _markalar, seciliMarka, (newValue) {
                              setState(() => seciliMarka = newValue);
                           });
                        }),
                        SizedBox(height: 10),
                        CustomCupertinoListTile(
                            title: Text('Hafta Sonu Durumu'),
                            additionalInfo: Text(haftasonuDurumu),
                            onTap: () {
                              _showPicker(context, ['Çalışıyor', 'Çalışmıyor'],
                                  haftasonuDurumu, (newValue) {
                                setState(() => haftasonuDurumu = newValue);
                              });
                            }),
                        SizedBox(height: 10),
                        if (guzergahlar.isNotEmpty)
                          CustomCupertinoListTile(
                              title: Text('Güzergah'),
                              additionalInfo: Text(seciliGuzergah),
                              onTap: () {
                                _showPicker(context, guzergahlar, seciliGuzergah,
                                    (newValue) {
                                  setState(() => seciliGuzergah = newValue);
                                });
                              })
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text("Önce bir güzergah ekleyin.",
                                style: TextStyle(color: CupertinoColors.systemRed)),
                          ),
                        SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: CupertinoButton(
                                borderRadius: BorderRadius.circular(16.0),
                                color: _duzenlenenIndex == null 
                                  ? CupertinoColors.systemTeal
                                  : CupertinoColors.systemOrange,
                                onPressed: _saveOrUpdateArac,
                                child: Text(
                                  _duzenlenenIndex == null ? 'Kaydet' : 'Güncelle',
                                   style: TextStyle(
                                    color: CupertinoColors.white,
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
            // --- DEĞİŞİKLİK BURADA: Liste başlığı animasyon için sarmalandı ---
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
                        color: CupertinoColors.secondaryLabel,
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
                  // ... empty state kodu aynı ...
                ),
              )
            else
              // --- DEĞİŞİKLİK BURADA: Kayıtlı araçlar listesi animasyonlu hale getirildi ---
              AnimationLimiter(
                child: ListView.builder(
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
