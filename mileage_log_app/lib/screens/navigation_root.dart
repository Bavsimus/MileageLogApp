import 'package:flutter/cupertino.dart';
import 'araclar_page.dart';
import 'tablo_olustur_page.dart';
import 'tablolar_page.dart';

class NavigationRoot extends StatefulWidget {
  const NavigationRoot({super.key});

  @override
  State<NavigationRoot> createState() => _NavigationRootState();
}

class _NavigationRootState extends State<NavigationRoot> {
  int _currentIndex = 1;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    AraclarPage(),
    TabloOlusturPage(),
    TablolarPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // Sekme verilerini (ikon ve başlık) bir liste olarak tanımlayalım.
    final List<Map<String, dynamic>> tabItems = [
      {'icon': CupertinoIcons.car_detailed, 'label': 'Araçlar'},
      {'icon': CupertinoIcons.table_fill, 'label': 'Tablo Oluştur'},
      {'icon': CupertinoIcons.folder_fill, 'label': 'Tablolar'},
    ];

    // Bu widget, her sayfanın kendi başlık çubuğuna sahip olması için
    // artık bir CupertinoPageScaffold içermiyor. Sadece içeriği yönetiyor.
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            children: _pages,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        CupertinoTabBar(
          height: 60,
          backgroundColor: CupertinoColors.tertiarySystemGroupedBackground,
          border: Border(
            top: BorderSide.none, // Üst çizgiyi kaldırır
          ),
          currentIndex: _currentIndex,
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          items: tabItems.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> item = entry.value;

            return BottomNavigationBarItem(
              icon: Icon(item['icon']),
              label: index == _currentIndex ? item['label'] : '',
            );
          }).toList(),
        ),
      ],
    );
  }
}
