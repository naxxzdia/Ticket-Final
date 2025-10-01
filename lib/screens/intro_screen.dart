import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'signup_screen.dart';

class OnboardingPageData {
  final String title;
  final String body;
  final String asset;
  final List<Color> ringGradient;
  const OnboardingPageData({
    required this.title,
    required this.body,
    required this.asset,
    required this.ringGradient,
  });
}

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  final _controller = PageController();
  int _index = 0;
  final List<String> _backgrounds = const [
    'assets/images/page1.jpg',
    'assets/images/page2.jpg',
    'assets/images/page3.jpg',
  ];

  final List<OnboardingPageData> _pages = const [
    OnboardingPageData(
      title: 'Discover Events',
      body: 'Explore curated experiences tailored for you. Music, art, culture — all in one place.',
      asset: 'assets/images/front.jpg',
      ringGradient: [Color(0xFFFFD1DC), Color(0xFFE75480), Color(0xFF673AB7)],
    ),
    OnboardingPageData(
      title: 'Seamless Booking',
      body: 'Secure your spot in seconds with a smooth ticket purchasing flow and instant confirmation.',
      asset: 'assets/images/sakamoto2.jpg',
      ringGradient: [Color(0xFFE75480), Color(0xFF673AB7), Color(0xFF311B92)],
    ),
    OnboardingPageData(
      title: 'Your Digital Pass',
      body: 'Store and access your e‑tickets anytime. No paper. No hassle. Just enjoy.',
      asset: 'assets/images/sakamoto3.jpg',
      ringGradient: [Color(0xFF673AB7), Color(0xFFE75480), Color(0xFFFFD1DC)],
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ON_BOARDING', false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    final bg = _backgrounds[(_index.clamp(0, _backgrounds.length - 1))];
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              bg,
              fit: BoxFit.cover,
            ),
          ),
          // dark gradient overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.65),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // top bar (back / skip)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      if (_index > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white70),
                          onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic),
                        )
                      else
                        const SizedBox(width: 48),
                      const Spacer(),
                      if (_index < _pages.length - 1)
                        TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(foregroundColor: Colors.white70),
                          child: const Text('Skip', style: TextStyle(fontSize: 14)),
                        )
                      else
                        const SizedBox(width: 64),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (_, i) => _OnboardSlide(data: _pages[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (c, anim) => FadeTransition(opacity: anim, child: c),
                        child: Text(
                          page.title,
                          key: ValueKey(page.title),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: Text(
                          page.body,
                          key: ValueKey(page.body),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _DotsIndicator(length: _pages.length, index: _index),
                const SizedBox(height: 28),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: _GradientButton(
                      label: _index == _pages.length - 1 ? 'Get Started' : 'Next',
                      onTap: () {
                        if (_index == _pages.length - 1) {
                          _finish();
                        } else {
                          _controller.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardSlide extends StatelessWidget {
  final OnboardingPageData data;
  const _OnboardSlide({required this.data});
  @override
  Widget build(BuildContext context) {
    // Center text overlay removed; just spacer area so PageView keeps height
    return const SizedBox.shrink();
  }
}

class _DotsIndicator extends StatelessWidget {
  final int length;
  final int index;
  const _DotsIndicator({required this.length, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            height: 10,
            width: active ? 34 : 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: active
                  ? const LinearGradient(
                      colors: [
                        Color(0xFFFFD1DC),
                        Color(0xFFE75480),
                        Color(0xFF673AB7),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: active ? null : Colors.white12,
            ));
      }),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD1DC),
              Color(0xFFE75480),
              Color(0xFF673AB7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}