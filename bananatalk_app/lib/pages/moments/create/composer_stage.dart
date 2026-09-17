/// The two steps of posting a moment.
///
/// Compose first, configure second. NOT media-first, which is what Instagram
/// does and what a literal copy would give: this app allows text-only moments
/// with gradient backgrounds, so a media-first flow would open by refusing to
/// let someone type.
///
/// Two steps rather than three. Instagram's middle step is crop-and-filter,
/// which here already lives in VideoEditorScreen for video and does not exist
/// for photos — a stage that sometimes has nothing in it is worse than no
/// stage.
enum ComposerStage {
  /// What the moment says: caption, background, media.
  compose,

  /// Who sees it and how it is filed: privacy, category, tags, schedule.
  details,
}

extension ComposerStageX on ComposerStage {
  bool get isFirst => this == ComposerStage.compose;
  bool get isLast => this == ComposerStage.details;

  ComposerStage get next =>
      this == ComposerStage.compose ? ComposerStage.details : this;

  ComposerStage get previous =>
      this == ComposerStage.details ? ComposerStage.compose : this;

  int get index => ComposerStage.values.indexOf(this);
}

/// Whether the composer may advance past [stage].
///
/// Only the compose step gates: there is nothing to configure about a moment
/// with no content. The details step never blocks — everything on it is
/// optional, and the post button carries its own validation.
bool canAdvanceFrom({
  required ComposerStage stage,
  required bool hasCaption,
  required bool hasMedia,
}) {
  if (stage != ComposerStage.compose) return true;
  // Either alone is a moment: a photo needs no words, and a text post needs no
  // photo. Requiring both would refuse half the posts this app exists for.
  return hasCaption || hasMedia;
}
