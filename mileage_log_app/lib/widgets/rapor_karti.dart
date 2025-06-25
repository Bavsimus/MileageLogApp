import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class RaporKarti extends StatelessWidget {
  final File file;
  final VoidCallback onTap;

  const RaporKarti({
    super.key,
    required this.file,
    required this.onTap,
  });

  // Dosya yolundan sadece dosya adını alan yardımcı metot
  String _getFileName(String path) {
    return path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _getFileName(file.path);
    final modificationDate = file.lastModifiedSync();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).barBackgroundColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Sol tarafta belirgin bir ikon
            Icon(CupertinoIcons.doc_chart_fill, color: CupertinoTheme.of(context).primaryColor, size: 36),
            const SizedBox(width: 16),
            // Ortada dosya adı ve tarihi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Oluşturulma: ${DateFormat.yMd('tr_TR').add_Hm().format(modificationDate)}",
                    style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Sağda, tıklanabilir olduğunu belirten ok ikonu
            const Icon(CupertinoIcons.right_chevron, color: CupertinoColors.tertiaryLabel),
          ],
        ),
      ),
    );
  }
}
