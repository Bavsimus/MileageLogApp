import 'package:flutter/cupertino.dart';

// Sınıfın adı 'CupertinoListTile' -> 'CustomCupertinoListTile' olarak değiştirildi.
class CustomCupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget additionalInfo;
  final VoidCallback onTap;

  const CustomCupertinoListTile({
    super.key,
    required this.title,
    required this.additionalInfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DefaultTextStyle(
              style: CupertinoTheme.of(context).textTheme.textStyle,
              child: title,
            ),
            Row(
              children: [
                DefaultTextStyle(
                  style: CupertinoTheme.of(context).textTheme.textStyle
                      .copyWith(color: CupertinoColors.secondaryLabel),
                  child: additionalInfo,
                ),
                const SizedBox(width: 6),
                const Icon(
                  CupertinoIcons.chevron_up_chevron_down,
                  size: 16,
                  color: CupertinoColors.tertiaryLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
