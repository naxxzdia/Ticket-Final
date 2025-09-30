import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_repository.dart';
import '../services/api_client.dart';
import 'event_detail_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final EventRepository _repo = EventRepository(ApiClient());

  (List<Event>, List<Event>, List<Event>)? _cache;
  Object? _error;
  bool _loading = false;

  String? _selectedCategory; // null or 'All' means show everything

  final List<String> baseCategories = const [
    'Music Concert',
    'Sports',
    'Show',
  ];

  Future<(List<Event>, List<Event>, List<Event>)> _loadSections() async {
    final trending = await _repo.fetchTrending();
    final upcoming = await _repo.fetchUpcoming();
    final nearby = await _repo.fetchNearby();
    return (trending, upcoming, nearby);
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _loadSections();
      setState(() {
        _cache = data;
      });
    } catch (e) {
      setState(() {
        _error = e;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      );

  Widget _horizontalEvents(List<Event> events, {double height = 190}) {
    if (events.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
            child: Text('No events', style: TextStyle(color: Colors.white54))),
      );
    }
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final e = events[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(event: e),
                ),
              );
            },
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'event-image-${e.id}',
                      child: Image.network(e.imageUrl, fit: BoxFit.cover),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('฿${e.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            e.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _cache;
    final trending = data?.$1 ?? [];
    final upcoming = data?.$2 ?? [];
    final nearby = data?.$3 ?? [];
    return RefreshIndicator(
      onRefresh: _refresh,
      color: Colors.white,
      backgroundColor: Colors.black,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            pinned: true,
            title: const Text('Home', style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: _refresh,
              )
            ],
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              // Slightly taller to avoid glyph baseline clipping
              height: 56,
              child: Builder(
                builder: (context) {
                  // Build dynamic category list based on loaded events (union) + base + 'All'
                  final set = <String>{...baseCategories};
                  if (_cache != null) {
                    for (final e in [..._cache!.$1, ..._cache!.$2, ..._cache!.$3]) {
                      if (e.category.trim().isNotEmpty) set.add(e.category.trim());
                    }
                  }
                  final categories = ['All', ...set.toList()];
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final bool selected = (_selectedCategory == null && cat == 'All') || _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (cat == 'All') {
                              _selectedCategory = null;
                            } else if (_selectedCategory == cat) {
                              _selectedCategory = null; // toggle off
                            } else {
                              _selectedCategory = cat;
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? LinearGradient(colors: [
                                    Colors.greenAccent.shade400,
                                    Colors.greenAccent.shade200,
                                  ])
                                : null,
                            color: selected ? null : Colors.grey[900],
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: selected ? Colors.greenAccent.shade400 : Colors.grey[800]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.music_note, size: 16, color: selected ? Colors.black87 : Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                cat,
                                style: TextStyle(
                                  color: selected ? Colors.black : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2, // give extra line box space to avoid clipping
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                    const SizedBox(height: 12),
                    Text('Failed to load events', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(_error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    )
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(child: _sectionTitle('Trending Events')),
            SliverToBoxAdapter(child: _horizontalEvents(_filterByCategory(trending))),
            SliverToBoxAdapter(child: _sectionTitle('Upcoming Events')),
            SliverToBoxAdapter(child: _horizontalEvents(_filterByCategory(upcoming), height: 170)),
            SliverToBoxAdapter(child: _sectionTitle('Nearby Events')),
            SliverToBoxAdapter(child: _horizontalEvents(_filterByCategory(nearby), height: 170)),
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ]
        ],
      ),
    );
  }

  List<Event> _filterByCategory(List<Event> list) {
    if (_selectedCategory == null) return list;
    final sel = _selectedCategory!.toLowerCase();
    return list.where((e) => e.category.toLowerCase() == sel).toList();
  }
}
