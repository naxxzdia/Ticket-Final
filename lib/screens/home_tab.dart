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
  bool _disposed = false; // defensive flag

  String? _selectedCategory; // null or 'All' means show everything

  final List<String> baseCategories = const [
    'Music Concert',
    'Sports',
    'Show',
  ];

  Future<(List<Event>, List<Event>, List<Event>)> _loadSections() async {
    // Wrap each call with timeout to avoid hanging spinner forever
    Future<List<Event>> safe(Future<List<Event>> f()) async {
      try {
        return await f().timeout(const Duration(seconds: 8));
      } catch (e) {
        // propagate the first error upward; handled in _refresh
        rethrow;
      }
    }
    final trending = await safe(_repo.fetchTrending);
    final upcoming = await safe(_repo.fetchUpcoming);
    final nearby = await safe(_repo.fetchNearby);
    return (trending, upcoming, nearby);
  }

  Future<void> _refresh() async {
    if (_disposed) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _loadSections();
      if (!_disposed) {
        setState(() { _cache = data; });
      }
    } catch (e) {
      if (!_disposed) {
        setState(() { _error = e; });
      }
    } finally {
      if (!_disposed) {
        setState(() { _loading = false; });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600, // Semi-Bold
                color: Color(0xFFFF4081), // pink accent
                letterSpacing: .4,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 2,
              width: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withOpacity(.30), // soft purple divider
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
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
                    // dark overlay card background for contrast
                    Container(color: const Color(0xFF2A2A2A).withOpacity(.25)),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF2A2A2A).withOpacity(.95),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: _eventCardTexts(e),
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

  Widget _eventCardTexts(Event e) {
    final date = e.date;
    final month = const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][date.month-1];
    final dateStr = '${date.day.toString().padLeft(2,'0')} $month ${date.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text('\$${e.price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFFFF4081), // pink accent price
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            )),
        const SizedBox(height: 4),
        Text(
          e.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dateStr,
          style: const TextStyle(
            color: Color(0xFFFF9AA2), // soft pink accent for subtitle
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: .2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _cache;
    final trending = data?.$1 ?? [];
    final upcoming = data?.$2 ?? [];
    final nearby = data?.$3 ?? [];
    const bg = Color(0xFF1A1A1A);
    return RefreshIndicator(
      onRefresh: _refresh,
      color: Colors.white,
      backgroundColor: bg,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: bg,
            pinned: true,
            elevation: 0,
            title: const Text(
              'Home',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white, // pure white
                letterSpacing: .4,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFFFF4081)), // pink accent
                onPressed: _refresh,
                tooltip: 'Refresh',
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
                                ? const LinearGradient(
                                    colors: [Color(0xFFFF9AA2), Color(0xFF673AB7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: selected ? null : const Color(0xFF2E2E2E),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: selected ? const Color(0xFF673AB7) : const Color(0xFF2E2E2E),
                              width: 1.2,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF673AB7).withOpacity(.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.music_note,
                                size: 16,
                                color: selected ? Colors.white : const Color(0xFFE0E0E0),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat,
                                style: TextStyle(
                                  color: selected ? Colors.white : const Color(0xFFE0E0E0),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                  letterSpacing: .3,
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
                    const Text('Failed to load events', style: TextStyle(color: Colors.white70)),
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
