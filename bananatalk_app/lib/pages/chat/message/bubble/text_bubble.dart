// This file is scaffolding for C13.
//
// The text-message rendering is already fully extracted into
// [TextMessageView] at message_bubble/text_message_view.dart.
// [_buildMessageContent] in message_bubble.dart delegates to it directly;
// there is no inline text rendering left to extract here.
//
// C13 will introduce [TextBubble] as a thin wrapper (using [BubbleContainer])
// once the M3 container polish lands, replacing the inline decoration inside
// [TextMessageView].

export 'package:bananatalk_app/pages/chat/message/message_bubble/text_message_view.dart'
    show TextMessageView;
