import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// UUID v7: time-ordered, safe to create offline. Use for every record.
String newId() => _uuid.v7();
