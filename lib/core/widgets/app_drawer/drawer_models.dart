class DrawerSection {
  final String title;
  final String iconAsset;
  final List<DrawerItem> items;

  DrawerSection({
    required this.title,
    required this.iconAsset,
    required this.items,
  });
}

class DrawerItem {
  final String title;
  final void Function() onTap;

  DrawerItem({required this.title, required this.onTap});
}
