import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/rapor_karti.dart';
import 'package:flutter/services.dart';

class TablolarPage extends StatefulWidget {
  @override
  _TablolarPageState createState() => _TablolarPageState();
}

class _TablolarPageState extends State<TablolarPage> {
  List<File> _savedFiles = [];
  bool _isLoading = true;

  // --- YENİ EKLENEN STATE DEĞİŞKENLERİ ---
  bool _isSelectionMode = false;
  final Set<File> _selectedFiles = {};
  // --- BİTTİ ---

  @override
  void initState() {
    super.initState();
    _loadSavedReports();
  }

  Future<void> _loadSavedReports() async {
    // Seçim modundaysak, yenileme yapmadan önce moddan çıkalım
    if (_isSelectionMode) {
      _exitSelectionMode();
    }
    setState(() { _isLoading = true; });
    try {
      final directory = await getApplicationDocumentsDirectory();
      if (await directory.exists()) {
        final files = directory.listSync();
        setState(() {
          _savedFiles = files
              .where((file) => file.path.endsWith('.xlsx'))
              .map((file) => File(file.path))
              .toList()
                ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        });
      }
    } catch (e) {
       showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
        title: Text('Hata'),
        content: Text('Kaydedilmiş raporlar okunurken bir sorun oluştu: $e'),
        actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('Tamam'), onPressed: () => Navigator.of(context).pop())],
      ));
    } finally {
        setState(() { _isLoading = false; });
    }
  }

  Future<void> _openFile(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
        title: Text('Dosya Açılamadı'),
        content: Text('Bu dosyayı açacak bir uygulama bulunamadı.\n\nHata: ${result.message}'),
        actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('Tamam'), onPressed: () => Navigator.of(context).pop())],
      ));
    }
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      _loadSavedReports();
    } catch (e) {
      showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
        title: Text('Hata'),
        content: Text('Dosya silinirken bir sorun oluştu.'),
        actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('Tamam'), onPressed: () => Navigator.of(context).pop())],
      ));
    }
  }

  // --- YENİ EKLENEN METOTLAR ---

  // Seçim modunu başlatır
  void _enterSelectionMode(File file) {
    setState(() {
      _isSelectionMode = true;
      _selectedFiles.add(file);
    });
  }

  // Seçim modundan çıkar
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedFiles.clear();
    });
  }

  // Bir dosyanın seçim durumunu değiştirir
  void _toggleSelection(File file) {
    setState(() {
      if (_selectedFiles.contains(file)) {
        _selectedFiles.remove(file);
        // Eğer son seçili dosya da kaldırıldıysa, seçim modundan çık
        if (_selectedFiles.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedFiles.add(file);
      }
    });
  }

  // Seçili dosyaları paylaşır
  Future<void> _shareSelectedFiles() async {
    if (_selectedFiles.isEmpty) return;

    final List<XFile> filesToShare = _selectedFiles.map((file) => XFile(file.path)).toList();
    
    try {
      await Share.shareXFiles(filesToShare, text: 'Seçilen Raporlar');
    } catch(e) {
      // Hata yönetimi
    } finally {
      // Paylaşım sonrası seçim modundan çık
      _exitSelectionMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // --- NAVİGASYON BARI GÜNCELLENDİ ---
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isSelectionMode ? '${_selectedFiles.length} Rapor Seçildi' : "Kaydedilmiş Raporlar"),
        // Seçim modundaysa "Vazgeç" butonu göster
        leading: _isSelectionMode
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text('Vazgeç'),
                onPressed: _exitSelectionMode,
              )
            : null,
        // Seçim modundaysa "Paylaş" butonu, değilse "Yenile" butonu göster
        trailing: _isSelectionMode
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text('Paylaş'),
                onPressed: _shareSelectedFiles,
              )
            : CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(CupertinoIcons.refresh),
                onPressed: _loadSavedReports,
              ),
      ),
      child: _isLoading
          ? Center(child: CupertinoActivityIndicator(radius: 15))
          : _savedFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.folder_open, size: 60, color: CupertinoColors.secondaryLabel),
                      SizedBox(height: 16),
                      Text(
                        "Henüz kaydedilmiş bir rapor bulunmuyor.",
                        style: CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 90.0, horizontal: 12.0),
                  itemCount: _savedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _savedFiles[index];
                    final isSelected = _selectedFiles.contains(file);

                    // --- LİSTE ELEMANI GÜNCELLENDİ ---
                    return GestureDetector(
                      onTap: () {
                        if (_isSelectionMode) {
                          HapticFeedback.lightImpact();
                          _toggleSelection(file);
                        } else {
                          _openFile(file.path);
                        }
                      },
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          _enterSelectionMode(file);
                        }
                      },
                      child: Stack(
                        children: [
                          Dismissible(
                            key: Key(file.path),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) { _deleteFile(file); },
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemRed,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Icon(CupertinoIcons.delete_solid, color: CupertinoColors.white),
                            ),
                            child: RaporKarti(
                              file: file,
                              onTap: () { // onTap'ı GestureDetector'a taşıdığımız için burayı boş bırakabiliriz
                                if (_isSelectionMode) {
                                  _toggleSelection(file);
                                } else {
                                  _openFile(file.path);
                                }
                              },
                            ),
                          ),
                          // Eğer dosya seçiliyse, üzerine bir overlay ve ikon ekle
                          if (isSelected)
                            Positioned.fill(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6.0),
                                decoration: BoxDecoration(
                                  color: CupertinoTheme.of(context).primaryColor.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 16.0),
                                    child: Icon(
                                      CupertinoIcons.check_mark_circled_solid,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
