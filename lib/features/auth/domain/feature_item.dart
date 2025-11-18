class FeatureItem {
  final String title;
  final String icon;
  final bool isPrimary;

  const FeatureItem({
    required this.title,
    required this.icon,
    this.isPrimary = false,
  });
}