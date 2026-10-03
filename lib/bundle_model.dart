import 'dart:convert';
import 'id_generator.dart';

class BundleItem {
  final String title;
  final int seconds;
  final bool startsNext;

  const BundleItem({
    required this.title,
    required this.seconds,
    this.startsNext = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'seconds': seconds,
      'startsNext': startsNext,
    };
  }

  factory BundleItem.fromMap(Map<String, dynamic> map) {
    final seconds = map['seconds'] as int;
    if (seconds <= 0) {
      throw const FormatException('A bundle timer needs a time above zero');
    }
    return BundleItem(
      title: map['title'] as String,
      seconds: seconds,
      startsNext: map['startsNext'] as bool? ?? false,
    );
  }
}

class Bundle {
  final int id;
  String name;
  List<BundleItem> items;

  Bundle({int? id, required this.name, required this.items})
      : id = id ?? newId();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  factory Bundle.fromMap(Map<String, dynamic> map) {
    final items = (map['items'] as List)
        .map((item) => BundleItem.fromMap(item as Map<String, dynamic>))
        .toList();
    if (items.isEmpty) {
      throw const FormatException('A bundle needs at least one timer');
    }
    return Bundle(
      id: map['id'] as int?,
      name: map['name'] as String,
      items: items,
    );
  }

  static String listToJson(List<Bundle> bundles) {
    return jsonEncode(bundles.map((bundle) => bundle.toMap()).toList());
  }

  static List<Bundle> listFromJson(String json) {
    final List<dynamic> decoded;
    try {
      decoded = jsonDecode(json) as List<dynamic>;
    } catch (_) {
      return [];
    }

    final bundles = <Bundle>[];
    for (final item in decoded) {
      try {
        bundles.add(Bundle.fromMap(item as Map<String, dynamic>));
      } catch (_) {
        continue;
      }
    }
    return bundles;
  }
}
