/// Where a subscriber manages or cancels their VIP subscription: the store
/// that billed it. Android: Play's subscription page for this app (the only
/// way to cancel a Play subscription); iOS: App Store subscriptions.
Uri subscriptionManagementUri({required bool isIOS, required String packageName}) => isIOS
    ? Uri.parse('https://apps.apple.com/account/subscriptions')
    : Uri.https('play.google.com', '/store/account/subscriptions', {'package': packageName});
