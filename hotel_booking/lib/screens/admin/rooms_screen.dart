import 'package:flutter/material.dart';

import '../../widgets/catalog_list.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});
  @override
  Widget build(BuildContext context) => const CatalogList(section: 'rooms');
}