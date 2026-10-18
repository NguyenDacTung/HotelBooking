import 'package:flutter/material.dart';

import '../../widgets/catalog_list.dart';

class RoomClosuresScreen extends StatelessWidget {
  const RoomClosuresScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const CatalogList(section: 'room-closures');
}
