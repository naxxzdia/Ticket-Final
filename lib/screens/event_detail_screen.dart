import 'package:flutter/material.dart';
import '../models/event.dart';
import 'checkout/checkout_flow_screen.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});
  final Event event;

  String _formatDate(DateTime d) => "${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}";
  String _formatTime(DateTime d) => "${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.black,
                pinned: true,
                expandedHeight: 320,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'event-image-${event.id}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(event.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[800], child: const Icon(Icons.image_not_supported, color: Colors.white54))),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event.category, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '฿${event.price.toStringAsFixed(0)} / person',
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Flexible(
                                        child: Text(
                                          'Bills included',
                                          style: TextStyle(color: Colors.white54, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.event, color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_formatDate(event.date.toLocal())}  ${_formatTime(event.date.toLocal())}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(event.location, style: const TextStyle(color: Colors.white70))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Event Details', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        event.description.isNotEmpty ? event.description : 'No description provided.',
                        style: const TextStyle(color: Colors.white70, height: 1.4),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.grey[900]?.withOpacity(0.95),
                border: const Border(top: BorderSide(color: Colors.white12)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade400,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CheckoutFlowScreen(event: event),
                        ),
                      );
                    },
                    child: const Text('Buy Tickets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
