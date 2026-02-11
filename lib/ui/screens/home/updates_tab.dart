import 'package:busin/controllers/auth_controller.dart';
import 'package:busin/controllers/update_controller.dart';
import 'package:busin/models/bus_update.dart';
import 'package:busin/ui/components/widgets/user_avatar.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class UpdatesTab extends StatefulWidget {
  const UpdatesTab({super.key});

  static const String routeName = '/updates_tab';

  @override
  State<UpdatesTab> createState() => _UpdatesTabState();
}

class _UpdatesTabState extends State<UpdatesTab> with WidgetsBindingObserver {
  final AuthController authController = Get.find<AuthController>();
  final UpdateController updateController = Get.find<UpdateController>();

  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  /// Track previous keyboard visibility to detect system dismiss.
  bool _wasKeyboardOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Mark updates as seen when user opens this tab
    updateController.markAsSeen();

    // Listen to type changes to update prefill/hint (only while focused)
    ever(updateController.selectedType, (BusUpdateType type) {
      if (_messageFocusNode.hasFocus) {
        _applyPrefill(type);
      }
    });

    // Drive the isInputFocused flag from FocusNode so home.dart can hide the tab bar
    _messageFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final hasFocus = _messageFocusNode.hasFocus;
    updateController.isInputFocused.value = hasFocus;

    // When user focuses, apply type-specific prefill
    if (hasFocus) {
      _applyPrefill(updateController.selectedType.value);
    }
  }

  /// Detect keyboard hide via system dismiss button (which doesn't unfocus the FocusNode).
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Use addPostFrameCallback so MediaQuery reflects the new insets
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
      if (_wasKeyboardOpen && !isKeyboardOpen && _messageFocusNode.hasFocus) {
        // Keyboard was dismissed via system button — force unfocus
        _messageFocusNode.unfocus();
      }
      _wasKeyboardOpen = isKeyboardOpen;
    });
  }

  void _applyPrefill(BusUpdateType type) {
    final langCode = localeController.locale.languageCode;
    final prefill = type.prefillMessage(langCode);
    if (prefill.isNotEmpty) {
      _messageController.text = prefill;
      // Move cursor to end
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
    } else {
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageFocusNode.removeListener(_onFocusChange);
    updateController.isInputFocused.value = false;
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _submitUpdate() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    HapticFeedback.mediumImpact();
    updateController.submitUpdate(
      authorId: authController.userId,
      authorName: authController.userDisplayName,
      authorPhotoUrl: authController.userProfileImage,
      message: message,
    );

    // Full reset to initial idle state
    _messageController.clear();
    updateController.selectedType.value = BusUpdateType.busLocation;
    _messageFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = localeController.locale.languageCode;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 8.0,
          ),
          child: Column(
            children: [
              // --- Latest update pinned at the very top ---
              Obx(() {
                final latest = updateController.latestUpdate.value;
                if (latest == null) return const SizedBox.shrink();
                return _LatestUpdateCard(update: latest, langCode: langCode)
                    .animate()
                    .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: -0.05,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    );
              }),

              // --- Scrollable older updates OR empty state ---
              Expanded(
                child: Obx(() {
                  final updates = updateController.todayUpdates;
                  final olderUpdates = updateController.olderUpdates;

                  if (updates.isEmpty) {
                    return _EmptyState(langCode: langCode);
                  }

                  if (olderUpdates.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          langCode == 'en'
                              ? 'Earlier today'
                              : 'Plus tôt aujourd\'hui',
                          style: AppTextStyles.small.copyWith(color: greyColor),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.only(
                            bottom: isKeyboardOpen ? 8 : 120,
                          ),
                          itemCount: olderUpdates.length,
                          itemBuilder: (context, index) {
                            final update = olderUpdates[index];
                            return Opacity(
                              opacity: 0.55,
                              child:
                                  _UpdateTile(
                                        update: update,
                                        langCode: langCode,
                                        onDelete:
                                            authController.userId ==
                                                    update.authorId ||
                                                authController.isAdmin
                                            ? () => updateController
                                                  .deleteUpdate(update.id)
                                            : null,
                                      )
                                      .animate()
                                      .fadeIn(
                                        duration: 300.ms,
                                        delay: (50 * index).ms,
                                        curve: Curves.easeOut,
                                      )
                                      .slideY(
                                        begin: 0.04,
                                        end: 0,
                                        duration: 350.ms,
                                        delay: (50 * index).ms,
                                        curve: Curves.easeOut,
                                      ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ),

              // --- Input area pinned at the bottom ---
              Obx(() {
                final isFocused = updateController.isInputFocused.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: isKeyboardOpen
                        ? 0
                        : isFocused
                        ? 0
                        : MediaQuery.viewPaddingOf(context).bottom + 80,
                  ),
                  child: _UpdateInputArea(
                    messageController: _messageController,
                    messageFocusNode: _messageFocusNode,
                    updateController: updateController,
                    langCode: langCode,
                    onSubmit: _submitUpdate,
                    isFocused: isFocused,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Empty State – warm greeting while no updates exist
// ─────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.langCode});

  final String langCode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child:
            Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSunrise,
                      size: 64,
                      color: accentColor.withValues(alpha: 0.6),
                    ),
                    const Gap(16),
                    Text(
                      getTimeGreeting(langCode),
                      style: AppTextStyles.h2.copyWith(color: accentColor),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(8),
                    Text(
                      langCode == 'en'
                          ? 'No updates yet today.\nBe the first to share one!'
                          : 'Pas encore de mises à jour aujourd\'hui.\nSoyez le premier à en partager !',
                      style: AppTextStyles.body.copyWith(color: greyColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.easeOut,
                ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Latest update card – prominent & live
// ─────────────────────────────────────────────────────────
class _LatestUpdateCard extends StatelessWidget {
  const _LatestUpdateCard({required this.update, required this.langCode});

  final BusUpdate update;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeController.isDark
              ? [seedPalette.shade800, seedPalette.shade900]
              : [seedPalette.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius * 2.5,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: LIVE badge + type
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: borderRadius * 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'LIVE',
                      style: AppTextStyles.small.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  update.type.label(langCode),
                  style: AppTextStyles.small.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatRelativeDateTime(update.createdAt, locale: langCode),
                style: AppTextStyles.small.copyWith(color: greyColor),
              ),
            ],
          ),
          const Gap(12),

          // Message
          Text(update.message, style: AppTextStyles.h4),
          const Gap(12),

          // Author
          Row(
            children: [
              UserAvatar(tag: update.authorPhotoUrl, radius: 12),
              const Gap(8),
              Expanded(
                child: Text(
                  update.authorName,
                  style: AppTextStyles.small.copyWith(color: greyColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Older update tile – compact style
// ─────────────────────────────────────────────────────────
class _UpdateTile extends StatelessWidget {
  const _UpdateTile({
    required this.update,
    required this.langCode,
    this.onDelete,
  });

  final BusUpdate update;
  final String langCode;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeController.isDark
            ? seedColor.withValues(alpha: 0.3)
            : seedPalette.shade50.withValues(alpha: 0.6),
        borderRadius: borderRadius * 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(tag: update.authorPhotoUrl, radius: 14),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        update.type.label(langCode),
                        style: AppTextStyles.small.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      formatRelativeDateTime(
                        update.createdAt,
                        locale: langCode,
                      ),
                      style: AppTextStyles.small.copyWith(
                        color: greyColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  update.message,
                  style: AppTextStyles.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                Text(
                  update.authorName,
                  style: AppTextStyles.small.copyWith(
                    color: greyColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                color: errorColor,
                size: 16,
              ),
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Bottom input area – type selector + text input + send
// Transparent by default, shows chips + send on focus
// ─────────────────────────────────────────────────────────
class _UpdateInputArea extends StatelessWidget {
  const _UpdateInputArea({
    required this.messageController,
    required this.messageFocusNode,
    required this.updateController,
    required this.langCode,
    required this.onSubmit,
    required this.isFocused,
  });

  final TextEditingController messageController;
  final FocusNode messageFocusNode;
  final UpdateController updateController;
  final String langCode;
  final VoidCallback onSubmit;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isFocused
            ? (themeController.isDark ? seedPalette.shade900 : Colors.white)
            : Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4.0,
        children: [
          // Type selector chips – only visible when focused
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isFocused
                ? Obx(() {
                    final currentType = updateController.selectedType.value;
                    return SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: BusUpdateType.values.length,
                        separatorBuilder: (_, __) => const Gap(8),
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final type = BusUpdateType.values[index];
                          final isSelected = currentType == type;
                          return ChoiceChip(
                            label: Text(
                              type.label(langCode),
                              style: AppTextStyles.small.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : themeController.isDark
                                    ? lightColor
                                    : seedColor,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              updateController.changeType(type);
                            },
                            selectedColor: accentColor,
                            backgroundColor: themeController.isDark
                                ? seedColor.withValues(alpha: 0.5)
                                : seedPalette.shade50,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: borderRadius * 1.25,
                            ),
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                          );
                        },
                      ),
                    );
                  })
                : const SizedBox.shrink(),
          ),

          // Text input + Send button (send only visible when focused)
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.paddingOf(context).bottom + 8.0,
            ),

            child: Row(
              children: [
                Expanded(
                  child: Obx(() {
                    final type = updateController.selectedType.value;
                    final genericHint = langCode == 'en'
                        ? 'Send an update to your mates...'
                        : 'Envoyer une mise à jour à vos potes...';
                    return TextField(
                      controller: messageController,
                      focusNode: messageFocusNode,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      minLines: 1,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: isFocused
                            ? type.hintText(langCode)
                            : genericHint,
                        hintStyle: AppTextStyles.body.copyWith(
                          color: greyColor,
                        ),
                        border: AppInputBorders.border,
                        enabledBorder: AppInputBorders.enabledBorder,
                        focusedBorder: AppInputBorders.focusedBorder,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    );
                  }),
                ),
                // Send button – animated in/out
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.centerRight,
                  child: isFocused
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Obx(() {
                            final isBusy = updateController.isBusy.value;
                            return IconButton.filled(
                              onPressed: isBusy ? null : onSubmit,
                              style: IconButton.styleFrom(
                                backgroundColor: accentColor,
                                disabledBackgroundColor: accentColor.withValues(
                                  alpha: 0.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: borderRadius * 2.0,
                                ),
                                fixedSize: const Size(48, 48),
                              ),
                              icon: isBusy
                                  ? SizedBox(
                                      width: 20.0,
                                      height: 20.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: lightColor,
                                      ),
                                    )
                                  : HugeIcon(
                                      icon: HugeIcons.strokeRoundedSent,
                                      color: lightColor,
                                      size: 20,
                                    ),
                            );
                          }),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
