import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/purchased_ticket.dart';

class TicketStorage {
  static const _key = 'purchased_tickets';
  static final TicketStorage instance = TicketStorage._();
  TicketStorage._();

  final _uuid = const Uuid();
  List<PurchasedTicket> _cache = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? '';
    _cache = PurchasedTicket.decodeList(raw);
    _cache = _refreshPassed(_cache);
    _loaded = true;
  }

  List<PurchasedTicket> _refreshPassed(List<PurchasedTicket> list) {
    final now = DateTime.now();
    return list
        .map((t) => t.eventDate.isBefore(now) && !t.passed ? t.copyWith(passed: true) : t)
        .toList(growable: false);
  }

  Future<List<PurchasedTicket>> loadAll() async {
    await _ensureLoaded();
    return List.unmodifiable(_cache);
  }

  Future<PurchasedTicket> add({
    required String eventId,
    required String title,
    required String imageUrl,
    required String location,
    required DateTime eventDate,
    required String zoneCode,
    required String zoneLabel,
    required double unitPrice,
    required int quantity,
    required String orderId,
  }) async {
    await _ensureLoaded();
    final ticket = PurchasedTicket(
      id: _uuid.v4(),
      eventId: eventId,
      title: title,
      imageUrl: imageUrl,
      location: location,
      eventDate: eventDate,
      zoneCode: zoneCode,
      zoneLabel: zoneLabel,
      unitPrice: unitPrice,
      quantity: quantity,
      total: unitPrice * quantity,
      orderId: orderId,
      purchasedAt: DateTime.now(),
      passed: false,
    );
    _cache = [..._cache, ticket];
    await _persist();
    return ticket;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, PurchasedTicket.encodeList(_cache));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _cache = [];
    _loaded = true;
  }

  Future<bool> remove(String id) async {
    await _ensureLoaded();
    final before = _cache.length;
    _cache = _cache.where((t) => t.id != id).toList(growable: false);
    if (_cache.length != before) {
      await _persist();
      return true;
    }
    return false;
  }

  Future<int> removeMany(Iterable<String> ids) async {
    await _ensureLoaded();
    final idSet = ids.toSet();
    final before = _cache.length;
    _cache = _cache.where((t) => !idSet.contains(t.id)).toList(growable: false);
    if (_cache.length != before) {
      await _persist();
    }
    return before - _cache.length;
  }
}
