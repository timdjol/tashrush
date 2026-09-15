import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../game/block_rush_game.dart';
import '../../game/pieces/piece.dart';
import '../../localization/app_localizations.dart';
import '../../models/game_models.dart';
import '../../services/ad_service.dart';
import '../../services/booster_service.dart';
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

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _boardKey = GlobalKey();
  late GameController controller;
  late BlockRushGame game;
  bool _ready = false;
  Timer? _comboTimer;
  Timer? _hintTimer;
  late final AnimationController _invalidDropController;
  bool _showCombo = false;
  int _lastComboEffectScore = -1;
  bool _pausedByLifecycle = false;
  bool _hammerMode = false;

  @override
  void initState() {
    super.initState();
    _invalidDropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

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
      boosters: services.boosters,
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
    if (mounted && !controller.session.isGameOver) _scheduleHint();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _comboTimer?.cancel();
    _hintTimer?.cancel();
    _invalidDropController.dispose();
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
      _scheduleHint();
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
    _hintTimer?.cancel();
    if (details.data < 0 || details.data >= controller.session.pieces.length) {
      return;
    }
    final piece = controller.session.pieces[details.data];
    final origin = _originFromFeedback(details.offset, piece);
    if (origin != null) game.preview(piece, origin);
  }

  Future<void> _accept(DragTargetDetails<int> details) async {
    _hintTimer?.cancel();
    if (details.data < 0 || details.data >= controller.session.pieces.length) {
      return;
    }
    final piece = controller.session.pieces[details.data];
    final origin = _originFromFeedback(details.offset, piece);
    game.preview(null, null);
    if (origin == null) {
      _showInvalidDrop();
      return;
    }
    final services = AppServices.of(context);
    final placed =
        await controller.place(details.data, origin.row, origin.column);
    if (placed) {
      await services.audio.play('place');
      final clear = controller.lastClear;
      if (clear.lines > 0 || clear.bombsTriggered > 0) {
        game.playClearEffect(clear);
        if (clear.bombsTriggered > 0) {
          unawaited(services.audio.duckFor(const Duration(milliseconds: 900)));
        }
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
      _scheduleHint();
    } else {
      _showInvalidDrop();
    }
  }

  void _showInvalidDrop() {
    game.preview(null, null);
    _invalidDropController.forward(from: 0);
    unawaited(AppServices.of(context).haptics.light());
    _scheduleHint();
  }

  void _scheduleHint() {
    _hintTimer?.cancel();
    if (!_ready || controller.paused || controller.session.isGameOver) return;
    _hintTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted || controller.paused) return;
      final hint = controller.findPlacementHint();
      if (hint != null) {
        game.preview(hint.piece, hint.origin, isHint: true);
      }
    });
  }

  void _dragStarted() {
    if (_hammerMode) setState(() => _hammerMode = false);
    _hintTimer?.cancel();
    game.preview(null, null);
  }

  void _dragEnded(DraggableDetails details) {
    if (!details.wasAccepted) _showInvalidDrop();
    _scheduleHint();
  }

  Future<void> _useBooster(BoosterType type) async {
    final services = AppServices.of(context);
    if (type == BoosterType.hammer) {
      if (!services.boosters.canAfford(type)) {
        _showBoosterMessage(false);
        return;
      }
      setState(() => _hammerMode = !_hammerMode);
      game.preview(null, null);
      return;
    }
    final success = type == BoosterType.singleCell
        ? await controller.useSingleCellBooster()
        : await controller.useShuffleBooster();
    if (!mounted) return;
    if (success) services.progression.refresh();
    _showBoosterMessage(success);
  }

  Future<void> _hammerTap(TapUpDetails details) async {
    if (!_hammerMode) return;
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    final cell = box.size.width / GameConstants.boardSize;
    final row = (local.dy / cell).floor();
    final column = (local.dx / cell).floor();
    final success = await controller.useHammerBooster(row, column);
    if (!mounted) return;
    if (success) {
      _hammerMode = false;
      AppServices.of(context).progression.refresh();
      await AppServices.of(context).haptics.medium();
    }
    _showBoosterMessage(success);
  }

  void _showBoosterMessage(bool success) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? l10n.boosterUsed : l10n.notEnoughCoins)),
    );
  }

  Future<void> _showGameOver() async {
    controller.pause();
    game.pauseEngine();
    final l10n = AppLocalizations.of(context)!;
    final services = AppServices.of(context);
    final stats = controller.session.stats;
    _hintTimer?.cancel();
    game.preview(null, null);
    await services.audio.setDucked(true);
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
    await services.audio.setDucked(false);
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
      final unlocked = await controller.finish();
      await _showAchievementAnnouncements(unlocked);
      services.progression.refresh();
      final games = services.storage.getInt('totalGames');
      if (games > 0 && games % GameConstants.interstitialEveryGames == 0) {
        await services.ads.showInterstitial();
      }
      controller.restart();
      game.resumeEngine();
    } else if (action == 'home' && mounted) {
      final unlocked = await controller.finish();
      await _showAchievementAnnouncements(unlocked);
      services.progression.refresh();
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _pause() async {
    _hintTimer?.cancel();
    game.preview(null, null);
    final progression = AppServices.of(context).progression;
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
      _scheduleHint();
      return;
    }
    if (action == 'restart') {
      final unlocked = await controller.finish();
      await _showAchievementAnnouncements(unlocked);
      progression.refresh();
      controller.restart();
      game.resumeEngine();
      _scheduleHint();
      return;
    }
    if (action == 'home') {
      final unlocked = await controller.finish();
      await _showAchievementAnnouncements(unlocked);
      progression.refresh();
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }
    controller.resume();
    game.resumeEngine();
    _scheduleHint();
  }

  Future<void> _showAchievementAnnouncements(List<String> ids) async {
    if (!mounted || ids.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final names = ids.map((id) => switch (id) {
          'beginner' => l10n.achievementBeginner,
          'master' => l10n.achievementMaster,
          'combo_king' => l10n.achievementComboKing,
          'line_crusher' => l10n.achievementLineCrusher,
          _ => l10n.achievementVeteran,
        });
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.emoji_events_rounded,
            color: RushPalette.gold, size: 48),
        title: Text(l10n.achievementUnlocked),
        content: Text(names.join('\n'), textAlign: TextAlign.center),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                child: AnimatedBuilder(
                  animation: _invalidDropController,
                  builder: (context, child) {
                    final progress = _invalidDropController.value;
                    final offset =
                        math.sin(progress * math.pi * 6) * (1 - progress) * 9;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onTapUp: _hammerMode ? _hammerTap : null,
                            child: DragTarget<int>(
                              key: _boardKey,
                              onMove: _dragMove,
                              onLeave: (_) => game.preview(null, null),
                              onAcceptWithDetails: _accept,
                              builder: (context, _, __) => ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child:
                                    GameWidget(key: ValueKey(game), game: game),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: FadeTransition(
                              opacity: TweenSequence<double>([
                                TweenSequenceItem(
                                  tween: Tween<double>(begin: 0, end: .9)
                                      .chain(CurveTween(curve: Curves.easeOut)),
                                  weight: 30,
                                ),
                                TweenSequenceItem(
                                  tween: Tween<double>(begin: .9, end: 0)
                                      .chain(CurveTween(curve: Curves.easeIn)),
                                  weight: 70,
                                ),
                              ]).animate(_invalidDropController),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: RushPalette.coral,
                                    width: 4,
                                  ),
                                ),
                              ),
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
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: AppServices.of(context).boosters,
              builder: (context, _) {
                final boosters = AppServices.of(context).boosters;
                return Row(children: [
                  _CoinPill(value: boosters.coins),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _BoosterButton(
                      icon: Icons.crop_square_rounded,
                      price: boosters.price(BoosterType.singleCell),
                      tooltip: l10n.singleCellBooster,
                      onPressed: () => _useBooster(BoosterType.singleCell),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _BoosterButton(
                      icon: Icons.shuffle_rounded,
                      price: boosters.price(BoosterType.shuffle),
                      tooltip: l10n.shuffleBooster,
                      onPressed: () => _useBooster(BoosterType.shuffle),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _BoosterButton(
                      icon: Icons.hardware_rounded,
                      price: boosters.price(BoosterType.hammer),
                      tooltip: l10n.hammerBooster,
                      selected: _hammerMode,
                      onPressed: () => _useBooster(BoosterType.hammer),
                    ),
                  ),
                ]);
              },
            ),
            const SizedBox(height: 8),
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
                          piece: controller.session.pieces[index],
                          onDragStarted: _dragStarted,
                          onDragEnd: _dragEnded,
                        ),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: RushPalette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RushPalette.gold),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.monetization_on_rounded,
              color: RushPalette.gold, size: 20),
          const SizedBox(width: 4),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
      );
}

class _BoosterButton extends StatelessWidget {
  const _BoosterButton({
    required this.icon,
    required this.price,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });
  final IconData icon;
  final int price;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: SizedBox(
          height: 44,
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              backgroundColor: selected ? RushPalette.gold : null,
            ),
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text('$price',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      );
}

class _DraggablePiece extends StatelessWidget {
  const _DraggablePiece({
    required this.index,
    required this.piece,
    required this.onDragStarted,
    required this.onDragEnd,
  });
  static const feedbackCellSize = 30.0;
  static const _touchTargetSize = 88.0;
  static const _fingerLift = 64.0;

  final int index;
  final Piece piece;
  final VoidCallback onDragStarted;
  final DragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) => Draggable<int>(
        data: index,
        maxSimultaneousDrags: 1,
        rootOverlay: true,
        onDragStarted: onDragStarted,
        onDragEnd: onDragEnd,
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
