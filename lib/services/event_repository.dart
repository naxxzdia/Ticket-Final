import '../models/event.dart';
import 'api_client.dart';

class EventRepository {
  final ApiClient api;
  EventRepository(this.api);

  Future<List<Event>> fetchTrending() async {
    // json-server collection: trendingEvents
    final list = await api.getJsonList('/trendingEvents');
    return list.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Event>> fetchUpcoming() async {
    // json-server collection: upcomingEvents
    final list = await api.getJsonList('/upcomingEvents');
    return list.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Event>> fetchNearby({double? lat, double? lng}) async {
    final params = <String, String>{};
    if (lat != null && lng != null) {
      params['lat'] = lat.toString();
      params['lng'] = lng.toString();
    }
    // json-server collection: nearbyEvents (ignores lat/lng for now)
    final list = await api.getJsonList('/nearbyEvents', query: params.isEmpty ? null : params);
    return list.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }
}
