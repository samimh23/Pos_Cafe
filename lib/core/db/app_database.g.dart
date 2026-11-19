// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $KvEntriesTable extends KvEntries with TableInfo<$KvEntriesTable, KvRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KvEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kv_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<KvRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KvRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvRow(
      key:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}key'],
          )!,
      value:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}value'],
          )!,
    );
  }

  @override
  $KvEntriesTable createAlias(String alias) {
    return $KvEntriesTable(attachedDatabase, alias);
  }
}

class KvRow extends DataClass implements Insertable<KvRow> {
  final String key;
  final String value;
  const KvRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KvEntriesCompanion toCompanion(bool nullToAbsent) {
    return KvEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory KvRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KvRow copyWith({String? key, String? value}) =>
      KvRow(key: key ?? this.key, value: value ?? this.value);
  KvRow copyWithCompanion(KvEntriesCompanion data) {
    return KvRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvRow && other.key == this.key && other.value == this.value);
}

class KvEntriesCompanion extends UpdateCompanion<KvRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KvEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KvEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KvRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KvEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KvEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KvEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      sortOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sort_order'],
          )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final int sortOrder;
  final String? color;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.color,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      color: serializer.fromJson<String?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'color': serializer.toJson<String?>(color),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? name,
    int? sortOrder,
    Value<String?> color = const Value.absent(),
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    color: color.present ? color.value : this.color,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.color == this.color);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<String?> color;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    this.sortOrder = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<String>? color,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (color != null) 'color': color,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<String?>? color,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      color: color ?? this.color,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('color: $color, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatRateBpMeta = const VerificationMeta(
    'vatRateBp',
  );
  @override
  late final GeneratedColumn<int> vatRateBp = GeneratedColumn<int>(
    'vat_rate_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1900),
  );
  static const VerificationMeta _stationMeta = const VerificationMeta(
    'station',
  );
  @override
  late final GeneratedColumn<String> station = GeneratedColumn<String>(
    'station',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _modifierGroupsJsonMeta =
      const VerificationMeta('modifierGroupsJson');
  @override
  late final GeneratedColumn<String> modifierGroupsJson =
      GeneratedColumn<String>(
        'modifier_groups_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _availableMeta = const VerificationMeta(
    'available',
  );
  @override
  late final GeneratedColumn<bool> available = GeneratedColumn<bool>(
    'available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    name,
    price,
    vatRateBp,
    station,
    modifierGroupsJson,
    available,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('vat_rate_bp')) {
      context.handle(
        _vatRateBpMeta,
        vatRateBp.isAcceptableOrUnknown(data['vat_rate_bp']!, _vatRateBpMeta),
      );
    }
    if (data.containsKey('station')) {
      context.handle(
        _stationMeta,
        station.isAcceptableOrUnknown(data['station']!, _stationMeta),
      );
    }
    if (data.containsKey('modifier_groups_json')) {
      context.handle(
        _modifierGroupsJsonMeta,
        modifierGroupsJson.isAcceptableOrUnknown(
          data['modifier_groups_json']!,
          _modifierGroupsJsonMeta,
        ),
      );
    }
    if (data.containsKey('available')) {
      context.handle(
        _availableMeta,
        available.isAcceptableOrUnknown(data['available']!, _availableMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      categoryId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}category_id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      price:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}price'],
          )!,
      vatRateBp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}vat_rate_bp'],
          )!,
      station:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}station'],
          )!,
      modifierGroupsJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}modifier_groups_json'],
          )!,
      available:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}available'],
          )!,
      sortOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sort_order'],
          )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  final String id;
  final String categoryId;
  final String name;

  /// Price TTC in millimes.
  final int price;

  /// VAT in basis points (1900 = 19 %).
  final int vatRateBp;
  final String station;
  final String modifierGroupsJson;
  final bool available;

  /// Order chosen by the owner (v3).
  final int sortOrder;
  const ProductRow({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.vatRateBp,
    required this.station,
    required this.modifierGroupsJson,
    required this.available,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<int>(price);
    map['vat_rate_bp'] = Variable<int>(vatRateBp);
    map['station'] = Variable<String>(station);
    map['modifier_groups_json'] = Variable<String>(modifierGroupsJson);
    map['available'] = Variable<bool>(available);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      name: Value(name),
      price: Value(price),
      vatRateBp: Value(vatRateBp),
      station: Value(station),
      modifierGroupsJson: Value(modifierGroupsJson),
      available: Value(available),
      sortOrder: Value(sortOrder),
    );
  }

  factory ProductRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<int>(json['price']),
      vatRateBp: serializer.fromJson<int>(json['vatRateBp']),
      station: serializer.fromJson<String>(json['station']),
      modifierGroupsJson: serializer.fromJson<String>(
        json['modifierGroupsJson'],
      ),
      available: serializer.fromJson<bool>(json['available']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<int>(price),
      'vatRateBp': serializer.toJson<int>(vatRateBp),
      'station': serializer.toJson<String>(station),
      'modifierGroupsJson': serializer.toJson<String>(modifierGroupsJson),
      'available': serializer.toJson<bool>(available),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ProductRow copyWith({
    String? id,
    String? categoryId,
    String? name,
    int? price,
    int? vatRateBp,
    String? station,
    String? modifierGroupsJson,
    bool? available,
    int? sortOrder,
  }) => ProductRow(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    price: price ?? this.price,
    vatRateBp: vatRateBp ?? this.vatRateBp,
    station: station ?? this.station,
    modifierGroupsJson: modifierGroupsJson ?? this.modifierGroupsJson,
    available: available ?? this.available,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ProductRow copyWithCompanion(ProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      vatRateBp: data.vatRateBp.present ? data.vatRateBp.value : this.vatRateBp,
      station: data.station.present ? data.station.value : this.station,
      modifierGroupsJson:
          data.modifierGroupsJson.present
              ? data.modifierGroupsJson.value
              : this.modifierGroupsJson,
      available: data.available.present ? data.available.value : this.available,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('vatRateBp: $vatRateBp, ')
          ..write('station: $station, ')
          ..write('modifierGroupsJson: $modifierGroupsJson, ')
          ..write('available: $available, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    name,
    price,
    vatRateBp,
    station,
    modifierGroupsJson,
    available,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.price == this.price &&
          other.vatRateBp == this.vatRateBp &&
          other.station == this.station &&
          other.modifierGroupsJson == this.modifierGroupsJson &&
          other.available == this.available &&
          other.sortOrder == this.sortOrder);
}

class ProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<String> name;
  final Value<int> price;
  final Value<int> vatRateBp;
  final Value<String> station;
  final Value<String> modifierGroupsJson;
  final Value<bool> available;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.vatRateBp = const Value.absent(),
    this.station = const Value.absent(),
    this.modifierGroupsJson = const Value.absent(),
    this.available = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String categoryId,
    required String name,
    required int price,
    this.vatRateBp = const Value.absent(),
    this.station = const Value.absent(),
    this.modifierGroupsJson = const Value.absent(),
    this.available = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       categoryId = Value(categoryId),
       name = Value(name),
       price = Value(price);
  static Insertable<ProductRow> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? name,
    Expression<int>? price,
    Expression<int>? vatRateBp,
    Expression<String>? station,
    Expression<String>? modifierGroupsJson,
    Expression<bool>? available,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (vatRateBp != null) 'vat_rate_bp': vatRateBp,
      if (station != null) 'station': station,
      if (modifierGroupsJson != null)
        'modifier_groups_json': modifierGroupsJson,
      if (available != null) 'available': available,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? categoryId,
    Value<String>? name,
    Value<int>? price,
    Value<int>? vatRateBp,
    Value<String>? station,
    Value<String>? modifierGroupsJson,
    Value<bool>? available,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      price: price ?? this.price,
      vatRateBp: vatRateBp ?? this.vatRateBp,
      station: station ?? this.station,
      modifierGroupsJson: modifierGroupsJson ?? this.modifierGroupsJson,
      available: available ?? this.available,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (vatRateBp.present) {
      map['vat_rate_bp'] = Variable<int>(vatRateBp.value);
    }
    if (station.present) {
      map['station'] = Variable<String>(station.value);
    }
    if (modifierGroupsJson.present) {
      map['modifier_groups_json'] = Variable<String>(modifierGroupsJson.value);
    }
    if (available.present) {
      map['available'] = Variable<bool>(available.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('vatRateBp: $vatRateBp, ')
          ..write('station: $station, ')
          ..write('modifierGroupsJson: $modifierGroupsJson, ')
          ..write('available: $available, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxEventsTable extends OutboxEvents
    with TableInfo<$OutboxEventsTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceSeqMeta = const VerificationMeta(
    'deviceSeq',
  );
  @override
  late final GeneratedColumn<int> deviceSeq = GeneratedColumn<int>(
    'device_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _staffIdMeta = const VerificationMeta(
    'staffId',
  );
  @override
  late final GeneratedColumn<String> staffId = GeneratedColumn<String>(
    'staff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvedByMeta = const VerificationMeta(
    'approvedBy',
  );
  @override
  late final GeneratedColumn<String> approvedBy = GeneratedColumn<String>(
    'approved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rejectedCodeMeta = const VerificationMeta(
    'rejectedCode',
  );
  @override
  late final GeneratedColumn<String> rejectedCode = GeneratedColumn<String>(
    'rejected_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    version,
    entityId,
    deviceSeq,
    occurredAt,
    staffId,
    approvedBy,
    payloadJson,
    rejectedCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('device_seq')) {
      context.handle(
        _deviceSeqMeta,
        deviceSeq.isAcceptableOrUnknown(data['device_seq']!, _deviceSeqMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceSeqMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('staff_id')) {
      context.handle(
        _staffIdMeta,
        staffId.isAcceptableOrUnknown(data['staff_id']!, _staffIdMeta),
      );
    }
    if (data.containsKey('approved_by')) {
      context.handle(
        _approvedByMeta,
        approvedBy.isAcceptableOrUnknown(data['approved_by']!, _approvedByMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('rejected_code')) {
      context.handle(
        _rejectedCodeMeta,
        rejectedCode.isAcceptableOrUnknown(
          data['rejected_code']!,
          _rejectedCodeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}type'],
          )!,
      version:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}version'],
          )!,
      entityId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}entity_id'],
          )!,
      deviceSeq:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}device_seq'],
          )!,
      occurredAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}occurred_at'],
          )!,
      staffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_id'],
      ),
      approvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by'],
      ),
      payloadJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payload_json'],
          )!,
      rejectedCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejected_code'],
      ),
    );
  }

  @override
  $OutboxEventsTable createAlias(String alias) {
    return $OutboxEventsTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  /// UUID v7 — idempotency key on the server.
  final String id;
  final String type;
  final int version;
  final String entityId;

  /// 1, 2, 3… per device. Gaps on the server = lost events.
  final int deviceSeq;
  final DateTime occurredAt;
  final String? staffId;
  final String? approvedBy;
  final String payloadJson;

  /// Set when the server refuses the event — it stays for investigation, not retried.
  final String? rejectedCode;
  const OutboxRow({
    required this.id,
    required this.type,
    required this.version,
    required this.entityId,
    required this.deviceSeq,
    required this.occurredAt,
    this.staffId,
    this.approvedBy,
    required this.payloadJson,
    this.rejectedCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['version'] = Variable<int>(version);
    map['entity_id'] = Variable<String>(entityId);
    map['device_seq'] = Variable<int>(deviceSeq);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || staffId != null) {
      map['staff_id'] = Variable<String>(staffId);
    }
    if (!nullToAbsent || approvedBy != null) {
      map['approved_by'] = Variable<String>(approvedBy);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || rejectedCode != null) {
      map['rejected_code'] = Variable<String>(rejectedCode);
    }
    return map;
  }

  OutboxEventsCompanion toCompanion(bool nullToAbsent) {
    return OutboxEventsCompanion(
      id: Value(id),
      type: Value(type),
      version: Value(version),
      entityId: Value(entityId),
      deviceSeq: Value(deviceSeq),
      occurredAt: Value(occurredAt),
      staffId:
          staffId == null && nullToAbsent
              ? const Value.absent()
              : Value(staffId),
      approvedBy:
          approvedBy == null && nullToAbsent
              ? const Value.absent()
              : Value(approvedBy),
      payloadJson: Value(payloadJson),
      rejectedCode:
          rejectedCode == null && nullToAbsent
              ? const Value.absent()
              : Value(rejectedCode),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      version: serializer.fromJson<int>(json['version']),
      entityId: serializer.fromJson<String>(json['entityId']),
      deviceSeq: serializer.fromJson<int>(json['deviceSeq']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      staffId: serializer.fromJson<String?>(json['staffId']),
      approvedBy: serializer.fromJson<String?>(json['approvedBy']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      rejectedCode: serializer.fromJson<String?>(json['rejectedCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'version': serializer.toJson<int>(version),
      'entityId': serializer.toJson<String>(entityId),
      'deviceSeq': serializer.toJson<int>(deviceSeq),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'staffId': serializer.toJson<String?>(staffId),
      'approvedBy': serializer.toJson<String?>(approvedBy),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'rejectedCode': serializer.toJson<String?>(rejectedCode),
    };
  }

  OutboxRow copyWith({
    String? id,
    String? type,
    int? version,
    String? entityId,
    int? deviceSeq,
    DateTime? occurredAt,
    Value<String?> staffId = const Value.absent(),
    Value<String?> approvedBy = const Value.absent(),
    String? payloadJson,
    Value<String?> rejectedCode = const Value.absent(),
  }) => OutboxRow(
    id: id ?? this.id,
    type: type ?? this.type,
    version: version ?? this.version,
    entityId: entityId ?? this.entityId,
    deviceSeq: deviceSeq ?? this.deviceSeq,
    occurredAt: occurredAt ?? this.occurredAt,
    staffId: staffId.present ? staffId.value : this.staffId,
    approvedBy: approvedBy.present ? approvedBy.value : this.approvedBy,
    payloadJson: payloadJson ?? this.payloadJson,
    rejectedCode: rejectedCode.present ? rejectedCode.value : this.rejectedCode,
  );
  OutboxRow copyWithCompanion(OutboxEventsCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      version: data.version.present ? data.version.value : this.version,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      deviceSeq: data.deviceSeq.present ? data.deviceSeq.value : this.deviceSeq,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      approvedBy:
          data.approvedBy.present ? data.approvedBy.value : this.approvedBy,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      rejectedCode:
          data.rejectedCode.present
              ? data.rejectedCode.value
              : this.rejectedCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('version: $version, ')
          ..write('entityId: $entityId, ')
          ..write('deviceSeq: $deviceSeq, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('staffId: $staffId, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rejectedCode: $rejectedCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    version,
    entityId,
    deviceSeq,
    occurredAt,
    staffId,
    approvedBy,
    payloadJson,
    rejectedCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.version == this.version &&
          other.entityId == this.entityId &&
          other.deviceSeq == this.deviceSeq &&
          other.occurredAt == this.occurredAt &&
          other.staffId == this.staffId &&
          other.approvedBy == this.approvedBy &&
          other.payloadJson == this.payloadJson &&
          other.rejectedCode == this.rejectedCode);
}

class OutboxEventsCompanion extends UpdateCompanion<OutboxRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<int> version;
  final Value<String> entityId;
  final Value<int> deviceSeq;
  final Value<DateTime> occurredAt;
  final Value<String?> staffId;
  final Value<String?> approvedBy;
  final Value<String> payloadJson;
  final Value<String?> rejectedCode;
  final Value<int> rowid;
  const OutboxEventsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.version = const Value.absent(),
    this.entityId = const Value.absent(),
    this.deviceSeq = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.staffId = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rejectedCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxEventsCompanion.insert({
    required String id,
    required String type,
    this.version = const Value.absent(),
    required String entityId,
    required int deviceSeq,
    required DateTime occurredAt,
    this.staffId = const Value.absent(),
    this.approvedBy = const Value.absent(),
    required String payloadJson,
    this.rejectedCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       entityId = Value(entityId),
       deviceSeq = Value(deviceSeq),
       occurredAt = Value(occurredAt),
       payloadJson = Value(payloadJson);
  static Insertable<OutboxRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<int>? version,
    Expression<String>? entityId,
    Expression<int>? deviceSeq,
    Expression<DateTime>? occurredAt,
    Expression<String>? staffId,
    Expression<String>? approvedBy,
    Expression<String>? payloadJson,
    Expression<String>? rejectedCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (version != null) 'version': version,
      if (entityId != null) 'entity_id': entityId,
      if (deviceSeq != null) 'device_seq': deviceSeq,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (staffId != null) 'staff_id': staffId,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rejectedCode != null) 'rejected_code': rejectedCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<int>? version,
    Value<String>? entityId,
    Value<int>? deviceSeq,
    Value<DateTime>? occurredAt,
    Value<String?>? staffId,
    Value<String?>? approvedBy,
    Value<String>? payloadJson,
    Value<String?>? rejectedCode,
    Value<int>? rowid,
  }) {
    return OutboxEventsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      version: version ?? this.version,
      entityId: entityId ?? this.entityId,
      deviceSeq: deviceSeq ?? this.deviceSeq,
      occurredAt: occurredAt ?? this.occurredAt,
      staffId: staffId ?? this.staffId,
      approvedBy: approvedBy ?? this.approvedBy,
      payloadJson: payloadJson ?? this.payloadJson,
      rejectedCode: rejectedCode ?? this.rejectedCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (deviceSeq.present) {
      map['device_seq'] = Variable<int>(deviceSeq.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (staffId.present) {
      map['staff_id'] = Variable<String>(staffId.value);
    }
    if (approvedBy.present) {
      map['approved_by'] = Variable<String>(approvedBy.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rejectedCode.present) {
      map['rejected_code'] = Variable<String>(rejectedCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEventsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('version: $version, ')
          ..write('entityId: $entityId, ')
          ..write('deviceSeq: $deviceSeq, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('staffId: $staffId, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rejectedCode: $rejectedCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, OrderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('takeaway'),
  );
  static const VerificationMeta _tableLabelMeta = const VerificationMeta(
    'tableLabel',
  );
  @override
  late final GeneratedColumn<String> tableLabel = GeneratedColumn<String>(
    'table_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tableIdMeta = const VerificationMeta(
    'tableId',
  );
  @override
  late final GeneratedColumn<String> tableId = GeneratedColumn<String>(
    'table_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _receiptNumberMeta = const VerificationMeta(
    'receiptNumber',
  );
  @override
  late final GeneratedColumn<String> receiptNumber = GeneratedColumn<String>(
    'receipt_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _billRequestedAtMeta = const VerificationMeta(
    'billRequestedAt',
  );
  @override
  late final GeneratedColumn<DateTime> billRequestedAt =
      GeneratedColumn<DateTime>(
        'bill_requested_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    status,
    type,
    tableLabel,
    tableId,
    openedAt,
    closedAt,
    total,
    receiptNumber,
    billRequestedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('table_label')) {
      context.handle(
        _tableLabelMeta,
        tableLabel.isAcceptableOrUnknown(data['table_label']!, _tableLabelMeta),
      );
    }
    if (data.containsKey('table_id')) {
      context.handle(
        _tableIdMeta,
        tableId.isAcceptableOrUnknown(data['table_id']!, _tableIdMeta),
      );
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    }
    if (data.containsKey('receipt_number')) {
      context.handle(
        _receiptNumberMeta,
        receiptNumber.isAcceptableOrUnknown(
          data['receipt_number']!,
          _receiptNumberMeta,
        ),
      );
    }
    if (data.containsKey('bill_requested_at')) {
      context.handle(
        _billRequestedAtMeta,
        billRequestedAt.isAcceptableOrUnknown(
          data['bill_requested_at']!,
          _billRequestedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}type'],
          )!,
      tableLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_label'],
      ),
      tableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_id'],
      ),
      openedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}opened_at'],
          )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      total:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}total'],
          )!,
      receiptNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_number'],
      ),
      billRequestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}bill_requested_at'],
      ),
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class OrderRow extends DataClass implements Insertable<OrderRow> {
  final String id;

  /// open | paid | cancelled
  final String status;

  /// takeaway | table
  final String type;

  /// Table name snapshot ("4") — stays right even if the table is renamed later.
  final String? tableLabel;

  /// Table the order is on; null = counter / takeaway (v5).
  final String? tableId;
  final DateTime openedAt;
  final DateTime? closedAt;

  /// TTC in millimes, set when the order is paid.
  final int total;

  /// "T1-000042", set when the order is paid.
  final String? receiptNumber;

  /// A server asked for the bill ("l'addition") from a tablet (v6).
  final DateTime? billRequestedAt;
  const OrderRow({
    required this.id,
    required this.status,
    required this.type,
    this.tableLabel,
    this.tableId,
    required this.openedAt,
    this.closedAt,
    required this.total,
    this.receiptNumber,
    this.billRequestedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status'] = Variable<String>(status);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || tableLabel != null) {
      map['table_label'] = Variable<String>(tableLabel);
    }
    if (!nullToAbsent || tableId != null) {
      map['table_id'] = Variable<String>(tableId);
    }
    map['opened_at'] = Variable<DateTime>(openedAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    map['total'] = Variable<int>(total);
    if (!nullToAbsent || receiptNumber != null) {
      map['receipt_number'] = Variable<String>(receiptNumber);
    }
    if (!nullToAbsent || billRequestedAt != null) {
      map['bill_requested_at'] = Variable<DateTime>(billRequestedAt);
    }
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      status: Value(status),
      type: Value(type),
      tableLabel:
          tableLabel == null && nullToAbsent
              ? const Value.absent()
              : Value(tableLabel),
      tableId:
          tableId == null && nullToAbsent
              ? const Value.absent()
              : Value(tableId),
      openedAt: Value(openedAt),
      closedAt:
          closedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(closedAt),
      total: Value(total),
      receiptNumber:
          receiptNumber == null && nullToAbsent
              ? const Value.absent()
              : Value(receiptNumber),
      billRequestedAt:
          billRequestedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(billRequestedAt),
    );
  }

  factory OrderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderRow(
      id: serializer.fromJson<String>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      type: serializer.fromJson<String>(json['type']),
      tableLabel: serializer.fromJson<String?>(json['tableLabel']),
      tableId: serializer.fromJson<String?>(json['tableId']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      total: serializer.fromJson<int>(json['total']),
      receiptNumber: serializer.fromJson<String?>(json['receiptNumber']),
      billRequestedAt: serializer.fromJson<DateTime?>(json['billRequestedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(status),
      'type': serializer.toJson<String>(type),
      'tableLabel': serializer.toJson<String?>(tableLabel),
      'tableId': serializer.toJson<String?>(tableId),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'total': serializer.toJson<int>(total),
      'receiptNumber': serializer.toJson<String?>(receiptNumber),
      'billRequestedAt': serializer.toJson<DateTime?>(billRequestedAt),
    };
  }

  OrderRow copyWith({
    String? id,
    String? status,
    String? type,
    Value<String?> tableLabel = const Value.absent(),
    Value<String?> tableId = const Value.absent(),
    DateTime? openedAt,
    Value<DateTime?> closedAt = const Value.absent(),
    int? total,
    Value<String?> receiptNumber = const Value.absent(),
    Value<DateTime?> billRequestedAt = const Value.absent(),
  }) => OrderRow(
    id: id ?? this.id,
    status: status ?? this.status,
    type: type ?? this.type,
    tableLabel: tableLabel.present ? tableLabel.value : this.tableLabel,
    tableId: tableId.present ? tableId.value : this.tableId,
    openedAt: openedAt ?? this.openedAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    total: total ?? this.total,
    receiptNumber:
        receiptNumber.present ? receiptNumber.value : this.receiptNumber,
    billRequestedAt:
        billRequestedAt.present ? billRequestedAt.value : this.billRequestedAt,
  );
  OrderRow copyWithCompanion(OrdersCompanion data) {
    return OrderRow(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      type: data.type.present ? data.type.value : this.type,
      tableLabel:
          data.tableLabel.present ? data.tableLabel.value : this.tableLabel,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      total: data.total.present ? data.total.value : this.total,
      receiptNumber:
          data.receiptNumber.present
              ? data.receiptNumber.value
              : this.receiptNumber,
      billRequestedAt:
          data.billRequestedAt.present
              ? data.billRequestedAt.value
              : this.billRequestedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderRow(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('tableLabel: $tableLabel, ')
          ..write('tableId: $tableId, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('total: $total, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('billRequestedAt: $billRequestedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    status,
    type,
    tableLabel,
    tableId,
    openedAt,
    closedAt,
    total,
    receiptNumber,
    billRequestedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderRow &&
          other.id == this.id &&
          other.status == this.status &&
          other.type == this.type &&
          other.tableLabel == this.tableLabel &&
          other.tableId == this.tableId &&
          other.openedAt == this.openedAt &&
          other.closedAt == this.closedAt &&
          other.total == this.total &&
          other.receiptNumber == this.receiptNumber &&
          other.billRequestedAt == this.billRequestedAt);
}

class OrdersCompanion extends UpdateCompanion<OrderRow> {
  final Value<String> id;
  final Value<String> status;
  final Value<String> type;
  final Value<String?> tableLabel;
  final Value<String?> tableId;
  final Value<DateTime> openedAt;
  final Value<DateTime?> closedAt;
  final Value<int> total;
  final Value<String?> receiptNumber;
  final Value<DateTime?> billRequestedAt;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.type = const Value.absent(),
    this.tableLabel = const Value.absent(),
    this.tableId = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.total = const Value.absent(),
    this.receiptNumber = const Value.absent(),
    this.billRequestedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    this.status = const Value.absent(),
    this.type = const Value.absent(),
    this.tableLabel = const Value.absent(),
    this.tableId = const Value.absent(),
    required DateTime openedAt,
    this.closedAt = const Value.absent(),
    this.total = const Value.absent(),
    this.receiptNumber = const Value.absent(),
    this.billRequestedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       openedAt = Value(openedAt);
  static Insertable<OrderRow> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<String>? type,
    Expression<String>? tableLabel,
    Expression<String>? tableId,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? closedAt,
    Expression<int>? total,
    Expression<String>? receiptNumber,
    Expression<DateTime>? billRequestedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (tableLabel != null) 'table_label': tableLabel,
      if (tableId != null) 'table_id': tableId,
      if (openedAt != null) 'opened_at': openedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (total != null) 'total': total,
      if (receiptNumber != null) 'receipt_number': receiptNumber,
      if (billRequestedAt != null) 'bill_requested_at': billRequestedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith({
    Value<String>? id,
    Value<String>? status,
    Value<String>? type,
    Value<String?>? tableLabel,
    Value<String?>? tableId,
    Value<DateTime>? openedAt,
    Value<DateTime?>? closedAt,
    Value<int>? total,
    Value<String?>? receiptNumber,
    Value<DateTime?>? billRequestedAt,
    Value<int>? rowid,
  }) {
    return OrdersCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      type: type ?? this.type,
      tableLabel: tableLabel ?? this.tableLabel,
      tableId: tableId ?? this.tableId,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      total: total ?? this.total,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      billRequestedAt: billRequestedAt ?? this.billRequestedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (tableLabel.present) {
      map['table_label'] = Variable<String>(tableLabel.value);
    }
    if (tableId.present) {
      map['table_id'] = Variable<String>(tableId.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (receiptNumber.present) {
      map['receipt_number'] = Variable<String>(receiptNumber.value);
    }
    if (billRequestedAt.present) {
      map['bill_requested_at'] = Variable<DateTime>(billRequestedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('tableLabel: $tableLabel, ')
          ..write('tableId: $tableId, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('total: $total, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('billRequestedAt: $billRequestedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderLinesTable extends OrderLines
    with TableInfo<$OrderLinesTable, OrderLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<int> unitPrice = GeneratedColumn<int>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiersPriceMeta = const VerificationMeta(
    'modifiersPrice',
  );
  @override
  late final GeneratedColumn<int> modifiersPrice = GeneratedColumn<int>(
    'modifiers_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _modifiersJsonMeta = const VerificationMeta(
    'modifiersJson',
  );
  @override
  late final GeneratedColumn<String> modifiersJson = GeneratedColumn<String>(
    'modifiers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<int> qty = GeneratedColumn<int>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatRateBpMeta = const VerificationMeta(
    'vatRateBp',
  );
  @override
  late final GeneratedColumn<int> vatRateBp = GeneratedColumn<int>(
    'vat_rate_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stationMeta = const VerificationMeta(
    'station',
  );
  @override
  late final GeneratedColumn<String> station = GeneratedColumn<String>(
    'station',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidedMeta = const VerificationMeta('voided');
  @override
  late final GeneratedColumn<bool> voided = GeneratedColumn<bool>(
    'voided',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("voided" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentIdMeta = const VerificationMeta(
    'paymentId',
  );
  @override
  late final GeneratedColumn<String> paymentId = GeneratedColumn<String>(
    'payment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderId,
    productId,
    name,
    unitPrice,
    modifiersPrice,
    modifiersJson,
    qty,
    vatRateBp,
    station,
    note,
    voided,
    createdAt,
    paymentId,
    sentAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('modifiers_price')) {
      context.handle(
        _modifiersPriceMeta,
        modifiersPrice.isAcceptableOrUnknown(
          data['modifiers_price']!,
          _modifiersPriceMeta,
        ),
      );
    }
    if (data.containsKey('modifiers_json')) {
      context.handle(
        _modifiersJsonMeta,
        modifiersJson.isAcceptableOrUnknown(
          data['modifiers_json']!,
          _modifiersJsonMeta,
        ),
      );
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('vat_rate_bp')) {
      context.handle(
        _vatRateBpMeta,
        vatRateBp.isAcceptableOrUnknown(data['vat_rate_bp']!, _vatRateBpMeta),
      );
    } else if (isInserting) {
      context.missing(_vatRateBpMeta);
    }
    if (data.containsKey('station')) {
      context.handle(
        _stationMeta,
        station.isAcceptableOrUnknown(data['station']!, _stationMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('voided')) {
      context.handle(
        _voidedMeta,
        voided.isAcceptableOrUnknown(data['voided']!, _voidedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('payment_id')) {
      context.handle(
        _paymentIdMeta,
        paymentId.isAcceptableOrUnknown(data['payment_id']!, _paymentIdMeta),
      );
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderLineRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      orderId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}order_id'],
          )!,
      productId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}product_id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      unitPrice:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}unit_price'],
          )!,
      modifiersPrice:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}modifiers_price'],
          )!,
      modifiersJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}modifiers_json'],
          )!,
      qty:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}qty'],
          )!,
      vatRateBp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}vat_rate_bp'],
          )!,
      station:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}station'],
          )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      voided:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}voided'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      paymentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_id'],
      ),
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      ),
    );
  }

  @override
  $OrderLinesTable createAlias(String alias) {
    return $OrderLinesTable(attachedDatabase, alias);
  }
}

class OrderLineRow extends DataClass implements Insertable<OrderLineRow> {
  final String id;
  final String orderId;
  final String productId;
  final String name;

  /// Product price TTC in millimes (without modifiers).
  final int unitPrice;

  /// Sum of the chosen modifiers' extra prices, per unit.
  final int modifiersPrice;

  /// [{"id","name","extraPrice"}] — chosen modifiers.
  final String modifiersJson;
  final int qty;
  final int vatRateBp;
  final String station;
  final String? note;
  final bool voided;
  final DateTime createdAt;

  /// Set when this line was paid on its own ("split by items", v5) — it can't be changed anymore.
  final String? paymentId;

  /// When the line was sent to the bar / kitchen printer (v8). Null = not sent yet.
  final DateTime? sentAt;
  const OrderLineRow({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.modifiersPrice,
    required this.modifiersJson,
    required this.qty,
    required this.vatRateBp,
    required this.station,
    this.note,
    required this.voided,
    required this.createdAt,
    this.paymentId,
    this.sentAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['product_id'] = Variable<String>(productId);
    map['name'] = Variable<String>(name);
    map['unit_price'] = Variable<int>(unitPrice);
    map['modifiers_price'] = Variable<int>(modifiersPrice);
    map['modifiers_json'] = Variable<String>(modifiersJson);
    map['qty'] = Variable<int>(qty);
    map['vat_rate_bp'] = Variable<int>(vatRateBp);
    map['station'] = Variable<String>(station);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['voided'] = Variable<bool>(voided);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || paymentId != null) {
      map['payment_id'] = Variable<String>(paymentId);
    }
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<DateTime>(sentAt);
    }
    return map;
  }

  OrderLinesCompanion toCompanion(bool nullToAbsent) {
    return OrderLinesCompanion(
      id: Value(id),
      orderId: Value(orderId),
      productId: Value(productId),
      name: Value(name),
      unitPrice: Value(unitPrice),
      modifiersPrice: Value(modifiersPrice),
      modifiersJson: Value(modifiersJson),
      qty: Value(qty),
      vatRateBp: Value(vatRateBp),
      station: Value(station),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      voided: Value(voided),
      createdAt: Value(createdAt),
      paymentId:
          paymentId == null && nullToAbsent
              ? const Value.absent()
              : Value(paymentId),
      sentAt:
          sentAt == null && nullToAbsent ? const Value.absent() : Value(sentAt),
    );
  }

  factory OrderLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderLineRow(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      productId: serializer.fromJson<String>(json['productId']),
      name: serializer.fromJson<String>(json['name']),
      unitPrice: serializer.fromJson<int>(json['unitPrice']),
      modifiersPrice: serializer.fromJson<int>(json['modifiersPrice']),
      modifiersJson: serializer.fromJson<String>(json['modifiersJson']),
      qty: serializer.fromJson<int>(json['qty']),
      vatRateBp: serializer.fromJson<int>(json['vatRateBp']),
      station: serializer.fromJson<String>(json['station']),
      note: serializer.fromJson<String?>(json['note']),
      voided: serializer.fromJson<bool>(json['voided']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      paymentId: serializer.fromJson<String?>(json['paymentId']),
      sentAt: serializer.fromJson<DateTime?>(json['sentAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'productId': serializer.toJson<String>(productId),
      'name': serializer.toJson<String>(name),
      'unitPrice': serializer.toJson<int>(unitPrice),
      'modifiersPrice': serializer.toJson<int>(modifiersPrice),
      'modifiersJson': serializer.toJson<String>(modifiersJson),
      'qty': serializer.toJson<int>(qty),
      'vatRateBp': serializer.toJson<int>(vatRateBp),
      'station': serializer.toJson<String>(station),
      'note': serializer.toJson<String?>(note),
      'voided': serializer.toJson<bool>(voided),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'paymentId': serializer.toJson<String?>(paymentId),
      'sentAt': serializer.toJson<DateTime?>(sentAt),
    };
  }

  OrderLineRow copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? name,
    int? unitPrice,
    int? modifiersPrice,
    String? modifiersJson,
    int? qty,
    int? vatRateBp,
    String? station,
    Value<String?> note = const Value.absent(),
    bool? voided,
    DateTime? createdAt,
    Value<String?> paymentId = const Value.absent(),
    Value<DateTime?> sentAt = const Value.absent(),
  }) => OrderLineRow(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    productId: productId ?? this.productId,
    name: name ?? this.name,
    unitPrice: unitPrice ?? this.unitPrice,
    modifiersPrice: modifiersPrice ?? this.modifiersPrice,
    modifiersJson: modifiersJson ?? this.modifiersJson,
    qty: qty ?? this.qty,
    vatRateBp: vatRateBp ?? this.vatRateBp,
    station: station ?? this.station,
    note: note.present ? note.value : this.note,
    voided: voided ?? this.voided,
    createdAt: createdAt ?? this.createdAt,
    paymentId: paymentId.present ? paymentId.value : this.paymentId,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
  );
  OrderLineRow copyWithCompanion(OrderLinesCompanion data) {
    return OrderLineRow(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      productId: data.productId.present ? data.productId.value : this.productId,
      name: data.name.present ? data.name.value : this.name,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      modifiersPrice:
          data.modifiersPrice.present
              ? data.modifiersPrice.value
              : this.modifiersPrice,
      modifiersJson:
          data.modifiersJson.present
              ? data.modifiersJson.value
              : this.modifiersJson,
      qty: data.qty.present ? data.qty.value : this.qty,
      vatRateBp: data.vatRateBp.present ? data.vatRateBp.value : this.vatRateBp,
      station: data.station.present ? data.station.value : this.station,
      note: data.note.present ? data.note.value : this.note,
      voided: data.voided.present ? data.voided.value : this.voided,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      paymentId: data.paymentId.present ? data.paymentId.value : this.paymentId,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderLineRow(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('modifiersPrice: $modifiersPrice, ')
          ..write('modifiersJson: $modifiersJson, ')
          ..write('qty: $qty, ')
          ..write('vatRateBp: $vatRateBp, ')
          ..write('station: $station, ')
          ..write('note: $note, ')
          ..write('voided: $voided, ')
          ..write('createdAt: $createdAt, ')
          ..write('paymentId: $paymentId, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderId,
    productId,
    name,
    unitPrice,
    modifiersPrice,
    modifiersJson,
    qty,
    vatRateBp,
    station,
    note,
    voided,
    createdAt,
    paymentId,
    sentAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderLineRow &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.productId == this.productId &&
          other.name == this.name &&
          other.unitPrice == this.unitPrice &&
          other.modifiersPrice == this.modifiersPrice &&
          other.modifiersJson == this.modifiersJson &&
          other.qty == this.qty &&
          other.vatRateBp == this.vatRateBp &&
          other.station == this.station &&
          other.note == this.note &&
          other.voided == this.voided &&
          other.createdAt == this.createdAt &&
          other.paymentId == this.paymentId &&
          other.sentAt == this.sentAt);
}

class OrderLinesCompanion extends UpdateCompanion<OrderLineRow> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> productId;
  final Value<String> name;
  final Value<int> unitPrice;
  final Value<int> modifiersPrice;
  final Value<String> modifiersJson;
  final Value<int> qty;
  final Value<int> vatRateBp;
  final Value<String> station;
  final Value<String?> note;
  final Value<bool> voided;
  final Value<DateTime> createdAt;
  final Value<String?> paymentId;
  final Value<DateTime?> sentAt;
  final Value<int> rowid;
  const OrderLinesCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.productId = const Value.absent(),
    this.name = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.modifiersPrice = const Value.absent(),
    this.modifiersJson = const Value.absent(),
    this.qty = const Value.absent(),
    this.vatRateBp = const Value.absent(),
    this.station = const Value.absent(),
    this.note = const Value.absent(),
    this.voided = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.paymentId = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderLinesCompanion.insert({
    required String id,
    required String orderId,
    required String productId,
    required String name,
    required int unitPrice,
    this.modifiersPrice = const Value.absent(),
    this.modifiersJson = const Value.absent(),
    required int qty,
    required int vatRateBp,
    this.station = const Value.absent(),
    this.note = const Value.absent(),
    this.voided = const Value.absent(),
    required DateTime createdAt,
    this.paymentId = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderId = Value(orderId),
       productId = Value(productId),
       name = Value(name),
       unitPrice = Value(unitPrice),
       qty = Value(qty),
       vatRateBp = Value(vatRateBp),
       createdAt = Value(createdAt);
  static Insertable<OrderLineRow> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? productId,
    Expression<String>? name,
    Expression<int>? unitPrice,
    Expression<int>? modifiersPrice,
    Expression<String>? modifiersJson,
    Expression<int>? qty,
    Expression<int>? vatRateBp,
    Expression<String>? station,
    Expression<String>? note,
    Expression<bool>? voided,
    Expression<DateTime>? createdAt,
    Expression<String>? paymentId,
    Expression<DateTime>? sentAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (productId != null) 'product_id': productId,
      if (name != null) 'name': name,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (modifiersPrice != null) 'modifiers_price': modifiersPrice,
      if (modifiersJson != null) 'modifiers_json': modifiersJson,
      if (qty != null) 'qty': qty,
      if (vatRateBp != null) 'vat_rate_bp': vatRateBp,
      if (station != null) 'station': station,
      if (note != null) 'note': note,
      if (voided != null) 'voided': voided,
      if (createdAt != null) 'created_at': createdAt,
      if (paymentId != null) 'payment_id': paymentId,
      if (sentAt != null) 'sent_at': sentAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? orderId,
    Value<String>? productId,
    Value<String>? name,
    Value<int>? unitPrice,
    Value<int>? modifiersPrice,
    Value<String>? modifiersJson,
    Value<int>? qty,
    Value<int>? vatRateBp,
    Value<String>? station,
    Value<String?>? note,
    Value<bool>? voided,
    Value<DateTime>? createdAt,
    Value<String?>? paymentId,
    Value<DateTime?>? sentAt,
    Value<int>? rowid,
  }) {
    return OrderLinesCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      modifiersPrice: modifiersPrice ?? this.modifiersPrice,
      modifiersJson: modifiersJson ?? this.modifiersJson,
      qty: qty ?? this.qty,
      vatRateBp: vatRateBp ?? this.vatRateBp,
      station: station ?? this.station,
      note: note ?? this.note,
      voided: voided ?? this.voided,
      createdAt: createdAt ?? this.createdAt,
      paymentId: paymentId ?? this.paymentId,
      sentAt: sentAt ?? this.sentAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<int>(unitPrice.value);
    }
    if (modifiersPrice.present) {
      map['modifiers_price'] = Variable<int>(modifiersPrice.value);
    }
    if (modifiersJson.present) {
      map['modifiers_json'] = Variable<String>(modifiersJson.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (vatRateBp.present) {
      map['vat_rate_bp'] = Variable<int>(vatRateBp.value);
    }
    if (station.present) {
      map['station'] = Variable<String>(station.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (voided.present) {
      map['voided'] = Variable<bool>(voided.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (paymentId.present) {
      map['payment_id'] = Variable<String>(paymentId.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderLinesCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('modifiersPrice: $modifiersPrice, ')
          ..write('modifiersJson: $modifiersJson, ')
          ..write('qty: $qty, ')
          ..write('vatRateBp: $vatRateBp, ')
          ..write('station: $station, ')
          ..write('note: $note, ')
          ..write('voided: $voided, ')
          ..write('createdAt: $createdAt, ')
          ..write('paymentId: $paymentId, ')
          ..write('sentAt: $sentAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments
    with TableInfo<$PaymentsTable, PaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenderedMeta = const VerificationMeta(
    'tendered',
  );
  @override
  late final GeneratedColumn<int> tendered = GeneratedColumn<int>(
    'tendered',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changeGivenMeta = const VerificationMeta(
    'changeGiven',
  );
  @override
  late final GeneratedColumn<int> changeGiven = GeneratedColumn<int>(
    'change_given',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _drawerIdMeta = const VerificationMeta(
    'drawerId',
  );
  @override
  late final GeneratedColumn<String> drawerId = GeneratedColumn<String>(
    'drawer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderId,
    method,
    amount,
    tendered,
    changeGiven,
    createdAt,
    drawerId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('tendered')) {
      context.handle(
        _tenderedMeta,
        tendered.isAcceptableOrUnknown(data['tendered']!, _tenderedMeta),
      );
    } else if (isInserting) {
      context.missing(_tenderedMeta);
    }
    if (data.containsKey('change_given')) {
      context.handle(
        _changeGivenMeta,
        changeGiven.isAcceptableOrUnknown(
          data['change_given']!,
          _changeGivenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changeGivenMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('drawer_id')) {
      context.handle(
        _drawerIdMeta,
        drawerId.isAcceptableOrUnknown(data['drawer_id']!, _drawerIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      orderId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}order_id'],
          )!,
      method:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}method'],
          )!,
      amount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}amount'],
          )!,
      tendered:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}tendered'],
          )!,
      changeGiven:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}change_given'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      drawerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drawer_id'],
      ),
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class PaymentRow extends DataClass implements Insertable<PaymentRow> {
  final String id;
  final String orderId;

  /// cash | card
  final String method;
  final int amount;
  final int tendered;
  final int changeGiven;
  final DateTime createdAt;

  /// Cash drawer (device id) the money went into (v7) — for the cash session totals.
  final String? drawerId;
  const PaymentRow({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    required this.tendered,
    required this.changeGiven,
    required this.createdAt,
    this.drawerId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['method'] = Variable<String>(method);
    map['amount'] = Variable<int>(amount);
    map['tendered'] = Variable<int>(tendered);
    map['change_given'] = Variable<int>(changeGiven);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || drawerId != null) {
      map['drawer_id'] = Variable<String>(drawerId);
    }
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      method: Value(method),
      amount: Value(amount),
      tendered: Value(tendered),
      changeGiven: Value(changeGiven),
      createdAt: Value(createdAt),
      drawerId:
          drawerId == null && nullToAbsent
              ? const Value.absent()
              : Value(drawerId),
    );
  }

  factory PaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentRow(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      method: serializer.fromJson<String>(json['method']),
      amount: serializer.fromJson<int>(json['amount']),
      tendered: serializer.fromJson<int>(json['tendered']),
      changeGiven: serializer.fromJson<int>(json['changeGiven']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      drawerId: serializer.fromJson<String?>(json['drawerId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'method': serializer.toJson<String>(method),
      'amount': serializer.toJson<int>(amount),
      'tendered': serializer.toJson<int>(tendered),
      'changeGiven': serializer.toJson<int>(changeGiven),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'drawerId': serializer.toJson<String?>(drawerId),
    };
  }

  PaymentRow copyWith({
    String? id,
    String? orderId,
    String? method,
    int? amount,
    int? tendered,
    int? changeGiven,
    DateTime? createdAt,
    Value<String?> drawerId = const Value.absent(),
  }) => PaymentRow(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    method: method ?? this.method,
    amount: amount ?? this.amount,
    tendered: tendered ?? this.tendered,
    changeGiven: changeGiven ?? this.changeGiven,
    createdAt: createdAt ?? this.createdAt,
    drawerId: drawerId.present ? drawerId.value : this.drawerId,
  );
  PaymentRow copyWithCompanion(PaymentsCompanion data) {
    return PaymentRow(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      method: data.method.present ? data.method.value : this.method,
      amount: data.amount.present ? data.amount.value : this.amount,
      tendered: data.tendered.present ? data.tendered.value : this.tendered,
      changeGiven:
          data.changeGiven.present ? data.changeGiven.value : this.changeGiven,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      drawerId: data.drawerId.present ? data.drawerId.value : this.drawerId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentRow(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('method: $method, ')
          ..write('amount: $amount, ')
          ..write('tendered: $tendered, ')
          ..write('changeGiven: $changeGiven, ')
          ..write('createdAt: $createdAt, ')
          ..write('drawerId: $drawerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderId,
    method,
    amount,
    tendered,
    changeGiven,
    createdAt,
    drawerId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentRow &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.method == this.method &&
          other.amount == this.amount &&
          other.tendered == this.tendered &&
          other.changeGiven == this.changeGiven &&
          other.createdAt == this.createdAt &&
          other.drawerId == this.drawerId);
}

class PaymentsCompanion extends UpdateCompanion<PaymentRow> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> method;
  final Value<int> amount;
  final Value<int> tendered;
  final Value<int> changeGiven;
  final Value<DateTime> createdAt;
  final Value<String?> drawerId;
  final Value<int> rowid;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.method = const Value.absent(),
    this.amount = const Value.absent(),
    this.tendered = const Value.absent(),
    this.changeGiven = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.drawerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentsCompanion.insert({
    required String id,
    required String orderId,
    required String method,
    required int amount,
    required int tendered,
    required int changeGiven,
    required DateTime createdAt,
    this.drawerId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderId = Value(orderId),
       method = Value(method),
       amount = Value(amount),
       tendered = Value(tendered),
       changeGiven = Value(changeGiven),
       createdAt = Value(createdAt);
  static Insertable<PaymentRow> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? method,
    Expression<int>? amount,
    Expression<int>? tendered,
    Expression<int>? changeGiven,
    Expression<DateTime>? createdAt,
    Expression<String>? drawerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (method != null) 'method': method,
      if (amount != null) 'amount': amount,
      if (tendered != null) 'tendered': tendered,
      if (changeGiven != null) 'change_given': changeGiven,
      if (createdAt != null) 'created_at': createdAt,
      if (drawerId != null) 'drawer_id': drawerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? orderId,
    Value<String>? method,
    Value<int>? amount,
    Value<int>? tendered,
    Value<int>? changeGiven,
    Value<DateTime>? createdAt,
    Value<String?>? drawerId,
    Value<int>? rowid,
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      tendered: tendered ?? this.tendered,
      changeGiven: changeGiven ?? this.changeGiven,
      createdAt: createdAt ?? this.createdAt,
      drawerId: drawerId ?? this.drawerId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (tendered.present) {
      map['tendered'] = Variable<int>(tendered.value);
    }
    if (changeGiven.present) {
      map['change_given'] = Variable<int>(changeGiven.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (drawerId.present) {
      map['drawer_id'] = Variable<String>(drawerId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('method: $method, ')
          ..write('amount: $amount, ')
          ..write('tendered: $tendered, ')
          ..write('changeGiven: $changeGiven, ')
          ..write('createdAt: $createdAt, ')
          ..write('drawerId: $drawerId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaffMembersTable extends StaffMembers
    with TableInfo<$StaffMembersTable, StaffRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaffMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinHashMeta = const VerificationMeta(
    'pinHash',
  );
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
    'pin_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, role, pinHash];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staff_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<StaffRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('pin_hash')) {
      context.handle(
        _pinHashMeta,
        pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta),
      );
    } else if (isInserting) {
      context.missing(_pinHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StaffRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaffRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      role:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}role'],
          )!,
      pinHash:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}pin_hash'],
          )!,
    );
  }

  @override
  $StaffMembersTable createAlias(String alias) {
    return $StaffMembersTable(attachedDatabase, alias);
  }
}

class StaffRow extends DataClass implements Insertable<StaffRow> {
  final String id;
  final String name;

  /// manager | cashier | server | kitchen
  final String role;
  final String pinHash;
  const StaffRow({
    required this.id,
    required this.name,
    required this.role,
    required this.pinHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    map['pin_hash'] = Variable<String>(pinHash);
    return map;
  }

  StaffMembersCompanion toCompanion(bool nullToAbsent) {
    return StaffMembersCompanion(
      id: Value(id),
      name: Value(name),
      role: Value(role),
      pinHash: Value(pinHash),
    );
  }

  factory StaffRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaffRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      pinHash: serializer.fromJson<String>(json['pinHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'pinHash': serializer.toJson<String>(pinHash),
    };
  }

  StaffRow copyWith({
    String? id,
    String? name,
    String? role,
    String? pinHash,
  }) => StaffRow(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role ?? this.role,
    pinHash: pinHash ?? this.pinHash,
  );
  StaffRow copyWithCompanion(StaffMembersCompanion data) {
    return StaffRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('pinHash: $pinHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, role, pinHash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.role == this.role &&
          other.pinHash == this.pinHash);
}

class StaffMembersCompanion extends UpdateCompanion<StaffRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> role;
  final Value<String> pinHash;
  final Value<int> rowid;
  const StaffMembersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffMembersCompanion.insert({
    required String id,
    required String name,
    required String role,
    required String pinHash,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       role = Value(role),
       pinHash = Value(pinHash);
  static Insertable<StaffRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? pinHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (pinHash != null) 'pin_hash': pinHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? role,
    Value<String>? pinHash,
    Value<int>? rowid,
  }) {
    return StaffMembersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      pinHash: pinHash ?? this.pinHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StaffMembersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('pinHash: $pinHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FloorAreasTable extends FloorAreas
    with TableInfo<$FloorAreasTable, AreaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FloorAreasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'floor_areas';
  @override
  VerificationContext validateIntegrity(
    Insertable<AreaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AreaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AreaRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      sortOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sort_order'],
          )!,
    );
  }

  @override
  $FloorAreasTable createAlias(String alias) {
    return $FloorAreasTable(attachedDatabase, alias);
  }
}

class AreaRow extends DataClass implements Insertable<AreaRow> {
  final String id;
  final String name;
  final int sortOrder;
  const AreaRow({
    required this.id,
    required this.name,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  FloorAreasCompanion toCompanion(bool nullToAbsent) {
    return FloorAreasCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory AreaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AreaRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AreaRow copyWith({String? id, String? name, int? sortOrder}) => AreaRow(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AreaRow copyWithCompanion(FloorAreasCompanion data) {
    return AreaRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AreaRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AreaRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class FloorAreasCompanion extends UpdateCompanion<AreaRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const FloorAreasCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FloorAreasCompanion.insert({
    required String id,
    required String name,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<AreaRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FloorAreasCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return FloorAreasCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FloorAreasCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiningTablesTable extends DiningTables
    with TableInfo<$DiningTablesTable, DiningTableRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiningTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _areaIdMeta = const VerificationMeta('areaId');
  @override
  late final GeneratedColumn<String> areaId = GeneratedColumn<String>(
    'area_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seatsMeta = const VerificationMeta('seats');
  @override
  late final GeneratedColumn<int> seats = GeneratedColumn<int>(
    'seats',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, areaId, name, seats, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dining_tables';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiningTableRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('area_id')) {
      context.handle(
        _areaIdMeta,
        areaId.isAcceptableOrUnknown(data['area_id']!, _areaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_areaIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('seats')) {
      context.handle(
        _seatsMeta,
        seats.isAcceptableOrUnknown(data['seats']!, _seatsMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiningTableRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiningTableRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      areaId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}area_id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      seats:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}seats'],
          )!,
      sortOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sort_order'],
          )!,
    );
  }

  @override
  $DiningTablesTable createAlias(String alias) {
    return $DiningTablesTable(attachedDatabase, alias);
  }
}

class DiningTableRow extends DataClass implements Insertable<DiningTableRow> {
  final String id;
  final String areaId;
  final String name;
  final int seats;
  final int sortOrder;
  const DiningTableRow({
    required this.id,
    required this.areaId,
    required this.name,
    required this.seats,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['area_id'] = Variable<String>(areaId);
    map['name'] = Variable<String>(name);
    map['seats'] = Variable<int>(seats);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  DiningTablesCompanion toCompanion(bool nullToAbsent) {
    return DiningTablesCompanion(
      id: Value(id),
      areaId: Value(areaId),
      name: Value(name),
      seats: Value(seats),
      sortOrder: Value(sortOrder),
    );
  }

  factory DiningTableRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiningTableRow(
      id: serializer.fromJson<String>(json['id']),
      areaId: serializer.fromJson<String>(json['areaId']),
      name: serializer.fromJson<String>(json['name']),
      seats: serializer.fromJson<int>(json['seats']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'areaId': serializer.toJson<String>(areaId),
      'name': serializer.toJson<String>(name),
      'seats': serializer.toJson<int>(seats),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  DiningTableRow copyWith({
    String? id,
    String? areaId,
    String? name,
    int? seats,
    int? sortOrder,
  }) => DiningTableRow(
    id: id ?? this.id,
    areaId: areaId ?? this.areaId,
    name: name ?? this.name,
    seats: seats ?? this.seats,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  DiningTableRow copyWithCompanion(DiningTablesCompanion data) {
    return DiningTableRow(
      id: data.id.present ? data.id.value : this.id,
      areaId: data.areaId.present ? data.areaId.value : this.areaId,
      name: data.name.present ? data.name.value : this.name,
      seats: data.seats.present ? data.seats.value : this.seats,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiningTableRow(')
          ..write('id: $id, ')
          ..write('areaId: $areaId, ')
          ..write('name: $name, ')
          ..write('seats: $seats, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, areaId, name, seats, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiningTableRow &&
          other.id == this.id &&
          other.areaId == this.areaId &&
          other.name == this.name &&
          other.seats == this.seats &&
          other.sortOrder == this.sortOrder);
}

class DiningTablesCompanion extends UpdateCompanion<DiningTableRow> {
  final Value<String> id;
  final Value<String> areaId;
  final Value<String> name;
  final Value<int> seats;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const DiningTablesCompanion({
    this.id = const Value.absent(),
    this.areaId = const Value.absent(),
    this.name = const Value.absent(),
    this.seats = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiningTablesCompanion.insert({
    required String id,
    required String areaId,
    required String name,
    this.seats = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       areaId = Value(areaId),
       name = Value(name);
  static Insertable<DiningTableRow> custom({
    Expression<String>? id,
    Expression<String>? areaId,
    Expression<String>? name,
    Expression<int>? seats,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (areaId != null) 'area_id': areaId,
      if (name != null) 'name': name,
      if (seats != null) 'seats': seats,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiningTablesCompanion copyWith({
    Value<String>? id,
    Value<String>? areaId,
    Value<String>? name,
    Value<int>? seats,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return DiningTablesCompanion(
      id: id ?? this.id,
      areaId: areaId ?? this.areaId,
      name: name ?? this.name,
      seats: seats ?? this.seats,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (areaId.present) {
      map['area_id'] = Variable<String>(areaId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (seats.present) {
      map['seats'] = Variable<int>(seats.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiningTablesCompanion(')
          ..write('id: $id, ')
          ..write('areaId: $areaId, ')
          ..write('name: $name, ')
          ..write('seats: $seats, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashSessionsTable extends CashSessions
    with TableInfo<$CashSessionsTable, CashSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _drawerIdMeta = const VerificationMeta(
    'drawerId',
  );
  @override
  late final GeneratedColumn<String> drawerId = GeneratedColumn<String>(
    'drawer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedByMeta = const VerificationMeta(
    'openedBy',
  );
  @override
  late final GeneratedColumn<String> openedBy = GeneratedColumn<String>(
    'opened_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openingFloatMeta = const VerificationMeta(
    'openingFloat',
  );
  @override
  late final GeneratedColumn<int> openingFloat = GeneratedColumn<int>(
    'opening_float',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closedByMeta = const VerificationMeta(
    'closedBy',
  );
  @override
  late final GeneratedColumn<String> closedBy = GeneratedColumn<String>(
    'closed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countedCashMeta = const VerificationMeta(
    'countedCash',
  );
  @override
  late final GeneratedColumn<int> countedCash = GeneratedColumn<int>(
    'counted_cash',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedCashMeta = const VerificationMeta(
    'expectedCash',
  );
  @override
  late final GeneratedColumn<int> expectedCash = GeneratedColumn<int>(
    'expected_cash',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    drawerId,
    status,
    openedAt,
    openedBy,
    openingFloat,
    closedAt,
    closedBy,
    countedCash,
    expectedCash,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('drawer_id')) {
      context.handle(
        _drawerIdMeta,
        drawerId.isAcceptableOrUnknown(data['drawer_id']!, _drawerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_drawerIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('opened_by')) {
      context.handle(
        _openedByMeta,
        openedBy.isAcceptableOrUnknown(data['opened_by']!, _openedByMeta),
      );
    }
    if (data.containsKey('opening_float')) {
      context.handle(
        _openingFloatMeta,
        openingFloat.isAcceptableOrUnknown(
          data['opening_float']!,
          _openingFloatMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingFloatMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('closed_by')) {
      context.handle(
        _closedByMeta,
        closedBy.isAcceptableOrUnknown(data['closed_by']!, _closedByMeta),
      );
    }
    if (data.containsKey('counted_cash')) {
      context.handle(
        _countedCashMeta,
        countedCash.isAcceptableOrUnknown(
          data['counted_cash']!,
          _countedCashMeta,
        ),
      );
    }
    if (data.containsKey('expected_cash')) {
      context.handle(
        _expectedCashMeta,
        expectedCash.isAcceptableOrUnknown(
          data['expected_cash']!,
          _expectedCashMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashSessionRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      drawerId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}drawer_id'],
          )!,
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      openedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}opened_at'],
          )!,
      openedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opened_by'],
      ),
      openingFloat:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}opening_float'],
          )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      closedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}closed_by'],
      ),
      countedCash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}counted_cash'],
      ),
      expectedCash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_cash'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $CashSessionsTable createAlias(String alias) {
    return $CashSessionsTable(attachedDatabase, alias);
  }
}

class CashSessionRow extends DataClass implements Insertable<CashSessionRow> {
  final String id;

  /// Device id of the POS whose drawer this is.
  final String drawerId;

  /// open | closed
  final String status;
  final DateTime openedAt;
  final String? openedBy;

  /// Millimes.
  final int openingFloat;
  final DateTime? closedAt;
  final String? closedBy;
  final int? countedCash;
  final int? expectedCash;
  final String? note;
  const CashSessionRow({
    required this.id,
    required this.drawerId,
    required this.status,
    required this.openedAt,
    this.openedBy,
    required this.openingFloat,
    this.closedAt,
    this.closedBy,
    this.countedCash,
    this.expectedCash,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['drawer_id'] = Variable<String>(drawerId);
    map['status'] = Variable<String>(status);
    map['opened_at'] = Variable<DateTime>(openedAt);
    if (!nullToAbsent || openedBy != null) {
      map['opened_by'] = Variable<String>(openedBy);
    }
    map['opening_float'] = Variable<int>(openingFloat);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    if (!nullToAbsent || closedBy != null) {
      map['closed_by'] = Variable<String>(closedBy);
    }
    if (!nullToAbsent || countedCash != null) {
      map['counted_cash'] = Variable<int>(countedCash);
    }
    if (!nullToAbsent || expectedCash != null) {
      map['expected_cash'] = Variable<int>(expectedCash);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  CashSessionsCompanion toCompanion(bool nullToAbsent) {
    return CashSessionsCompanion(
      id: Value(id),
      drawerId: Value(drawerId),
      status: Value(status),
      openedAt: Value(openedAt),
      openedBy:
          openedBy == null && nullToAbsent
              ? const Value.absent()
              : Value(openedBy),
      openingFloat: Value(openingFloat),
      closedAt:
          closedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(closedAt),
      closedBy:
          closedBy == null && nullToAbsent
              ? const Value.absent()
              : Value(closedBy),
      countedCash:
          countedCash == null && nullToAbsent
              ? const Value.absent()
              : Value(countedCash),
      expectedCash:
          expectedCash == null && nullToAbsent
              ? const Value.absent()
              : Value(expectedCash),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory CashSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashSessionRow(
      id: serializer.fromJson<String>(json['id']),
      drawerId: serializer.fromJson<String>(json['drawerId']),
      status: serializer.fromJson<String>(json['status']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      openedBy: serializer.fromJson<String?>(json['openedBy']),
      openingFloat: serializer.fromJson<int>(json['openingFloat']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      closedBy: serializer.fromJson<String?>(json['closedBy']),
      countedCash: serializer.fromJson<int?>(json['countedCash']),
      expectedCash: serializer.fromJson<int?>(json['expectedCash']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'drawerId': serializer.toJson<String>(drawerId),
      'status': serializer.toJson<String>(status),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'openedBy': serializer.toJson<String?>(openedBy),
      'openingFloat': serializer.toJson<int>(openingFloat),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'closedBy': serializer.toJson<String?>(closedBy),
      'countedCash': serializer.toJson<int?>(countedCash),
      'expectedCash': serializer.toJson<int?>(expectedCash),
      'note': serializer.toJson<String?>(note),
    };
  }

  CashSessionRow copyWith({
    String? id,
    String? drawerId,
    String? status,
    DateTime? openedAt,
    Value<String?> openedBy = const Value.absent(),
    int? openingFloat,
    Value<DateTime?> closedAt = const Value.absent(),
    Value<String?> closedBy = const Value.absent(),
    Value<int?> countedCash = const Value.absent(),
    Value<int?> expectedCash = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => CashSessionRow(
    id: id ?? this.id,
    drawerId: drawerId ?? this.drawerId,
    status: status ?? this.status,
    openedAt: openedAt ?? this.openedAt,
    openedBy: openedBy.present ? openedBy.value : this.openedBy,
    openingFloat: openingFloat ?? this.openingFloat,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    closedBy: closedBy.present ? closedBy.value : this.closedBy,
    countedCash: countedCash.present ? countedCash.value : this.countedCash,
    expectedCash: expectedCash.present ? expectedCash.value : this.expectedCash,
    note: note.present ? note.value : this.note,
  );
  CashSessionRow copyWithCompanion(CashSessionsCompanion data) {
    return CashSessionRow(
      id: data.id.present ? data.id.value : this.id,
      drawerId: data.drawerId.present ? data.drawerId.value : this.drawerId,
      status: data.status.present ? data.status.value : this.status,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      openedBy: data.openedBy.present ? data.openedBy.value : this.openedBy,
      openingFloat:
          data.openingFloat.present
              ? data.openingFloat.value
              : this.openingFloat,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      closedBy: data.closedBy.present ? data.closedBy.value : this.closedBy,
      countedCash:
          data.countedCash.present ? data.countedCash.value : this.countedCash,
      expectedCash:
          data.expectedCash.present
              ? data.expectedCash.value
              : this.expectedCash,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashSessionRow(')
          ..write('id: $id, ')
          ..write('drawerId: $drawerId, ')
          ..write('status: $status, ')
          ..write('openedAt: $openedAt, ')
          ..write('openedBy: $openedBy, ')
          ..write('openingFloat: $openingFloat, ')
          ..write('closedAt: $closedAt, ')
          ..write('closedBy: $closedBy, ')
          ..write('countedCash: $countedCash, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    drawerId,
    status,
    openedAt,
    openedBy,
    openingFloat,
    closedAt,
    closedBy,
    countedCash,
    expectedCash,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashSessionRow &&
          other.id == this.id &&
          other.drawerId == this.drawerId &&
          other.status == this.status &&
          other.openedAt == this.openedAt &&
          other.openedBy == this.openedBy &&
          other.openingFloat == this.openingFloat &&
          other.closedAt == this.closedAt &&
          other.closedBy == this.closedBy &&
          other.countedCash == this.countedCash &&
          other.expectedCash == this.expectedCash &&
          other.note == this.note);
}

class CashSessionsCompanion extends UpdateCompanion<CashSessionRow> {
  final Value<String> id;
  final Value<String> drawerId;
  final Value<String> status;
  final Value<DateTime> openedAt;
  final Value<String?> openedBy;
  final Value<int> openingFloat;
  final Value<DateTime?> closedAt;
  final Value<String?> closedBy;
  final Value<int?> countedCash;
  final Value<int?> expectedCash;
  final Value<String?> note;
  final Value<int> rowid;
  const CashSessionsCompanion({
    this.id = const Value.absent(),
    this.drawerId = const Value.absent(),
    this.status = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.openedBy = const Value.absent(),
    this.openingFloat = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.closedBy = const Value.absent(),
    this.countedCash = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashSessionsCompanion.insert({
    required String id,
    required String drawerId,
    this.status = const Value.absent(),
    required DateTime openedAt,
    this.openedBy = const Value.absent(),
    required int openingFloat,
    this.closedAt = const Value.absent(),
    this.closedBy = const Value.absent(),
    this.countedCash = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       drawerId = Value(drawerId),
       openedAt = Value(openedAt),
       openingFloat = Value(openingFloat);
  static Insertable<CashSessionRow> custom({
    Expression<String>? id,
    Expression<String>? drawerId,
    Expression<String>? status,
    Expression<DateTime>? openedAt,
    Expression<String>? openedBy,
    Expression<int>? openingFloat,
    Expression<DateTime>? closedAt,
    Expression<String>? closedBy,
    Expression<int>? countedCash,
    Expression<int>? expectedCash,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (drawerId != null) 'drawer_id': drawerId,
      if (status != null) 'status': status,
      if (openedAt != null) 'opened_at': openedAt,
      if (openedBy != null) 'opened_by': openedBy,
      if (openingFloat != null) 'opening_float': openingFloat,
      if (closedAt != null) 'closed_at': closedAt,
      if (closedBy != null) 'closed_by': closedBy,
      if (countedCash != null) 'counted_cash': countedCash,
      if (expectedCash != null) 'expected_cash': expectedCash,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? drawerId,
    Value<String>? status,
    Value<DateTime>? openedAt,
    Value<String?>? openedBy,
    Value<int>? openingFloat,
    Value<DateTime?>? closedAt,
    Value<String?>? closedBy,
    Value<int?>? countedCash,
    Value<int?>? expectedCash,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return CashSessionsCompanion(
      id: id ?? this.id,
      drawerId: drawerId ?? this.drawerId,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      openedBy: openedBy ?? this.openedBy,
      openingFloat: openingFloat ?? this.openingFloat,
      closedAt: closedAt ?? this.closedAt,
      closedBy: closedBy ?? this.closedBy,
      countedCash: countedCash ?? this.countedCash,
      expectedCash: expectedCash ?? this.expectedCash,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (drawerId.present) {
      map['drawer_id'] = Variable<String>(drawerId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (openedBy.present) {
      map['opened_by'] = Variable<String>(openedBy.value);
    }
    if (openingFloat.present) {
      map['opening_float'] = Variable<int>(openingFloat.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (closedBy.present) {
      map['closed_by'] = Variable<String>(closedBy.value);
    }
    if (countedCash.present) {
      map['counted_cash'] = Variable<int>(countedCash.value);
    }
    if (expectedCash.present) {
      map['expected_cash'] = Variable<int>(expectedCash.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashSessionsCompanion(')
          ..write('id: $id, ')
          ..write('drawerId: $drawerId, ')
          ..write('status: $status, ')
          ..write('openedAt: $openedAt, ')
          ..write('openedBy: $openedBy, ')
          ..write('openingFloat: $openingFloat, ')
          ..write('closedAt: $closedAt, ')
          ..write('closedBy: $closedBy, ')
          ..write('countedCash: $countedCash, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashMovementsTable extends CashMovements
    with TableInfo<$CashMovementsTable, CashMovementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _staffIdMeta = const VerificationMeta(
    'staffId',
  );
  @override
  late final GeneratedColumn<String> staffId = GeneratedColumn<String>(
    'staff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    type,
    amount,
    reason,
    staffId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashMovementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('staff_id')) {
      context.handle(
        _staffIdMeta,
        staffId.isAcceptableOrUnknown(data['staff_id']!, _staffIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashMovementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashMovementRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      sessionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}session_id'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}type'],
          )!,
      amount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}amount'],
          )!,
      reason:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}reason'],
          )!,
      staffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_id'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $CashMovementsTable createAlias(String alias) {
    return $CashMovementsTable(attachedDatabase, alias);
  }
}

class CashMovementRow extends DataClass implements Insertable<CashMovementRow> {
  final String id;
  final String sessionId;

  /// in | out
  final String type;
  final int amount;
  final String reason;
  final String? staffId;
  final DateTime createdAt;
  const CashMovementRow({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.amount,
    required this.reason,
    this.staffId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<int>(amount);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || staffId != null) {
      map['staff_id'] = Variable<String>(staffId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CashMovementsCompanion toCompanion(bool nullToAbsent) {
    return CashMovementsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      type: Value(type),
      amount: Value(amount),
      reason: Value(reason),
      staffId:
          staffId == null && nullToAbsent
              ? const Value.absent()
              : Value(staffId),
      createdAt: Value(createdAt),
    );
  }

  factory CashMovementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashMovementRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<int>(json['amount']),
      reason: serializer.fromJson<String>(json['reason']),
      staffId: serializer.fromJson<String?>(json['staffId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<int>(amount),
      'reason': serializer.toJson<String>(reason),
      'staffId': serializer.toJson<String?>(staffId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CashMovementRow copyWith({
    String? id,
    String? sessionId,
    String? type,
    int? amount,
    String? reason,
    Value<String?> staffId = const Value.absent(),
    DateTime? createdAt,
  }) => CashMovementRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    reason: reason ?? this.reason,
    staffId: staffId.present ? staffId.value : this.staffId,
    createdAt: createdAt ?? this.createdAt,
  );
  CashMovementRow copyWithCompanion(CashMovementsCompanion data) {
    return CashMovementRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      reason: data.reason.present ? data.reason.value : this.reason,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashMovementRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('staffId: $staffId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, type, amount, reason, staffId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashMovementRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.reason == this.reason &&
          other.staffId == this.staffId &&
          other.createdAt == this.createdAt);
}

class CashMovementsCompanion extends UpdateCompanion<CashMovementRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> type;
  final Value<int> amount;
  final Value<String> reason;
  final Value<String?> staffId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CashMovementsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.reason = const Value.absent(),
    this.staffId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashMovementsCompanion.insert({
    required String id,
    required String sessionId,
    required String type,
    required int amount,
    required String reason,
    this.staffId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       type = Value(type),
       amount = Value(amount),
       reason = Value(reason),
       createdAt = Value(createdAt);
  static Insertable<CashMovementRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? type,
    Expression<int>? amount,
    Expression<String>? reason,
    Expression<String>? staffId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (reason != null) 'reason': reason,
      if (staffId != null) 'staff_id': staffId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashMovementsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? type,
    Value<int>? amount,
    Value<String>? reason,
    Value<String?>? staffId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CashMovementsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      staffId: staffId ?? this.staffId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (staffId.present) {
      map['staff_id'] = Variable<String>(staffId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashMovementsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('staffId: $staffId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KvEntriesTable kvEntries = $KvEntriesTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $OutboxEventsTable outboxEvents = $OutboxEventsTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $OrderLinesTable orderLines = $OrderLinesTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $StaffMembersTable staffMembers = $StaffMembersTable(this);
  late final $FloorAreasTable floorAreas = $FloorAreasTable(this);
  late final $DiningTablesTable diningTables = $DiningTablesTable(this);
  late final $CashSessionsTable cashSessions = $CashSessionsTable(this);
  late final $CashMovementsTable cashMovements = $CashMovementsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    kvEntries,
    categories,
    products,
    outboxEvents,
    orders,
    orderLines,
    payments,
    staffMembers,
    floorAreas,
    diningTables,
    cashSessions,
    cashMovements,
  ];
}

typedef $$KvEntriesTableCreateCompanionBuilder =
    KvEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$KvEntriesTableUpdateCompanionBuilder =
    KvEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$KvEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $KvEntriesTable> {
  $$KvEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KvEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $KvEntriesTable> {
  $$KvEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KvEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KvEntriesTable> {
  $$KvEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KvEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KvEntriesTable,
          KvRow,
          $$KvEntriesTableFilterComposer,
          $$KvEntriesTableOrderingComposer,
          $$KvEntriesTableAnnotationComposer,
          $$KvEntriesTableCreateCompanionBuilder,
          $$KvEntriesTableUpdateCompanionBuilder,
          (KvRow, BaseReferences<_$AppDatabase, $KvEntriesTable, KvRow>),
          KvRow,
          PrefetchHooks Function()
        > {
  $$KvEntriesTableTableManager(_$AppDatabase db, $KvEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$KvEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$KvEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$KvEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KvEntriesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => KvEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KvEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KvEntriesTable,
      KvRow,
      $$KvEntriesTableFilterComposer,
      $$KvEntriesTableOrderingComposer,
      $$KvEntriesTableAnnotationComposer,
      $$KvEntriesTableCreateCompanionBuilder,
      $$KvEntriesTableUpdateCompanionBuilder,
      (KvRow, BaseReferences<_$AppDatabase, $KvEntriesTable, KvRow>),
      KvRow,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String name,
      Value<int> sortOrder,
      Value<String?> color,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<String?> color,
      Value<int> rowid,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                color: color,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                color: color,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String id,
      required String categoryId,
      required String name,
      required int price,
      Value<int> vatRateBp,
      Value<String> station,
      Value<String> modifierGroupsJson,
      Value<bool> available,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      Value<String> categoryId,
      Value<String> name,
      Value<int> price,
      Value<int> vatRateBp,
      Value<String> station,
      Value<String> modifierGroupsJson,
      Value<bool> available,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vatRateBp => $composableBuilder(
    column: $table.vatRateBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get station => $composableBuilder(
    column: $table.station,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifierGroupsJson => $composableBuilder(
    column: $table.modifierGroupsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get available => $composableBuilder(
    column: $table.available,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vatRateBp => $composableBuilder(
    column: $table.vatRateBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get station => $composableBuilder(
    column: $table.station,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifierGroupsJson => $composableBuilder(
    column: $table.modifierGroupsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get available => $composableBuilder(
    column: $table.available,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get vatRateBp =>
      $composableBuilder(column: $table.vatRateBp, builder: (column) => column);

  GeneratedColumn<String> get station =>
      $composableBuilder(column: $table.station, builder: (column) => column);

  GeneratedColumn<String> get modifierGroupsJson => $composableBuilder(
    column: $table.modifierGroupsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get available =>
      $composableBuilder(column: $table.available, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          ProductRow,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (
            ProductRow,
            BaseReferences<_$AppDatabase, $ProductsTable, ProductRow>,
          ),
          ProductRow,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> price = const Value.absent(),
                Value<int> vatRateBp = const Value.absent(),
                Value<String> station = const Value.absent(),
                Value<String> modifierGroupsJson = const Value.absent(),
                Value<bool> available = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                categoryId: categoryId,
                name: name,
                price: price,
                vatRateBp: vatRateBp,
                station: station,
                modifierGroupsJson: modifierGroupsJson,
                available: available,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String categoryId,
                required String name,
                required int price,
                Value<int> vatRateBp = const Value.absent(),
                Value<String> station = const Value.absent(),
                Value<String> modifierGroupsJson = const Value.absent(),
                Value<bool> available = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                categoryId: categoryId,
                name: name,
                price: price,
                vatRateBp: vatRateBp,
                station: station,
                modifierGroupsJson: modifierGroupsJson,
                available: available,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      ProductRow,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (ProductRow, BaseReferences<_$AppDatabase, $ProductsTable, ProductRow>),
      ProductRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxEventsTableCreateCompanionBuilder =
    OutboxEventsCompanion Function({
      required String id,
      required String type,
      Value<int> version,
      required String entityId,
      required int deviceSeq,
      required DateTime occurredAt,
      Value<String?> staffId,
      Value<String?> approvedBy,
      required String payloadJson,
      Value<String?> rejectedCode,
      Value<int> rowid,
    });
typedef $$OutboxEventsTableUpdateCompanionBuilder =
    OutboxEventsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<int> version,
      Value<String> entityId,
      Value<int> deviceSeq,
      Value<DateTime> occurredAt,
      Value<String?> staffId,
      Value<String?> approvedBy,
      Value<String> payloadJson,
      Value<String?> rejectedCode,
      Value<int> rowid,
    });

class $$OutboxEventsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deviceSeq => $composableBuilder(
    column: $table.deviceSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get staffId => $composableBuilder(
    column: $table.staffId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectedCode => $composableBuilder(
    column: $table.rejectedCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deviceSeq => $composableBuilder(
    column: $table.deviceSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get staffId => $composableBuilder(
    column: $table.staffId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectedCode => $composableBuilder(
    column: $table.rejectedCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get deviceSeq =>
      $composableBuilder(column: $table.deviceSeq, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get staffId =>
      $composableBuilder(column: $table.staffId, builder: (column) => column);

  GeneratedColumn<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rejectedCode => $composableBuilder(
    column: $table.rejectedCode,
    builder: (column) => column,
  );
}

class $$OutboxEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxEventsTable,
          OutboxRow,
          $$OutboxEventsTableFilterComposer,
          $$OutboxEventsTableOrderingComposer,
          $$OutboxEventsTableAnnotationComposer,
          $$OutboxEventsTableCreateCompanionBuilder,
          $$OutboxEventsTableUpdateCompanionBuilder,
          (
            OutboxRow,
            BaseReferences<_$AppDatabase, $OutboxEventsTable, OutboxRow>,
          ),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxEventsTableTableManager(_$AppDatabase db, $OutboxEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$OutboxEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$OutboxEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$OutboxEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<int> deviceSeq = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> staffId = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String?> rejectedCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEventsCompanion(
                id: id,
                type: type,
                version: version,
                entityId: entityId,
                deviceSeq: deviceSeq,
                occurredAt: occurredAt,
                staffId: staffId,
                approvedBy: approvedBy,
                payloadJson: payloadJson,
                rejectedCode: rejectedCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                Value<int> version = const Value.absent(),
                required String entityId,
                required int deviceSeq,
                required DateTime occurredAt,
                Value<String?> staffId = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                required String payloadJson,
                Value<String?> rejectedCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEventsCompanion.insert(
                id: id,
                type: type,
                version: version,
                entityId: entityId,
                deviceSeq: deviceSeq,
                occurredAt: occurredAt,
                staffId: staffId,
                approvedBy: approvedBy,
                payloadJson: payloadJson,
                rejectedCode: rejectedCode,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxEventsTable,
      OutboxRow,
      $$OutboxEventsTableFilterComposer,
      $$OutboxEventsTableOrderingComposer,
      $$OutboxEventsTableAnnotationComposer,
      $$OutboxEventsTableCreateCompanionBuilder,
      $$OutboxEventsTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$AppDatabase, $OutboxEventsTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$OrdersTableCreateCompanionBuilder =
    OrdersCompanion Function({
      required String id,
      Value<String> status,
      Value<String> type,
      Value<String?> tableLabel,
      Value<String?> tableId,
      required DateTime openedAt,
      Value<DateTime?> closedAt,
      Value<int> total,
      Value<String?> receiptNumber,
      Value<DateTime?> billRequestedAt,
      Value<int> rowid,
    });
typedef $$OrdersTableUpdateCompanionBuilder =
    OrdersCompanion Function({
      Value<String> id,
      Value<String> status,
      Value<String> type,
      Value<String?> tableLabel,
      Value<String?> tableId,
      Value<DateTime> openedAt,
      Value<DateTime?> closedAt,
      Value<int> total,
      Value<String?> receiptNumber,
      Value<DateTime?> billRequestedAt,
      Value<int> rowid,
    });

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableLabel => $composableBuilder(
    column: $table.tableLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get billRequestedAt => $composableBuilder(
    column: $table.billRequestedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableLabel => $composableBuilder(
    column: $table.tableLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get billRequestedAt => $composableBuilder(
    column: $table.billRequestedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get tableLabel => $composableBuilder(
    column: $table.tableLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tableId =>
      $composableBuilder(column: $table.tableId, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get billRequestedAt => $composableBuilder(
    column: $table.billRequestedAt,
    builder: (column) => column,
  );
}

class $$OrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdersTable,
          OrderRow,
          $$OrdersTableFilterComposer,
          $$OrdersTableOrderingComposer,
          $$OrdersTableAnnotationComposer,
          $$OrdersTableCreateCompanionBuilder,
          $$OrdersTableUpdateCompanionBuilder,
          (OrderRow, BaseReferences<_$AppDatabase, $OrdersTable, OrderRow>),
          OrderRow,
          PrefetchHooks Function()
        > {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> tableLabel = const Value.absent(),
                Value<String?> tableId = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<String?> receiptNumber = const Value.absent(),
                Value<DateTime?> billRequestedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion(
                id: id,
                status: status,
                type: type,
                tableLabel: tableLabel,
                tableId: tableId,
                openedAt: openedAt,
                closedAt: closedAt,
                total: total,
                receiptNumber: receiptNumber,
                billRequestedAt: billRequestedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> status = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> tableLabel = const Value.absent(),
                Value<String?> tableId = const Value.absent(),
                required DateTime openedAt,
                Value<DateTime?> closedAt = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<String?> receiptNumber = const Value.absent(),
                Value<DateTime?> billRequestedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion.insert(
                id: id,
                status: status,
                type: type,
                tableLabel: tableLabel,
                tableId: tableId,
                openedAt: openedAt,
                closedAt: closedAt,
                total: total,
                receiptNumber: receiptNumber,
                billRequestedAt: billRequestedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdersTable,
      OrderRow,
      $$OrdersTableFilterComposer,
      $$OrdersTableOrderingComposer,
      $$OrdersTableAnnotationComposer,
      $$OrdersTableCreateCompanionBuilder,
      $$OrdersTableUpdateCompanionBuilder,
      (OrderRow, BaseReferences<_$AppDatabase, $OrdersTable, OrderRow>),
      OrderRow,
      PrefetchHooks Function()
    >;
typedef $$OrderLinesTableCreateCompanionBuilder =
    OrderLinesCompanion Function({
      required String id,
      required String orderId,
      required String productId,
      required String name,
      required int unitPrice,
      Value<int> modifiersPrice,
      Value<String> modifiersJson,
      required int qty,
      required int vatRateBp,
      Value<String> station,
      Value<String?> note,
      Value<bool> voided,
      required DateTime createdAt,
      Value<String?> paymentId,
      Value<DateTime?> sentAt,
      Value<int> rowid,
    });
typedef $$OrderLinesTableUpdateCompanionBuilder =
    OrderLinesCompanion Function({
      Value<String> id,
      Value<String> orderId,
      Value<String> productId,
      Value<String> name,
      Value<int> unitPrice,
      Value<int> modifiersPrice,
      Value<String> modifiersJson,
      Value<int> qty,
      Value<int> vatRateBp,
      Value<String> station,
      Value<String?> note,
      Value<bool> voided,
      Value<DateTime> createdAt,
      Value<String?> paymentId,
      Value<DateTime?> sentAt,
      Value<int> rowid,
    });

class $$OrderLinesTableFilterComposer
    extends Composer<_$AppDatabase, $OrderLinesTable> {
  $$OrderLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiersPrice => $composableBuilder(
    column: $table.modifiersPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiersJson => $composableBuilder(
    column: $table.modifiersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vatRateBp => $composableBuilder(
    column: $table.vatRateBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get station => $composableBuilder(
    column: $table.station,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get voided => $composableBuilder(
    column: $table.voided,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentId => $composableBuilder(
    column: $table.paymentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrderLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderLinesTable> {
  $$OrderLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiersPrice => $composableBuilder(
    column: $table.modifiersPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiersJson => $composableBuilder(
    column: $table.modifiersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vatRateBp => $composableBuilder(
    column: $table.vatRateBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get station => $composableBuilder(
    column: $table.station,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get voided => $composableBuilder(
    column: $table.voided,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentId => $composableBuilder(
    column: $table.paymentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrderLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderLinesTable> {
  $$OrderLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<int> get modifiersPrice => $composableBuilder(
    column: $table.modifiersPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiersJson => $composableBuilder(
    column: $table.modifiersJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<int> get vatRateBp =>
      $composableBuilder(column: $table.vatRateBp, builder: (column) => column);

  GeneratedColumn<String> get station =>
      $composableBuilder(column: $table.station, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get voided =>
      $composableBuilder(column: $table.voided, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get paymentId =>
      $composableBuilder(column: $table.paymentId, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);
}

class $$OrderLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrderLinesTable,
          OrderLineRow,
          $$OrderLinesTableFilterComposer,
          $$OrderLinesTableOrderingComposer,
          $$OrderLinesTableAnnotationComposer,
          $$OrderLinesTableCreateCompanionBuilder,
          $$OrderLinesTableUpdateCompanionBuilder,
          (
            OrderLineRow,
            BaseReferences<_$AppDatabase, $OrderLinesTable, OrderLineRow>,
          ),
          OrderLineRow,
          PrefetchHooks Function()
        > {
  $$OrderLinesTableTableManager(_$AppDatabase db, $OrderLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$OrderLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$OrderLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$OrderLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> unitPrice = const Value.absent(),
                Value<int> modifiersPrice = const Value.absent(),
                Value<String> modifiersJson = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<int> vatRateBp = const Value.absent(),
                Value<String> station = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> voided = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> paymentId = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderLinesCompanion(
                id: id,
                orderId: orderId,
                productId: productId,
                name: name,
                unitPrice: unitPrice,
                modifiersPrice: modifiersPrice,
                modifiersJson: modifiersJson,
                qty: qty,
                vatRateBp: vatRateBp,
                station: station,
                note: note,
                voided: voided,
                createdAt: createdAt,
                paymentId: paymentId,
                sentAt: sentAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String orderId,
                required String productId,
                required String name,
                required int unitPrice,
                Value<int> modifiersPrice = const Value.absent(),
                Value<String> modifiersJson = const Value.absent(),
                required int qty,
                required int vatRateBp,
                Value<String> station = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> voided = const Value.absent(),
                required DateTime createdAt,
                Value<String?> paymentId = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderLinesCompanion.insert(
                id: id,
                orderId: orderId,
                productId: productId,
                name: name,
                unitPrice: unitPrice,
                modifiersPrice: modifiersPrice,
                modifiersJson: modifiersJson,
                qty: qty,
                vatRateBp: vatRateBp,
                station: station,
                note: note,
                voided: voided,
                createdAt: createdAt,
                paymentId: paymentId,
                sentAt: sentAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrderLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrderLinesTable,
      OrderLineRow,
      $$OrderLinesTableFilterComposer,
      $$OrderLinesTableOrderingComposer,
      $$OrderLinesTableAnnotationComposer,
      $$OrderLinesTableCreateCompanionBuilder,
      $$OrderLinesTableUpdateCompanionBuilder,
      (
        OrderLineRow,
        BaseReferences<_$AppDatabase, $OrderLinesTable, OrderLineRow>,
      ),
      OrderLineRow,
      PrefetchHooks Function()
    >;
typedef $$PaymentsTableCreateCompanionBuilder =
    PaymentsCompanion Function({
      required String id,
      required String orderId,
      required String method,
      required int amount,
      required int tendered,
      required int changeGiven,
      required DateTime createdAt,
      Value<String?> drawerId,
      Value<int> rowid,
    });
typedef $$PaymentsTableUpdateCompanionBuilder =
    PaymentsCompanion Function({
      Value<String> id,
      Value<String> orderId,
      Value<String> method,
      Value<int> amount,
      Value<int> tendered,
      Value<int> changeGiven,
      Value<DateTime> createdAt,
      Value<String?> drawerId,
      Value<int> rowid,
    });

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tendered => $composableBuilder(
    column: $table.tendered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changeGiven => $composableBuilder(
    column: $table.changeGiven,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get drawerId => $composableBuilder(
    column: $table.drawerId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tendered => $composableBuilder(
    column: $table.tendered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeGiven => $composableBuilder(
    column: $table.changeGiven,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get drawerId => $composableBuilder(
    column: $table.drawerId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get tendered =>
      $composableBuilder(column: $table.tendered, builder: (column) => column);

  GeneratedColumn<int> get changeGiven => $composableBuilder(
    column: $table.changeGiven,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get drawerId =>
      $composableBuilder(column: $table.drawerId, builder: (column) => column);
}

class $$PaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTable,
          PaymentRow,
          $$PaymentsTableFilterComposer,
          $$PaymentsTableOrderingComposer,
          $$PaymentsTableAnnotationComposer,
          $$PaymentsTableCreateCompanionBuilder,
          $$PaymentsTableUpdateCompanionBuilder,
          (
            PaymentRow,
            BaseReferences<_$AppDatabase, $PaymentsTable, PaymentRow>,
          ),
          PaymentRow,
          PrefetchHooks Function()
        > {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> tendered = const Value.absent(),
                Value<int> changeGiven = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> drawerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion(
                id: id,
                orderId: orderId,
                method: method,
                amount: amount,
                tendered: tendered,
                changeGiven: changeGiven,
                createdAt: createdAt,
                drawerId: drawerId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String orderId,
                required String method,
                required int amount,
                required int tendered,
                required int changeGiven,
                required DateTime createdAt,
                Value<String?> drawerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion.insert(
                id: id,
                orderId: orderId,
                method: method,
                amount: amount,
                tendered: tendered,
                changeGiven: changeGiven,
                createdAt: createdAt,
                drawerId: drawerId,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTable,
      PaymentRow,
      $$PaymentsTableFilterComposer,
      $$PaymentsTableOrderingComposer,
      $$PaymentsTableAnnotationComposer,
      $$PaymentsTableCreateCompanionBuilder,
      $$PaymentsTableUpdateCompanionBuilder,
      (PaymentRow, BaseReferences<_$AppDatabase, $PaymentsTable, PaymentRow>),
      PaymentRow,
      PrefetchHooks Function()
    >;
typedef $$StaffMembersTableCreateCompanionBuilder =
    StaffMembersCompanion Function({
      required String id,
      required String name,
      required String role,
      required String pinHash,
      Value<int> rowid,
    });
typedef $$StaffMembersTableUpdateCompanionBuilder =
    StaffMembersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> role,
      Value<String> pinHash,
      Value<int> rowid,
    });

class $$StaffMembersTableFilterComposer
    extends Composer<_$AppDatabase, $StaffMembersTable> {
  $$StaffMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StaffMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $StaffMembersTable> {
  $$StaffMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StaffMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $StaffMembersTable> {
  $$StaffMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);
}

class $$StaffMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StaffMembersTable,
          StaffRow,
          $$StaffMembersTableFilterComposer,
          $$StaffMembersTableOrderingComposer,
          $$StaffMembersTableAnnotationComposer,
          $$StaffMembersTableCreateCompanionBuilder,
          $$StaffMembersTableUpdateCompanionBuilder,
          (
            StaffRow,
            BaseReferences<_$AppDatabase, $StaffMembersTable, StaffRow>,
          ),
          StaffRow,
          PrefetchHooks Function()
        > {
  $$StaffMembersTableTableManager(_$AppDatabase db, $StaffMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$StaffMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$StaffMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$StaffMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> pinHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StaffMembersCompanion(
                id: id,
                name: name,
                role: role,
                pinHash: pinHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String role,
                required String pinHash,
                Value<int> rowid = const Value.absent(),
              }) => StaffMembersCompanion.insert(
                id: id,
                name: name,
                role: role,
                pinHash: pinHash,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StaffMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StaffMembersTable,
      StaffRow,
      $$StaffMembersTableFilterComposer,
      $$StaffMembersTableOrderingComposer,
      $$StaffMembersTableAnnotationComposer,
      $$StaffMembersTableCreateCompanionBuilder,
      $$StaffMembersTableUpdateCompanionBuilder,
      (StaffRow, BaseReferences<_$AppDatabase, $StaffMembersTable, StaffRow>),
      StaffRow,
      PrefetchHooks Function()
    >;
typedef $$FloorAreasTableCreateCompanionBuilder =
    FloorAreasCompanion Function({
      required String id,
      required String name,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$FloorAreasTableUpdateCompanionBuilder =
    FloorAreasCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$FloorAreasTableFilterComposer
    extends Composer<_$AppDatabase, $FloorAreasTable> {
  $$FloorAreasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FloorAreasTableOrderingComposer
    extends Composer<_$AppDatabase, $FloorAreasTable> {
  $$FloorAreasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FloorAreasTableAnnotationComposer
    extends Composer<_$AppDatabase, $FloorAreasTable> {
  $$FloorAreasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$FloorAreasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FloorAreasTable,
          AreaRow,
          $$FloorAreasTableFilterComposer,
          $$FloorAreasTableOrderingComposer,
          $$FloorAreasTableAnnotationComposer,
          $$FloorAreasTableCreateCompanionBuilder,
          $$FloorAreasTableUpdateCompanionBuilder,
          (AreaRow, BaseReferences<_$AppDatabase, $FloorAreasTable, AreaRow>),
          AreaRow,
          PrefetchHooks Function()
        > {
  $$FloorAreasTableTableManager(_$AppDatabase db, $FloorAreasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$FloorAreasTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$FloorAreasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$FloorAreasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FloorAreasCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FloorAreasCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FloorAreasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FloorAreasTable,
      AreaRow,
      $$FloorAreasTableFilterComposer,
      $$FloorAreasTableOrderingComposer,
      $$FloorAreasTableAnnotationComposer,
      $$FloorAreasTableCreateCompanionBuilder,
      $$FloorAreasTableUpdateCompanionBuilder,
      (AreaRow, BaseReferences<_$AppDatabase, $FloorAreasTable, AreaRow>),
      AreaRow,
      PrefetchHooks Function()
    >;
typedef $$DiningTablesTableCreateCompanionBuilder =
    DiningTablesCompanion Function({
      required String id,
      required String areaId,
      required String name,
      Value<int> seats,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$DiningTablesTableUpdateCompanionBuilder =
    DiningTablesCompanion Function({
      Value<String> id,
      Value<String> areaId,
      Value<String> name,
      Value<int> seats,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$DiningTablesTableFilterComposer
    extends Composer<_$AppDatabase, $DiningTablesTable> {
  $$DiningTablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaId => $composableBuilder(
    column: $table.areaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seats => $composableBuilder(
    column: $table.seats,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DiningTablesTableOrderingComposer
    extends Composer<_$AppDatabase, $DiningTablesTable> {
  $$DiningTablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaId => $composableBuilder(
    column: $table.areaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seats => $composableBuilder(
    column: $table.seats,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiningTablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiningTablesTable> {
  $$DiningTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get areaId =>
      $composableBuilder(column: $table.areaId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get seats =>
      $composableBuilder(column: $table.seats, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$DiningTablesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiningTablesTable,
          DiningTableRow,
          $$DiningTablesTableFilterComposer,
          $$DiningTablesTableOrderingComposer,
          $$DiningTablesTableAnnotationComposer,
          $$DiningTablesTableCreateCompanionBuilder,
          $$DiningTablesTableUpdateCompanionBuilder,
          (
            DiningTableRow,
            BaseReferences<_$AppDatabase, $DiningTablesTable, DiningTableRow>,
          ),
          DiningTableRow,
          PrefetchHooks Function()
        > {
  $$DiningTablesTableTableManager(_$AppDatabase db, $DiningTablesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$DiningTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$DiningTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$DiningTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> areaId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> seats = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiningTablesCompanion(
                id: id,
                areaId: areaId,
                name: name,
                seats: seats,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String areaId,
                required String name,
                Value<int> seats = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiningTablesCompanion.insert(
                id: id,
                areaId: areaId,
                name: name,
                seats: seats,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DiningTablesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiningTablesTable,
      DiningTableRow,
      $$DiningTablesTableFilterComposer,
      $$DiningTablesTableOrderingComposer,
      $$DiningTablesTableAnnotationComposer,
      $$DiningTablesTableCreateCompanionBuilder,
      $$DiningTablesTableUpdateCompanionBuilder,
      (
        DiningTableRow,
        BaseReferences<_$AppDatabase, $DiningTablesTable, DiningTableRow>,
      ),
      DiningTableRow,
      PrefetchHooks Function()
    >;
typedef $$CashSessionsTableCreateCompanionBuilder =
    CashSessionsCompanion Function({
      required String id,
      required String drawerId,
      Value<String> status,
      required DateTime openedAt,
      Value<String?> openedBy,
      required int openingFloat,
      Value<DateTime?> closedAt,
      Value<String?> closedBy,
      Value<int?> countedCash,
      Value<int?> expectedCash,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$CashSessionsTableUpdateCompanionBuilder =
    CashSessionsCompanion Function({
      Value<String> id,
      Value<String> drawerId,
      Value<String> status,
      Value<DateTime> openedAt,
      Value<String?> openedBy,
      Value<int> openingFloat,
      Value<DateTime?> closedAt,
      Value<String?> closedBy,
      Value<int?> countedCash,
      Value<int?> expectedCash,
      Value<String?> note,
      Value<int> rowid,
    });

class $$CashSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $CashSessionsTable> {
  $$CashSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get drawerId => $composableBuilder(
    column: $table.drawerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openedBy => $composableBuilder(
    column: $table.openedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingFloat => $composableBuilder(
    column: $table.openingFloat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closedBy => $composableBuilder(
    column: $table.closedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get countedCash => $composableBuilder(
    column: $table.countedCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CashSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CashSessionsTable> {
  $$CashSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get drawerId => $composableBuilder(
    column: $table.drawerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openedBy => $composableBuilder(
    column: $table.openedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingFloat => $composableBuilder(
    column: $table.openingFloat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closedBy => $composableBuilder(
    column: $table.closedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get countedCash => $composableBuilder(
    column: $table.countedCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CashSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashSessionsTable> {
  $$CashSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get drawerId =>
      $composableBuilder(column: $table.drawerId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<String> get openedBy =>
      $composableBuilder(column: $table.openedBy, builder: (column) => column);

  GeneratedColumn<int> get openingFloat => $composableBuilder(
    column: $table.openingFloat,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<String> get closedBy =>
      $composableBuilder(column: $table.closedBy, builder: (column) => column);

  GeneratedColumn<int> get countedCash => $composableBuilder(
    column: $table.countedCash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$CashSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashSessionsTable,
          CashSessionRow,
          $$CashSessionsTableFilterComposer,
          $$CashSessionsTableOrderingComposer,
          $$CashSessionsTableAnnotationComposer,
          $$CashSessionsTableCreateCompanionBuilder,
          $$CashSessionsTableUpdateCompanionBuilder,
          (
            CashSessionRow,
            BaseReferences<_$AppDatabase, $CashSessionsTable, CashSessionRow>,
          ),
          CashSessionRow,
          PrefetchHooks Function()
        > {
  $$CashSessionsTableTableManager(_$AppDatabase db, $CashSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CashSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CashSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$CashSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> drawerId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<String?> openedBy = const Value.absent(),
                Value<int> openingFloat = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<String?> closedBy = const Value.absent(),
                Value<int?> countedCash = const Value.absent(),
                Value<int?> expectedCash = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashSessionsCompanion(
                id: id,
                drawerId: drawerId,
                status: status,
                openedAt: openedAt,
                openedBy: openedBy,
                openingFloat: openingFloat,
                closedAt: closedAt,
                closedBy: closedBy,
                countedCash: countedCash,
                expectedCash: expectedCash,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String drawerId,
                Value<String> status = const Value.absent(),
                required DateTime openedAt,
                Value<String?> openedBy = const Value.absent(),
                required int openingFloat,
                Value<DateTime?> closedAt = const Value.absent(),
                Value<String?> closedBy = const Value.absent(),
                Value<int?> countedCash = const Value.absent(),
                Value<int?> expectedCash = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashSessionsCompanion.insert(
                id: id,
                drawerId: drawerId,
                status: status,
                openedAt: openedAt,
                openedBy: openedBy,
                openingFloat: openingFloat,
                closedAt: closedAt,
                closedBy: closedBy,
                countedCash: countedCash,
                expectedCash: expectedCash,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CashSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashSessionsTable,
      CashSessionRow,
      $$CashSessionsTableFilterComposer,
      $$CashSessionsTableOrderingComposer,
      $$CashSessionsTableAnnotationComposer,
      $$CashSessionsTableCreateCompanionBuilder,
      $$CashSessionsTableUpdateCompanionBuilder,
      (
        CashSessionRow,
        BaseReferences<_$AppDatabase, $CashSessionsTable, CashSessionRow>,
      ),
      CashSessionRow,
      PrefetchHooks Function()
    >;
typedef $$CashMovementsTableCreateCompanionBuilder =
    CashMovementsCompanion Function({
      required String id,
      required String sessionId,
      required String type,
      required int amount,
      required String reason,
      Value<String?> staffId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CashMovementsTableUpdateCompanionBuilder =
    CashMovementsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> type,
      Value<int> amount,
      Value<String> reason,
      Value<String?> staffId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CashMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $CashMovementsTable> {
  $$CashMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get staffId => $composableBuilder(
    column: $table.staffId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CashMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $CashMovementsTable> {
  $$CashMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get staffId => $composableBuilder(
    column: $table.staffId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CashMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashMovementsTable> {
  $$CashMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get staffId =>
      $composableBuilder(column: $table.staffId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CashMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashMovementsTable,
          CashMovementRow,
          $$CashMovementsTableFilterComposer,
          $$CashMovementsTableOrderingComposer,
          $$CashMovementsTableAnnotationComposer,
          $$CashMovementsTableCreateCompanionBuilder,
          $$CashMovementsTableUpdateCompanionBuilder,
          (
            CashMovementRow,
            BaseReferences<_$AppDatabase, $CashMovementsTable, CashMovementRow>,
          ),
          CashMovementRow,
          PrefetchHooks Function()
        > {
  $$CashMovementsTableTableManager(_$AppDatabase db, $CashMovementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CashMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$CashMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CashMovementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> staffId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashMovementsCompanion(
                id: id,
                sessionId: sessionId,
                type: type,
                amount: amount,
                reason: reason,
                staffId: staffId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String type,
                required int amount,
                required String reason,
                Value<String?> staffId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CashMovementsCompanion.insert(
                id: id,
                sessionId: sessionId,
                type: type,
                amount: amount,
                reason: reason,
                staffId: staffId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CashMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashMovementsTable,
      CashMovementRow,
      $$CashMovementsTableFilterComposer,
      $$CashMovementsTableOrderingComposer,
      $$CashMovementsTableAnnotationComposer,
      $$CashMovementsTableCreateCompanionBuilder,
      $$CashMovementsTableUpdateCompanionBuilder,
      (
        CashMovementRow,
        BaseReferences<_$AppDatabase, $CashMovementsTable, CashMovementRow>,
      ),
      CashMovementRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KvEntriesTableTableManager get kvEntries =>
      $$KvEntriesTableTableManager(_db, _db.kvEntries);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$OutboxEventsTableTableManager get outboxEvents =>
      $$OutboxEventsTableTableManager(_db, _db.outboxEvents);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$OrderLinesTableTableManager get orderLines =>
      $$OrderLinesTableTableManager(_db, _db.orderLines);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$StaffMembersTableTableManager get staffMembers =>
      $$StaffMembersTableTableManager(_db, _db.staffMembers);
  $$FloorAreasTableTableManager get floorAreas =>
      $$FloorAreasTableTableManager(_db, _db.floorAreas);
  $$DiningTablesTableTableManager get diningTables =>
      $$DiningTablesTableTableManager(_db, _db.diningTables);
  $$CashSessionsTableTableManager get cashSessions =>
      $$CashSessionsTableTableManager(_db, _db.cashSessions);
  $$CashMovementsTableTableManager get cashMovements =>
      $$CashMovementsTableTableManager(_db, _db.cashMovements);
}
