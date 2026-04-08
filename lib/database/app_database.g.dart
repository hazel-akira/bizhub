// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, phone, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Customer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final int id;
  final String name;
  final String phone;
  final DateTime createdAt;
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      createdAt: Value(createdAt),
    );
  }

  factory Customer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    DateTime? createdAt,
  }) => Customer(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    createdAt: createdAt ?? this.createdAt,
  );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.createdAt == this.createdAt);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<DateTime> createdAt;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CustomersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Customer> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CustomersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? phone,
    Value<DateTime>? createdAt,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, Order> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<int> customerId = GeneratedColumn<int>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (id)',
    ),
  );
  static const VerificationMeta _ndenguCountMeta = const VerificationMeta(
    'ndenguCount',
  );
  @override
  late final GeneratedColumn<int> ndenguCount = GeneratedColumn<int>(
    'ndengu_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _meatCountMeta = const VerificationMeta(
    'meatCount',
  );
  @override
  late final GeneratedColumn<int> meatCount = GeneratedColumn<int>(
    'meat_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _orderDateMeta = const VerificationMeta(
    'orderDate',
  );
  @override
  late final GeneratedColumn<DateTime> orderDate = GeneratedColumn<DateTime>(
    'order_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    ndenguCount,
    meatCount,
    orderDate,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Order> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('ndengu_count')) {
      context.handle(
        _ndenguCountMeta,
        ndenguCount.isAcceptableOrUnknown(
          data['ndengu_count']!,
          _ndenguCountMeta,
        ),
      );
    }
    if (data.containsKey('meat_count')) {
      context.handle(
        _meatCountMeta,
        meatCount.isAcceptableOrUnknown(data['meat_count']!, _meatCountMeta),
      );
    }
    if (data.containsKey('order_date')) {
      context.handle(
        _orderDateMeta,
        orderDate.isAcceptableOrUnknown(data['order_date']!, _orderDateMeta),
      );
    } else if (isInserting) {
      context.missing(_orderDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Order(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}customer_id'],
      )!,
      ndenguCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ndengu_count'],
      )!,
      meatCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meat_count'],
      )!,
      orderDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}order_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class Order extends DataClass implements Insertable<Order> {
  final int id;
  final int customerId;
  final int ndenguCount;
  final int meatCount;
  final DateTime orderDate;
  final String status;
  const Order({
    required this.id,
    required this.customerId,
    required this.ndenguCount,
    required this.meatCount,
    required this.orderDate,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['customer_id'] = Variable<int>(customerId);
    map['ndengu_count'] = Variable<int>(ndenguCount);
    map['meat_count'] = Variable<int>(meatCount);
    map['order_date'] = Variable<DateTime>(orderDate);
    map['status'] = Variable<String>(status);
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      customerId: Value(customerId),
      ndenguCount: Value(ndenguCount),
      meatCount: Value(meatCount),
      orderDate: Value(orderDate),
      status: Value(status),
    );
  }

  factory Order.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Order(
      id: serializer.fromJson<int>(json['id']),
      customerId: serializer.fromJson<int>(json['customerId']),
      ndenguCount: serializer.fromJson<int>(json['ndenguCount']),
      meatCount: serializer.fromJson<int>(json['meatCount']),
      orderDate: serializer.fromJson<DateTime>(json['orderDate']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'customerId': serializer.toJson<int>(customerId),
      'ndenguCount': serializer.toJson<int>(ndenguCount),
      'meatCount': serializer.toJson<int>(meatCount),
      'orderDate': serializer.toJson<DateTime>(orderDate),
      'status': serializer.toJson<String>(status),
    };
  }

  Order copyWith({
    int? id,
    int? customerId,
    int? ndenguCount,
    int? meatCount,
    DateTime? orderDate,
    String? status,
  }) => Order(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    ndenguCount: ndenguCount ?? this.ndenguCount,
    meatCount: meatCount ?? this.meatCount,
    orderDate: orderDate ?? this.orderDate,
    status: status ?? this.status,
  );
  Order copyWithCompanion(OrdersCompanion data) {
    return Order(
      id: data.id.present ? data.id.value : this.id,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      ndenguCount: data.ndenguCount.present
          ? data.ndenguCount.value
          : this.ndenguCount,
      meatCount: data.meatCount.present ? data.meatCount.value : this.meatCount,
      orderDate: data.orderDate.present ? data.orderDate.value : this.orderDate,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Order(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('ndenguCount: $ndenguCount, ')
          ..write('meatCount: $meatCount, ')
          ..write('orderDate: $orderDate, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, customerId, ndenguCount, meatCount, orderDate, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Order &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.ndenguCount == this.ndenguCount &&
          other.meatCount == this.meatCount &&
          other.orderDate == this.orderDate &&
          other.status == this.status);
}

class OrdersCompanion extends UpdateCompanion<Order> {
  final Value<int> id;
  final Value<int> customerId;
  final Value<int> ndenguCount;
  final Value<int> meatCount;
  final Value<DateTime> orderDate;
  final Value<String> status;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.ndenguCount = const Value.absent(),
    this.meatCount = const Value.absent(),
    this.orderDate = const Value.absent(),
    this.status = const Value.absent(),
  });
  OrdersCompanion.insert({
    this.id = const Value.absent(),
    required int customerId,
    this.ndenguCount = const Value.absent(),
    this.meatCount = const Value.absent(),
    required DateTime orderDate,
    this.status = const Value.absent(),
  }) : customerId = Value(customerId),
       orderDate = Value(orderDate);
  static Insertable<Order> custom({
    Expression<int>? id,
    Expression<int>? customerId,
    Expression<int>? ndenguCount,
    Expression<int>? meatCount,
    Expression<DateTime>? orderDate,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (ndenguCount != null) 'ndengu_count': ndenguCount,
      if (meatCount != null) 'meat_count': meatCount,
      if (orderDate != null) 'order_date': orderDate,
      if (status != null) 'status': status,
    });
  }

  OrdersCompanion copyWith({
    Value<int>? id,
    Value<int>? customerId,
    Value<int>? ndenguCount,
    Value<int>? meatCount,
    Value<DateTime>? orderDate,
    Value<String>? status,
  }) {
    return OrdersCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      ndenguCount: ndenguCount ?? this.ndenguCount,
      meatCount: meatCount ?? this.meatCount,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<int>(customerId.value);
    }
    if (ndenguCount.present) {
      map['ndengu_count'] = Variable<int>(ndenguCount.value);
    }
    if (meatCount.present) {
      map['meat_count'] = Variable<int>(meatCount.value);
    }
    if (orderDate.present) {
      map['order_date'] = Variable<DateTime>(orderDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('ndenguCount: $ndenguCount, ')
          ..write('meatCount: $meatCount, ')
          ..write('orderDate: $orderDate, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $SalesTable extends Sales with TableInfo<$SalesTable, Sale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<int> orderId = GeneratedColumn<int>(
    'order_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES orders (id)',
    ),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _ndenguCountMeta = const VerificationMeta(
    'ndenguCount',
  );
  @override
  late final GeneratedColumn<int> ndenguCount = GeneratedColumn<int>(
    'ndengu_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _meatCountMeta = const VerificationMeta(
    'meatCount',
  );
  @override
  late final GeneratedColumn<int> meatCount = GeneratedColumn<int>(
    'meat_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isPaidMeta = const VerificationMeta('isPaid');
  @override
  late final GeneratedColumn<bool> isPaid = GeneratedColumn<bool>(
    'is_paid',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_paid" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderId,
    createdAt,
    ndenguCount,
    meatCount,
    totalAmount,
    customerName,
    isPaid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('ndengu_count')) {
      context.handle(
        _ndenguCountMeta,
        ndenguCount.isAcceptableOrUnknown(
          data['ndengu_count']!,
          _ndenguCountMeta,
        ),
      );
    }
    if (data.containsKey('meat_count')) {
      context.handle(
        _meatCountMeta,
        meatCount.isAcceptableOrUnknown(data['meat_count']!, _meatCountMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('is_paid')) {
      context.handle(
        _isPaidMeta,
        isPaid.isAcceptableOrUnknown(data['is_paid']!, _isPaidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sale(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      ndenguCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ndengu_count'],
      )!,
      meatCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meat_count'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      isPaid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_paid'],
      )!,
    );
  }

  @override
  $SalesTable createAlias(String alias) {
    return $SalesTable(attachedDatabase, alias);
  }
}

class Sale extends DataClass implements Insertable<Sale> {
  final int id;
  final int? orderId;
  final DateTime createdAt;
  final int ndenguCount;
  final int meatCount;
  final double totalAmount;
  final String customerName;
  final bool isPaid;
  const Sale({
    required this.id,
    this.orderId,
    required this.createdAt,
    required this.ndenguCount,
    required this.meatCount,
    required this.totalAmount,
    required this.customerName,
    required this.isPaid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || orderId != null) {
      map['order_id'] = Variable<int>(orderId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['ndengu_count'] = Variable<int>(ndenguCount);
    map['meat_count'] = Variable<int>(meatCount);
    map['total_amount'] = Variable<double>(totalAmount);
    map['customer_name'] = Variable<String>(customerName);
    map['is_paid'] = Variable<bool>(isPaid);
    return map;
  }

  SalesCompanion toCompanion(bool nullToAbsent) {
    return SalesCompanion(
      id: Value(id),
      orderId: orderId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderId),
      createdAt: Value(createdAt),
      ndenguCount: Value(ndenguCount),
      meatCount: Value(meatCount),
      totalAmount: Value(totalAmount),
      customerName: Value(customerName),
      isPaid: Value(isPaid),
    );
  }

  factory Sale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sale(
      id: serializer.fromJson<int>(json['id']),
      orderId: serializer.fromJson<int?>(json['orderId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      ndenguCount: serializer.fromJson<int>(json['ndenguCount']),
      meatCount: serializer.fromJson<int>(json['meatCount']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      customerName: serializer.fromJson<String>(json['customerName']),
      isPaid: serializer.fromJson<bool>(json['isPaid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'orderId': serializer.toJson<int?>(orderId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'ndenguCount': serializer.toJson<int>(ndenguCount),
      'meatCount': serializer.toJson<int>(meatCount),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'customerName': serializer.toJson<String>(customerName),
      'isPaid': serializer.toJson<bool>(isPaid),
    };
  }

  Sale copyWith({
    int? id,
    Value<int?> orderId = const Value.absent(),
    DateTime? createdAt,
    int? ndenguCount,
    int? meatCount,
    double? totalAmount,
    String? customerName,
    bool? isPaid,
  }) => Sale(
    id: id ?? this.id,
    orderId: orderId.present ? orderId.value : this.orderId,
    createdAt: createdAt ?? this.createdAt,
    ndenguCount: ndenguCount ?? this.ndenguCount,
    meatCount: meatCount ?? this.meatCount,
    totalAmount: totalAmount ?? this.totalAmount,
    customerName: customerName ?? this.customerName,
    isPaid: isPaid ?? this.isPaid,
  );
  Sale copyWithCompanion(SalesCompanion data) {
    return Sale(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      ndenguCount: data.ndenguCount.present
          ? data.ndenguCount.value
          : this.ndenguCount,
      meatCount: data.meatCount.present ? data.meatCount.value : this.meatCount,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      isPaid: data.isPaid.present ? data.isPaid.value : this.isPaid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sale(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('ndenguCount: $ndenguCount, ')
          ..write('meatCount: $meatCount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('customerName: $customerName, ')
          ..write('isPaid: $isPaid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderId,
    createdAt,
    ndenguCount,
    meatCount,
    totalAmount,
    customerName,
    isPaid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sale &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.createdAt == this.createdAt &&
          other.ndenguCount == this.ndenguCount &&
          other.meatCount == this.meatCount &&
          other.totalAmount == this.totalAmount &&
          other.customerName == this.customerName &&
          other.isPaid == this.isPaid);
}

class SalesCompanion extends UpdateCompanion<Sale> {
  final Value<int> id;
  final Value<int?> orderId;
  final Value<DateTime> createdAt;
  final Value<int> ndenguCount;
  final Value<int> meatCount;
  final Value<double> totalAmount;
  final Value<String> customerName;
  final Value<bool> isPaid;
  const SalesCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.ndenguCount = const Value.absent(),
    this.meatCount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.customerName = const Value.absent(),
    this.isPaid = const Value.absent(),
  });
  SalesCompanion.insert({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.ndenguCount = const Value.absent(),
    this.meatCount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.customerName = const Value.absent(),
    this.isPaid = const Value.absent(),
  });
  static Insertable<Sale> custom({
    Expression<int>? id,
    Expression<int>? orderId,
    Expression<DateTime>? createdAt,
    Expression<int>? ndenguCount,
    Expression<int>? meatCount,
    Expression<double>? totalAmount,
    Expression<String>? customerName,
    Expression<bool>? isPaid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (createdAt != null) 'created_at': createdAt,
      if (ndenguCount != null) 'ndengu_count': ndenguCount,
      if (meatCount != null) 'meat_count': meatCount,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (customerName != null) 'customer_name': customerName,
      if (isPaid != null) 'is_paid': isPaid,
    });
  }

  SalesCompanion copyWith({
    Value<int>? id,
    Value<int?>? orderId,
    Value<DateTime>? createdAt,
    Value<int>? ndenguCount,
    Value<int>? meatCount,
    Value<double>? totalAmount,
    Value<String>? customerName,
    Value<bool>? isPaid,
  }) {
    return SalesCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      createdAt: createdAt ?? this.createdAt,
      ndenguCount: ndenguCount ?? this.ndenguCount,
      meatCount: meatCount ?? this.meatCount,
      totalAmount: totalAmount ?? this.totalAmount,
      customerName: customerName ?? this.customerName,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<int>(orderId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (ndenguCount.present) {
      map['ndengu_count'] = Variable<int>(ndenguCount.value);
    }
    if (meatCount.present) {
      map['meat_count'] = Variable<int>(meatCount.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (isPaid.present) {
      map['is_paid'] = Variable<bool>(isPaid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('ndenguCount: $ndenguCount, ')
          ..write('meatCount: $meatCount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('customerName: $customerName, ')
          ..write('isPaid: $isPaid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('daily'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, amount, category, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Expense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final int id;
  final String name;
  final double amount;
  final String category;
  final DateTime createdAt;
  const Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    map['category'] = Variable<String>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      name: Value(name),
      amount: Value(amount),
      category: Value(category),
      createdAt: Value(createdAt),
    );
  }

  factory Expense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      category: serializer.fromJson<String>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'category': serializer.toJson<String>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Expense copyWith({
    int? id,
    String? name,
    double? amount,
    String? category,
    DateTime? createdAt,
  }) => Expense(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
  );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, amount, category, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.createdAt == this.createdAt);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> amount;
  final Value<String> category;
  final Value<DateTime> createdAt;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExpensesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double amount,
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       amount = Value(amount);
  static Insertable<Expense> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExpensesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? amount,
    Value<String>? category,
    Value<DateTime>? createdAt,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $UnpaidRecordsTable extends UnpaidRecords
    with TableInfo<$UnpaidRecordsTable, UnpaidRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnpaidRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isPaidMeta = const VerificationMeta('isPaid');
  @override
  late final GeneratedColumn<bool> isPaid = GeneratedColumn<bool>(
    'is_paid',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_paid" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerName,
    amount,
    date,
    notes,
    isPaid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unpaid_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<UnpaidRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_paid')) {
      context.handle(
        _isPaidMeta,
        isPaid.isAcceptableOrUnknown(data['is_paid']!, _isPaidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UnpaidRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnpaidRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      isPaid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_paid'],
      )!,
    );
  }

  @override
  $UnpaidRecordsTable createAlias(String alias) {
    return $UnpaidRecordsTable(attachedDatabase, alias);
  }
}

class UnpaidRecord extends DataClass implements Insertable<UnpaidRecord> {
  final int id;
  final String customerName;
  final double amount;
  final DateTime date;
  final String notes;
  final bool isPaid;
  const UnpaidRecord({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.notes,
    required this.isPaid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['customer_name'] = Variable<String>(customerName);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<DateTime>(date);
    map['notes'] = Variable<String>(notes);
    map['is_paid'] = Variable<bool>(isPaid);
    return map;
  }

  UnpaidRecordsCompanion toCompanion(bool nullToAbsent) {
    return UnpaidRecordsCompanion(
      id: Value(id),
      customerName: Value(customerName),
      amount: Value(amount),
      date: Value(date),
      notes: Value(notes),
      isPaid: Value(isPaid),
    );
  }

  factory UnpaidRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnpaidRecord(
      id: serializer.fromJson<int>(json['id']),
      customerName: serializer.fromJson<String>(json['customerName']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      notes: serializer.fromJson<String>(json['notes']),
      isPaid: serializer.fromJson<bool>(json['isPaid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'customerName': serializer.toJson<String>(customerName),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<DateTime>(date),
      'notes': serializer.toJson<String>(notes),
      'isPaid': serializer.toJson<bool>(isPaid),
    };
  }

  UnpaidRecord copyWith({
    int? id,
    String? customerName,
    double? amount,
    DateTime? date,
    String? notes,
    bool? isPaid,
  }) => UnpaidRecord(
    id: id ?? this.id,
    customerName: customerName ?? this.customerName,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    notes: notes ?? this.notes,
    isPaid: isPaid ?? this.isPaid,
  );
  UnpaidRecord copyWithCompanion(UnpaidRecordsCompanion data) {
    return UnpaidRecord(
      id: data.id.present ? data.id.value : this.id,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
      isPaid: data.isPaid.present ? data.isPaid.value : this.isPaid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnpaidRecord(')
          ..write('id: $id, ')
          ..write('customerName: $customerName, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('isPaid: $isPaid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, customerName, amount, date, notes, isPaid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnpaidRecord &&
          other.id == this.id &&
          other.customerName == this.customerName &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.notes == this.notes &&
          other.isPaid == this.isPaid);
}

class UnpaidRecordsCompanion extends UpdateCompanion<UnpaidRecord> {
  final Value<int> id;
  final Value<String> customerName;
  final Value<double> amount;
  final Value<DateTime> date;
  final Value<String> notes;
  final Value<bool> isPaid;
  const UnpaidRecordsCompanion({
    this.id = const Value.absent(),
    this.customerName = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.isPaid = const Value.absent(),
  });
  UnpaidRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String customerName,
    required double amount,
    required DateTime date,
    this.notes = const Value.absent(),
    this.isPaid = const Value.absent(),
  }) : customerName = Value(customerName),
       amount = Value(amount),
       date = Value(date);
  static Insertable<UnpaidRecord> custom({
    Expression<int>? id,
    Expression<String>? customerName,
    Expression<double>? amount,
    Expression<DateTime>? date,
    Expression<String>? notes,
    Expression<bool>? isPaid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerName != null) 'customer_name': customerName,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (isPaid != null) 'is_paid': isPaid,
    });
  }

  UnpaidRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? customerName,
    Value<double>? amount,
    Value<DateTime>? date,
    Value<String>? notes,
    Value<bool>? isPaid,
  }) {
    return UnpaidRecordsCompanion(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isPaid.present) {
      map['is_paid'] = Variable<bool>(isPaid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnpaidRecordsCompanion(')
          ..write('id: $id, ')
          ..write('customerName: $customerName, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('isPaid: $isPaid')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments with TableInfo<$PaymentsTable, Payment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<int> saleId = GeneratedColumn<int>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (id)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, saleId, amount, method, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Payment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Payment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Payment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sale_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class Payment extends DataClass implements Insertable<Payment> {
  final int id;
  final int saleId;
  final double amount;
  final String method;
  final DateTime createdAt;
  const Payment({
    required this.id,
    required this.saleId,
    required this.amount,
    required this.method,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sale_id'] = Variable<int>(saleId);
    map['amount'] = Variable<double>(amount);
    map['method'] = Variable<String>(method);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      amount: Value(amount),
      method: Value(method),
      createdAt: Value(createdAt),
    );
  }

  factory Payment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Payment(
      id: serializer.fromJson<int>(json['id']),
      saleId: serializer.fromJson<int>(json['saleId']),
      amount: serializer.fromJson<double>(json['amount']),
      method: serializer.fromJson<String>(json['method']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'saleId': serializer.toJson<int>(saleId),
      'amount': serializer.toJson<double>(amount),
      'method': serializer.toJson<String>(method),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Payment copyWith({
    int? id,
    int? saleId,
    double? amount,
    String? method,
    DateTime? createdAt,
  }) => Payment(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    amount: amount ?? this.amount,
    method: method ?? this.method,
    createdAt: createdAt ?? this.createdAt,
  );
  Payment copyWithCompanion(PaymentsCompanion data) {
    return Payment(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      amount: data.amount.present ? data.amount.value : this.amount,
      method: data.method.present ? data.method.value : this.method,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Payment(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, saleId, amount, method, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Payment &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.amount == this.amount &&
          other.method == this.method &&
          other.createdAt == this.createdAt);
}

class PaymentsCompanion extends UpdateCompanion<Payment> {
  final Value<int> id;
  final Value<int> saleId;
  final Value<double> amount;
  final Value<String> method;
  final Value<DateTime> createdAt;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.amount = const Value.absent(),
    this.method = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PaymentsCompanion.insert({
    this.id = const Value.absent(),
    required int saleId,
    required double amount,
    required String method,
    this.createdAt = const Value.absent(),
  }) : saleId = Value(saleId),
       amount = Value(amount),
       method = Value(method);
  static Insertable<Payment> custom({
    Expression<int>? id,
    Expression<int>? saleId,
    Expression<double>? amount,
    Expression<String>? method,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (amount != null) 'amount': amount,
      if (method != null) 'method': method,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PaymentsCompanion copyWith({
    Value<int>? id,
    Value<int>? saleId,
    Value<double>? amount,
    Value<String>? method,
    Value<DateTime>? createdAt,
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<int>(saleId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ProductionBatchesTable extends ProductionBatches
    with TableInfo<$ProductionBatchesTable, ProductionBatche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductionBatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ndenguPreparedMeta = const VerificationMeta(
    'ndenguPrepared',
  );
  @override
  late final GeneratedColumn<int> ndenguPrepared = GeneratedColumn<int>(
    'ndengu_prepared',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _meatPreparedMeta = const VerificationMeta(
    'meatPrepared',
  );
  @override
  late final GeneratedColumn<int> meatPrepared = GeneratedColumn<int>(
    'meat_prepared',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    ndenguPrepared,
    meatPrepared,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'production_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductionBatche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('ndengu_prepared')) {
      context.handle(
        _ndenguPreparedMeta,
        ndenguPrepared.isAcceptableOrUnknown(
          data['ndengu_prepared']!,
          _ndenguPreparedMeta,
        ),
      );
    }
    if (data.containsKey('meat_prepared')) {
      context.handle(
        _meatPreparedMeta,
        meatPrepared.isAcceptableOrUnknown(
          data['meat_prepared']!,
          _meatPreparedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductionBatche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductionBatche(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      ndenguPrepared: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ndengu_prepared'],
      )!,
      meatPrepared: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meat_prepared'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProductionBatchesTable createAlias(String alias) {
    return $ProductionBatchesTable(attachedDatabase, alias);
  }
}

class ProductionBatche extends DataClass
    implements Insertable<ProductionBatche> {
  final int id;
  final DateTime date;
  final int ndenguPrepared;
  final int meatPrepared;
  final DateTime createdAt;
  const ProductionBatche({
    required this.id,
    required this.date,
    required this.ndenguPrepared,
    required this.meatPrepared,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['ndengu_prepared'] = Variable<int>(ndenguPrepared);
    map['meat_prepared'] = Variable<int>(meatPrepared);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProductionBatchesCompanion toCompanion(bool nullToAbsent) {
    return ProductionBatchesCompanion(
      id: Value(id),
      date: Value(date),
      ndenguPrepared: Value(ndenguPrepared),
      meatPrepared: Value(meatPrepared),
      createdAt: Value(createdAt),
    );
  }

  factory ProductionBatche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductionBatche(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      ndenguPrepared: serializer.fromJson<int>(json['ndenguPrepared']),
      meatPrepared: serializer.fromJson<int>(json['meatPrepared']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'ndenguPrepared': serializer.toJson<int>(ndenguPrepared),
      'meatPrepared': serializer.toJson<int>(meatPrepared),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProductionBatche copyWith({
    int? id,
    DateTime? date,
    int? ndenguPrepared,
    int? meatPrepared,
    DateTime? createdAt,
  }) => ProductionBatche(
    id: id ?? this.id,
    date: date ?? this.date,
    ndenguPrepared: ndenguPrepared ?? this.ndenguPrepared,
    meatPrepared: meatPrepared ?? this.meatPrepared,
    createdAt: createdAt ?? this.createdAt,
  );
  ProductionBatche copyWithCompanion(ProductionBatchesCompanion data) {
    return ProductionBatche(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      ndenguPrepared: data.ndenguPrepared.present
          ? data.ndenguPrepared.value
          : this.ndenguPrepared,
      meatPrepared: data.meatPrepared.present
          ? data.meatPrepared.value
          : this.meatPrepared,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductionBatche(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('ndenguPrepared: $ndenguPrepared, ')
          ..write('meatPrepared: $meatPrepared, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, ndenguPrepared, meatPrepared, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductionBatche &&
          other.id == this.id &&
          other.date == this.date &&
          other.ndenguPrepared == this.ndenguPrepared &&
          other.meatPrepared == this.meatPrepared &&
          other.createdAt == this.createdAt);
}

class ProductionBatchesCompanion extends UpdateCompanion<ProductionBatche> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> ndenguPrepared;
  final Value<int> meatPrepared;
  final Value<DateTime> createdAt;
  const ProductionBatchesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.ndenguPrepared = const Value.absent(),
    this.meatPrepared = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProductionBatchesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.ndenguPrepared = const Value.absent(),
    this.meatPrepared = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : date = Value(date);
  static Insertable<ProductionBatche> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? ndenguPrepared,
    Expression<int>? meatPrepared,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (ndenguPrepared != null) 'ndengu_prepared': ndenguPrepared,
      if (meatPrepared != null) 'meat_prepared': meatPrepared,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProductionBatchesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<int>? ndenguPrepared,
    Value<int>? meatPrepared,
    Value<DateTime>? createdAt,
  }) {
    return ProductionBatchesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      ndenguPrepared: ndenguPrepared ?? this.ndenguPrepared,
      meatPrepared: meatPrepared ?? this.meatPrepared,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (ndenguPrepared.present) {
      map['ndengu_prepared'] = Variable<int>(ndenguPrepared.value);
    }
    if (meatPrepared.present) {
      map['meat_prepared'] = Variable<int>(meatPrepared.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductionBatchesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('ndenguPrepared: $ndenguPrepared, ')
          ..write('meatPrepared: $meatPrepared, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ProfitRecordsTable extends ProfitRecords
    with TableInfo<$ProfitRecordsTable, ProfitRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfitRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _samosasPreparedMeta = const VerificationMeta(
    'samosasPrepared',
  );
  @override
  late final GeneratedColumn<int> samosasPrepared = GeneratedColumn<int>(
    'samosas_prepared',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pricePerSamosaMeta = const VerificationMeta(
    'pricePerSamosa',
  );
  @override
  late final GeneratedColumn<double> pricePerSamosa = GeneratedColumn<double>(
    'price_per_samosa',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(40),
  );
  static const VerificationMeta _meatCostMeta = const VerificationMeta(
    'meatCost',
  );
  @override
  late final GeneratedColumn<double> meatCost = GeneratedColumn<double>(
    'meat_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dhaniaCostMeta = const VerificationMeta(
    'dhaniaCost',
  );
  @override
  late final GeneratedColumn<double> dhaniaCost = GeneratedColumn<double>(
    'dhania_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _flourWeeklyCostMeta = const VerificationMeta(
    'flourWeeklyCost',
  );
  @override
  late final GeneratedColumn<double> flourWeeklyCost = GeneratedColumn<double>(
    'flour_weekly_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _onionsWeeklyCostMeta = const VerificationMeta(
    'onionsWeeklyCost',
  );
  @override
  late final GeneratedColumn<double> onionsWeeklyCost = GeneratedColumn<double>(
    'onions_weekly_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _oilMonthlyCostMeta = const VerificationMeta(
    'oilMonthlyCost',
  );
  @override
  late final GeneratedColumn<double> oilMonthlyCost = GeneratedColumn<double>(
    'oil_monthly_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _gasCostMeta = const VerificationMeta(
    'gasCost',
  );
  @override
  late final GeneratedColumn<double> gasCost = GeneratedColumn<double>(
    'gas_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _transportCostMeta = const VerificationMeta(
    'transportCost',
  );
  @override
  late final GeneratedColumn<double> transportCost = GeneratedColumn<double>(
    'transport_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _labourCostMeta = const VerificationMeta(
    'labourCost',
  );
  @override
  late final GeneratedColumn<double> labourCost = GeneratedColumn<double>(
    'labour_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _revenueMeta = const VerificationMeta(
    'revenue',
  );
  @override
  late final GeneratedColumn<double> revenue = GeneratedColumn<double>(
    'revenue',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCostsMeta = const VerificationMeta(
    'totalCosts',
  );
  @override
  late final GeneratedColumn<double> totalCosts = GeneratedColumn<double>(
    'total_costs',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _profitMeta = const VerificationMeta('profit');
  @override
  late final GeneratedColumn<double> profit = GeneratedColumn<double>(
    'profit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    samosasPrepared,
    pricePerSamosa,
    meatCost,
    dhaniaCost,
    flourWeeklyCost,
    onionsWeeklyCost,
    oilMonthlyCost,
    gasCost,
    transportCost,
    labourCost,
    revenue,
    totalCosts,
    profit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profit_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfitRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('samosas_prepared')) {
      context.handle(
        _samosasPreparedMeta,
        samosasPrepared.isAcceptableOrUnknown(
          data['samosas_prepared']!,
          _samosasPreparedMeta,
        ),
      );
    }
    if (data.containsKey('price_per_samosa')) {
      context.handle(
        _pricePerSamosaMeta,
        pricePerSamosa.isAcceptableOrUnknown(
          data['price_per_samosa']!,
          _pricePerSamosaMeta,
        ),
      );
    }
    if (data.containsKey('meat_cost')) {
      context.handle(
        _meatCostMeta,
        meatCost.isAcceptableOrUnknown(data['meat_cost']!, _meatCostMeta),
      );
    }
    if (data.containsKey('dhania_cost')) {
      context.handle(
        _dhaniaCostMeta,
        dhaniaCost.isAcceptableOrUnknown(data['dhania_cost']!, _dhaniaCostMeta),
      );
    }
    if (data.containsKey('flour_weekly_cost')) {
      context.handle(
        _flourWeeklyCostMeta,
        flourWeeklyCost.isAcceptableOrUnknown(
          data['flour_weekly_cost']!,
          _flourWeeklyCostMeta,
        ),
      );
    }
    if (data.containsKey('onions_weekly_cost')) {
      context.handle(
        _onionsWeeklyCostMeta,
        onionsWeeklyCost.isAcceptableOrUnknown(
          data['onions_weekly_cost']!,
          _onionsWeeklyCostMeta,
        ),
      );
    }
    if (data.containsKey('oil_monthly_cost')) {
      context.handle(
        _oilMonthlyCostMeta,
        oilMonthlyCost.isAcceptableOrUnknown(
          data['oil_monthly_cost']!,
          _oilMonthlyCostMeta,
        ),
      );
    }
    if (data.containsKey('gas_cost')) {
      context.handle(
        _gasCostMeta,
        gasCost.isAcceptableOrUnknown(data['gas_cost']!, _gasCostMeta),
      );
    }
    if (data.containsKey('transport_cost')) {
      context.handle(
        _transportCostMeta,
        transportCost.isAcceptableOrUnknown(
          data['transport_cost']!,
          _transportCostMeta,
        ),
      );
    }
    if (data.containsKey('labour_cost')) {
      context.handle(
        _labourCostMeta,
        labourCost.isAcceptableOrUnknown(data['labour_cost']!, _labourCostMeta),
      );
    }
    if (data.containsKey('revenue')) {
      context.handle(
        _revenueMeta,
        revenue.isAcceptableOrUnknown(data['revenue']!, _revenueMeta),
      );
    }
    if (data.containsKey('total_costs')) {
      context.handle(
        _totalCostsMeta,
        totalCosts.isAcceptableOrUnknown(data['total_costs']!, _totalCostsMeta),
      );
    }
    if (data.containsKey('profit')) {
      context.handle(
        _profitMeta,
        profit.isAcceptableOrUnknown(data['profit']!, _profitMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfitRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfitRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      samosasPrepared: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}samosas_prepared'],
      )!,
      pricePerSamosa: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_per_samosa'],
      )!,
      meatCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}meat_cost'],
      )!,
      dhaniaCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dhania_cost'],
      )!,
      flourWeeklyCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}flour_weekly_cost'],
      )!,
      onionsWeeklyCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}onions_weekly_cost'],
      )!,
      oilMonthlyCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}oil_monthly_cost'],
      )!,
      gasCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gas_cost'],
      )!,
      transportCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}transport_cost'],
      )!,
      labourCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}labour_cost'],
      )!,
      revenue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}revenue'],
      )!,
      totalCosts: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_costs'],
      )!,
      profit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit'],
      )!,
    );
  }

  @override
  $ProfitRecordsTable createAlias(String alias) {
    return $ProfitRecordsTable(attachedDatabase, alias);
  }
}

class ProfitRecord extends DataClass implements Insertable<ProfitRecord> {
  final int id;
  final DateTime date;
  final int samosasPrepared;
  final double pricePerSamosa;
  final double meatCost;
  final double dhaniaCost;
  final double flourWeeklyCost;
  final double onionsWeeklyCost;
  final double oilMonthlyCost;
  final double gasCost;
  final double transportCost;
  final double labourCost;
  final double revenue;
  final double totalCosts;
  final double profit;
  const ProfitRecord({
    required this.id,
    required this.date,
    required this.samosasPrepared,
    required this.pricePerSamosa,
    required this.meatCost,
    required this.dhaniaCost,
    required this.flourWeeklyCost,
    required this.onionsWeeklyCost,
    required this.oilMonthlyCost,
    required this.gasCost,
    required this.transportCost,
    required this.labourCost,
    required this.revenue,
    required this.totalCosts,
    required this.profit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['samosas_prepared'] = Variable<int>(samosasPrepared);
    map['price_per_samosa'] = Variable<double>(pricePerSamosa);
    map['meat_cost'] = Variable<double>(meatCost);
    map['dhania_cost'] = Variable<double>(dhaniaCost);
    map['flour_weekly_cost'] = Variable<double>(flourWeeklyCost);
    map['onions_weekly_cost'] = Variable<double>(onionsWeeklyCost);
    map['oil_monthly_cost'] = Variable<double>(oilMonthlyCost);
    map['gas_cost'] = Variable<double>(gasCost);
    map['transport_cost'] = Variable<double>(transportCost);
    map['labour_cost'] = Variable<double>(labourCost);
    map['revenue'] = Variable<double>(revenue);
    map['total_costs'] = Variable<double>(totalCosts);
    map['profit'] = Variable<double>(profit);
    return map;
  }

  ProfitRecordsCompanion toCompanion(bool nullToAbsent) {
    return ProfitRecordsCompanion(
      id: Value(id),
      date: Value(date),
      samosasPrepared: Value(samosasPrepared),
      pricePerSamosa: Value(pricePerSamosa),
      meatCost: Value(meatCost),
      dhaniaCost: Value(dhaniaCost),
      flourWeeklyCost: Value(flourWeeklyCost),
      onionsWeeklyCost: Value(onionsWeeklyCost),
      oilMonthlyCost: Value(oilMonthlyCost),
      gasCost: Value(gasCost),
      transportCost: Value(transportCost),
      labourCost: Value(labourCost),
      revenue: Value(revenue),
      totalCosts: Value(totalCosts),
      profit: Value(profit),
    );
  }

  factory ProfitRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfitRecord(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      samosasPrepared: serializer.fromJson<int>(json['samosasPrepared']),
      pricePerSamosa: serializer.fromJson<double>(json['pricePerSamosa']),
      meatCost: serializer.fromJson<double>(json['meatCost']),
      dhaniaCost: serializer.fromJson<double>(json['dhaniaCost']),
      flourWeeklyCost: serializer.fromJson<double>(json['flourWeeklyCost']),
      onionsWeeklyCost: serializer.fromJson<double>(json['onionsWeeklyCost']),
      oilMonthlyCost: serializer.fromJson<double>(json['oilMonthlyCost']),
      gasCost: serializer.fromJson<double>(json['gasCost']),
      transportCost: serializer.fromJson<double>(json['transportCost']),
      labourCost: serializer.fromJson<double>(json['labourCost']),
      revenue: serializer.fromJson<double>(json['revenue']),
      totalCosts: serializer.fromJson<double>(json['totalCosts']),
      profit: serializer.fromJson<double>(json['profit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'samosasPrepared': serializer.toJson<int>(samosasPrepared),
      'pricePerSamosa': serializer.toJson<double>(pricePerSamosa),
      'meatCost': serializer.toJson<double>(meatCost),
      'dhaniaCost': serializer.toJson<double>(dhaniaCost),
      'flourWeeklyCost': serializer.toJson<double>(flourWeeklyCost),
      'onionsWeeklyCost': serializer.toJson<double>(onionsWeeklyCost),
      'oilMonthlyCost': serializer.toJson<double>(oilMonthlyCost),
      'gasCost': serializer.toJson<double>(gasCost),
      'transportCost': serializer.toJson<double>(transportCost),
      'labourCost': serializer.toJson<double>(labourCost),
      'revenue': serializer.toJson<double>(revenue),
      'totalCosts': serializer.toJson<double>(totalCosts),
      'profit': serializer.toJson<double>(profit),
    };
  }

  ProfitRecord copyWith({
    int? id,
    DateTime? date,
    int? samosasPrepared,
    double? pricePerSamosa,
    double? meatCost,
    double? dhaniaCost,
    double? flourWeeklyCost,
    double? onionsWeeklyCost,
    double? oilMonthlyCost,
    double? gasCost,
    double? transportCost,
    double? labourCost,
    double? revenue,
    double? totalCosts,
    double? profit,
  }) => ProfitRecord(
    id: id ?? this.id,
    date: date ?? this.date,
    samosasPrepared: samosasPrepared ?? this.samosasPrepared,
    pricePerSamosa: pricePerSamosa ?? this.pricePerSamosa,
    meatCost: meatCost ?? this.meatCost,
    dhaniaCost: dhaniaCost ?? this.dhaniaCost,
    flourWeeklyCost: flourWeeklyCost ?? this.flourWeeklyCost,
    onionsWeeklyCost: onionsWeeklyCost ?? this.onionsWeeklyCost,
    oilMonthlyCost: oilMonthlyCost ?? this.oilMonthlyCost,
    gasCost: gasCost ?? this.gasCost,
    transportCost: transportCost ?? this.transportCost,
    labourCost: labourCost ?? this.labourCost,
    revenue: revenue ?? this.revenue,
    totalCosts: totalCosts ?? this.totalCosts,
    profit: profit ?? this.profit,
  );
  ProfitRecord copyWithCompanion(ProfitRecordsCompanion data) {
    return ProfitRecord(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      samosasPrepared: data.samosasPrepared.present
          ? data.samosasPrepared.value
          : this.samosasPrepared,
      pricePerSamosa: data.pricePerSamosa.present
          ? data.pricePerSamosa.value
          : this.pricePerSamosa,
      meatCost: data.meatCost.present ? data.meatCost.value : this.meatCost,
      dhaniaCost: data.dhaniaCost.present
          ? data.dhaniaCost.value
          : this.dhaniaCost,
      flourWeeklyCost: data.flourWeeklyCost.present
          ? data.flourWeeklyCost.value
          : this.flourWeeklyCost,
      onionsWeeklyCost: data.onionsWeeklyCost.present
          ? data.onionsWeeklyCost.value
          : this.onionsWeeklyCost,
      oilMonthlyCost: data.oilMonthlyCost.present
          ? data.oilMonthlyCost.value
          : this.oilMonthlyCost,
      gasCost: data.gasCost.present ? data.gasCost.value : this.gasCost,
      transportCost: data.transportCost.present
          ? data.transportCost.value
          : this.transportCost,
      labourCost: data.labourCost.present
          ? data.labourCost.value
          : this.labourCost,
      revenue: data.revenue.present ? data.revenue.value : this.revenue,
      totalCosts: data.totalCosts.present
          ? data.totalCosts.value
          : this.totalCosts,
      profit: data.profit.present ? data.profit.value : this.profit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfitRecord(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('samosasPrepared: $samosasPrepared, ')
          ..write('pricePerSamosa: $pricePerSamosa, ')
          ..write('meatCost: $meatCost, ')
          ..write('dhaniaCost: $dhaniaCost, ')
          ..write('flourWeeklyCost: $flourWeeklyCost, ')
          ..write('onionsWeeklyCost: $onionsWeeklyCost, ')
          ..write('oilMonthlyCost: $oilMonthlyCost, ')
          ..write('gasCost: $gasCost, ')
          ..write('transportCost: $transportCost, ')
          ..write('labourCost: $labourCost, ')
          ..write('revenue: $revenue, ')
          ..write('totalCosts: $totalCosts, ')
          ..write('profit: $profit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    samosasPrepared,
    pricePerSamosa,
    meatCost,
    dhaniaCost,
    flourWeeklyCost,
    onionsWeeklyCost,
    oilMonthlyCost,
    gasCost,
    transportCost,
    labourCost,
    revenue,
    totalCosts,
    profit,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfitRecord &&
          other.id == this.id &&
          other.date == this.date &&
          other.samosasPrepared == this.samosasPrepared &&
          other.pricePerSamosa == this.pricePerSamosa &&
          other.meatCost == this.meatCost &&
          other.dhaniaCost == this.dhaniaCost &&
          other.flourWeeklyCost == this.flourWeeklyCost &&
          other.onionsWeeklyCost == this.onionsWeeklyCost &&
          other.oilMonthlyCost == this.oilMonthlyCost &&
          other.gasCost == this.gasCost &&
          other.transportCost == this.transportCost &&
          other.labourCost == this.labourCost &&
          other.revenue == this.revenue &&
          other.totalCosts == this.totalCosts &&
          other.profit == this.profit);
}

class ProfitRecordsCompanion extends UpdateCompanion<ProfitRecord> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> samosasPrepared;
  final Value<double> pricePerSamosa;
  final Value<double> meatCost;
  final Value<double> dhaniaCost;
  final Value<double> flourWeeklyCost;
  final Value<double> onionsWeeklyCost;
  final Value<double> oilMonthlyCost;
  final Value<double> gasCost;
  final Value<double> transportCost;
  final Value<double> labourCost;
  final Value<double> revenue;
  final Value<double> totalCosts;
  final Value<double> profit;
  const ProfitRecordsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.samosasPrepared = const Value.absent(),
    this.pricePerSamosa = const Value.absent(),
    this.meatCost = const Value.absent(),
    this.dhaniaCost = const Value.absent(),
    this.flourWeeklyCost = const Value.absent(),
    this.onionsWeeklyCost = const Value.absent(),
    this.oilMonthlyCost = const Value.absent(),
    this.gasCost = const Value.absent(),
    this.transportCost = const Value.absent(),
    this.labourCost = const Value.absent(),
    this.revenue = const Value.absent(),
    this.totalCosts = const Value.absent(),
    this.profit = const Value.absent(),
  });
  ProfitRecordsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.samosasPrepared = const Value.absent(),
    this.pricePerSamosa = const Value.absent(),
    this.meatCost = const Value.absent(),
    this.dhaniaCost = const Value.absent(),
    this.flourWeeklyCost = const Value.absent(),
    this.onionsWeeklyCost = const Value.absent(),
    this.oilMonthlyCost = const Value.absent(),
    this.gasCost = const Value.absent(),
    this.transportCost = const Value.absent(),
    this.labourCost = const Value.absent(),
    this.revenue = const Value.absent(),
    this.totalCosts = const Value.absent(),
    this.profit = const Value.absent(),
  }) : date = Value(date);
  static Insertable<ProfitRecord> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? samosasPrepared,
    Expression<double>? pricePerSamosa,
    Expression<double>? meatCost,
    Expression<double>? dhaniaCost,
    Expression<double>? flourWeeklyCost,
    Expression<double>? onionsWeeklyCost,
    Expression<double>? oilMonthlyCost,
    Expression<double>? gasCost,
    Expression<double>? transportCost,
    Expression<double>? labourCost,
    Expression<double>? revenue,
    Expression<double>? totalCosts,
    Expression<double>? profit,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (samosasPrepared != null) 'samosas_prepared': samosasPrepared,
      if (pricePerSamosa != null) 'price_per_samosa': pricePerSamosa,
      if (meatCost != null) 'meat_cost': meatCost,
      if (dhaniaCost != null) 'dhania_cost': dhaniaCost,
      if (flourWeeklyCost != null) 'flour_weekly_cost': flourWeeklyCost,
      if (onionsWeeklyCost != null) 'onions_weekly_cost': onionsWeeklyCost,
      if (oilMonthlyCost != null) 'oil_monthly_cost': oilMonthlyCost,
      if (gasCost != null) 'gas_cost': gasCost,
      if (transportCost != null) 'transport_cost': transportCost,
      if (labourCost != null) 'labour_cost': labourCost,
      if (revenue != null) 'revenue': revenue,
      if (totalCosts != null) 'total_costs': totalCosts,
      if (profit != null) 'profit': profit,
    });
  }

  ProfitRecordsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<int>? samosasPrepared,
    Value<double>? pricePerSamosa,
    Value<double>? meatCost,
    Value<double>? dhaniaCost,
    Value<double>? flourWeeklyCost,
    Value<double>? onionsWeeklyCost,
    Value<double>? oilMonthlyCost,
    Value<double>? gasCost,
    Value<double>? transportCost,
    Value<double>? labourCost,
    Value<double>? revenue,
    Value<double>? totalCosts,
    Value<double>? profit,
  }) {
    return ProfitRecordsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      samosasPrepared: samosasPrepared ?? this.samosasPrepared,
      pricePerSamosa: pricePerSamosa ?? this.pricePerSamosa,
      meatCost: meatCost ?? this.meatCost,
      dhaniaCost: dhaniaCost ?? this.dhaniaCost,
      flourWeeklyCost: flourWeeklyCost ?? this.flourWeeklyCost,
      onionsWeeklyCost: onionsWeeklyCost ?? this.onionsWeeklyCost,
      oilMonthlyCost: oilMonthlyCost ?? this.oilMonthlyCost,
      gasCost: gasCost ?? this.gasCost,
      transportCost: transportCost ?? this.transportCost,
      labourCost: labourCost ?? this.labourCost,
      revenue: revenue ?? this.revenue,
      totalCosts: totalCosts ?? this.totalCosts,
      profit: profit ?? this.profit,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (samosasPrepared.present) {
      map['samosas_prepared'] = Variable<int>(samosasPrepared.value);
    }
    if (pricePerSamosa.present) {
      map['price_per_samosa'] = Variable<double>(pricePerSamosa.value);
    }
    if (meatCost.present) {
      map['meat_cost'] = Variable<double>(meatCost.value);
    }
    if (dhaniaCost.present) {
      map['dhania_cost'] = Variable<double>(dhaniaCost.value);
    }
    if (flourWeeklyCost.present) {
      map['flour_weekly_cost'] = Variable<double>(flourWeeklyCost.value);
    }
    if (onionsWeeklyCost.present) {
      map['onions_weekly_cost'] = Variable<double>(onionsWeeklyCost.value);
    }
    if (oilMonthlyCost.present) {
      map['oil_monthly_cost'] = Variable<double>(oilMonthlyCost.value);
    }
    if (gasCost.present) {
      map['gas_cost'] = Variable<double>(gasCost.value);
    }
    if (transportCost.present) {
      map['transport_cost'] = Variable<double>(transportCost.value);
    }
    if (labourCost.present) {
      map['labour_cost'] = Variable<double>(labourCost.value);
    }
    if (revenue.present) {
      map['revenue'] = Variable<double>(revenue.value);
    }
    if (totalCosts.present) {
      map['total_costs'] = Variable<double>(totalCosts.value);
    }
    if (profit.present) {
      map['profit'] = Variable<double>(profit.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfitRecordsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('samosasPrepared: $samosasPrepared, ')
          ..write('pricePerSamosa: $pricePerSamosa, ')
          ..write('meatCost: $meatCost, ')
          ..write('dhaniaCost: $dhaniaCost, ')
          ..write('flourWeeklyCost: $flourWeeklyCost, ')
          ..write('onionsWeeklyCost: $onionsWeeklyCost, ')
          ..write('oilMonthlyCost: $oilMonthlyCost, ')
          ..write('gasCost: $gasCost, ')
          ..write('transportCost: $transportCost, ')
          ..write('labourCost: $labourCost, ')
          ..write('revenue: $revenue, ')
          ..write('totalCosts: $totalCosts, ')
          ..write('profit: $profit')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $SalesTable sales = $SalesTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $UnpaidRecordsTable unpaidRecords = $UnpaidRecordsTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $ProductionBatchesTable productionBatches =
      $ProductionBatchesTable(this);
  late final $ProfitRecordsTable profitRecords = $ProfitRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    customers,
    orders,
    sales,
    expenses,
    unpaidRecords,
    payments,
    productionBatches,
    profitRecords,
  ];
}

typedef $$CustomersTableCreateCompanionBuilder =
    CustomersCompanion Function({
      Value<int> id,
      required String name,
      Value<String> phone,
      Value<DateTime> createdAt,
    });
typedef $$CustomersTableUpdateCompanionBuilder =
    CustomersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> phone,
      Value<DateTime> createdAt,
    });

final class $$CustomersTableReferences
    extends BaseReferences<_$AppDatabase, $CustomersTable, Customer> {
  $$CustomersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OrdersTable, List<Order>> _ordersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.orders,
    aliasName: $_aliasNameGenerator(db.customers.id, db.orders.customerId),
  );

  $$OrdersTableProcessedTableManager get ordersRefs {
    final manager = $$OrdersTableTableManager(
      $_db,
      $_db.orders,
    ).filter((f) => f.customerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ordersRefs(
    Expression<bool> Function($$OrdersTableFilterComposer f) f,
  ) {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableFilterComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> ordersRefs<T extends Object>(
    Expression<T> Function($$OrdersTableAnnotationComposer a) f,
  ) {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableAnnotationComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTable,
          Customer,
          $$CustomersTableFilterComposer,
          $$CustomersTableOrderingComposer,
          $$CustomersTableAnnotationComposer,
          $$CustomersTableCreateCompanionBuilder,
          $$CustomersTableUpdateCompanionBuilder,
          (Customer, $$CustomersTableReferences),
          Customer,
          PrefetchHooks Function({bool ordersRefs})
        > {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CustomersCompanion(
                id: id,
                name: name,
                phone: phone,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> phone = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CustomersCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ordersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (ordersRefs) db.orders],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ordersRefs)
                    await $_getPrefetchedData<Customer, $CustomersTable, Order>(
                      currentTable: table,
                      referencedTable: $$CustomersTableReferences
                          ._ordersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CustomersTableReferences(db, table, p0).ordersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.customerId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTable,
      Customer,
      $$CustomersTableFilterComposer,
      $$CustomersTableOrderingComposer,
      $$CustomersTableAnnotationComposer,
      $$CustomersTableCreateCompanionBuilder,
      $$CustomersTableUpdateCompanionBuilder,
      (Customer, $$CustomersTableReferences),
      Customer,
      PrefetchHooks Function({bool ordersRefs})
    >;
typedef $$OrdersTableCreateCompanionBuilder =
    OrdersCompanion Function({
      Value<int> id,
      required int customerId,
      Value<int> ndenguCount,
      Value<int> meatCount,
      required DateTime orderDate,
      Value<String> status,
    });
typedef $$OrdersTableUpdateCompanionBuilder =
    OrdersCompanion Function({
      Value<int> id,
      Value<int> customerId,
      Value<int> ndenguCount,
      Value<int> meatCount,
      Value<DateTime> orderDate,
      Value<String> status,
    });

final class $$OrdersTableReferences
    extends BaseReferences<_$AppDatabase, $OrdersTable, Order> {
  $$OrdersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CustomersTable _customerIdTable(_$AppDatabase db) => db.customers
      .createAlias($_aliasNameGenerator(db.orders.customerId, db.customers.id));

  $$CustomersTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<int>('customer_id')!;

    final manager = $$CustomersTableTableManager(
      $_db,
      $_db.customers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SalesTable, List<Sale>> _salesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sales,
    aliasName: $_aliasNameGenerator(db.orders.id, db.sales.orderId),
  );

  $$SalesTableProcessedTableManager get salesRefs {
    final manager = $$SalesTableTableManager(
      $_db,
      $_db.sales,
    ).filter((f) => f.orderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_salesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ndenguCount => $composableBuilder(
    column: $table.ndenguCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get meatCount => $composableBuilder(
    column: $table.meatCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get orderDate => $composableBuilder(
    column: $table.orderDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomersTableFilterComposer get customerId {
    final $$CustomersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableFilterComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> salesRefs(
    Expression<bool> Function($$SalesTableFilterComposer f) f,
  ) {
    final $$SalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableFilterComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ndenguCount => $composableBuilder(
    column: $table.ndenguCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get meatCount => $composableBuilder(
    column: $table.meatCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get orderDate => $composableBuilder(
    column: $table.orderDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomersTableOrderingComposer get customerId {
    final $$CustomersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableOrderingComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ndenguCount => $composableBuilder(
    column: $table.ndenguCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get meatCount =>
      $composableBuilder(column: $table.meatCount, builder: (column) => column);

  GeneratedColumn<DateTime> get orderDate =>
      $composableBuilder(column: $table.orderDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$CustomersTableAnnotationComposer get customerId {
    final $$CustomersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableAnnotationComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> salesRefs<T extends Object>(
    Expression<T> Function($$SalesTableAnnotationComposer a) f,
  ) {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableAnnotationComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdersTable,
          Order,
          $$OrdersTableFilterComposer,
          $$OrdersTableOrderingComposer,
          $$OrdersTableAnnotationComposer,
          $$OrdersTableCreateCompanionBuilder,
          $$OrdersTableUpdateCompanionBuilder,
          (Order, $$OrdersTableReferences),
          Order,
          PrefetchHooks Function({bool customerId, bool salesRefs})
        > {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> customerId = const Value.absent(),
                Value<int> ndenguCount = const Value.absent(),
                Value<int> meatCount = const Value.absent(),
                Value<DateTime> orderDate = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => OrdersCompanion(
                id: id,
                customerId: customerId,
                ndenguCount: ndenguCount,
                meatCount: meatCount,
                orderDate: orderDate,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int customerId,
                Value<int> ndenguCount = const Value.absent(),
                Value<int> meatCount = const Value.absent(),
                required DateTime orderDate,
                Value<String> status = const Value.absent(),
              }) => OrdersCompanion.insert(
                id: id,
                customerId: customerId,
                ndenguCount: ndenguCount,
                meatCount: meatCount,
                orderDate: orderDate,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$OrdersTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({customerId = false, salesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (salesRefs) db.sales],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (customerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.customerId,
                                referencedTable: $$OrdersTableReferences
                                    ._customerIdTable(db),
                                referencedColumn: $$OrdersTableReferences
                                    ._customerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (salesRefs)
                    await $_getPrefetchedData<Order, $OrdersTable, Sale>(
                      currentTable: table,
                      referencedTable: $$OrdersTableReferences._salesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$OrdersTableReferences(db, table, p0).salesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.orderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$OrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdersTable,
      Order,
      $$OrdersTableFilterComposer,
      $$OrdersTableOrderingComposer,
      $$OrdersTableAnnotationComposer,
      $$OrdersTableCreateCompanionBuilder,
      $$OrdersTableUpdateCompanionBuilder,
      (Order, $$OrdersTableReferences),
      Order,
      PrefetchHooks Function({bool customerId, bool salesRefs})
    >;
typedef $$SalesTableCreateCompanionBuilder =
    SalesCompanion Function({
      Value<int> id,
      Value<int?> orderId,
      Value<DateTime> createdAt,
      Value<int> ndenguCount,
      Value<int> meatCount,
      Value<double> totalAmount,
      Value<String> customerName,
      Value<bool> isPaid,
    });
typedef $$SalesTableUpdateCompanionBuilder =
    SalesCompanion Function({
      Value<int> id,
      Value<int?> orderId,
      Value<DateTime> createdAt,
      Value<int> ndenguCount,
      Value<int> meatCount,
      Value<double> totalAmount,
      Value<String> customerName,
      Value<bool> isPaid,
    });

final class $$SalesTableReferences
    extends BaseReferences<_$AppDatabase, $SalesTable, Sale> {
  $$SalesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrdersTable _orderIdTable(_$AppDatabase db) => db.orders.createAlias(
    $_aliasNameGenerator(db.sales.orderId, db.orders.id),
  );

  $$OrdersTableProcessedTableManager? get orderId {
    final $_column = $_itemColumn<int>('order_id');
    if ($_column == null) return null;
    final manager = $$OrdersTableTableManager(
      $_db,
      $_db.orders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PaymentsTable, List<Payment>> _paymentsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.payments,
    aliasName: $_aliasNameGenerator(db.sales.id, db.payments.saleId),
  );

  $$PaymentsTableProcessedTableManager get paymentsRefs {
    final manager = $$PaymentsTableTableManager(
      $_db,
      $_db.payments,
    ).filter((f) => f.saleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SalesTableFilterComposer extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ndenguCount => $composableBuilder(
    column: $table.ndenguCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get meatCount => $composableBuilder(
    column: $table.meatCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPaid => $composableBuilder(
    column: $table.isPaid,
    builder: (column) => ColumnFilters(column),
  );

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableFilterComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> paymentsRefs(
    Expression<bool> Function($$PaymentsTableFilterComposer f) f,
  ) {
    final $$PaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableFilterComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SalesTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ndenguCount => $composableBuilder(
    column: $table.ndenguCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get meatCount => $composableBuilder(
    column: $table.meatCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPaid => $composableBuilder(
    column: $table.isPaid,
    builder: (column) => ColumnOrderings(column),
  );

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableOrderingComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get ndenguCount => $composableBuilder(
    column: $table.ndenguCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get meatCount =>
      $composableBuilder(column: $table.meatCount, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPaid =>
      $composableBuilder(column: $table.isPaid, builder: (column) => column);

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableAnnotationComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> paymentsRefs<T extends Object>(
    Expression<T> Function($$PaymentsTableAnnotationComposer a) f,
  ) {
    final $$PaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalesTable,
          Sale,
          $$SalesTableFilterComposer,
          $$SalesTableOrderingComposer,
          $$SalesTableAnnotationComposer,
          $$SalesTableCreateCompanionBuilder,
          $$SalesTableUpdateCompanionBuilder,
          (Sale, $$SalesTableReferences),
          Sale,
          PrefetchHooks Function({bool orderId, bool paymentsRefs})
        > {
  $$SalesTableTableManager(_$AppDatabase db, $SalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> orderId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> ndenguCount = const Value.absent(),
                Value<int> meatCount = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<bool> isPaid = const Value.absent(),
              }) => SalesCompanion(
                id: id,
                orderId: orderId,
                createdAt: createdAt,
                ndenguCount: ndenguCount,
                meatCount: meatCount,
                totalAmount: totalAmount,
                customerName: customerName,
                isPaid: isPaid,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> orderId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> ndenguCount = const Value.absent(),
                Value<int> meatCount = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<bool> isPaid = const Value.absent(),
              }) => SalesCompanion.insert(
                id: id,
                orderId: orderId,
                createdAt: createdAt,
                ndenguCount: ndenguCount,
                meatCount: meatCount,
                totalAmount: totalAmount,
                customerName: customerName,
                isPaid: isPaid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SalesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({orderId = false, paymentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (paymentsRefs) db.payments],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (orderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.orderId,
                                referencedTable: $$SalesTableReferences
                                    ._orderIdTable(db),
                                referencedColumn: $$SalesTableReferences
                                    ._orderIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (paymentsRefs)
                    await $_getPrefetchedData<Sale, $SalesTable, Payment>(
                      currentTable: table,
                      referencedTable: $$SalesTableReferences
                          ._paymentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SalesTableReferences(db, table, p0).paymentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.saleId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalesTable,
      Sale,
      $$SalesTableFilterComposer,
      $$SalesTableOrderingComposer,
      $$SalesTableAnnotationComposer,
      $$SalesTableCreateCompanionBuilder,
      $$SalesTableUpdateCompanionBuilder,
      (Sale, $$SalesTableReferences),
      Sale,
      PrefetchHooks Function({bool orderId, bool paymentsRefs})
    >;
typedef $$ExpensesTableCreateCompanionBuilder =
    ExpensesCompanion Function({
      Value<int> id,
      required String name,
      required double amount,
      Value<String> category,
      Value<DateTime> createdAt,
    });
typedef $$ExpensesTableUpdateCompanionBuilder =
    ExpensesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> amount,
      Value<String> category,
      Value<DateTime> createdAt,
    });

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          Expense,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
          Expense,
          PrefetchHooks Function()
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                name: name,
                amount: amount,
                category: category,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double amount,
                Value<String> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                name: name,
                amount: amount,
                category: category,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      Expense,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
      Expense,
      PrefetchHooks Function()
    >;
typedef $$UnpaidRecordsTableCreateCompanionBuilder =
    UnpaidRecordsCompanion Function({
      Value<int> id,
      required String customerName,
      required double amount,
      required DateTime date,
      Value<String> notes,
      Value<bool> isPaid,
    });
typedef $$UnpaidRecordsTableUpdateCompanionBuilder =
    UnpaidRecordsCompanion Function({
      Value<int> id,
      Value<String> customerName,
      Value<double> amount,
      Value<DateTime> date,
      Value<String> notes,
      Value<bool> isPaid,
    });

class $$UnpaidRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $UnpaidRecordsTable> {
  $$UnpaidRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPaid => $composableBuilder(
    column: $table.isPaid,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UnpaidRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $UnpaidRecordsTable> {
  $$UnpaidRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPaid => $composableBuilder(
    column: $table.isPaid,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnpaidRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnpaidRecordsTable> {
  $$UnpaidRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isPaid =>
      $composableBuilder(column: $table.isPaid, builder: (column) => column);
}

class $$UnpaidRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnpaidRecordsTable,
          UnpaidRecord,
          $$UnpaidRecordsTableFilterComposer,
          $$UnpaidRecordsTableOrderingComposer,
          $$UnpaidRecordsTableAnnotationComposer,
          $$UnpaidRecordsTableCreateCompanionBuilder,
          $$UnpaidRecordsTableUpdateCompanionBuilder,
          (
            UnpaidRecord,
            BaseReferences<_$AppDatabase, $UnpaidRecordsTable, UnpaidRecord>,
          ),
          UnpaidRecord,
          PrefetchHooks Function()
        > {
  $$UnpaidRecordsTableTableManager(_$AppDatabase db, $UnpaidRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnpaidRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnpaidRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnpaidRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<bool> isPaid = const Value.absent(),
              }) => UnpaidRecordsCompanion(
                id: id,
                customerName: customerName,
                amount: amount,
                date: date,
                notes: notes,
                isPaid: isPaid,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String customerName,
                required double amount,
                required DateTime date,
                Value<String> notes = const Value.absent(),
                Value<bool> isPaid = const Value.absent(),
              }) => UnpaidRecordsCompanion.insert(
                id: id,
                customerName: customerName,
                amount: amount,
                date: date,
                notes: notes,
                isPaid: isPaid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UnpaidRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnpaidRecordsTable,
      UnpaidRecord,
      $$UnpaidRecordsTableFilterComposer,
      $$UnpaidRecordsTableOrderingComposer,
      $$UnpaidRecordsTableAnnotationComposer,
      $$UnpaidRecordsTableCreateCompanionBuilder,
      $$UnpaidRecordsTableUpdateCompanionBuilder,
      (
        UnpaidRecord,
        BaseReferences<_$AppDatabase, $UnpaidRecordsTable, UnpaidRecord>,
      ),
      UnpaidRecord,
      PrefetchHooks Function()
    >;
typedef $$PaymentsTableCreateCompanionBuilder =
    PaymentsCompanion Function({
      Value<int> id,
      required int saleId,
      required double amount,
      required String method,
      Value<DateTime> createdAt,
    });
typedef $$PaymentsTableUpdateCompanionBuilder =
    PaymentsCompanion Function({
      Value<int> id,
      Value<int> saleId,
      Value<double> amount,
      Value<String> method,
      Value<DateTime> createdAt,
    });

final class $$PaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $PaymentsTable, Payment> {
  $$PaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SalesTable _saleIdTable(_$AppDatabase db) => db.sales.createAlias(
    $_aliasNameGenerator(db.payments.saleId, db.sales.id),
  );

  $$SalesTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<int>('sale_id')!;

    final manager = $$SalesTableTableManager(
      $_db,
      $_db.sales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SalesTableFilterComposer get saleId {
    final $$SalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableFilterComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SalesTableOrderingComposer get saleId {
    final $$SalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableOrderingComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SalesTableAnnotationComposer get saleId {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableAnnotationComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTable,
          Payment,
          $$PaymentsTableFilterComposer,
          $$PaymentsTableOrderingComposer,
          $$PaymentsTableAnnotationComposer,
          $$PaymentsTableCreateCompanionBuilder,
          $$PaymentsTableUpdateCompanionBuilder,
          (Payment, $$PaymentsTableReferences),
          Payment,
          PrefetchHooks Function({bool saleId})
        > {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> saleId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PaymentsCompanion(
                id: id,
                saleId: saleId,
                amount: amount,
                method: method,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int saleId,
                required double amount,
                required String method,
                Value<DateTime> createdAt = const Value.absent(),
              }) => PaymentsCompanion.insert(
                id: id,
                saleId: saleId,
                amount: amount,
                method: method,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({saleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (saleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.saleId,
                                referencedTable: $$PaymentsTableReferences
                                    ._saleIdTable(db),
                                referencedColumn: $$PaymentsTableReferences
                                    ._saleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTable,
      Payment,
      $$PaymentsTableFilterComposer,
      $$PaymentsTableOrderingComposer,
      $$PaymentsTableAnnotationComposer,
      $$PaymentsTableCreateCompanionBuilder,
      $$PaymentsTableUpdateCompanionBuilder,
      (Payment, $$PaymentsTableReferences),
      Payment,
      PrefetchHooks Function({bool saleId})
    >;
typedef $$ProductionBatchesTableCreateCompanionBuilder =
    ProductionBatchesCompanion Function({
      Value<int> id,
      required DateTime date,
      Value<int> ndenguPrepared,
      Value<int> meatPrepared,
      Value<DateTime> createdAt,
    });
typedef $$ProductionBatchesTableUpdateCompanionBuilder =
    ProductionBatchesCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<int> ndenguPrepared,
      Value<int> meatPrepared,
      Value<DateTime> createdAt,
    });

class $$ProductionBatchesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductionBatchesTable> {
  $$ProductionBatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ndenguPrepared => $composableBuilder(
    column: $table.ndenguPrepared,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get meatPrepared => $composableBuilder(
    column: $table.meatPrepared,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductionBatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductionBatchesTable> {
  $$ProductionBatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ndenguPrepared => $composableBuilder(
    column: $table.ndenguPrepared,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get meatPrepared => $composableBuilder(
    column: $table.meatPrepared,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductionBatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductionBatchesTable> {
  $$ProductionBatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get ndenguPrepared => $composableBuilder(
    column: $table.ndenguPrepared,
    builder: (column) => column,
  );

  GeneratedColumn<int> get meatPrepared => $composableBuilder(
    column: $table.meatPrepared,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProductionBatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductionBatchesTable,
          ProductionBatche,
          $$ProductionBatchesTableFilterComposer,
          $$ProductionBatchesTableOrderingComposer,
          $$ProductionBatchesTableAnnotationComposer,
          $$ProductionBatchesTableCreateCompanionBuilder,
          $$ProductionBatchesTableUpdateCompanionBuilder,
          (
            ProductionBatche,
            BaseReferences<
              _$AppDatabase,
              $ProductionBatchesTable,
              ProductionBatche
            >,
          ),
          ProductionBatche,
          PrefetchHooks Function()
        > {
  $$ProductionBatchesTableTableManager(
    _$AppDatabase db,
    $ProductionBatchesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductionBatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductionBatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductionBatchesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> ndenguPrepared = const Value.absent(),
                Value<int> meatPrepared = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProductionBatchesCompanion(
                id: id,
                date: date,
                ndenguPrepared: ndenguPrepared,
                meatPrepared: meatPrepared,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                Value<int> ndenguPrepared = const Value.absent(),
                Value<int> meatPrepared = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProductionBatchesCompanion.insert(
                id: id,
                date: date,
                ndenguPrepared: ndenguPrepared,
                meatPrepared: meatPrepared,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductionBatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductionBatchesTable,
      ProductionBatche,
      $$ProductionBatchesTableFilterComposer,
      $$ProductionBatchesTableOrderingComposer,
      $$ProductionBatchesTableAnnotationComposer,
      $$ProductionBatchesTableCreateCompanionBuilder,
      $$ProductionBatchesTableUpdateCompanionBuilder,
      (
        ProductionBatche,
        BaseReferences<
          _$AppDatabase,
          $ProductionBatchesTable,
          ProductionBatche
        >,
      ),
      ProductionBatche,
      PrefetchHooks Function()
    >;
typedef $$ProfitRecordsTableCreateCompanionBuilder =
    ProfitRecordsCompanion Function({
      Value<int> id,
      required DateTime date,
      Value<int> samosasPrepared,
      Value<double> pricePerSamosa,
      Value<double> meatCost,
      Value<double> dhaniaCost,
      Value<double> flourWeeklyCost,
      Value<double> onionsWeeklyCost,
      Value<double> oilMonthlyCost,
      Value<double> gasCost,
      Value<double> transportCost,
      Value<double> labourCost,
      Value<double> revenue,
      Value<double> totalCosts,
      Value<double> profit,
    });
typedef $$ProfitRecordsTableUpdateCompanionBuilder =
    ProfitRecordsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<int> samosasPrepared,
      Value<double> pricePerSamosa,
      Value<double> meatCost,
      Value<double> dhaniaCost,
      Value<double> flourWeeklyCost,
      Value<double> onionsWeeklyCost,
      Value<double> oilMonthlyCost,
      Value<double> gasCost,
      Value<double> transportCost,
      Value<double> labourCost,
      Value<double> revenue,
      Value<double> totalCosts,
      Value<double> profit,
    });

class $$ProfitRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ProfitRecordsTable> {
  $$ProfitRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get samosasPrepared => $composableBuilder(
    column: $table.samosasPrepared,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pricePerSamosa => $composableBuilder(
    column: $table.pricePerSamosa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get meatCost => $composableBuilder(
    column: $table.meatCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dhaniaCost => $composableBuilder(
    column: $table.dhaniaCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get flourWeeklyCost => $composableBuilder(
    column: $table.flourWeeklyCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get onionsWeeklyCost => $composableBuilder(
    column: $table.onionsWeeklyCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get oilMonthlyCost => $composableBuilder(
    column: $table.oilMonthlyCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gasCost => $composableBuilder(
    column: $table.gasCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get transportCost => $composableBuilder(
    column: $table.transportCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get labourCost => $composableBuilder(
    column: $table.labourCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get revenue => $composableBuilder(
    column: $table.revenue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalCosts => $composableBuilder(
    column: $table.totalCosts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profit => $composableBuilder(
    column: $table.profit,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfitRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfitRecordsTable> {
  $$ProfitRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get samosasPrepared => $composableBuilder(
    column: $table.samosasPrepared,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pricePerSamosa => $composableBuilder(
    column: $table.pricePerSamosa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get meatCost => $composableBuilder(
    column: $table.meatCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dhaniaCost => $composableBuilder(
    column: $table.dhaniaCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get flourWeeklyCost => $composableBuilder(
    column: $table.flourWeeklyCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get onionsWeeklyCost => $composableBuilder(
    column: $table.onionsWeeklyCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get oilMonthlyCost => $composableBuilder(
    column: $table.oilMonthlyCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gasCost => $composableBuilder(
    column: $table.gasCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get transportCost => $composableBuilder(
    column: $table.transportCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get labourCost => $composableBuilder(
    column: $table.labourCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get revenue => $composableBuilder(
    column: $table.revenue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalCosts => $composableBuilder(
    column: $table.totalCosts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profit => $composableBuilder(
    column: $table.profit,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfitRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfitRecordsTable> {
  $$ProfitRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get samosasPrepared => $composableBuilder(
    column: $table.samosasPrepared,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pricePerSamosa => $composableBuilder(
    column: $table.pricePerSamosa,
    builder: (column) => column,
  );

  GeneratedColumn<double> get meatCost =>
      $composableBuilder(column: $table.meatCost, builder: (column) => column);

  GeneratedColumn<double> get dhaniaCost => $composableBuilder(
    column: $table.dhaniaCost,
    builder: (column) => column,
  );

  GeneratedColumn<double> get flourWeeklyCost => $composableBuilder(
    column: $table.flourWeeklyCost,
    builder: (column) => column,
  );

  GeneratedColumn<double> get onionsWeeklyCost => $composableBuilder(
    column: $table.onionsWeeklyCost,
    builder: (column) => column,
  );

  GeneratedColumn<double> get oilMonthlyCost => $composableBuilder(
    column: $table.oilMonthlyCost,
    builder: (column) => column,
  );

  GeneratedColumn<double> get gasCost =>
      $composableBuilder(column: $table.gasCost, builder: (column) => column);

  GeneratedColumn<double> get transportCost => $composableBuilder(
    column: $table.transportCost,
    builder: (column) => column,
  );

  GeneratedColumn<double> get labourCost => $composableBuilder(
    column: $table.labourCost,
    builder: (column) => column,
  );

  GeneratedColumn<double> get revenue =>
      $composableBuilder(column: $table.revenue, builder: (column) => column);

  GeneratedColumn<double> get totalCosts => $composableBuilder(
    column: $table.totalCosts,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profit =>
      $composableBuilder(column: $table.profit, builder: (column) => column);
}

class $$ProfitRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfitRecordsTable,
          ProfitRecord,
          $$ProfitRecordsTableFilterComposer,
          $$ProfitRecordsTableOrderingComposer,
          $$ProfitRecordsTableAnnotationComposer,
          $$ProfitRecordsTableCreateCompanionBuilder,
          $$ProfitRecordsTableUpdateCompanionBuilder,
          (
            ProfitRecord,
            BaseReferences<_$AppDatabase, $ProfitRecordsTable, ProfitRecord>,
          ),
          ProfitRecord,
          PrefetchHooks Function()
        > {
  $$ProfitRecordsTableTableManager(_$AppDatabase db, $ProfitRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfitRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfitRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfitRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> samosasPrepared = const Value.absent(),
                Value<double> pricePerSamosa = const Value.absent(),
                Value<double> meatCost = const Value.absent(),
                Value<double> dhaniaCost = const Value.absent(),
                Value<double> flourWeeklyCost = const Value.absent(),
                Value<double> onionsWeeklyCost = const Value.absent(),
                Value<double> oilMonthlyCost = const Value.absent(),
                Value<double> gasCost = const Value.absent(),
                Value<double> transportCost = const Value.absent(),
                Value<double> labourCost = const Value.absent(),
                Value<double> revenue = const Value.absent(),
                Value<double> totalCosts = const Value.absent(),
                Value<double> profit = const Value.absent(),
              }) => ProfitRecordsCompanion(
                id: id,
                date: date,
                samosasPrepared: samosasPrepared,
                pricePerSamosa: pricePerSamosa,
                meatCost: meatCost,
                dhaniaCost: dhaniaCost,
                flourWeeklyCost: flourWeeklyCost,
                onionsWeeklyCost: onionsWeeklyCost,
                oilMonthlyCost: oilMonthlyCost,
                gasCost: gasCost,
                transportCost: transportCost,
                labourCost: labourCost,
                revenue: revenue,
                totalCosts: totalCosts,
                profit: profit,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                Value<int> samosasPrepared = const Value.absent(),
                Value<double> pricePerSamosa = const Value.absent(),
                Value<double> meatCost = const Value.absent(),
                Value<double> dhaniaCost = const Value.absent(),
                Value<double> flourWeeklyCost = const Value.absent(),
                Value<double> onionsWeeklyCost = const Value.absent(),
                Value<double> oilMonthlyCost = const Value.absent(),
                Value<double> gasCost = const Value.absent(),
                Value<double> transportCost = const Value.absent(),
                Value<double> labourCost = const Value.absent(),
                Value<double> revenue = const Value.absent(),
                Value<double> totalCosts = const Value.absent(),
                Value<double> profit = const Value.absent(),
              }) => ProfitRecordsCompanion.insert(
                id: id,
                date: date,
                samosasPrepared: samosasPrepared,
                pricePerSamosa: pricePerSamosa,
                meatCost: meatCost,
                dhaniaCost: dhaniaCost,
                flourWeeklyCost: flourWeeklyCost,
                onionsWeeklyCost: onionsWeeklyCost,
                oilMonthlyCost: oilMonthlyCost,
                gasCost: gasCost,
                transportCost: transportCost,
                labourCost: labourCost,
                revenue: revenue,
                totalCosts: totalCosts,
                profit: profit,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfitRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfitRecordsTable,
      ProfitRecord,
      $$ProfitRecordsTableFilterComposer,
      $$ProfitRecordsTableOrderingComposer,
      $$ProfitRecordsTableAnnotationComposer,
      $$ProfitRecordsTableCreateCompanionBuilder,
      $$ProfitRecordsTableUpdateCompanionBuilder,
      (
        ProfitRecord,
        BaseReferences<_$AppDatabase, $ProfitRecordsTable, ProfitRecord>,
      ),
      ProfitRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db, _db.sales);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$UnpaidRecordsTableTableManager get unpaidRecords =>
      $$UnpaidRecordsTableTableManager(_db, _db.unpaidRecords);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$ProductionBatchesTableTableManager get productionBatches =>
      $$ProductionBatchesTableTableManager(_db, _db.productionBatches);
  $$ProfitRecordsTableTableManager get profitRecords =>
      $$ProfitRecordsTableTableManager(_db, _db.profitRecords);
}
