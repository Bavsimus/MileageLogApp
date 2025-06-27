import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
// Animasyon paketini import ediyoruz
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/arac_model.dart';

class RaporOnizlemePage extends StatelessWidget {
  final Map<AracModel, List<List<dynamic>>> raporVerisi;

  const RaporOnizlemePage({super.key, required this.raporVerisi});

  Future<void> _saveAndShare({required BuildContext context, bool share = false}) async {
    // ... Bu metotta değişiklik yok, aynı kalıyor ...
    var excel = Excel.createExcel();

    raporVerisi.forEach((arac, satirlar) {
      Sheet sheet = excel[arac.plaka];
      excel.setDefaultSheet(arac.plaka);

      final List<String> basliklar = [
        'Tarih',
        'Gün Başı KM',
        'Gün Sonu KM',
        'Yapılan KM',
        'Güzergah'
      ];
      sheet.appendRow(basliklar.map((e) => TextCellValue(e)).toList());

      for (var satir in satirlar) {
        sheet.appendRow(satir.map((e) {
          if (e is num) {
            return DoubleCellValue(e.toDouble());
          }
          return TextCellValue(e.toString());
        }).toList());
      }
    });

    final List<int>? excelBytes = excel.save();
    if (excelBytes == null) return;
    final Uint8List fileBytes = Uint8List.fromList(excelBytes);

    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final dosyaAdi =
        'KM_Raporu_${raporVerisi.keys.first.plaka}_${DateFormat('yyyy-MM-dd_HH-mm').format(now)}.xlsx';
    final path = '${directory.path}/$dosyaAdi';
    final file = File(path);
    await file.writeAsBytes(fileBytes);

    if (context.mounted) {
      if (share) {
        final xFile = XFile(path);
        await Share.shareXFiles([xFile], text: 'KM Raporu');
      } else {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Başarıyla Kaydedildi'),
            content: Text('$dosyaAdi adıyla kaydedildi.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Tamam'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardBackgroundColor = theme.barBackgroundColor;
    final primaryTextColor = theme.textTheme.textStyle.color ?? CupertinoColors.black;
    final dividerColor = CupertinoColors.separator.resolveFrom(context);
    
    // Rapor kartlarını animasyon index'i ile birlikte oluşturmak için listeyi hazırlıyoruz.
    final raporEntries = raporVerisi.entries.toList();

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Rapor Önizleme'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _saveAndShare(context: context, share: true),
              child: const Icon(CupertinoIcons.share),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _saveAndShare(context: context),
              child: const Icon(CupertinoIcons.down_arrow),
            ),
          ],
        ),
      ),
      child: SafeArea(
        // --- DEĞİŞİKLİK: ListView -> AnimationLimiter + ListView.builder ---
        child: AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: raporEntries.length,
            itemBuilder: (context, index) {
              final entry = raporEntries[index];
              final arac = entry.key;
              final data = entry.value;

              // --- DEĞİŞİKLİK: Her bir kart animasyonlarla sarmalandı ---
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildAracRaporKarti(
                      context: context,
                      arac: arac,
                      data: data,
                      theme: theme,
                      cardBackgroundColor: cardBackgroundColor,
                      primaryTextColor: primaryTextColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAracRaporKarti({
    required BuildContext context,
    required AracModel arac,
    required List<List<dynamic>> data,
    required CupertinoThemeData theme,
    required Color cardBackgroundColor,
    required Color primaryTextColor,
  }) {
    DateTime? raporTarihi;
    if (data.isNotEmpty && data.first.isNotEmpty) {
      try {
        raporTarihi = DateTime.parse((data.first.first as String).split('.').reversed.join('-'));
      } catch (e) {
        raporTarihi = null;
      }
    }

    return Card(
      elevation: 0,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.only(bottom: 20.0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arac.plaka,
                  style: theme.textTheme.navTitleTextStyle.copyWith(color: primaryTextColor),
                ),
                if (raporTarihi != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMM('tr_TR').format(raporTarihi) + ' Raporu',
                    style: theme.textTheme.tabLabelTextStyle.copyWith(color: theme.primaryColor),
                  ),
                ],
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              dividerThickness: 1,
              columnSpacing: 25, // Sütun aralığı artırıldı
              headingRowHeight: 40,
              headingTextStyle: theme.textTheme.textStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
              dataTextStyle: theme.textTheme.textStyle.copyWith(
                color: primaryTextColor,
              ),
              // --- DEĞİŞİKLİK: Zebra deseni için eklendi ---
              dataRowColor: MaterialStateProperty.resolveWith<Color?>((states) {
                // Burada direkt index'e erişemediğimiz için şimdilik null bırakıyoruz.
                // Daha basit bir çözüm için DataRow'ları elle oluşturacağız.
                return null;
              }),
              columns: const [
                DataColumn(label: Text('Tarih')),
                DataColumn(label: Text('G. Başı KM')),
                DataColumn(label: Text('G. Sonu KM')),
                DataColumn(label: Text('Yapılan KM')),
                DataColumn(label: Text('Güzergah')),
              ],
              // --- DEĞİŞİKLİK: Zebra deseni ve sağa hizalama için .map -> asMap().entries.map ---
              rows: data.asMap().entries.map((indexedEntry) {
                final int rowIndex = indexedEntry.key;
                final List<dynamic> satir = indexedEntry.value;

                final rowColor = rowIndex.isOdd
                    ? CupertinoColors.systemGrey6.withOpacity(0.5)
                    : null; // Çift satırlar varsayılan renkte

                return DataRow(
                  color: MaterialStateProperty.all(rowColor),
                  cells: [
                    // Tarih ve Güzergah (sola dayalı)
                    DataCell(Text(satir[0].toString())),
                    // Sayısal değerler (sağa dayalı)
                    DataCell(Align(alignment: Alignment.centerRight, child: Text(satir[1].toString()))),
                    DataCell(Align(alignment: Alignment.centerRight, child: Text(satir[2].toString()))),
                    DataCell(Align(alignment: Alignment.centerRight, child: Text(satir[3].toString()))),
                    DataCell(Text(satir[4].toString())),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}