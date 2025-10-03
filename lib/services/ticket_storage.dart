import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/purchased_ticket.dart';

class TicketStorage {
  static const _legacyKey = 'purchased_tickets'; // old global key
  static final TicketStorage instance = TicketStorage._();
  TicketStorage._();

  final _uuid = const Uuid();
  List<PurchasedTicket> _cache = [];
  bool _loaded = false;
  String? _loadedUid; // which user the cache belongs to

  String _keyFor(String uid) => 'purchased_tickets_$uid';

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _ensureLoaded() async {
    final uid = _currentUid;
    if (uid == null) {
      // no user => treat as empty
      _cache = [];
      _loaded = true;
      _loadedUid = null;
      return;
    }
    if (_loaded && _loadedUid == uid) return; // already loaded for this user

    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(uid);

    // Migration: if per-user key absent but legacy exists, migrate and clear legacy
    if (!prefs.containsKey(key) && prefs.containsKey(_legacyKey)) {
      final legacyRaw = prefs.getString(_legacyKey) ?? '';
      final list = PurchasedTicket.decodeList(legacyRaw);
      await prefs.setString(key, PurchasedTicket.encodeList(list));
      // Optionally keep legacy for other (unlikely) guest context. We remove to avoid duplication.
      await prefs.remove(_legacyKey);
    }

    final raw = prefs.getString(key) ?? '';
    _cache = PurchasedTicket.decodeList(raw);
    _cache = _refreshPassed(_cache);
    _loaded = true;
    _loadedUid = uid;
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
    final uid = _currentUid;
    if (uid == null) return; // nothing to persist without user context
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(uid), PurchasedTicket.encodeList(_cache));
  }

  Future<void> clearAll() async {
    final uid = _currentUid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(uid));
    _cache = [];
    _loaded = true;
    _loadedUid = uid;
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

  /// Clear in-memory cache only (called after signOut so next user doesn't see previous tickets)
  void resetMemory() {
    _cache = [];
    _loaded = false;
    _loadedUid = null;
  }
}
