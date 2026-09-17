import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

/// Who runs a club, and who is in it.
///
/// The club page showed a member COUNT and nothing else — no owner, no faces —
/// which asked people to join something with no visible human behind it. That
/// is the weakest possible pitch for a group whose entire value is the people
/// in it, and "who is behind this?" is the first question anyone asks.
///
/// Renders nothing when the payload carries no members, so list responses
/// (which send a thinner shape) and older builds degrade to exactly what they
/// showed before.
class ClubPeopleSection extends StatelessWidget {
  const ClubPeopleSection({
    super.key,
    required this.club,
    this.onMemberTap,
    this.onMemberLongPress,
  });

  final Club club;
  final void Function(ClubMember member)? onMemberTap;

  /// Long-press opens management for an owner or organizer. Long-press rather
  /// than a visible button per row: the common case is browsing faces, and a
  /// kebab on every avatar would make a social row look like an admin table.
  final void Function(ClubMember member)? onMemberLongPress;

  @override
  Widget build(BuildContext context) {
    if (club.members.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final leaders = club.leaders;
    final rest = club.members.where((m) => !m.leads).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leaders.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(l10n.clubOrganizers, style: context.titleMedium),
          ),
          _AvatarRow(
            key: const Key('club-organizers'),
            members: leaders,
            onTap: onMemberTap,
            onLongPress: onMemberLongPress,
            showRole: true,
          ),
        ],
        if (rest.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '${l10n.clubMembersLabel} · ${club.memberCount}',
              style: context.titleMedium,
            ),
          ),
          _AvatarRow(
            key: const Key('club-members'),
            members: rest,
            onTap: onMemberTap,
            onLongPress: onMemberLongPress,
            showRole: false,
          ),
        ],
      ],
    );
  }
}

class _AvatarRow extends StatelessWidget {
  const _AvatarRow({
    super.key,
    required this.members,
    required this.showRole,
    this.onTap,
    this.onLongPress,
  });

  final List<ClubMember> members;
  final bool showRole;
  final void Function(ClubMember member)? onTap;
  final void Function(ClubMember member)? onLongPress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: showRole ? 104 : 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final m = members[i];
          return GestureDetector(
            onTap: onTap == null ? null : () => onTap!(m),
            onLongPress: onLongPress == null ? null : () => onLongPress!(m),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  _Avatar(member: m),
                  const SizedBox(height: 6),
                  Text(
                    m.name.isEmpty ? '—' : m.name,
                    style: context.captionSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (showRole)
                    Text(
                      m.isOwner ? '★' : '·',
                      style: context.captionSmall.copyWith(
                        color: m.isOwner
                            ? context.primaryColor
                            : context.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member});

  final ClubMember member;

  @override
  Widget build(BuildContext context) {
    final url = member.avatar;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: member.isOwner
            ? Border.all(color: context.primaryColor, width: 2)
            : null,
        color: context.containerColor,
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? Center(
              child: Text(
                member.name.isEmpty ? '?' : member.name.characters.first,
                style: context.titleMedium,
              ),
            )
          : CachedImageWidget(imageUrl: url, fit: BoxFit.cover),
    );
  }
}
