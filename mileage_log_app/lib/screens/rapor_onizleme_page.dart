import 'dart:io';
import 'package:data_table_2/data_table_2.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/arac_model.dart';

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
    final fileName = 'AracRaporu_${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}.xlsx';
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final file = File(path);
      await file.writeAsBytes(fileBytes);

      // ignore: use_build_context_synchronously
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
        // Bu sayfadan geri dönebilmek için 'leading' (sol taraf) butonunu ekliyoruz.
        leading: CupertinoNavigationBarBackButton(
          previousPageTitle: 'Geri',
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.share),
          onPressed: () => _kaydetVePaylas(context),
        ),
      ),
      child: Material(
        // DataTable2'nin çalışabilmesi için Material widget'ı ile sarmalıyoruz.
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
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
                        return DataRow(
                          cells: [
                            DataCell(Text(row[0].toString())),
                            DataCell(Text(row[1].toString())),
                            DataCell(Text(row[2].toString())),
                            DataCell(Text(row[3].toString())),
                            DataCell(Text(row[4].toString())),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
