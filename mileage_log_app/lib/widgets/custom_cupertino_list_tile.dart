import 'package:flutter/cupertino.dart';

class CustomCupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget additionalInfo;
  final VoidCallback onTap;

  const CustomCupertinoListTile({super.key, required this.title, required this.additionalInfo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // --- DEĞİŞİKLİK: Sabit yükseklik eklendi ---
        height: 50, // Yüksekliği buradan istediğin gibi ayarlayabilirsin.

        // Dikey padding'i kaldırıp sadece yatay boşluk bırakıyoruz ki içerik ortalansın.
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5.resolveFrom(context),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DefaultTextStyle(style: CupertinoTheme.of(context).textTheme.textStyle, child: title),
            Row(
              children: [
                DefaultTextStyle(
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(color: CupertinoColors.secondaryLabel),
                  child: additionalInfo
                ),
                SizedBox(width: 8),
                Icon(CupertinoIcons.chevron_up_chevron_down, size: 16, color: CupertinoColors.tertiaryLabel)
              ],
            )
          ],
        ),
      ),
    );
  }
}
