# Chat capture: draft privacy wording for the owner's review

Date: 2026-11-14. Status: DRAFT. Nothing here is published. The server switch `STUDY_FROM_CHATS_ENABLED` stays off until the owner has reviewed this and updated the policy and store forms.

This is a product draft, not legal advice. If the app has users in the EU, UK, Korea or California, have whoever reviews the privacy policy read it.

## What the feature does with data

- When a learner translates a message in a one-to-one chat, up to 8 words or short phrases (2 to 40 characters, at most 4 words; at most 8 characters in languages written without spaces) from that translation are saved to the learner's private study list, with their meaning. Whole messages are not saved.
- When a chat partner corrects one of the learner's messages, the learner's own sentence, the corrected sentence and the partner's note are saved to the learner's private mistakes list.
- Only the learner sees these lists. The partner's name is not shown on them.
- No new data is sent to an AI provider: the words come from a translation the learner already asked for. The partner's note is never sent to an AI provider.
- Words the learner has not kept are removed automatically after 14 days. Everything is deleted when the learner deletes their account. When a partner deletes their account, corrections they wrote are deleted from the learner's list, and words that came only from their chats are deleted unless the learner kept them.
- Collection is on by default once the switch is on; a learner can dismiss any item.

## Proposed privacy policy text

Add under the section that describes learning features:

> **Study list from your chats.** When you translate a message in a chat, we save a few words or short phrases from that translation, with their meanings, to your private study list so you can review them later. When a chat partner corrects one of your messages, we save your sentence and their correction to your private list of mistakes. Only you can see these lists. Words you do not keep are removed after 14 days, and everything is deleted when you delete your account. If the other person deletes their account, their corrections are removed from your list.

Add under the section that describes what other users can see or keep:

> A short word or phrase from a message you sent may be saved to your chat partner's private study list if they translate that message. A correction you write on a partner's message is saved to their private list. Both are removed if you delete your account, unless your partner has saved the word as their own vocabulary.

## Store data forms

- **App Store privacy label:** the data is already covered if "User Content: Messages / Other User Content" is declared as collected, linked to the user, used for App Functionality. Check that it is; no new category is needed. Not used for tracking.
- **Google Play Data safety:** "Messages: Other in-app messages" collected, not shared, purpose App functionality, user can request deletion. Check it is declared; no new type is needed.
- If either form currently says messages are not stored beyond delivery, it needs correcting.

## Questions for the owner

1. Is default-on acceptable, or should the first captured word show a one-time notice ("Words you look up are saved here")? A notice is cheap to add in the app plan for phase 2b.
2. Should a partner be able to opt out of their words being saved to someone else's list? Not built. The saved text is at most a short phrase the learner could copy by hand.
3. The last line of the second paragraph ("unless your partner has saved the word") — confirm you are comfortable that a kept word outlives the partner's account. It is a dictionary-style entry (word and meaning) with no link to the partner.
