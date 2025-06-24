import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class TablolarPage extends StatefulWidget {
  const TablolarPage({super.key});

  @override
  _TablolarPageState createState() => _TablolarPageState();
}

class _TablolarPageState extends State<TablolarPage> {
  List<File> _savedFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedReports();
  }

  Future<void> _loadSavedReports() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final directory = await getApplicationDocumentsDirectory();
      if (await directory.exists()) {
        final files = directory.listSync();
        setState(() {
          _savedFiles =
              files
                  .where((file) => file.path.endsWith('.xlsx'))
                  .map((file) => File(file.path))
                  .toList()
                ..sort(
                  (a, b) =>
                      b.lastModifiedSync().compareTo(a.lastModifiedSync()),
                );
        });
      }
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Hata'),
          content: Text('Kaydedilmiş raporlar okunurken bir sorun oluştu: $e'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Tamam'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openFile(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Dosya Açılamadı'),
          content: Text(
            'Bu dosyayı açacak bir uygulama bulunamadı.\n\nHata: ${result.message}',
          ),
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

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      _loadSavedReports();
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Hata'),
          content: const Text('Dosya silinirken bir sorun oluştu.'),
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

  String _getFileName(String path) {
    return path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Kaydedilmiş Raporlar"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _loadSavedReports,
          child: Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 15))
            : _savedFiles.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.folder_open,
                      size: 60,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Henüz kaydedilmiş bir rapor bulunmuyor.",
                      style: CupertinoTheme.of(context).textTheme.textStyle,
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _savedFiles.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 56),
                itemBuilder: (context, index) {
                  final file = _savedFiles[index];
                  final fileName = _getFileName(file.path);

                  return Dismissible(
                    key: Key(fileName),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      _deleteFile(file);
                    },
                    background: Container(
                      color: CupertinoColors.systemRed,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: const Icon(
                        CupertinoIcons.delete_solid,
                        color: CupertinoColors.white,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () => _openFile(file.path),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        color: CupertinoTheme.of(
                          context,
                        ).scaffoldBackgroundColor,
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.doc_chart_fill,
                              color: CupertinoColors.systemTeal,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileName,
                                    style: CupertinoTheme.of(
                                      context,
                                    ).textTheme.textStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Oluşturulma: ${DateFormat.yMd('tr_TR').add_Hm().format(file.lastModifiedSync())}",
                                    style: CupertinoTheme.of(
                                      context,
                                    ).textTheme.tabLabelTextStyle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              CupertinoIcons.right_chevron,
                              color: CupertinoColors.tertiaryLabel,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
