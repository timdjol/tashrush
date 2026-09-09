import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../game/block_rush_game.dart';
import '../../game/pieces/piece.dart';
import '../../localization/app_localizations.dart';
import '../../models/game_models.dart';
import '../../utils/game_constants.dart';
import '../../widgets/rush_card.dart';
import 'game_controller.dart';
import 'piece_preview.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _boardKey = GlobalKey();
  late GameController controller;
  late BlockRushGame game;
  bool _ready = false;

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
    unawaited(controller.start());
    _ready = true;
  }

  void _onChanged() {
    game.refresh(controller.session);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_ready) unawaited(controller.finish());
    controller.removeListener(_onChanged);
    controller.dispose();
    super.dispose();
  }

  GridPoint? _originFromGlobal(Offset global) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(global);
    final cellSize = box.size.width / GameConstants.boardSize;
    return GridPoint(
        (local.dy / cellSize).floor(), (local.dx / cellSize).floor());
  }

  void _dragMove(DragTargetDetails<int> details) {
    final origin = _originFromGlobal(details.offset);
    if (origin == null || details.data >= controller.session.pieces.length) {
      return;
    }
    game.preview(controller.session.pieces[details.data], origin);
  }

  Future<void> _accept(DragTargetDetails<int> details) async {
    final origin = _originFromGlobal(details.offset);
    game.preview(null, null);
    if (origin == null) return;
    final services = AppServices.of(context);
    final placed =
        await controller.place(details.data, origin.row, origin.column);
    if (placed) {
      await services.audio.play('place');
      final clear = controller.lastClear;
      if (clear.lines > 0 || clear.bombsTriggered > 0) {
        game.playClearEffect(lines: clear.lines, bombs: clear.bombsTriggered);
        await services.audio
            .play(clear.bombsTriggered > 0 ? 'explosion' : 'clear');
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
              TextButton(
                  onPressed: () => Navigator.pop(context, 'continue'),
                  child: Text(l10n.continueLabel)),
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
        controller.session.continueAfterReward();
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
  static const _feedbackCellSize = 30.0;
  static const _touchTargetSize = 88.0;

  final int index;
  final Piece piece;

  @override
  Widget build(BuildContext context) => Draggable<int>(
        data: index,
        dragAnchorStrategy: (_, __, ___) => Offset(
          piece.width * _feedbackCellSize / 2,
          piece.height * _feedbackCellSize / 2,
        ),
        feedback: Material(
            color: Colors.transparent,
            child: PiecePreview(piece: piece, cellSize: _feedbackCellSize)),
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
