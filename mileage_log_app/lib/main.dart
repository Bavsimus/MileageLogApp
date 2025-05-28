import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MaterialApp(
    debugShowCheckedModeBanner: false, home: AyBazliExcelOlusturucu()));

class AyBazliExcelOlusturucu extends StatefulWidget {
  @override
  _AyBazliExcelOlusturucuState createState() => _AyBazliExcelOlusturucuState();
}

class _AyBazliExcelOlusturucuState extends State<AyBazliExcelOlusturucu> {
  final _formKey = GlobalKey<FormState>();
  int? selectedMonth;
  int? selectedYear;
  final TextEditingController gorevYeriController = TextEditingController();
  final TextEditingController baslangicKmController = TextEditingController();
  final TextEditingController yapilanKmController = TextEditingController();

  int daysInMonth(int year, int month) {
    final firstDayNextMonth =
        (month < 12) ? DateTime(year, month + 1, 1) : DateTime(year + 1, 1, 1);
    return firstDayNextMonth.subtract(Duration(days: 1)).day;
  }

  Future<bool> checkStoragePermission() async {
    print("📂 Depolama izni kontrol ediliyor...");
    final status = await Permission.storage.status;

    if (status.isGranted) {
      print("✅ Depolama izni zaten verilmiş");
      return true;
    }

    final result = await Permission.storage.request();
    print("🟡 Depolama izni sonucu: $result");

    if (result.isGranted) return true;

    if (result.isPermanentlyDenied) {
      print("❌ Depolama izni kalıcı olarak reddedildi");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen ayarlardan depolama izni verin")),
      );
      await openAppSettings();
    }

    return false;
  }

  Future<void> createMonthlyExcel() async {
    print("🔘 createMonthlyExcel() çağrıldı");

    try {
      if (!_formKey.currentState!.validate()) {
        print("⚠️ Form doğrulama başarısız");
        return;
      }

      if (!await checkStoragePermission()) {
        print("🚫 İzin alınamadı");
        return;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Çizelge'];

      final int month = selectedMonth!;
      final int year = selectedYear!;
      final int dayCount = daysInMonth(year, month);
      final int gunBasi = int.parse(baslangicKmController.text);
      final int kmBaz = int.parse(yapilanKmController.text);
      final String gorevYeri = gorevYeriController.text;
      final Random rnd = Random();

      sheet.appendRow([
        "TARİH",
        "GÜN BAŞI (km)",
        "GÜN SONU (km)",
        "YAPILAN KİLOMETRE",
        "GÖREV YERİ"
      ]);

      int currentKm = gunBasi;

      for (int i = 1; i <= dayCount; i++) {
        int varyant = rnd.nextInt(21) - 10;
        int yapilan = kmBaz + varyant;
        int gunSonu = currentKm + yapilan;
        String formattedDate =
            "${i.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}.$year";

        sheet.appendRow([
          formattedDate,
          currentKm,
          gunSonu,
          yapilan,
          gorevYeri,
        ]);

        currentKm = gunSonu;
      }

      Directory directory = Directory('/storage/emulated/0/Download');
      String filePath = "${directory.path}/KGM_Raporu_${month}_$year.xlsx";

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      print("✅ Excel dosyası başarıyla oluşturuldu: $filePath");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Excel oluşturuldu:\nDownload klasörüne kaydedildi'),
        duration: Duration(seconds: 4),
      ));
    } catch (e) {
      print("❌ Hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Hata: ${e.toString()}"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("KGM Aylık Excel Raporu")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<int>(
                value: selectedMonth,
                decoration: InputDecoration(labelText: "Ay"),
                items: List.generate(
                    12,
                    (index) => DropdownMenuItem(
                        value: index + 1, child: Text("${index + 1}"))),
                onChanged: (val) => setState(() => selectedMonth = val),
                validator: (val) => val == null ? "Lütfen ay seçin" : null,
              ),
              DropdownButtonFormField<int>(
                value: selectedYear,
                decoration: InputDecoration(labelText: "Yıl"),
                items: List.generate(
                    5,
                    (index) => DropdownMenuItem(
                        value: 2023 + index, child: Text("${2023 + index}"))),
                onChanged: (val) => setState(() => selectedYear = val),
                validator: (val) => val == null ? "Yıl seçin" : null,
              ),
              TextFormField(
                controller: gorevYeriController,
                decoration: InputDecoration(labelText: "Görev Yeri"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Görev yeri girin" : null,
              ),
              TextFormField(
                controller: baslangicKmController,
                decoration: InputDecoration(labelText: "Gün Başı Km"),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? "Başlangıç km girin" : null,
              ),
              TextFormField(
                controller: yapilanKmController,
                decoration:
                    InputDecoration(labelText: "Günlük Yapılan Km (baz)"),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? "Yapılan km girin" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  print("🟢 Butona basıldı");
                  createMonthlyExcel();
                },
                child: Text("Excel Oluştur"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
