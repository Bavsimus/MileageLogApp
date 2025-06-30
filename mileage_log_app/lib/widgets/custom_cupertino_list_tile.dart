import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomCupertinoListTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const CustomCupertinoListTile({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent, // Tıklama alanının tüm satırı kaplaması için
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0, left: 12.0),
              child: Icon(
                icon,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                value,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}