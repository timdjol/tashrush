import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../game/block_rush_game.dart';
import '../../game/pieces/piece.dart';
import '../../localization/app_localizations.dart';
import '../../models/game_models.dart';
import '../../services/ad_service.dart';
import '../../utils/game_constants.dart';
import '../../widgets/rush_card.dart';
import 'drag_placement_mapper.dart';
import 'game_controller.dart';
import 'piece_preview.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final _boardKey = GlobalKey();
  late GameController controller;
  late BlockRushGame game;
  bool _ready = false;
  Timer? _comboTimer;
  bool _showCombo = false;
  int _lastComboEffectScore = -1;
  bool _pausedByLifecycle = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    final services = AppServices.of(context);
    final dailyMode = ModalRoute.of(context)?.settings.arguments == true;
    controller = GameController(
      storage: services.storage,
      analytics: services.analytics,
      achievements: services.achievements,
      leaderboard: services.leaderboard,
      dailyService: services.daily,
      dailyMode: dailyMode,
    )..addListener(_onChanged);
    game = BlockRushGame(controller.session);
    WidgetsBinding.instance.addObserver(this);
    unawaited(controller.start());
    _ready = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInitialDialogs());
  }

  void _onChanged() {
    game.refresh(controller.session);
    final stats = controller.session.stats;
    if (controller.lastClear.lines > 0 &&
        stats.combo > 1 &&
        stats.score != _lastComboEffectScore) {
      _lastComboEffectScore = stats.score;
      _comboTimer?.cancel();
      _showCombo = true;
      _comboTimer = Timer(const Duration(milliseconds: 950), () {
        if (mounted) setState(() => _showCombo = false);
      });
    }
    if (mounted) setState(() {});
  }

  Future<void> _showInitialDialogs() async {
    if (!mounted || !_ready) return;
    final storage = AppServices.of(context).storage;
    if (!storage.getBool('tutorialSeen')) {
      controller.pause();
      game.pauseEngine();
      final l10n = AppLocalizations.of(context)!;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(l10n.tutorialTitle, textAlign: TextAlign.center),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _TutorialStep(
                icon: Icons.touch_app_rounded, text: l10n.tutorialDrag),
            _TutorialStep(
                icon: Icons.auto_awesome_rounded, text: l10n.tutorialClear),
            _TutorialStep(
                icon: Icons.ac_unit_rounded, text: l10n.tutorialSpecials),
          ]),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.tutorialStart),
            ),
          ],
        ),
      );
      await storage.setBool('tutorialSeen', true);
      if (!mounted) return;
      controller.resume();
      game.resumeEngine();
    }
    if (controller.session.isGameOver && mounted) await _showGameOver();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _comboTimer?.cancel();
    if (_ready) unawaited(controller.finish());
    controller.removeListener(_onChanged);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ready) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      if (!controller.paused) {
        _pausedByLifecycle = true;
        controller.pause();
        game.pauseEngine();
      }
      unawaited(controller.persist());
    } else if (state == AppLifecycleState.resumed && _pausedByLifecycle) {
      _pausedByLifecycle = false;
      controller.resume();
      game.resumeEngine();
    }
  }

  GridPoint? _originFromFeedback(Offset feedbackTopLeft, Piece piece) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final feedbackCenter = feedbackTopLeft +
        Offset(
          piece.width * _DraggablePiece.feedbackCellSize / 2,
          piece.height * _DraggablePiece.feedbackCellSize / 2,
        );
    final local = box.globalToLocal(feedbackCenter);
    return DragPlacementMapper.originForCenter(
      localCenter: local,
      boardSide: box.size.width,
      piece: piece,
    );
  }

  void _dragMove(DragTargetDetails<int> details) {
    if (details.data < 0 || details.data >= controller.session.pieces.length) {
      return;
    }
    final piece = controller.session.pieces[details.data];
    final origin = _originFromFeedback(details.offset, piece);
    if (origin != null) game.preview(piece, origin);
  }

  Future<void> _accept(DragTargetDetails<int> details) async {
    if (details.data < 0 || details.data >= controller.session.pieces.length) {
      return;
    }
    final piece = controller.session.pieces[details.data];
    final origin = _originFromFeedback(details.offset, piece);
    game.preview(null, null);
    if (origin == null) return;
    final services = AppServices.of(context);
    final placed =
        await controller.place(details.data, origin.row, origin.column);
    if (placed) {
      await services.audio.play('place');
      final clear = controller.lastClear;
      if (clear.lines > 0 || clear.bombsTriggered > 0) {
        game.playClearEffect(clear);
        await services.audio
            .play(clear.bombsTriggered > 0 ? 'explosion' : 'clear');
      }
      if (clear.goldDestroyed > 0) {
        await services.audio.play('gold');
      }
      if (clear.bombsTriggered > 0) {
        await services.haptics.strong();
      } else if (controller.session.stats.combo > 0) {
        if (controller.session.stats.combo > 1) {
          await services.audio.play('combo');
        }
        await services.haptics.medium();
      } else {
        await services.haptics.light();
      }
      if (controller.session.isGameOver && mounted) {
        await services.haptics.strong();
        await _showGameOver();
      }
    }
  }

  Future<void> _showGameOver() async {
    controller.pause();
    game.pauseEngine();
    final l10n = AppLocalizations.of(context)!;
    final services = AppServices.of(context);
    final stats = controller.session.stats;
    await services.audio.play('game_over');
    if (!mounted) return;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(l10n.gameOver, textAlign: TextAlign.center),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${stats.score}',
                style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: RushPalette.violet)),
            Text(
                '${l10n.best}: ${stats.score > controller.bestScore ? stats.score : controller.bestScore}'),
            Text('${l10n.lines}: ${stats.lines}'),
            Text('${l10n.highestCombo}: ×${stats.highestCombo}'),
            Text(
                '${l10n.time}: ${controller.session.duration.inMinutes}:${(controller.session.duration.inSeconds % 60).toString().padLeft(2, '0')}'),
          ]),
          actions: [
            if (!controller.session.continueUsed)
              ValueListenableBuilder<RewardedAdState>(
                valueListenable: services.ads.rewardedState,
                builder: (context, state, _) => TextButton(
                  onPressed: switch (state) {
                    RewardedAdState.ready => () =>
                        Navigator.pop(context, 'continue'),
                    RewardedAdState.unavailable => services.ads.retryRewarded,
                    RewardedAdState.loading => null,
                  },
                  child: Text(switch (state) {
                    RewardedAdState.ready => l10n.continueLabel,
                    RewardedAdState.loading => l10n.adLoading,
                    RewardedAdState.unavailable => l10n.retryAd,
                  }),
                ),
              ),
            TextButton(
                onPressed: () => Navigator.pop(context, 'restart'),
                child: Text(l10n.restart)),
            TextButton(
                onPressed: () => Navigator.pop(context, 'home'),
                child: Text(l10n.home)),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'continue') {
      final rewarded = await services.ads.showRewarded();
      if (rewarded) {
        await controller.continueAfterReward();
        controller.resume();
        game.resumeEngine();
        _onChanged();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adNotReady)),
        );
        await _showGameOver();
      }
    } else if (action == 'restart') {
      await controller.finish();
      final games = services.storage.getInt('totalGames');
      if (games > 0 && games % GameConstants.interstitialEveryGames == 0) {
        await services.ads.showInterstitial();
      }
      controller.restart();
      game.resumeEngine();
    } else if (action == 'home' && mounted) {
      await controller.finish();
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _pause() async {
    controller.pause();
    game.pauseEngine();
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l10n.pause, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          FilledButton(
              onPressed: () => Navigator.pop(context, 'resume'),
              child: Text(l10n.resume)),
          TextButton(
              onPressed: () => Navigator.pop(context, 'restart'),
              child: Text(l10n.restart)),
          TextButton(
              onPressed: () => Navigator.pop(context, 'settings'),
              child: Text(l10n.settings)),
          TextButton(
              onPressed: () => Navigator.pop(context, 'home'),
              child: Text(l10n.home)),
        ]),
      ),
    );
    if (!mounted) return;
    if (action == 'settings') {
      await Navigator.pushNamed(context, '/settings');
      if (!mounted) return;
      controller.resume();
      game.resumeEngine();
      return;
    }
    if (action == 'restart') {
      await controller.finish();
      controller.restart();
      game.resumeEngine();
      return;
    }
    if (action == 'home') {
      await controller.finish();
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }
    controller.resume();
    game.resumeEngine();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final stats = controller.session.stats;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: _Stat(
                      label: l10n.best, value: '${controller.bestScore}')),
              Expanded(
                  child: _Stat(label: l10n.score, value: '${stats.score}')),
              Expanded(
                  child: _Stat(
                      label: l10n.combo,
                      value: stats.combo == 0 ? '—' : '×${stats.combo}')),
              IconButton.filledTonal(
                  onPressed: _pause, icon: const Icon(Icons.pause_rounded)),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: DragTarget<int>(
                          key: _boardKey,
                          onMove: _dragMove,
                          onLeave: (_) => game.preview(null, null),
                          onAcceptWithDetails: _accept,
                          builder: (context, _, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: GameWidget(key: ValueKey(game), game: game),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 220),
                          scale: _showCombo ? 1 : .72,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: _showCombo ? 1 : 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: RushPalette.ink.withAlpha(218),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: RushPalette.gold, width: 2),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                child: Text(
                                  '${l10n.combo} ×${stats.combo}',
                                  style: const TextStyle(
                                    color: RushPalette.gold,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: RushCard(
                key: ValueKey(controller.session.pieces
                    .map((piece) => piece.id)
                    .join('|')),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var index = 0;
                          index < controller.session.pieces.length;
                          index++)
                        _DraggablePiece(
                            index: index,
                            piece: controller.session.pieces[index]),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DraggablePiece extends StatelessWidget {
  const _DraggablePiece({required this.index, required this.piece});
  static const feedbackCellSize = 30.0;
  static const _touchTargetSize = 88.0;
  static const _fingerLift = 64.0;

  final int index;
  final Piece piece;

  @override
  Widget build(BuildContext context) => Draggable<int>(
        data: index,
        maxSimultaneousDrags: 1,
        rootOverlay: true,
        dragAnchorStrategy: (_, __, ___) => Offset(
          piece.width * feedbackCellSize / 2,
          piece.height * feedbackCellSize / 2 + _fingerLift,
        ),
        feedback: Material(
            color: Colors.transparent,
            child: PiecePreview(piece: piece, cellSize: feedbackCellSize)),
        childWhenDragging: SizedBox.square(
          dimension: _touchTargetSize,
          child: Center(
            child: Opacity(opacity: .22, child: PiecePreview(piece: piece)),
          ),
        ),
        child: SizedBox.square(
          dimension: _touchTargetSize,
          child: Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 160),
              scale: 1,
              child: PiecePreview(piece: piece),
            ),
          ),
        ),
      );
}

class _TutorialStep extends StatelessWidget {
  const _TutorialStep({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: RushPalette.sand,
            foregroundColor: RushPalette.coral,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ]),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: Text(value,
              key: ValueKey(value),
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        ),
      ]);
}
