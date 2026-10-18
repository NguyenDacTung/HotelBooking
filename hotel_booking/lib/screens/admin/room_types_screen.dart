import 'package:flutter/material.dart';

import '../../widgets/catalog_list.dart';

class RoomTypesScreen extends StatelessWidget {
  const RoomTypesScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const CatalogList(section: 'room-types');
}
