import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const AlphaSurfaceFixture());

class AlphaSurfaceFixture extends StatelessWidget {
  const AlphaSurfaceFixture({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.transparent),
      home: const AlphaSurfacePage(),
    );
  }
}

class AlphaSurfacePage extends StatefulWidget {
  const AlphaSurfacePage({super.key});

  @override
  State<AlphaSurfacePage> createState() => _AlphaSurfacePageState();
}

class _AlphaSurfacePageState extends State<AlphaSurfacePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);
  double _backgroundAlpha = 0;

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int alpha = (_backgroundAlpha * 255).round().clamp(0, 255);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: const Color(0xff23466e).withAlpha(alpha)),
          Center(
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Opaque Flutter text / transparent background',
                        style: TextStyle(color: Colors.black, fontSize: 22)),
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (_, __) => Transform.rotate(
                        angle: _animation.value * math.pi / 18,
                        child: const Icon(Icons.auto_awesome,
                            color: Colors.black, size: 32),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: Slider(
                        min: 0,
                        max: 1,
                        divisions: 4,
                        value: _backgroundAlpha,
                        onChanged: (value) =>
                            setState(() => _backgroundAlpha = value),
                      ),
                    ),
                    Text('background ${(100 * _backgroundAlpha).round()}%'),
                    const SizedBox(height: 8),
                    const SizedBox(
                      width: 260,
                      child: TextField(decoration: InputDecoration(
                        labelText: 'Keyboard / IME probe',
                        border: OutlineInputBorder(),
                      )),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Pointer / focus probe'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
