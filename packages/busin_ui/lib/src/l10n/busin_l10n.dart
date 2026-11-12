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

  /// No description provided for @subscriptionRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get subscriptionRevoked;

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

  /// No description provided for @setupWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String setupWelcome(String name);

  /// No description provided for @setupBody.
  ///
  /// In en, this message translates to:
  /// **'Tell your school who you are so the driver can find you. It takes a minute.'**
  String get setupBody;

  /// No description provided for @setupSave.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get setupSave;

  /// No description provided for @setupNotYou.
  ///
  /// In en, this message translates to:
  /// **'Not you? Sign out'**
  String get setupNotYou;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldFullName;

  /// No description provided for @fieldFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'As on your student card'**
  String get fieldFullNameHint;

  /// No description provided for @fieldMatricule.
  ///
  /// In en, this message translates to:
  /// **'Student number'**
  String get fieldMatricule;

  /// No description provided for @fieldMatriculeHint.
  ///
  /// In en, this message translates to:
  /// **'For example ICT2026-0001'**
  String get fieldMatriculeHint;

  /// No description provided for @fieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get fieldPhone;

  /// No description provided for @fieldPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'For example 677 12 34 56'**
  String get fieldPhoneHint;

  /// No description provided for @fieldDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get fieldDepartment;

  /// No description provided for @fieldDepartmentHint.
  ///
  /// In en, this message translates to:
  /// **'Choose your department'**
  String get fieldDepartmentHint;

  /// No description provided for @fieldProgram.
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get fieldProgram;

  /// No description provided for @fieldProgramHint.
  ///
  /// In en, this message translates to:
  /// **'Choose your degree level'**
  String get fieldProgramHint;

  /// No description provided for @fieldFaculty.
  ///
  /// In en, this message translates to:
  /// **'Faculty'**
  String get fieldFaculty;

  /// No description provided for @fieldFacultyHint.
  ///
  /// In en, this message translates to:
  /// **'Choose your faculty'**
  String get fieldFacultyHint;

  /// No description provided for @fieldDepartmentFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a faculty first'**
  String get fieldDepartmentFirst;

  /// No description provided for @choiceNone.
  ///
  /// In en, this message translates to:
  /// **'Not chosen'**
  String get choiceNone;

  /// No description provided for @fieldTooShort.
  ///
  /// In en, this message translates to:
  /// **'That looks too short.'**
  String get fieldTooShort;

  /// No description provided for @fieldTooLong.
  ///
  /// In en, this message translates to:
  /// **'That is too long.'**
  String get fieldTooLong;

  /// No description provided for @fieldInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check this one: it has characters we cannot use.'**
  String get fieldInvalid;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileTitle;

  /// No description provided for @profileOpen.
  ///
  /// In en, this message translates to:
  /// **'Open your profile'**
  String get profileOpen;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get profileDetails;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get profileEdit;

  /// No description provided for @profileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileNotSet;

  /// No description provided for @profileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String profileMemberSince(String date);

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Details saved.'**
  String get profileSaved;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of BusIn?'**
  String get profileSignOutTitle;

  /// No description provided for @profileSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in with Google again.'**
  String get profileSignOutBody;

  /// No description provided for @profileCredits.
  ///
  /// In en, this message translates to:
  /// **'3D illustrations by Thiings (thiings.co)'**
  String get profileCredits;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// No description provided for @loadingSlowTitle.
  ///
  /// In en, this message translates to:
  /// **'This is taking longer than usual'**
  String get loadingSlowTitle;

  /// No description provided for @loadingSlowBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection. BusIn keeps trying.'**
  String get loadingSlowBody;

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
  /// **'Hop on. BusIn handles the rest.'**
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

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @profileAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profileAppearance;

  /// No description provided for @profileAppearanceHint.
  ///
  /// In en, this message translates to:
  /// **'Kept on this phone.'**
  String get profileAppearanceHint;

  /// No description provided for @profileTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get profileTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @profileHistory.
  ///
  /// In en, this message translates to:
  /// **'Boarding history'**
  String get profileHistory;

  /// No description provided for @profileHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'Every time you boarded, newest first.'**
  String get profileHistoryBody;

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

  /// No description provided for @subscribeErrorProof.
  ///
  /// In en, this message translates to:
  /// **'The payment proof is missing. Add a clear photo of your receipt and send the request again.'**
  String get subscribeErrorProof;

  /// No description provided for @subscribeErrorEnded.
  ///
  /// In en, this message translates to:
  /// **'This semester has ended. Pull down to refresh and see what is open now.'**
  String get subscribeErrorEnded;

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

  /// No description provided for @proofView.
  ///
  /// In en, this message translates to:
  /// **'View your payment proof full screen'**
  String get proofView;

  /// No description provided for @proofClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get proofClose;

  /// No description provided for @requestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your requests this semester'**
  String get requestsTitle;

  /// No description provided for @requestsHint.
  ///
  /// In en, this message translates to:
  /// **'Everything that happened, the latest first.'**
  String get requestsHint;

  /// No description provided for @requestOf.
  ///
  /// In en, this message translates to:
  /// **'Request of {date}'**
  String requestOf(String date);

  /// No description provided for @requestEventRequested.
  ///
  /// In en, this message translates to:
  /// **'You sent the request'**
  String get requestEventRequested;

  /// No description provided for @requestEventApproved.
  ///
  /// In en, this message translates to:
  /// **'Your school approved it'**
  String get requestEventApproved;

  /// No description provided for @requestEventRejected.
  ///
  /// In en, this message translates to:
  /// **'Your school declined it'**
  String get requestEventRejected;

  /// No description provided for @requestEventRevoked.
  ///
  /// In en, this message translates to:
  /// **'Your school ended it'**
  String get requestEventRevoked;

  /// No description provided for @requestEventReinstated.
  ///
  /// In en, this message translates to:
  /// **'Your school gave it back'**
  String get requestEventReinstated;

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

  /// No description provided for @statusRevokedTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription ended by your school'**
  String get statusRevokedTitle;

  /// No description provided for @statusRevokedReason.
  ///
  /// In en, this message translates to:
  /// **'Your school\'s reason:'**
  String get statusRevokedReason;

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

  /// No description provided for @qrChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking your subscription'**
  String get qrChecking;

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

  /// No description provided for @qrLive.
  ///
  /// In en, this message translates to:
  /// **'Live code'**
  String get qrLive;

  /// No description provided for @qrPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your code to yourself'**
  String get qrPrivateTitle;

  /// No description provided for @qrPrivateBodyProtected.
  ///
  /// In en, this message translates to:
  /// **'It changes by itself, and screenshots are turned off here.'**
  String get qrPrivateBodyProtected;

  /// No description provided for @qrPrivateBody.
  ///
  /// In en, this message translates to:
  /// **'It changes by itself and only works for you.'**
  String get qrPrivateBody;

  /// No description provided for @qrRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Code refreshed.'**
  String get qrRefreshed;

  /// No description provided for @boardTitle.
  ///
  /// In en, this message translates to:
  /// **'How to board'**
  String get boardTitle;

  /// No description provided for @boardStep1.
  ///
  /// In en, this message translates to:
  /// **'Have this screen open when you reach the door.'**
  String get boardStep1;

  /// No description provided for @boardStep2.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone to the scanner until it confirms.'**
  String get boardStep2;

  /// No description provided for @boardStep3.
  ///
  /// In en, this message translates to:
  /// **'Take any seat. Your ride is saved in History.'**
  String get boardStep3;

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

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your boardings'**
  String get historyTitle;

  /// No description provided for @historyStatWeek.
  ///
  /// In en, this message translates to:
  /// **'Boardings this week'**
  String get historyStatWeek;

  /// No description provided for @historyStatStop.
  ///
  /// In en, this message translates to:
  /// **'Most used stop'**
  String get historyStatStop;

  /// No description provided for @historyStatStopNone.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get historyStatStopNone;

  /// No description provided for @historyDayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 boarding} other{{count} boardings}}'**
  String historyDayCount(int count);

  /// No description provided for @historyDayFirst.
  ///
  /// In en, this message translates to:
  /// **'First boarding'**
  String get historyDayFirst;

  /// No description provided for @historyDayLast.
  ///
  /// In en, this message translates to:
  /// **'Last boarding'**
  String get historyDayLast;

  /// No description provided for @historyDayStops.
  ///
  /// In en, this message translates to:
  /// **'Stops used'**
  String get historyDayStops;

  /// No description provided for @historySelectedDay.
  ///
  /// In en, this message translates to:
  /// **'Selected day'**
  String get historySelectedDay;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No boardings yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Each time you board with your code, it appears here.'**
  String get historyEmptyBody;

  /// No description provided for @historyStopUnknown.
  ///
  /// In en, this message translates to:
  /// **'Stop not recorded'**
  String get historyStopUnknown;

  /// No description provided for @historyLoadMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load more. Tap to try again.'**
  String get historyLoadMoreFailed;

  /// No description provided for @busLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Following the bus is for subscribers'**
  String get busLockedTitle;

  /// No description provided for @busLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Once your subscription is approved you can see where your bus is, live.'**
  String get busLockedBody;

  /// No description provided for @busLockedAction.
  ///
  /// In en, this message translates to:
  /// **'Go to subscription'**
  String get busLockedAction;

  /// No description provided for @busNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No bus is running right now'**
  String get busNoneTitle;

  /// No description provided for @busNoneBody.
  ///
  /// In en, this message translates to:
  /// **'When a trip starts you can follow its bus here.'**
  String get busNoneBody;

  /// No description provided for @busWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the bus to share its location.'**
  String get busWaiting;

  /// No description provided for @busUpdatedSeconds.
  ///
  /// In en, this message translates to:
  /// **'Updated {seconds} s ago'**
  String busUpdatedSeconds(String seconds);

  /// No description provided for @busUpdatedMinutes.
  ///
  /// In en, this message translates to:
  /// **'Updated {minutes} min ago'**
  String busUpdatedMinutes(String minutes);

  /// No description provided for @busStale.
  ///
  /// In en, this message translates to:
  /// **'Last seen {minutes} min ago. The bus may be out of signal.'**
  String busStale(String minutes);

  /// No description provided for @busSpeed.
  ///
  /// In en, this message translates to:
  /// **'{kmh} km/h'**
  String busSpeed(String kmh);

  /// No description provided for @busEtaMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String busEtaMinutes(String minutes);

  /// No description provided for @busEtaArriving.
  ///
  /// In en, this message translates to:
  /// **'Arriving'**
  String get busEtaArriving;

  /// No description provided for @busEtaCaption.
  ///
  /// In en, this message translates to:
  /// **'{km} km from {stop}'**
  String busEtaCaption(String km, String stop);

  /// No description provided for @busDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String busDistanceKm(String km);

  /// No description provided for @busEtaLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated arrival'**
  String get busEtaLabel;

  /// No description provided for @busRunning.
  ///
  /// In en, this message translates to:
  /// **'Running buses'**
  String get busRunning;

  /// No description provided for @busYourStop.
  ///
  /// In en, this message translates to:
  /// **'Your stop'**
  String get busYourStop;

  /// No description provided for @busRecenter.
  ///
  /// In en, this message translates to:
  /// **'Show the bus'**
  String get busRecenter;

  /// No description provided for @busLiveFailed.
  ///
  /// In en, this message translates to:
  /// **'Live updates are not available right now.'**
  String get busLiveFailed;

  /// No description provided for @busMapLabel.
  ///
  /// In en, this message translates to:
  /// **'Map of the bus and the stops'**
  String get busMapLabel;

  /// No description provided for @busUpdateFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following {bus} · {direction}'**
  String busUpdateFollowing(String bus, String direction);

  /// No description provided for @busUpdateAtStop.
  ///
  /// In en, this message translates to:
  /// **'At {stop}'**
  String busUpdateAtStop(String stop);

  /// No description provided for @busUpdateLeftStop.
  ///
  /// In en, this message translates to:
  /// **'Left {stop}'**
  String busUpdateLeftStop(String stop);

  /// No description provided for @busUpdateStopped.
  ///
  /// In en, this message translates to:
  /// **'Not moving for {minutes} min'**
  String busUpdateStopped(String minutes);

  /// No description provided for @busUpdateMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving again'**
  String get busUpdateMoving;

  /// No description provided for @busUpdateNearMyStop.
  ///
  /// In en, this message translates to:
  /// **'Almost at your stop, about {minutes} min away'**
  String busUpdateNearMyStop(String minutes);

  /// No description provided for @busUpdatePassedMyStop.
  ///
  /// In en, this message translates to:
  /// **'The bus has passed your stop'**
  String get busUpdatePassedMyStop;

  /// No description provided for @busUpdateSignalLost.
  ///
  /// In en, this message translates to:
  /// **'No news from the bus for {minutes} min'**
  String busUpdateSignalLost(String minutes);

  /// No description provided for @busUpdateSignalBack.
  ///
  /// In en, this message translates to:
  /// **'Back in touch with the bus'**
  String get busUpdateSignalBack;

  /// No description provided for @busUpdateEnded.
  ///
  /// In en, this message translates to:
  /// **'The trip of {bus} has ended'**
  String busUpdateEnded(String bus);

  /// No description provided for @busUpdateDismiss.
  ///
  /// In en, this message translates to:
  /// **'Hide this update'**
  String get busUpdateDismiss;

  /// No description provided for @busUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Live updates'**
  String get busUpdatesTitle;

  /// No description provided for @busUpdatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'What the bus does appears here while you follow it.'**
  String get busUpdatesEmpty;

  /// No description provided for @busMeShow.
  ///
  /// In en, this message translates to:
  /// **'Show me'**
  String get busMeShow;

  /// No description provided for @busMeHide.
  ///
  /// In en, this message translates to:
  /// **'Hide me'**
  String get busMeHide;

  /// No description provided for @busMeFind.
  ///
  /// In en, this message translates to:
  /// **'Find me'**
  String get busMeFind;

  /// No description provided for @busMeWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'See yourself on the map'**
  String get busMeWhyTitle;

  /// No description provided for @busMeWhyBody.
  ///
  /// In en, this message translates to:
  /// **'BusIn will use your phone\'s precise location while this tab is open, to show you next to your stop and the bus. It stays on your phone: it is never sent or kept.'**
  String get busMeWhyBody;

  /// No description provided for @busMeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get busMeContinue;

  /// No description provided for @busMeNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get busMeNotNow;

  /// No description provided for @busMeDenied.
  ///
  /// In en, this message translates to:
  /// **'Location is not allowed for BusIn, so you are not shown.'**
  String get busMeDenied;

  /// No description provided for @busMeDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off for BusIn. You can allow it in your phone\'s settings.'**
  String get busMeDeniedForever;

  /// No description provided for @busMeOff.
  ///
  /// In en, this message translates to:
  /// **'Location is switched off on your phone.'**
  String get busMeOff;

  /// No description provided for @busMeSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get busMeSettings;

  /// No description provided for @busMeApproximate.
  ///
  /// In en, this message translates to:
  /// **'Your phone shares only an approximate position. Allow precise location for BusIn to see exactly where you are.'**
  String get busMeApproximate;

  /// No description provided for @busMeWalkM.
  ///
  /// In en, this message translates to:
  /// **'{distance} m from your stop, about {minutes} min on foot'**
  String busMeWalkM(String distance, String minutes);

  /// No description provided for @busMeWalkKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km from your stop, about {minutes} min on foot'**
  String busMeWalkKm(String distance, String minutes);

  /// No description provided for @pushPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified'**
  String get pushPromptTitle;

  /// No description provided for @pushPromptBody.
  ///
  /// In en, this message translates to:
  /// **'We can tell you as soon as your school decides on your request, even when the app is closed.'**
  String get pushPromptBody;

  /// No description provided for @pushPromptEnable.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get pushPromptEnable;

  /// No description provided for @pushPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get pushPromptLater;

  /// No description provided for @pushPromptDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. You can turn them on in your phone\'s settings.'**
  String get pushPromptDenied;

  /// No description provided for @pushForegroundApproved.
  ///
  /// In en, this message translates to:
  /// **'Your subscription was approved.'**
  String get pushForegroundApproved;

  /// No description provided for @pushForegroundRejected.
  ///
  /// In en, this message translates to:
  /// **'Your school has decided on your subscription.'**
  String get pushForegroundRejected;

  /// No description provided for @liveReinstated.
  ///
  /// In en, this message translates to:
  /// **'Your school gave your subscription back.'**
  String get liveReinstated;

  /// No description provided for @liveRevoked.
  ///
  /// In en, this message translates to:
  /// **'Your school ended your subscription.'**
  String get liveRevoked;

  /// No description provided for @pushForegroundView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get pushForegroundView;

  /// No description provided for @navQrShort.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get navQrShort;

  /// No description provided for @greetMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetMorning;

  /// No description provided for @greetAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetAfternoon;

  /// No description provided for @greetEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetEvening;

  /// No description provided for @stageSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get stageSent;

  /// No description provided for @stageChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get stageChecking;

  /// No description provided for @stageDecided.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get stageDecided;

  /// No description provided for @stageSemantics.
  ///
  /// In en, this message translates to:
  /// **'Step {number} of {total}: {label}'**
  String stageSemantics(String number, String total, String label);

  /// No description provided for @howTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howTitle;

  /// No description provided for @howStep1.
  ///
  /// In en, this message translates to:
  /// **'Choose where you board.'**
  String get howStep1;

  /// No description provided for @howStep2.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of your payment receipt.'**
  String get howStep2;

  /// No description provided for @howStep3.
  ///
  /// In en, this message translates to:
  /// **'Your school checks it and decides.'**
  String get howStep3;

  /// No description provided for @howStep4.
  ///
  /// In en, this message translates to:
  /// **'Show your boarding code and ride.'**
  String get howStep4;

  /// No description provided for @proofAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get proofAdded;

  /// No description provided for @legalTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalTitle;

  /// No description provided for @legalHint.
  ///
  /// In en, this message translates to:
  /// **'Terms and privacy. They are in the app, so you can read them offline.'**
  String get legalHint;

  /// No description provided for @legalTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get legalTerms;

  /// No description provided for @legalTermsBody.
  ///
  /// In en, this message translates to:
  /// **'The rules for using BusIn'**
  String get legalTermsBody;

  /// No description provided for @legalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get legalPrivacy;

  /// No description provided for @legalPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'What we keep about you, and why'**
  String get legalPrivacyBody;

  /// No description provided for @legalAcceptable.
  ///
  /// In en, this message translates to:
  /// **'Acceptable use'**
  String get legalAcceptable;

  /// No description provided for @legalAcceptableBody.
  ///
  /// In en, this message translates to:
  /// **'What is and is not allowed'**
  String get legalAcceptableBody;

  /// No description provided for @legalInShort.
  ///
  /// In en, this message translates to:
  /// **'In short'**
  String get legalInShort;

  /// No description provided for @legalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String legalUpdated(String date);

  /// No description provided for @legalAppliesTo.
  ///
  /// In en, this message translates to:
  /// **'Applies to {school}'**
  String legalAppliesTo(String school);

  /// No description provided for @legalAlsoRead.
  ///
  /// In en, this message translates to:
  /// **'Also read'**
  String get legalAlsoRead;

  /// No description provided for @legalQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions about your data?'**
  String get legalQuestionsTitle;

  /// No description provided for @legalQuestionsBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your school\'s administration. They can correct your details and answer requests about your account.'**
  String get legalQuestionsBody;

  /// No description provided for @legalReadTime.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min read'**
  String legalReadTime(int minutes);

  /// No description provided for @legalOnThisPage.
  ///
  /// In en, this message translates to:
  /// **'On this page'**
  String get legalOnThisPage;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get offlineTitle;

  /// No description provided for @offlineBody.
  ///
  /// In en, this message translates to:
  /// **'Your saved pass still works at the door. Last updated {when}.'**
  String offlineBody(String when);

  /// No description provided for @offlineSavedCopy.
  ///
  /// In en, this message translates to:
  /// **'This is the copy saved on this phone ({when}). Connect to the internet to send or change a request.'**
  String offlineSavedCopy(String when);

  /// No description provided for @offlineNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to send your request.'**
  String get offlineNeedsConnection;

  /// No description provided for @proofUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your payment proof'**
  String get proofUnavailable;

  /// No description provided for @proofUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'It could not be loaded. Tap to try again.'**
  String get proofUnavailableHint;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your school'**
  String get joinTitle;

  /// No description provided for @joinBody.
  ///
  /// In en, this message translates to:
  /// **'Your Google account is not a school email, so ask your school to let you in. An administrator there will check it is you.'**
  String get joinBody;

  /// No description provided for @joinSearch.
  ///
  /// In en, this message translates to:
  /// **'Search for your school'**
  String get joinSearch;

  /// No description provided for @joinSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Name or city'**
  String get joinSearchHint;

  /// No description provided for @joinEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No school accepts your email yet'**
  String get joinEmptyTitle;

  /// No description provided for @joinEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your school email, or ask your school to accept students with other email addresses.'**
  String get joinEmptyBody;

  /// No description provided for @joinNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No school matches your search.'**
  String get joinNoMatch;

  /// No description provided for @joinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask to join {school}?'**
  String joinConfirmTitle(String school);

  /// No description provided for @joinConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'An administrator of {school} will check that you are their student. You can change your request while you wait.'**
  String joinConfirmBody(String school);

  /// No description provided for @joinConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Ask to join'**
  String get joinConfirmAction;

  /// No description provided for @joinSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent.'**
  String get joinSent;

  /// No description provided for @joinTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Wait a few seconds before changing your request.'**
  String get joinTooSoon;

  /// No description provided for @joinDeclinedTitle.
  ///
  /// In en, this message translates to:
  /// **'{school} declined your request'**
  String joinDeclinedTitle(String school);

  /// No description provided for @joinDeclinedNoReason.
  ///
  /// In en, this message translates to:
  /// **'They did not give a reason. You can ask another school, or contact them.'**
  String get joinDeclinedNoReason;

  /// No description provided for @joinDeclinedReason.
  ///
  /// In en, this message translates to:
  /// **'Their reason: {reason}'**
  String joinDeclinedReason(String reason);

  /// No description provided for @waitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {school}'**
  String waitingTitle(String school);

  /// No description provided for @waitingBody.
  ///
  /// In en, this message translates to:
  /// **'You asked to join on {date}. An administrator of your school will check your request; you can use BusIn as soon as they accept it.'**
  String waitingBody(String date);

  /// No description provided for @waitingCheck.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get waitingCheck;

  /// No description provided for @waitingStill.
  ///
  /// In en, this message translates to:
  /// **'Still waiting. We will check again when you come back to the app.'**
  String get waitingStill;

  /// No description provided for @waitingChange.
  ///
  /// In en, this message translates to:
  /// **'Choose another school'**
  String get waitingChange;

  /// No description provided for @joiningTitle.
  ///
  /// In en, this message translates to:
  /// **'You are joining {school}'**
  String joiningTitle(String school);

  /// No description provided for @joiningBody.
  ///
  /// In en, this message translates to:
  /// **'Your school email puts you in this school.'**
  String get joiningBody;

  /// No description provided for @joiningNotMine.
  ///
  /// In en, this message translates to:
  /// **'Not my school?'**
  String get joiningNotMine;

  /// No description provided for @joiningNotMineTitle.
  ///
  /// In en, this message translates to:
  /// **'Not your school?'**
  String get joiningNotMineTitle;

  /// No description provided for @joiningNotMineBody.
  ///
  /// In en, this message translates to:
  /// **'You signed in with an email of {school}. If you study somewhere else, sign out and sign in with your own school\'s account.'**
  String joiningNotMineBody(String school);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Choose your bus days and what BusIn reminds you of.'**
  String get notificationsHint;

  /// No description provided for @notificationsDays.
  ///
  /// In en, this message translates to:
  /// **'My bus days'**
  String get notificationsDays;

  /// No description provided for @notificationsDaysHint.
  ///
  /// In en, this message translates to:
  /// **'Reminders come only on these days.'**
  String get notificationsDaysHint;

  /// No description provided for @notificationsMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning reminder'**
  String get notificationsMorning;

  /// No description provided for @notificationsMorningHint.
  ///
  /// In en, this message translates to:
  /// **'A nudge before you leave home.'**
  String get notificationsMorningHint;

  /// No description provided for @notificationsEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening reminder'**
  String get notificationsEvening;

  /// No description provided for @notificationsEveningHint.
  ///
  /// In en, this message translates to:
  /// **'Almost time to head back to the bus.'**
  String get notificationsEveningHint;

  /// No description provided for @notificationsBusNear.
  ///
  /// In en, this message translates to:
  /// **'Bus near my stop'**
  String get notificationsBusNear;

  /// No description provided for @notificationsBusNearHint.
  ///
  /// In en, this message translates to:
  /// **'When your bus is about this far from your stop.'**
  String get notificationsBusNearHint;

  /// No description provided for @notificationsBusNearMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String notificationsBusNearMinutes(int minutes);

  /// No description provided for @notificationsBoarding.
  ///
  /// In en, this message translates to:
  /// **'A word when I board'**
  String get notificationsBoarding;

  /// No description provided for @notificationsBoardingHint.
  ///
  /// In en, this message translates to:
  /// **'A short message on screen when your code is scanned.'**
  String get notificationsBoardingHint;

  /// No description provided for @notificationsSchool.
  ///
  /// In en, this message translates to:
  /// **'From your school'**
  String get notificationsSchool;

  /// No description provided for @notificationsSchoolHint.
  ///
  /// In en, this message translates to:
  /// **'Changes to your semester or service. Always on.'**
  String get notificationsSchoolHint;

  /// No description provided for @notificationsAt.
  ///
  /// In en, this message translates to:
  /// **'At {time}'**
  String notificationsAt(String time);

  /// No description provided for @notificationsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get notificationsSaved;

  /// No description provided for @notificationsPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications in your phone\'s settings so reminders can show.'**
  String get notificationsPermission;

  /// No description provided for @reminderMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Bus day'**
  String get reminderMorningTitle;

  /// No description provided for @reminderMorningBody.
  ///
  /// In en, this message translates to:
  /// **'Your pass is ready. Open BusIn to see where the bus is.'**
  String get reminderMorningBody;

  /// No description provided for @reminderEveningTitle.
  ///
  /// In en, this message translates to:
  /// **'Heading home?'**
  String get reminderEveningTitle;

  /// No description provided for @reminderEveningBody.
  ///
  /// In en, this message translates to:
  /// **'Time to get ready for the bus. Open BusIn to see where it is.'**
  String get reminderEveningBody;

  /// No description provided for @boardedTitle.
  ///
  /// In en, this message translates to:
  /// **'On board'**
  String get boardedTitle;

  /// No description provided for @boardedEarlier.
  ///
  /// In en, this message translates to:
  /// **'You boarded at {time}'**
  String boardedEarlier(String time);

  /// No description provided for @boardedClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get boardedClose;

  /// No description provided for @streakTitle.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get streakTitle;

  /// No description provided for @streakHint.
  ///
  /// In en, this message translates to:
  /// **'Count the days you take the bus, and join your school\'s leaderboard.'**
  String get streakHint;

  /// No description provided for @streakOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep a streak?'**
  String get streakOnTitle;

  /// No description provided for @streakOnBody.
  ///
  /// In en, this message translates to:
  /// **'BusIn counts the days you board. Rest days and days without buses do not break it; only a bus day you miss does. You will also appear on your school\'s leaderboard as {name}. You can turn it off at any time.'**
  String streakOnBody(String name);

  /// No description provided for @streakOnAction.
  ///
  /// In en, this message translates to:
  /// **'Turn on streaks'**
  String get streakOnAction;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No streak yet} =1{1-day streak} other{{count}-day streak}}'**
  String streakDays(int count);

  /// No description provided for @streakBest.
  ///
  /// In en, this message translates to:
  /// **'Best {count}'**
  String streakBest(int count);

  /// No description provided for @streakRides.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ride this semester} other{{count} rides this semester}}'**
  String streakRides(int count);

  /// No description provided for @streakSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Your streak'**
  String get streakSheetTitle;

  /// No description provided for @streakRode.
  ///
  /// In en, this message translates to:
  /// **'Rode'**
  String get streakRode;

  /// No description provided for @streakMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get streakMissed;

  /// No description provided for @streakRest.
  ///
  /// In en, this message translates to:
  /// **'Rest or no bus'**
  String get streakRest;

  /// No description provided for @streakToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get streakToday;

  /// No description provided for @streakViewLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak view'**
  String get streakViewLabel;

  /// No description provided for @streakTabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get streakTabCalendar;

  /// No description provided for @streakTabBoard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get streakTabBoard;

  /// No description provided for @leaderboardNote.
  ///
  /// In en, this message translates to:
  /// **'Students of your school who keep a streak, by current streak.'**
  String get leaderboardNote;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one is on the board yet.'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get leaderboardYou;

  /// No description provided for @leaderboardRank.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank}'**
  String leaderboardRank(int rank);

  /// No description provided for @pushForegroundBusNear.
  ///
  /// In en, this message translates to:
  /// **'Your bus is a few minutes from your stop.'**
  String get pushForegroundBusNear;

  /// No description provided for @areaTitle.
  ///
  /// In en, this message translates to:
  /// **'My area'**
  String get areaTitle;

  /// No description provided for @areaHint.
  ///
  /// In en, this message translates to:
  /// **'Roughly where you live, to help your school place stops. Optional.'**
  String get areaHint;

  /// No description provided for @areaLaterHint.
  ///
  /// In en, this message translates to:
  /// **'Add it when you are home.'**
  String get areaLaterHint;

  /// No description provided for @areaIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell your school roughly where you live, so it can place stops and plan routes near students. It is rounded to about 500 metres, never tracked, and only you can see it. Your school only sees how many students live in each zone, and how far groups of at least five live from their stops.'**
  String get areaIntro;

  /// No description provided for @areaAtHome.
  ///
  /// In en, this message translates to:
  /// **'Are you home right now?'**
  String get areaAtHome;

  /// No description provided for @areaYesHome.
  ///
  /// In en, this message translates to:
  /// **'Yes, I am home'**
  String get areaYesHome;

  /// No description provided for @areaNoSearch.
  ///
  /// In en, this message translates to:
  /// **'No, search a place'**
  String get areaNoSearch;

  /// No description provided for @areaExplainTitle.
  ///
  /// In en, this message translates to:
  /// **'One reading, roughly'**
  String get areaExplainTitle;

  /// No description provided for @areaExplainBody.
  ///
  /// In en, this message translates to:
  /// **'BusIn will ask for your approximate location and read it once. It is rounded to about 500 metres before it is saved, and the app never reads it again unless you ask.'**
  String get areaExplainBody;

  /// No description provided for @areaContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get areaContinue;

  /// No description provided for @areaNameLabel.
  ///
  /// In en, this message translates to:
  /// **'What do you call this area?'**
  String get areaNameLabel;

  /// No description provided for @areaNameHint.
  ///
  /// In en, this message translates to:
  /// **'For example your neighbourhood'**
  String get areaNameHint;

  /// No description provided for @areaDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get areaDefaultName;

  /// No description provided for @areaSave.
  ///
  /// In en, this message translates to:
  /// **'Save my area'**
  String get areaSave;

  /// No description provided for @areaSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search a neighbourhood or street'**
  String get areaSearchLabel;

  /// No description provided for @areaSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No place found.'**
  String get areaSearchEmpty;

  /// No description provided for @areaNotSeeing.
  ///
  /// In en, this message translates to:
  /// **'Not seeing your street?'**
  String get areaNotSeeing;

  /// No description provided for @areaNotSeeingBody.
  ///
  /// In en, this message translates to:
  /// **'Do it from home instead: BusIn then reads your approximate location once. Your profile will remind you.'**
  String get areaNotSeeingBody;

  /// No description provided for @areaRemindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me at home'**
  String get areaRemindMe;

  /// No description provided for @areaSaved.
  ///
  /// In en, this message translates to:
  /// **'Your area is saved.'**
  String get areaSaved;

  /// No description provided for @areaRemoved.
  ///
  /// In en, this message translates to:
  /// **'Your area was removed.'**
  String get areaRemoved;

  /// No description provided for @areaRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove my area'**
  String get areaRemove;

  /// No description provided for @areaChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get areaChange;

  /// No description provided for @areaRounded.
  ///
  /// In en, this message translates to:
  /// **'Rounded to about 500 metres. Only you can see it.'**
  String get areaRounded;

  /// No description provided for @areaTooFar.
  ///
  /// In en, this message translates to:
  /// **'This place is too far from your school\'s buses.'**
  String get areaTooFar;

  /// No description provided for @areaDenied.
  ///
  /// In en, this message translates to:
  /// **'BusIn cannot read your location. You can search a place instead.'**
  String get areaDenied;

  /// No description provided for @areaDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked for BusIn. Allow it in your phone settings, or search a place.'**
  String get areaDeniedForever;

  /// No description provided for @areaOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get areaOpenSettings;

  /// No description provided for @areaOff.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off on your phone.'**
  String get areaOff;

  /// No description provided for @areaFailed.
  ///
  /// In en, this message translates to:
  /// **'Your location could not be read. Try again or search a place.'**
  String get areaFailed;

  /// No description provided for @areaTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many searches. Wait a minute and try again.'**
  String get areaTooMany;

  /// No description provided for @notificationsSampleSent.
  ///
  /// In en, this message translates to:
  /// **'We sent you an example, so you can see how it looks.'**
  String get notificationsSampleSent;

  /// No description provided for @sampleBusNearTitle.
  ///
  /// In en, this message translates to:
  /// **'Your bus is almost here'**
  String get sampleBusNearTitle;

  /// No description provided for @sampleBusNearBody.
  ///
  /// In en, this message translates to:
  /// **'It is a few minutes from your stop. Open BusIn to follow it.'**
  String get sampleBusNearBody;

  /// No description provided for @areaOsmCredit.
  ///
  /// In en, this message translates to:
  /// **'Places from OpenStreetMap contributors'**
  String get areaOsmCredit;

  /// No description provided for @placeKindArea.
  ///
  /// In en, this message translates to:
  /// **'Neighbourhood'**
  String get placeKindArea;

  /// No description provided for @placeKindVillage.
  ///
  /// In en, this message translates to:
  /// **'Village or locality'**
  String get placeKindVillage;

  /// No description provided for @placeKindStreet.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get placeKindStreet;

  /// No description provided for @placeKindLandmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get placeKindLandmark;

  /// No description provided for @opsAppName.
  ///
  /// In en, this message translates to:
  /// **'BusIn Ops'**
  String get opsAppName;

  /// No description provided for @opsSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Run the trips. Check every boarding.'**
  String get opsSignInTitle;

  /// No description provided for @opsSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Staff sign-in. Use your school Google account to start trips, scan boarding codes and share the bus position.'**
  String get opsSignInSubtitle;

  /// No description provided for @opsNotStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'This app is for staff'**
  String get opsNotStaffTitle;

  /// No description provided for @opsNotStaffBody.
  ///
  /// In en, this message translates to:
  /// **'Students use the BusIn app to show their boarding code. If you should have staff access, ask your school\'s administrator.'**
  String get opsNotStaffBody;

  /// No description provided for @opsProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'BusIn Ops could not load your account'**
  String get opsProblemTitle;

  /// No description provided for @opsTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s trips'**
  String get opsTodayTitle;

  /// No description provided for @opsTodayEmpty.
  ///
  /// In en, this message translates to:
  /// **'No trips are scheduled today.'**
  String get opsTodayEmpty;

  /// No description provided for @opsOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Showing what this phone saved ({when}). Scans are kept and sent when the connection returns.'**
  String opsOfflineBody(String when);

  /// No description provided for @opsTodayMine.
  ///
  /// In en, this message translates to:
  /// **'Assigned to you'**
  String get opsTodayMine;

  /// No description provided for @opsTodayOthers.
  ///
  /// In en, this message translates to:
  /// **'Other trips'**
  String get opsTodayOthers;

  /// No description provided for @opsDeparts.
  ///
  /// In en, this message translates to:
  /// **'Departs {time}'**
  String opsDeparts(String time);

  /// No description provided for @opsTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get opsTripTitle;

  /// No description provided for @opsStart.
  ///
  /// In en, this message translates to:
  /// **'Start trip'**
  String get opsStart;

  /// No description provided for @opsEnd.
  ///
  /// In en, this message translates to:
  /// **'End trip'**
  String get opsEnd;

  /// No description provided for @opsEndTitle.
  ///
  /// In en, this message translates to:
  /// **'End this trip?'**
  String get opsEndTitle;

  /// No description provided for @opsEndBody.
  ///
  /// In en, this message translates to:
  /// **'No one can board it after this, and the bus position stops being shared.'**
  String get opsEndBody;

  /// No description provided for @opsStarted.
  ///
  /// In en, this message translates to:
  /// **'Trip started.'**
  String get opsStarted;

  /// No description provided for @opsEnded.
  ///
  /// In en, this message translates to:
  /// **'Trip ended.'**
  String get opsEnded;

  /// No description provided for @opsAssignedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Assigned to other staff members. Only the driver, the assistant or an administrator can start it.'**
  String get opsAssignedElsewhere;

  /// No description provided for @opsBusBusy.
  ///
  /// In en, this message translates to:
  /// **'This bus is already on another trip. End that one first.'**
  String get opsBusBusy;

  /// No description provided for @opsNotToday.
  ///
  /// In en, this message translates to:
  /// **'This trip is not scheduled for today.'**
  String get opsNotToday;

  /// No description provided for @opsNotScheduled.
  ///
  /// In en, this message translates to:
  /// **'This trip has already started or is over.'**
  String get opsNotScheduled;

  /// No description provided for @opsBoarded.
  ///
  /// In en, this message translates to:
  /// **'{count} of {capacity} on board'**
  String opsBoarded(int count, int capacity);

  /// No description provided for @opsScannerSoon.
  ///
  /// In en, this message translates to:
  /// **'Start the trip to scan boarding codes.'**
  String get opsScannerSoon;

  /// No description provided for @opsProblemBody.
  ///
  /// In en, this message translates to:
  /// **'Check the connection and try again. The first sign-in on a phone needs a connection.'**
  String get opsProblemBody;

  /// No description provided for @opsScan.
  ///
  /// In en, this message translates to:
  /// **'Scan boarding codes'**
  String get opsScan;

  /// No description provided for @opsScanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the student\'s boarding code.'**
  String get opsScanHint;

  /// No description provided for @opsResultBoarded.
  ///
  /// In en, this message translates to:
  /// **'On board'**
  String get opsResultBoarded;

  /// No description provided for @opsResultAlready.
  ///
  /// In en, this message translates to:
  /// **'Already on board'**
  String get opsResultAlready;

  /// No description provided for @opsResultInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not a valid boarding code'**
  String get opsResultInvalid;

  /// No description provided for @opsResultExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Ask the student to reopen their code.'**
  String get opsResultExpired;

  /// No description provided for @opsResultNotOnList.
  ///
  /// In en, this message translates to:
  /// **'Not on today\'s list. No valid subscription for today.'**
  String get opsResultNotOnList;

  /// No description provided for @opsResultNoKeys.
  ///
  /// In en, this message translates to:
  /// **'Today\'s list is missing. Connect to the internet to download it.'**
  String get opsResultNoKeys;

  /// No description provided for @opsResultChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking with the server...'**
  String get opsResultChecking;

  /// No description provided for @opsResultNotVerified.
  ///
  /// In en, this message translates to:
  /// **'This account is not active.'**
  String get opsResultNotVerified;

  /// No description provided for @opsResultNoSubscription.
  ///
  /// In en, this message translates to:
  /// **'No valid subscription for today.'**
  String get opsResultNoSubscription;

  /// No description provided for @opsResultUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not a student of this school.'**
  String get opsResultUnknown;

  /// No description provided for @opsKeysStatus.
  ///
  /// In en, this message translates to:
  /// **'Today\'s list: {count} riders, updated {time}'**
  String opsKeysStatus(int count, String time);

  /// No description provided for @opsKeysMissing.
  ///
  /// In en, this message translates to:
  /// **'No list for today yet. Connect to download it.'**
  String get opsKeysMissing;

  /// No description provided for @opsKeysRefresh.
  ///
  /// In en, this message translates to:
  /// **'Update the list'**
  String get opsKeysRefresh;

  /// No description provided for @opsPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All scans sent} =1{1 scan waiting to send} other{{count} scans waiting to send}}'**
  String opsPending(int count);

  /// No description provided for @opsRefusedLaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Refused by the server after boarding'**
  String get opsRefusedLaterTitle;

  /// No description provided for @opsRefusedLaterBody.
  ///
  /// In en, this message translates to:
  /// **'The phone let these students on, but the server did not accept the boarding (for example a subscription revoked since this morning).'**
  String get opsRefusedLaterBody;

  /// No description provided for @opsCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow the camera to scan boarding codes.'**
  String get opsCameraDenied;

  /// No description provided for @opsLocationWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Where each boarding happens'**
  String get opsLocationWhyTitle;

  /// No description provided for @opsLocationWhyBody.
  ///
  /// In en, this message translates to:
  /// **'BusIn Ops records the stop where each student boards, from this phone\'s location while the scanner is open. It is used for this trip and for planning stops, never to follow you.'**
  String get opsLocationWhyBody;

  /// No description provided for @opsLocationContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get opsLocationContinue;

  /// No description provided for @opsSignOutPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 scan is still waiting to send. Connect to the internet first, then sign out.} other{{count} scans are still waiting to send. Connect to the internet first, then sign out.}}'**
  String opsSignOutPending(int count);

  /// No description provided for @opsProfileOpen.
  ///
  /// In en, this message translates to:
  /// **'Profile and settings'**
  String get opsProfileOpen;

  /// No description provided for @opsSettingsScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get opsSettingsScanning;

  /// No description provided for @opsSettingsVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on each scan'**
  String get opsSettingsVibrate;

  /// No description provided for @opsSettingsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound on each scan'**
  String get opsSettingsSound;

  /// No description provided for @opsSettingsSoundHint.
  ///
  /// In en, this message translates to:
  /// **'A click when a student is let on, an alert when refused.'**
  String get opsSettingsSoundHint;

  /// No description provided for @opsSettingsDriving.
  ///
  /// In en, this message translates to:
  /// **'Driver mode'**
  String get opsSettingsDriving;

  /// No description provided for @opsSettingsOfferShare.
  ///
  /// In en, this message translates to:
  /// **'Offer to share the bus position when I start a trip'**
  String get opsSettingsOfferShare;

  /// No description provided for @opsSettingsOfferShareHint.
  ///
  /// In en, this message translates to:
  /// **'You can always turn sharing on from the trip.'**
  String get opsSettingsOfferShareHint;

  /// No description provided for @opsSettingsPhone.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get opsSettingsPhone;

  /// No description provided for @opsSettingsSendNow.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get opsSettingsSendNow;

  /// No description provided for @opsSettingsAllSent.
  ///
  /// In en, this message translates to:
  /// **'Everything is sent.'**
  String get opsSettingsAllSent;

  /// No description provided for @opsSettingsNotSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent yet: no connection. It will go when the connection is back.'**
  String get opsSettingsNotSent;

  /// No description provided for @opsAtStop.
  ///
  /// In en, this message translates to:
  /// **'At {stop}'**
  String opsAtStop(String stop);

  /// No description provided for @opsShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share the bus position'**
  String get opsShareTitle;

  /// No description provided for @opsShareBody.
  ///
  /// In en, this message translates to:
  /// **'Students following this bus see where it is, and those waiting get a push when it is a few minutes away.'**
  String get opsShareBody;

  /// No description provided for @opsShareLast.
  ///
  /// In en, this message translates to:
  /// **'Sharing. Last sent {time}'**
  String opsShareLast(String time);

  /// No description provided for @opsShareStarting.
  ///
  /// In en, this message translates to:
  /// **'Sharing. Waiting for the first position...'**
  String get opsShareStarting;

  /// No description provided for @opsShareWaiting.
  ///
  /// In en, this message translates to:
  /// **'No connection. Sharing resumes by itself.'**
  String get opsShareWaiting;

  /// No description provided for @opsShareOff.
  ///
  /// In en, this message translates to:
  /// **'Not sharing'**
  String get opsShareOff;

  /// No description provided for @opsShareDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow location to share the bus position.'**
  String get opsShareDenied;

  /// No description provided for @opsShareWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharing the bus position'**
  String get opsShareWhyTitle;

  /// No description provided for @opsShareWhyBody.
  ///
  /// In en, this message translates to:
  /// **'While the trip runs, this phone sends its position every 10 seconds, also with the screen off. A notification shows while it does. It stops when the trip ends or when you turn it off.'**
  String get opsShareWhyBody;

  /// No description provided for @opsShareNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'BusIn Ops is sharing the bus position'**
  String get opsShareNotificationTitle;

  /// No description provided for @opsShareNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Students can follow this bus until the trip ends.'**
  String get opsShareNotificationText;

  /// No description provided for @opsShareNotYours.
  ///
  /// In en, this message translates to:
  /// **'The driver or the assistant of this trip shares its position.'**
  String get opsShareNotYours;

  /// No description provided for @opsPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is waiting for approval'**
  String get opsPendingTitle;

  /// No description provided for @opsPendingBody.
  ///
  /// In en, this message translates to:
  /// **'A school administrator has to verify your account before you can use BusIn Ops. Ask them, then open the app again.'**
  String get opsPendingBody;

  /// No description provided for @opsFieldStart.
  ///
  /// In en, this message translates to:
  /// **'Start a trip that is not listed'**
  String get opsFieldStart;

  /// No description provided for @opsFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a trip'**
  String get opsFieldTitle;

  /// No description provided for @opsFieldBody.
  ///
  /// In en, this message translates to:
  /// **'Use this when nobody scheduled the trip. It is marked as started in the field, and your school\'s administrators can see it.'**
  String get opsFieldBody;

  /// No description provided for @opsFieldBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get opsFieldBus;

  /// No description provided for @opsFieldNoBuses.
  ///
  /// In en, this message translates to:
  /// **'No bus is free right now. Buses out of service or already on a trip are not listed.'**
  String get opsFieldNoBuses;

  /// No description provided for @opsFieldDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get opsFieldDirection;

  /// No description provided for @opsFieldRole.
  ///
  /// In en, this message translates to:
  /// **'You are'**
  String get opsFieldRole;

  /// No description provided for @opsFieldRoleDriver.
  ///
  /// In en, this message translates to:
  /// **'The driver'**
  String get opsFieldRoleDriver;

  /// No description provided for @opsFieldRoleAssistant.
  ///
  /// In en, this message translates to:
  /// **'The assistant'**
  String get opsFieldRoleAssistant;

  /// No description provided for @opsFieldOtherDriver.
  ///
  /// In en, this message translates to:
  /// **'Who is the driver?'**
  String get opsFieldOtherDriver;

  /// No description provided for @opsFieldOtherAssistant.
  ///
  /// In en, this message translates to:
  /// **'Who is the assistant?'**
  String get opsFieldOtherAssistant;

  /// No description provided for @opsFieldOtherNone.
  ///
  /// In en, this message translates to:
  /// **'Nobody yet'**
  String get opsFieldOtherNone;

  /// No description provided for @opsFieldOtherHint.
  ///
  /// In en, this message translates to:
  /// **'They are added to the trip and told, and can start it, scan and share the position.'**
  String get opsFieldOtherHint;

  /// No description provided for @opsFieldConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start the trip'**
  String get opsFieldConfirm;

  /// No description provided for @opsFieldStarted.
  ///
  /// In en, this message translates to:
  /// **'Trip started. It is marked as started in the field.'**
  String get opsFieldStarted;

  /// No description provided for @opsFieldBadge.
  ///
  /// In en, this message translates to:
  /// **'Started in the field'**
  String get opsFieldBadge;

  /// No description provided for @opsFieldScheduled.
  ///
  /// In en, this message translates to:
  /// **'A trip for this bus and direction is already scheduled today. Start that one from the list.'**
  String get opsFieldScheduled;

  /// No description provided for @opsFieldBusBusy.
  ///
  /// In en, this message translates to:
  /// **'This bus is already on a trip.'**
  String get opsFieldBusBusy;

  /// No description provided for @opsFieldOutOfService.
  ///
  /// In en, this message translates to:
  /// **'This bus is out of service.'**
  String get opsFieldOutOfService;

  /// No description provided for @opsFieldLimit.
  ///
  /// In en, this message translates to:
  /// **'You have started the most trips allowed today. Ask an administrator to schedule the next.'**
  String get opsFieldLimit;

  /// No description provided for @opsFieldOff.
  ///
  /// In en, this message translates to:
  /// **'Your school has turned this off.'**
  String get opsFieldOff;

  /// No description provided for @opsFieldCrew.
  ///
  /// In en, this message translates to:
  /// **'That colleague cannot be added. Pick someone else.'**
  String get opsFieldCrew;

  /// No description provided for @opsShareStandby.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s phone is sharing the bus position. This phone takes over by itself if it goes quiet.'**
  String opsShareStandby(String name);
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
