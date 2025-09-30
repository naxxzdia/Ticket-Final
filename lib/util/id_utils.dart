/// Utility helpers for generating lightweight ids / references used across
/// checkout, storage, and ticket display.

String generateOrderId(String eventId) {
  final seed = eventId.hashCode & 0xFFFFFF; // 6 hex chars
  return 'EVT${seed.toRadixString(16).padLeft(6,'0').toUpperCase()}';
}
