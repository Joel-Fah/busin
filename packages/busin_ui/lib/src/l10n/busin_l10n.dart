import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'busin_l10n_en.dart';
import 'busin_l10n_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of BusinL10n
/// returned by `BusinL10n.of(context)`.
///
/// Applications need to include `BusinL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/busin_l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: BusinL10n.localizationsDelegates,
///   supportedLocales: BusinL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the BusinL10n.supportedLocales
/// property.
abstract class BusinL10n {
  BusinL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static BusinL10n of(BuildContext context) {
    return Localizations.of<BusinL10n>(context, BusinL10n)!;
  }

  static const LocalizationsDelegate<BusinL10n> delegate = _BusinL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// No description provided for @stateLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get stateLoading;

  /// No description provided for @stateEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get stateEmpty;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get errorOffline;

  /// No description provided for @errorNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this.'**
  String get errorNotAllowed;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This could not be found.'**
  String get errorNotFound;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @accountPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get accountPending;

  /// No description provided for @accountVerified.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accountVerified;

  /// No description provided for @accountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get accountSuspended;

  /// No description provided for @subscriptionPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get subscriptionPending;

  /// No description provided for @subscriptionApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get subscriptionApproved;

  /// No description provided for @subscriptionRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get subscriptionRejected;

  /// No description provided for @subscriptionExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get subscriptionExpired;

  /// No description provided for @tripScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get tripScheduled;

  /// No description provided for @tripActive.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get tripActive;

  /// No description provided for @tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripCompleted;

  /// No description provided for @tripCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tripCancelled;

  /// No description provided for @directionInbound.
  ///
  /// In en, this message translates to:
  /// **'Going to school'**
  String get directionInbound;

  /// No description provided for @directionOutbound.
  ///
  /// In en, this message translates to:
  /// **'Going home'**
  String get directionOutbound;

  /// No description provided for @semesterFall.
  ///
  /// In en, this message translates to:
  /// **'Fall'**
  String get semesterFall;

  /// No description provided for @semesterSpring.
  ///
  /// In en, this message translates to:
  /// **'Spring'**
  String get semesterSpring;

  /// No description provided for @semesterSummer.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get semesterSummer;

  /// A semester as people name it, for example Fall 2026.
  ///
  /// In en, this message translates to:
  /// **'{name} {year}'**
  String semesterLabel(String name, int year);

  /// Spoken name of a person's avatar.
  ///
  /// In en, this message translates to:
  /// **'Picture of {name}'**
  String avatarOf(String name);

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingLabel;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'BusIn'**
  String get appName;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride with BusIn'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your school Google account to subscribe, show your boarding code and follow your bus.'**
  String get signInSubtitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get signInCancelled;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in did not work. Try again.'**
  String get signInFailed;

  /// No description provided for @signInNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This Google account is not allowed here. Use your school account.'**
  String get signInNotAllowed;

  /// No description provided for @blockedStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'This app is for students'**
  String get blockedStaffTitle;

  /// No description provided for @blockedStaffBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is a staff or administrator account. Staff use the BusIn ops app, and administrators use the admin portal.'**
  String get blockedStaffBody;

  /// No description provided for @blockedPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is waiting for approval'**
  String get blockedPendingTitle;

  /// No description provided for @blockedPendingBody.
  ///
  /// In en, this message translates to:
  /// **'A school administrator needs to verify your account before you can use BusIn.'**
  String get blockedPendingBody;

  /// No description provided for @blockedSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended'**
  String get blockedSuspendedTitle;

  /// No description provided for @blockedSuspendedBody.
  ///
  /// In en, this message translates to:
  /// **'Contact your school\'s transport office to find out why.'**
  String get blockedSuspendedBody;

  /// No description provided for @navSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get navSubscription;

  /// No description provided for @navQr.
  ///
  /// In en, this message translates to:
  /// **'Boarding code'**
  String get navQr;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navBus.
  ///
  /// In en, this message translates to:
  /// **'My bus'**
  String get navBus;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This part of the app is being built.'**
  String get comingSoonBody;

  /// No description provided for @subscriptionNoSemesterTitle.
  ///
  /// In en, this message translates to:
  /// **'No semester open yet'**
  String get subscriptionNoSemesterTitle;

  /// No description provided for @subscriptionNoSemesterBody.
  ///
  /// In en, this message translates to:
  /// **'You can subscribe as soon as your school adds the semester.'**
  String get subscriptionNoSemesterBody;

  /// No description provided for @subscriptionStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String subscriptionStarts(String date);

  /// No description provided for @subscribeHeading.
  ///
  /// In en, this message translates to:
  /// **'Subscribe for {semester}'**
  String subscribeHeading(String semester);

  /// No description provided for @subscribeIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose where you board and add a photo of your payment receipt. Your school checks it and approves your request.'**
  String get subscribeIntro;

  /// No description provided for @subscribeStopLabel.
  ///
  /// In en, this message translates to:
  /// **'Your stop'**
  String get subscribeStopLabel;

  /// No description provided for @subscribeStopHint.
  ///
  /// In en, this message translates to:
  /// **'Choose where you board'**
  String get subscribeStopHint;

  /// No description provided for @subscribeStopSearch.
  ///
  /// In en, this message translates to:
  /// **'Search stops'**
  String get subscribeStopSearch;

  /// No description provided for @subscribeStopNone.
  ///
  /// In en, this message translates to:
  /// **'No stop matches.'**
  String get subscribeStopNone;

  /// No description provided for @subscribeProofLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment proof'**
  String get subscribeProofLabel;

  /// No description provided for @subscribeProofHint.
  ///
  /// In en, this message translates to:
  /// **'Add a clear photo of your receipt'**
  String get subscribeProofHint;

  /// No description provided for @subscribeProofPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Only you and your school\'s administrators can see it.'**
  String get subscribeProofPrivacy;

  /// No description provided for @proofTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get proofTakePhoto;

  /// No description provided for @proofChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get proofChoosePhoto;

  /// No description provided for @proofChange.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get proofChange;

  /// No description provided for @subscribeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get subscribeSubmit;

  /// No description provided for @subscribeErrorType.
  ///
  /// In en, this message translates to:
  /// **'Use a JPEG, PNG or WebP photo.'**
  String get subscribeErrorType;

  /// No description provided for @subscribeErrorTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That photo is too large. Pick one under 5 MB.'**
  String get subscribeErrorTooLarge;

  /// No description provided for @subscribeErrorExists.
  ///
  /// In en, this message translates to:
  /// **'You already have a request for this semester. Pull down to refresh.'**
  String get subscribeErrorExists;

  /// No description provided for @subscriptionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get subscriptionStop;

  /// No description provided for @subscriptionSent.
  ///
  /// In en, this message translates to:
  /// **'Sent {date}'**
  String subscriptionSent(String date);

  /// No description provided for @subscriptionProofTitle.
  ///
  /// In en, this message translates to:
  /// **'Your payment proof'**
  String get subscriptionProofTitle;

  /// No description provided for @statusPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get statusPendingTitle;

  /// No description provided for @statusPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your school is checking your payment proof. Pull down to see if it has been decided.'**
  String get statusPendingBody;

  /// No description provided for @statusApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'You are subscribed'**
  String get statusApprovedTitle;

  /// No description provided for @statusApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'You can board at {stop}.'**
  String statusApprovedBody(String stop);

  /// No description provided for @statusApprovedAction.
  ///
  /// In en, this message translates to:
  /// **'Show boarding code'**
  String get statusApprovedAction;

  /// No description provided for @statusRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request not approved'**
  String get statusRejectedTitle;

  /// No description provided for @statusRejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Your school\'s reason:'**
  String get statusRejectedReason;

  /// No description provided for @statusRejectedNoReason.
  ///
  /// In en, this message translates to:
  /// **'Your school did not give a reason.'**
  String get statusRejectedNoReason;

  /// No description provided for @statusRequestAgain.
  ///
  /// In en, this message translates to:
  /// **'Request again'**
  String get statusRequestAgain;

  /// No description provided for @statusExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription ended'**
  String get statusExpiredTitle;

  /// No description provided for @statusExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'This subscription is no longer valid. You can send a new request.'**
  String get statusExpiredBody;

  /// No description provided for @qrTitle.
  ///
  /// In en, this message translates to:
  /// **'Boarding code'**
  String get qrTitle;

  /// No description provided for @qrHint.
  ///
  /// In en, this message translates to:
  /// **'Show this code to the driver or staff when you board.'**
  String get qrHint;

  /// No description provided for @qrImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Your boarding code. It changes every 30 seconds.'**
  String get qrImageLabel;

  /// No description provided for @qrRefreshesIn.
  ///
  /// In en, this message translates to:
  /// **'New code in {seconds} s'**
  String qrRefreshesIn(String seconds);

  /// No description provided for @qrScreenshotsOff.
  ///
  /// In en, this message translates to:
  /// **'Screenshots are turned off here so a copy of your code cannot be shared.'**
  String get qrScreenshotsOff;

  /// No description provided for @qrNoSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'No active subscription'**
  String get qrNoSubscriptionTitle;

  /// No description provided for @qrNoSubscriptionBody.
  ///
  /// In en, this message translates to:
  /// **'Your boarding code appears as soon as your subscription is approved.'**
  String get qrNoSubscriptionBody;

  /// No description provided for @qrGoToSubscription.
  ///
  /// In en, this message translates to:
  /// **'Go to subscription'**
  String get qrGoToSubscription;

  /// No description provided for @qrOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect once to set up your code'**
  String get qrOfflineTitle;

  /// No description provided for @qrOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Your phone needs the internet one time to get your boarding code. After that it works without a connection.'**
  String get qrOfflineBody;
}

class _BusinL10nDelegate extends LocalizationsDelegate<BusinL10n> {
  const _BusinL10nDelegate();

  @override
  Future<BusinL10n> load(Locale locale) {
    return SynchronousFuture<BusinL10n>(lookupBusinL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_BusinL10nDelegate old) => false;
}

BusinL10n lookupBusinL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return BusinL10nEn();
    case 'fr':
      return BusinL10nFr();
  }

  throw FlutterError(
    'BusinL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
