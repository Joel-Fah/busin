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
