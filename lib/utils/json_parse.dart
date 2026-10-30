import 'dart:convert';

/// Tolerant JSON readers.
///
/// Laravel/MySQL can send the same field as an int, a double, a numeric
/// string ("2000000.00"), or a 0/1 for booleans depending on column type
/// and model casts. Reading with `map['x'] ?? ''` into a typed field then
/// crashes with "type 'int' is not a subtype of type 'String'". These
/// helpers accept any of those shapes.

String asString(dynamic v, [String fallback = '']) =>
    v == null ? fallback : v.toString();

String? asStringOrNull(dynamic v) => v?.toString();

int asInt(dynamic v, [int fallback = 0]) => asIntOrNull(v) ?? fallback;

int? asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v.toString();
  return int.tryParse(s) ?? double.tryParse(s)?.toInt();
}

double asDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

bool asBool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return fallback;
}

/// Accepts a JSON list, or a JSON-encoded string of a list.
List<String> asStringList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.where((e) => e != null).map((e) => e.toString()).toList();
  if (v is String && v.trim().startsWith('[')) {
    try {
      final decoded = json.decode(v);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}
  }
  return [];
}
