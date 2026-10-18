import 'package:flutter/material.dart';

import '../../widgets/catalog_list.dart';

class AmenitiesScreen extends StatelessWidget {
  const AmenitiesScreen({super.key});
  @override
  Widget build(BuildContext context) => const CatalogList(section: 'amenities');
}
