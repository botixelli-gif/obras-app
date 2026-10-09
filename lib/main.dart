import 'package:flutter/material.dart';

import 'app.dart';
import 'data/demo_repository.dart';

void main() {
  runApp(ObrasApp(repository: DemoRepository()));
}
