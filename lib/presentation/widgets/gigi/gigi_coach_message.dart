import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/clean_theme.dart';

enum GigiEmotion { happy, expert, motivational, celebrating }

class GigiCoachMessage extends StatefulWidget {
  final String messageId;
  final String message;
  final String? title;
  final GigiEmotion emotion;
  final Widget? action;
  final bool isCompact;
  final bool defaultExpanded;
  final bool persistCollapse;

  const GigiCoachMessage({
    super.key,
    required this.messageId,
    required this.message,
    this.title,
    this.emotion = GigiEmotion.happy,
    this.action,
    this.isCompact = false,
    this.defaultExpanded = true,
    this.persistCollapse = true,
  });

  @override
  State<GigiCoachMessage> createState() => _GigiCoachMessageState();
}

class _GigiCoachMessageState extends State<GigiCoachMessage> {
  static const _prefPrefix = 'gigi_message_seen_v1::';

  bool _isExpanded = true;
  bool _isReady = false;
  bool _hasMarkedSeen = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    if (!widget.persistCollapse) {
      if (!mounted) return;
      setState(() {
        _isExpanded = widget.defaultExpanded;
        _isReady = true;
      });
      _markSeenIfNeeded();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_storageKey) ?? false;

    if (!mounted) return;

    setState(() {
      _isExpanded = hasSeen ? false : widget.defaultExpanded;
      _isReady = true;
    });

    _markSeenIfNeeded();
  }

  String get _storageKey => '$_prefPrefix${widget.messageId}';

  Future<void> _markSeenIfNeeded() async {
    if (_hasMarkedSeen || !_isExpanded) return;
    _hasMarkedSeen = true;

    if (widget.persistCollapse) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageKey, true);
    }
  }

  Future<void> _setExpanded(bool value) async {
    if (!mounted) return;
    setState(() => _isExpanded = value);
    if (value) {
      await _markSeenIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return _buildShell(
        child: const SizedBox(
          height: 64,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CleanTheme.primaryColor,
            ),
          ),
        ),
      );
    }

    return _buildShell(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _isExpanded ? _buildExpanded(context) : _buildCollapsed(context),
      ),
    );
  }

  Widget _buildShell({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CleanTheme.borderSecondary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey('expanded'),
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 360;

        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGigiAvatar(),
                  const SizedBox(width: 12),
                  Expanded(child: _buildHeader(showCollapse: true)),
                ],
              ),
              const SizedBox(height: 12),
              _buildMessageBody(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGigiAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(showCollapse: true),
                  const SizedBox(height: 8),
                  _buildMessageBody(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    return Align(
      key: const ValueKey('collapsed'),
      alignment: Alignment.centerRight,
      child: _buildInfoButton(
        icon: Icons.info_outline,
        label: 'Info',
        onPressed: () => _setExpanded(true),
      ),
    );
  }

  Widget _buildGigiAvatar({bool collapsed = false}) {
    final size = collapsed ? 40.0 : (widget.isCompact ? 48.0 : 60.0);

    return Container(
      key: const ValueKey('collapsed'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: CleanTheme.primaryColor.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset('assets/images/gigi_trainer.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildHeader({required bool showCollapse}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'GIGI',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: CleanTheme.primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _getEmotionIcon(),
                    size: 14,
                    color: CleanTheme.primaryColor,
                  ),
                ],
              ),
              if (widget.title != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.title!,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showCollapse)
          _buildInfoButton(
            icon: Icons.keyboard_arrow_up_rounded,
            label: 'Chiudi',
            onPressed: () => _setExpanded(false),
          ),
      ],
    );
  }

  Widget _buildMessageBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.message,
          style: GoogleFonts.inter(
            fontSize: widget.isCompact ? 14 : 15,
            color: CleanTheme.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
          softWrap: true,
        ),
        if (widget.action != null) ...[
          const SizedBox(height: 12),
          widget.action!,
        ],
      ],
    );
  }

  Widget _buildInfoButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: CleanTheme.primaryColor,
        backgroundColor: CleanTheme.primaryColor.withValues(alpha: 0.08),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  IconData _getEmotionIcon() {
    switch (widget.emotion) {
      case GigiEmotion.happy:
        return Icons.sentiment_satisfied_alt;
      case GigiEmotion.expert:
        return Icons.auto_awesome;
      case GigiEmotion.motivational:
        return Icons.bolt;
      case GigiEmotion.celebrating:
        return Icons.celebration;
    }
  }
}
