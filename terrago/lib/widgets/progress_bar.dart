import 'package:flutter/material.dart';

class VineImageProgress extends StatefulWidget {
  final String assetPath; // e.g. assets/ui/vine_bar.png
  final double progress; // 0..1
  final double height; // widget height
  final Duration animationDuration;
  final List<double> milestones; // fractions along width (0..1)
  final double milestoneYOffset; // fraction of height for dot center
  final double milestoneSize; // overlay size for glow/check
  final Color glowColor; // yellow glow
  final bool pulseOnReach;

  const VineImageProgress({
    super.key,
    required this.assetPath,
    this.progress = 0.0,
    this.height = 80,
    this.animationDuration = const Duration(milliseconds: 700),
    this.milestones = const [0.0, 0.25, 0.50, 0.75, 1.0],
    this.milestoneYOffset = 0.38,
    this.milestoneSize = 32,
    this.glowColor = const Color(0xFFF7C948),
    this.pulseOnReach = true,
  });

  @override
  State<VineImageProgress> createState() => _VineImageProgressState();
}

class _VineImageProgressState extends State<VineImageProgress>
    with TickerProviderStateMixin {
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;
  double _current = 0;

  late AnimationController _pulseCtrl;
  int? _pulsingIndex;
  late List<bool> _reached;

  // 100% desaturation to make the base vine grey
  static const List<double> _greyMatrix = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  @override
  void initState() {
    super.initState();
    _reached = List<bool>.filled(widget.milestones.length, false);

    _progressCtrl = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _progressAnim = Tween<double>(begin: 0, end: widget.progress).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() => _current = _progressAnim.value);
        _checkMilestonesDuringAnimation();
      });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    if (widget.progress > 0) _progressCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant VineImageProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress ||
        oldWidget.animationDuration != widget.animationDuration) {
      _animateTo(widget.progress);
    }
  }

  void _animateTo(double target) {
    _progressCtrl.duration = widget.animationDuration;
    _progressAnim = Tween<double>(begin: _current, end: target.clamp(0.0, 1.0))
        .animate(
            CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() => _current = _progressAnim.value);
        _checkMilestonesDuringAnimation();
      });
    _progressCtrl
      ..reset()
      ..forward();
  }

  void _checkMilestonesDuringAnimation() {
    int newly = -1;
    for (int i = 0; i < widget.milestones.length; i++) {
      final m = widget.milestones[i].clamp(0.0, 1.0);
      if (_current + 1e-6 >= m && !_reached[i]) newly = i;
    }
    if (newly >= 0) {
      _reached[newly] = true;
      if (widget.pulseOnReach) {
        _pulsingIndex = newly;
        _pulseCtrl
          ..reset()
          ..forward();
      }
    }
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final width = cons.maxWidth;

      return SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1) GREY BASE (whole image)
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(_greyMatrix),
              child: Image.asset(
                widget.assetPath,
                fit: BoxFit.cover,
              ),
            ),

            // 2) COLORED REVEAL (clip left->right by progress)
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: _current.clamp(0.0, 1.0),
                child: Image.asset(widget.assetPath, fit: BoxFit.cover),
              ),
            ),

            // 3) GLOWS + CHECKS on milestones
            ..._milestoneOverlays(width),
          ],
        ),
      );
    });
  }

  List<Widget> _milestoneOverlays(double width) {
    final y = widget.height * widget.milestoneYOffset;
    return List<Widget>.generate(widget.milestones.length, (i) {
      final frac = widget.milestones[i].clamp(0.0, 1.0);
      final x = width * frac - widget.milestoneSize / 2;
      final reached = _current + 1e-6 >= frac;
      final pulsing = _pulsingIndex == i;

      final Animation<double> scale = pulsing
          ? Tween<double>(begin: 1.0, end: 1.12).animate(
              CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOutBack))
          : const AlwaysStoppedAnimation(1.0);

      return Stack(children: [
        // GLOW halo
        Positioned(
          left: x,
          top: y - widget.milestoneSize / 2,
          child: AnimatedOpacity(
            opacity: reached ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: AnimatedBuilder(
              animation: scale,
              builder: (_, child) =>
                  Transform.scale(scale: scale.value, child: child),
              child: Container(
                width: widget.milestoneSize,
                height: widget.milestoneSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // transparent center but glowing outside
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: widget.glowColor.withOpacity(0.65),
                      blurRadius: widget.milestoneSize * 0.9,
                      spreadRadius: widget.milestoneSize * 0.15,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Checkmark
        Positioned(
          left: x,
          top: y - widget.milestoneSize / 2,
          child: AnimatedOpacity(
            opacity: reached ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: SizedBox(
              width: widget.milestoneSize,
              height: widget.milestoneSize,
              child: const Center(
                child: Icon(Icons.check_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ]);
    });
  }
}
