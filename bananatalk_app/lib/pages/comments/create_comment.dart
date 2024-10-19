import 'package:bananatalk_app/providers/provider_root/comments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateComment extends ConsumerStatefulWidget {
  final FocusNode focusNode;
  final String id;
  final VoidCallback onCommentAdded; // Callback when a comment is added

  const CreateComment({
    super.key,
    required this.id,
    required this.focusNode,
    required this.onCommentAdded, // Pass the callback here
  });

  @override
  ConsumerState<CreateComment> createState() => _CreateCommentState();
}

class _CreateCommentState extends ConsumerState<CreateComment> {
  TextEditingController commentController = TextEditingController();
  void submitComment() {
    String commentText = commentController.text.trim();
    if (commentText.isNotEmpty) {
      // Here you can implement the logic to submit the comment to your backend or provider
      // For example, call a function that handles the submission
      final commentProvider = ref.watch(commentsServiceProvider).createComment(
          title: commentText, id: widget.id); // Use ref to read the provider
      // commentProvider.submitComment(commentText);
      ref.refresh(commentsServiceProvider);
      ref.refresh(commentsProvider(widget.id));
      ref.refresh(momentsServiceProvider).getSingleMoment(id: widget.id);
      // Clear the text field after submission
      commentController.clear();

      // Optionally, you can update the UI to reflect the new comment
      // setState(() {
      //   // Update any state variables or provider data if needed
      // });
      widget.onCommentAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      commentController.text = value;
                    });
                  },
                  focusNode: widget.focusNode,
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          if (commentController.text.trim().isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white),
                onPressed: submitComment,
              ),
            ),
        ],
      ),
    );
  }
}
