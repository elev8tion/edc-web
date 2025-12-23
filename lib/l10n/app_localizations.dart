import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('es')
  ];

  /// First part of app name on splash screen
  ///
  /// In en, this message translates to:
  /// **'EVERYDAY'**
  String get appName;

  /// Second part of app name on splash screen
  ///
  /// In en, this message translates to:
  /// **'CHRISTIAN'**
  String get appNameSecond;

  /// App tagline on splash screen
  ///
  /// In en, this message translates to:
  /// **'Faith-guided wisdom for life\'s moments'**
  String get tagline;

  /// Loading message on splash screen
  ///
  /// In en, this message translates to:
  /// **'Preparing your spiritual journey'**
  String get loadingJourney;

  /// App version number
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get version;

  /// Footer message on splash screen
  ///
  /// In en, this message translates to:
  /// **'Built with ❤️ for faith'**
  String get builtWithFaith;

  /// Onboarding subtitle
  ///
  /// In en, this message translates to:
  /// **'Your faith-guided companion for life\'s moments'**
  String get faithGuidedCompanion;

  /// Feature title
  ///
  /// In en, this message translates to:
  /// **'AI Biblical Guidance'**
  String get aiBiblicalGuidance;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Get personalized Bible verses and wisdom for any situation'**
  String get aiBiblicalGuidanceDesc;

  /// Feature title
  ///
  /// In en, this message translates to:
  /// **'Daily Verses'**
  String get dailyVerses;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Receive encouraging Scripture at 9:30 AM or your preferred time'**
  String get dailyVersesDesc;

  /// Feature title
  ///
  /// In en, this message translates to:
  /// **'Complete Privacy'**
  String get completePrivacy;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'All your spiritual conversations stay on your device'**
  String get completePrivacyDesc;

  /// Call to action button
  ///
  /// In en, this message translates to:
  /// **'Begin Your Journey'**
  String get beginYourJourney;

  /// Skip onboarding option
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// Auth screen title
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Auth screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your spiritual journey'**
  String get signInToContinue;

  /// Privacy assurance message
  ///
  /// In en, this message translates to:
  /// **'Your spiritual conversations remain completely private on your device'**
  String get privacyNote;

  /// Sign in button and tab
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Sign up button and tab
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Create account button
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Biometric authentication button
  ///
  /// In en, this message translates to:
  /// **'Use Biometric'**
  String get useBiometric;

  /// Terms agreement message
  ///
  /// In en, this message translates to:
  /// **'By creating an account, you agree to keep your spiritual journey private and secure.'**
  String get agreeTerms;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// Email format validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// Name validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// Divider text between options
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// Morning greeting
  ///
  /// In en, this message translates to:
  /// **'Rise and shine'**
  String get riseAndShine;

  /// Afternoon greeting
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// Evening greeting
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// Home screen subtitle
  ///
  /// In en, this message translates to:
  /// **'How can I encourage you today?'**
  String get howCanIEncourage;

  /// Streak stat label
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get dayStreak;

  /// Prayers stat label
  ///
  /// In en, this message translates to:
  /// **'Prayers'**
  String get prayers;

  /// Verses read stat label
  ///
  /// In en, this message translates to:
  /// **'Verses Read'**
  String get versesRead;

  /// Devotionals stat label
  ///
  /// In en, this message translates to:
  /// **'Devotionals'**
  String get devotionals;

  /// Feature card title
  ///
  /// In en, this message translates to:
  /// **'AI Guidance'**
  String get aiGuidance;

  /// Feature card description
  ///
  /// In en, this message translates to:
  /// **'Get biblical wisdom for any situation you\'re facing'**
  String get aiGuidanceDesc;

  /// Biblical Chat feature title
  ///
  /// In en, this message translates to:
  /// **'Biblical Chat'**
  String get biblicalChat;

  /// Biblical Chat feature description
  ///
  /// In en, this message translates to:
  /// **'Get biblical wisdom for any situation you\'re facing'**
  String get biblicalChatDesc;

  /// Feature card title
  ///
  /// In en, this message translates to:
  /// **'Devotionals'**
  String get dailyDevotional;

  /// Feature card description
  ///
  /// In en, this message translates to:
  /// **'Grow closer to God with daily reflections'**
  String get dailyDevotionalDesc;

  /// Feature card title and screen title
  ///
  /// In en, this message translates to:
  /// **'Prayer Journal'**
  String get prayerJournal;

  /// Feature card description
  ///
  /// In en, this message translates to:
  /// **'Track your prayers and see God\'s faithfulness'**
  String get prayerJournalDesc;

  /// Feature card title and screen title
  ///
  /// In en, this message translates to:
  /// **'Reading Plans'**
  String get readingPlans;

  /// Reading plan notification setting
  ///
  /// In en, this message translates to:
  /// **'Reading Plan'**
  String get readingPlan;

  /// Feature card description
  ///
  /// In en, this message translates to:
  /// **'Structured Bible reading with daily guidance'**
  String get readingPlansDesc;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Navigation label for home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeScreen;

  /// Quick action label
  ///
  /// In en, this message translates to:
  /// **'Read Bible'**
  String get readBible;

  /// Quick action label
  ///
  /// In en, this message translates to:
  /// **'Bible Library'**
  String get bibleLibrary;

  /// Quick action label
  ///
  /// In en, this message translates to:
  /// **'Add Prayer'**
  String get addPrayer;

  /// Stat card label for saved verses count
  ///
  /// In en, this message translates to:
  /// **'Saved Verses'**
  String get savedVerses;

  /// Short label for saved verses tab (used at large text sizes)
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// Tooltip message for FAB menu
  ///
  /// In en, this message translates to:
  /// **'Tap here to navigate ✨'**
  String get fabTooltipMessage;

  /// Tutorial message for adding prayers via FAB button
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a new prayer ✨'**
  String get prayerCardTutorial;

  /// Tutorial message for Bible browser search
  ///
  /// In en, this message translates to:
  /// **'Search books or browse by testament ✨'**
  String get bibleBrowserTutorial;

  /// Tutorial message for devotional verse interactions
  ///
  /// In en, this message translates to:
  /// **'Tap verse references to read full passages ✨'**
  String get devotionalVerseTutorial;

  /// Tutorial message for chat message interactions
  ///
  /// In en, this message translates to:
  /// **'Long-press AI messages for options ✨'**
  String get chatTutorial;

  /// Tutorial message for reading plan completion
  ///
  /// In en, this message translates to:
  /// **'Tap to mark chapters complete ✨'**
  String get readingPlanTutorial;

  /// Quick action label
  ///
  /// In en, this message translates to:
  /// **'Share Verse'**
  String get shareVerse;

  /// Settings screen title and menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Settings screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Customize your app'**
  String get settingsSubtitle;

  /// Profile screen title and menu item
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Daily verse section title
  ///
  /// In en, this message translates to:
  /// **'Verse of the Day'**
  String get verseOfTheDay;

  /// Category badge
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get comfort;

  /// Chat CTA button
  ///
  /// In en, this message translates to:
  /// **'Start Spiritual Conversation'**
  String get startSpiritualConversation;

  /// Chat screen title
  ///
  /// In en, this message translates to:
  /// **'Biblical AI Guidance'**
  String get biblicalAIGuidance;

  /// Chat subtitle
  ///
  /// In en, this message translates to:
  /// **'Powered by local AI'**
  String get poweredByLocalAI;

  /// Chat input placeholder
  ///
  /// In en, this message translates to:
  /// **'Ask for biblical guidance...'**
  String get askForBiblicalGuidance;

  /// Welcome message greeting
  ///
  /// In en, this message translates to:
  /// **'Peace be with you! 🙏'**
  String get peaceBeWithYou;

  /// Welcome message content
  ///
  /// In en, this message translates to:
  /// **'I\'m here to provide intelligent scripture support directly from the word itself, for everyday Christian questions. Feel free to ask me about:\n\n• Scripture interpretation\n• Prayer requests\n• Life challenges\n• Faith questions\n• Daily encouragement\n\nHow can I help you today?'**
  String get chatWelcomeMessage;

  /// Prayer journal subtitle
  ///
  /// In en, this message translates to:
  /// **'Plan Pray Reflect'**
  String get bringRequestsToGod;

  /// Tab label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Tab label
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get answered;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No Active Prayers'**
  String get noActivePrayers;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Start your prayer journey by adding your first prayer request'**
  String get startPrayerJourney;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No Answered Prayers Yet'**
  String get noAnsweredPrayersYet;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Answered prayers appear here'**
  String get markPrayersAnswered;

  /// Menu action
  ///
  /// In en, this message translates to:
  /// **'Mark as Answered'**
  String get markAsAnswered;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Answered prayer label
  ///
  /// In en, this message translates to:
  /// **'How God Answered:'**
  String get howGodAnswered;

  /// Answered date label
  ///
  /// In en, this message translates to:
  /// **'Answered {date}'**
  String answered_date(String date);

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Prayer Request'**
  String get addPrayerRequest;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Title field placeholder
  ///
  /// In en, this message translates to:
  /// **'What are you praying for?'**
  String get whatArePrayingFor;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Description field placeholder
  ///
  /// In en, this message translates to:
  /// **'Share more details about your prayer request...'**
  String get shareMoreDetails;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Add Prayer'**
  String get addPrayerButton;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Mark Answered'**
  String get markAnswered;

  /// Answer description prompt
  ///
  /// In en, this message translates to:
  /// **'How did God answer this prayer?'**
  String get howDidGodAnswer;

  /// Answer field placeholder
  ///
  /// In en, this message translates to:
  /// **'Share how God answered your prayer...'**
  String get shareHowGodAnswered;

  /// Prayer category
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// Prayer category
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// Prayer category
  ///
  /// In en, this message translates to:
  /// **'Work/Career'**
  String get workCareer;

  /// Prayer category
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get protection;

  /// Prayer category
  ///
  /// In en, this message translates to:
  /// **'Guidance'**
  String get guidance;

  /// Prayer category
  ///
  /// In en, this message translates to:
  /// **'Gratitude'**
  String get gratitude;

  /// Prayer category
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// Category
  ///
  /// In en, this message translates to:
  /// **'Faith'**
  String get faith;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @ministry.
  ///
  /// In en, this message translates to:
  /// **'Ministry'**
  String get ministry;

  /// No description provided for @thanksgiving.
  ///
  /// In en, this message translates to:
  /// **'Thanksgiving'**
  String get thanksgiving;

  /// No description provided for @intercession.
  ///
  /// In en, this message translates to:
  /// **'Intercession'**
  String get intercession;

  /// No description provided for @finances.
  ///
  /// In en, this message translates to:
  /// **'Finances'**
  String get finances;

  /// No description provided for @relationships.
  ///
  /// In en, this message translates to:
  /// **'Relationships'**
  String get relationships;

  /// Date label for today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Date label for yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Relative date
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// Streak count
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String dayStreakCount(int count);

  /// Completion count
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String completed(int count);

  /// Day indicator
  ///
  /// In en, this message translates to:
  /// **'Day {number}'**
  String dayNumber(int number);

  /// Verse section title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Verse'**
  String get todaysVerse;

  /// Reflection section title
  ///
  /// In en, this message translates to:
  /// **'Reflection'**
  String get reflection;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompleted;

  /// Completion status
  ///
  /// In en, this message translates to:
  /// **'Devotional Completed'**
  String get devotionalCompleted;

  /// Completion date
  ///
  /// In en, this message translates to:
  /// **'Completed today'**
  String get completedToday;

  /// Completion date
  ///
  /// In en, this message translates to:
  /// **'Completed yesterday'**
  String get completedYesterday;

  /// Completion date
  ///
  /// In en, this message translates to:
  /// **'Completed {count} days ago'**
  String completedDaysAgo(int count);

  /// Navigation button
  ///
  /// In en, this message translates to:
  /// **'Previous Day'**
  String get previousDay;

  /// Navigation button
  ///
  /// In en, this message translates to:
  /// **'Next Day'**
  String get nextDay;

  /// Progress section title
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// Progress counter
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String progressCount(int current, int total);

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No Devotionals Available'**
  String get noDevotionalsAvailable;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Check back later for daily devotionals'**
  String get checkBackForDevotionals;

  /// Error state title
  ///
  /// In en, this message translates to:
  /// **'Error Loading Devotionals'**
  String get errorLoadingDevotionals;

  /// Reading plan subtitle
  ///
  /// In en, this message translates to:
  /// **'Grow in God\'s word daily'**
  String get growInGodsWord;

  /// Tab label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTab;

  /// Tab label
  ///
  /// In en, this message translates to:
  /// **'My Plans'**
  String get myPlans;

  /// Tab label
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No Active Reading Plan'**
  String get noActiveReadingPlan;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Start a reading plan to see today\'s readings here'**
  String get startReadingPlanPrompt;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Explore Plans'**
  String get explorePlans;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Readings'**
  String get todaysReadings;

  /// Empty readings title
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// Empty readings subtitle
  ///
  /// In en, this message translates to:
  /// **'No readings scheduled for today'**
  String get noReadingsToday;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No Active Plans'**
  String get noActivePlans;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Start a reading plan to track your progress'**
  String get startReadingPlanToTrack;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueReading;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Start Plan'**
  String get startPlan;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Marked as incomplete'**
  String get markedAsIncomplete;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Great job! Keep up the good work!'**
  String get greatJobKeepUp;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Reading plan started! Let\'s begin your journey.'**
  String get readingPlanStarted;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Error starting plan: {error}'**
  String errorStartingPlan(String error);

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Reset Reading Plan?'**
  String get resetReadingPlan;

  /// Dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset \"{planTitle}\"? All progress will be lost.'**
  String resetPlanConfirmation(String planTitle);

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Reading plan has been reset'**
  String get readingPlanReset;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Error resetting plan: {error}'**
  String errorResettingPlan(String error);

  /// Error state title
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong'**
  String get oopsSomethingWrong;

  /// Progress percentage
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String percentComplete(String percent);

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Verse Library'**
  String get verseLibrary;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Find comfort in God\'s word'**
  String get findComfortInGodsWord;

  /// Search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search verses or references...'**
  String get searchVersesOrReferences;

  /// Category filter
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Category
  ///
  /// In en, this message translates to:
  /// **'Hope'**
  String get hope;

  /// Category
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get love;

  /// Category
  ///
  /// In en, this message translates to:
  /// **'Peace'**
  String get peace;

  /// Category
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get strength;

  /// Category
  ///
  /// In en, this message translates to:
  /// **'Wisdom'**
  String get wisdom;

  /// Category
  ///
  /// In en, this message translates to:
  /// **'Forgiveness'**
  String get forgiveness;

  /// Tab label
  ///
  /// In en, this message translates to:
  /// **'All Verses'**
  String get allVerses;

  /// Tab label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Tab label with count
  ///
  /// In en, this message translates to:
  /// **'All Verses ({count})'**
  String allVersesCount(int count);

  /// Tab label with count
  ///
  /// In en, this message translates to:
  /// **'Favorites ({count})'**
  String favoritesCount(int count);

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No verses found'**
  String get noVersesFound;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or category filter'**
  String get tryAdjustingSearch;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'No verses available in this category'**
  String get noVersesInCategory;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No favorite verses yet'**
  String get noFavoriteVersesYet;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon on any verse to add it to your favorites'**
  String get tapHeartToFavorite;

  /// Bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Share Verse'**
  String get shareVerseTitle;

  /// Share option
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyToClipboard;

  /// Share option
  ///
  /// In en, this message translates to:
  /// **'Share with Friends'**
  String get shareWithFriends;

  /// Share option
  ///
  /// In en, this message translates to:
  /// **'Create Image Quote'**
  String get createImageQuote;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Setting label
  ///
  /// In en, this message translates to:
  /// **'Daily Notifications'**
  String get dailyNotifications;

  /// Setting description
  ///
  /// In en, this message translates to:
  /// **'Receive daily spiritual reminders'**
  String get dailyNotificationsDesc;

  /// Setting label
  ///
  /// In en, this message translates to:
  /// **'Prayer Reminders'**
  String get prayerReminders;

  /// Setting description
  ///
  /// In en, this message translates to:
  /// **'Get reminded to pray throughout the day'**
  String get prayerRemindersDesc;

  /// Setting label
  ///
  /// In en, this message translates to:
  /// **'Verse of the Day'**
  String get verseOfTheDaySetting;

  /// Setting description
  ///
  /// In en, this message translates to:
  /// **'Daily Bible verse notifications'**
  String get verseOfTheDayDesc;

  /// Daily devotional notification description
  ///
  /// In en, this message translates to:
  /// **'Morning inspiration to start your day'**
  String get dailyDevotionalNotificationDesc;

  /// Prayer reminders notification description
  ///
  /// In en, this message translates to:
  /// **'Gentle nudges to pause and pray'**
  String get prayerRemindersNotificationDesc;

  /// Verse of the day notification description
  ///
  /// In en, this message translates to:
  /// **'Daily scripture to reflect on'**
  String get verseOfTheDayNotificationDesc;

  /// Reading plan notification description
  ///
  /// In en, this message translates to:
  /// **'Stay on track with your Bible reading'**
  String get readingPlanNotificationDesc;

  /// Subscription section title
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// Manage subscription setting
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// World English Bible version abbreviation
  ///
  /// In en, this message translates to:
  /// **'WEB'**
  String get webBibleVersion;

  /// Appearance section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Delete all data action
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// Delete all data description
  ///
  /// In en, this message translates to:
  /// **'⚠️ Permanently delete all your data'**
  String get deleteAllDataDesc;

  /// App lock setting
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// App lock description
  ///
  /// In en, this message translates to:
  /// **'Require Face ID / Touch ID to open app'**
  String get appLockDesc;

  /// Set time button text
  ///
  /// In en, this message translates to:
  /// **'Set Time'**
  String get setTime;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Bible Settings'**
  String get bibleSettings;

  /// Setting label
  ///
  /// In en, this message translates to:
  /// **'Bible Version'**
  String get bibleVersion;

  /// Setting description
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred translation'**
  String get bibleVersionDesc;

  /// Setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Setting description
  ///
  /// In en, this message translates to:
  /// **'Select app language'**
  String get languageDesc;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// Setting label
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSize;

  /// Setting description
  ///
  /// In en, this message translates to:
  /// **'Adjust reading text size for better readability'**
  String get textSizeDesc;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get dataPrivacy;

  /// Setting label
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// Setting description
  ///
  /// In en, this message translates to:
  /// **'Use app without internet connection'**
  String get offlineModeDesc;

  /// Setting action
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// Setting description
  ///
  /// In en, this message translates to:
  /// **'Free up storage space'**
  String get clearCacheDesc;

  /// Setting action
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// Setting description
  ///
  /// In en, this message translates to:
  /// **'Backup your prayers and notes'**
  String get exportDataDesc;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Setting action
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpFAQ;

  /// Setting description
  ///
  /// In en, this message translates to:
  /// **'Get answers to common questions'**
  String get helpFAQDesc;

  /// Setting action
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// Setting description
  ///
  /// In en, this message translates to:
  /// **'Get help with technical issues'**
  String get contactSupportDesc;

  /// Setting action
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// Setting description
  ///
  /// In en, this message translates to:
  /// **'Share your feedback on the App Store'**
  String get rateAppDesc;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Info label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// Info label
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get build;

  /// Setting action
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Setting description
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get privacyPolicyDesc;

  /// Setting action
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Setting description
  ///
  /// In en, this message translates to:
  /// **'Read terms and conditions'**
  String get termsOfServiceDesc;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get clearCacheDialogTitle;

  /// Dialog message
  ///
  /// In en, this message translates to:
  /// **'This will free up storage space but may require re-downloading some content.'**
  String get clearCacheDialogMessage;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get cacheCleared;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Data export started - you will be notified when complete'**
  String get dataExportStarted;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpDialogTitle;

  /// Dialog message
  ///
  /// In en, this message translates to:
  /// **'For help and support, please visit our website or contact us through the app.'**
  String get helpDialogMessage;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Opening email client...'**
  String get openingEmailClient;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Opening App Store...'**
  String get openingAppStore;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Opening privacy policy...'**
  String get openingPrivacyPolicy;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Opening terms of service...'**
  String get openingTermsOfService;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Your Spiritual Journey'**
  String get yourSpiritualJourney;

  /// Stat label
  ///
  /// In en, this message translates to:
  /// **'Prayer Streak'**
  String get prayerStreak;

  /// Stat label
  ///
  /// In en, this message translates to:
  /// **'Total Prayers'**
  String get totalPrayers;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// Achievement progress
  ///
  /// In en, this message translates to:
  /// **'{unlocked}/{total}'**
  String achievementCount(int unlocked, int total);

  /// Achievement title
  ///
  /// In en, this message translates to:
  /// **'Prayer Warrior'**
  String get prayerWarrior;

  /// Achievement description
  ///
  /// In en, this message translates to:
  /// **'Prayed for 7 days in a row'**
  String get prayerWarriorDesc;

  /// Achievement title
  ///
  /// In en, this message translates to:
  /// **'Bible Scholar'**
  String get bibleScholar;

  /// Achievement description
  ///
  /// In en, this message translates to:
  /// **'Read 100 verses'**
  String get bibleScholarDesc;

  /// Achievement title
  ///
  /// In en, this message translates to:
  /// **'Faithful Friend'**
  String get faithfulFriend;

  /// Achievement description
  ///
  /// In en, this message translates to:
  /// **'Complete 30 devotionals'**
  String get faithfulFriendDesc;

  /// Achievement title
  ///
  /// In en, this message translates to:
  /// **'Scripture Master'**
  String get scriptureMaster;

  /// Achievement description
  ///
  /// In en, this message translates to:
  /// **'Complete 5 reading plans'**
  String get scriptureMasterDesc;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Menu item
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// Menu item
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Button and dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// Field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Sign Out?'**
  String get signOutQuestion;

  /// Dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmation;

  /// Member badge
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// Name deletion success message
  ///
  /// In en, this message translates to:
  /// **'Name deleted successfully'**
  String get nameDeleted;

  /// Achievement title
  ///
  /// In en, this message translates to:
  /// **'Unbroken'**
  String get achievementUnbroken;

  /// Achievement description
  ///
  /// In en, this message translates to:
  /// **'Maintain a 7-day prayer streak'**
  String get achievementUnbrokenDesc;

  /// Achievement title
  ///
  /// In en, this message translates to:
  /// **'Relentless'**
  String get achievementRelentless;

  /// Achievement description
  ///
  /// In en, this message translates to:
  /// **'Log 50 prayers'**
  String get achievementRelentlessDesc;

  /// Achievement title
  ///
  /// In en, this message translates to:
  /// **'Curator'**
  String get achievementCurator;

  /// Achievement description
  ///
  /// In en, this message translates to:
  /// **'Save 100 Bible verses'**
  String get achievementCuratorDesc;

  /// Achievement title
  ///
  /// In en, this message translates to:
  /// **'Daily Bread'**
  String get achievementDailyBread;

  /// Achievement description
  ///
  /// In en, this message translates to:
  /// **'Complete 30 devotionals'**
  String get achievementDailyBreadDesc;

  /// Achievement title
  ///
  /// In en, this message translates to:
  /// **'Deep Diver'**
  String get achievementDeepDiver;

  /// Achievement description
  ///
  /// In en, this message translates to:
  /// **'Start 5 reading plans'**
  String get achievementDeepDiverDesc;

  /// Achievement title
  ///
  /// In en, this message translates to:
  /// **'Disciple'**
  String get achievementDisciple;

  /// Achievement description
  ///
  /// In en, this message translates to:
  /// **'Share 10 items (verses, chats, prayers, or devotionals)'**
  String get achievementDiscipleDesc;

  /// Email error message
  ///
  /// In en, this message translates to:
  /// **'Could not open email app'**
  String get couldNotOpenEmailApp;

  /// Email error with details
  ///
  /// In en, this message translates to:
  /// **'Error opening email: {error}'**
  String errorOpeningEmailWithError(String error);

  /// Bible browser screen title
  ///
  /// In en, this message translates to:
  /// **'Bible Browser'**
  String get bibleBrowser;

  /// Bible browser subtitle
  ///
  /// In en, this message translates to:
  /// **'Read any chapter freely'**
  String get readAnyChapterFreely;

  /// Search input placeholder
  ///
  /// In en, this message translates to:
  /// **'Search books'**
  String get searchBooks;

  /// Loading message during verse search
  ///
  /// In en, this message translates to:
  /// **'Searching verses...'**
  String get searchingVerses;

  /// Old Testament tab label
  ///
  /// In en, this message translates to:
  /// **'Old Testament'**
  String get oldTestament;

  /// New Testament tab label
  ///
  /// In en, this message translates to:
  /// **'New Testament'**
  String get newTestament;

  /// Reading plan category: Complete Bible
  ///
  /// In en, this message translates to:
  /// **'Complete Bible'**
  String get categoryCompleteBible;

  /// Reading plan category: New Testament
  ///
  /// In en, this message translates to:
  /// **'New Testament'**
  String get categoryNewTestament;

  /// Reading plan category: Old Testament
  ///
  /// In en, this message translates to:
  /// **'Old Testament'**
  String get categoryOldTestament;

  /// Reading plan category: Gospels
  ///
  /// In en, this message translates to:
  /// **'Gospels'**
  String get categoryGospels;

  /// Reading plan category: Epistles
  ///
  /// In en, this message translates to:
  /// **'Epistles'**
  String get categoryEpistles;

  /// Reading plan category: Psalms
  ///
  /// In en, this message translates to:
  /// **'Psalms'**
  String get categoryPsalms;

  /// Reading plan category: Proverbs
  ///
  /// In en, this message translates to:
  /// **'Proverbs'**
  String get categoryProverbs;

  /// Reading plan category: Wisdom Literature
  ///
  /// In en, this message translates to:
  /// **'Wisdom Literature'**
  String get categoryWisdom;

  /// Reading plan category: Prophecy
  ///
  /// In en, this message translates to:
  /// **'Prophecy'**
  String get categoryProphecy;

  /// Empty state when no books match search
  ///
  /// In en, this message translates to:
  /// **'No books found'**
  String get noBooksFound;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearchTerm;

  /// Single chapter count
  ///
  /// In en, this message translates to:
  /// **'{count} chapter'**
  String chapterCount(int count);

  /// Multiple chapters count
  ///
  /// In en, this message translates to:
  /// **'{count} chapters'**
  String chaptersCount(int count);

  /// Chapter selector title
  ///
  /// In en, this message translates to:
  /// **'Select Chapter - {book}'**
  String selectChapterBook(String book);

  /// Verse search results count
  ///
  /// In en, this message translates to:
  /// **'{count} verses found'**
  String versesFoundCount(int count);

  /// Audio playback completion message
  ///
  /// In en, this message translates to:
  /// **'Chapter playback complete'**
  String get chapterPlaybackComplete;

  /// Reading completion success message
  ///
  /// In en, this message translates to:
  /// **'Reading marked as complete!'**
  String get readingMarkedComplete;

  /// Error message when updating reading fails
  ///
  /// In en, this message translates to:
  /// **'Error updating reading: {error}'**
  String errorUpdatingReading(String error);

  /// Audio playback error message
  ///
  /// In en, this message translates to:
  /// **'Audio playback error'**
  String get audioPlaybackError;

  /// Chapter progress indicator
  ///
  /// In en, this message translates to:
  /// **'Chapter {current} of {total}'**
  String chapterOfTotal(int current, int total);

  /// Single chapter label
  ///
  /// In en, this message translates to:
  /// **'1 chapter'**
  String get oneChapter;

  /// Empty verse message for specific book chapter
  ///
  /// In en, this message translates to:
  /// **'No verses found for {book} {chapter}'**
  String noVersesFoundForBook(String book, int chapter);

  /// Verse interaction tutorial tooltip
  ///
  /// In en, this message translates to:
  /// **'Double tap verse for actions ✨'**
  String get pressHoldVerseForActions;

  /// Verse removal confirmation
  ///
  /// In en, this message translates to:
  /// **'Removed from Verse Library'**
  String get removedFromVerseLibrary;

  /// Verse added confirmation
  ///
  /// In en, this message translates to:
  /// **'Added to Verse Library!'**
  String get addedToVerseLibrary;

  /// Reading completion button text when completed
  ///
  /// In en, this message translates to:
  /// **'✓ Reading Completed'**
  String get readingCompleted;

  /// Chapter loading error title
  ///
  /// In en, this message translates to:
  /// **'Error loading chapter'**
  String get errorLoadingChapter;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No verses empty state title
  ///
  /// In en, this message translates to:
  /// **'No verses available'**
  String get noVersesAvailable;

  /// No verses found for chapter range
  ///
  /// In en, this message translates to:
  /// **'Could not find verses for {book} {startChapter}-{endChapter}'**
  String couldNotFindVersesForRange(
      String book, int startChapter, int endChapter);

  /// Tooltip for devotional options button
  ///
  /// In en, this message translates to:
  /// **'Devotional options'**
  String get devotionalOptions;

  /// Share devotional menu option
  ///
  /// In en, this message translates to:
  /// **'Share Devotional'**
  String get shareDevotional;

  /// Devotional share success message
  ///
  /// In en, this message translates to:
  /// **'Devotional shared!'**
  String get devotionalShared;

  /// Devotional share error message
  ///
  /// In en, this message translates to:
  /// **'Unable to share devotional: {error}'**
  String unableToShareDevotional(String error);

  /// Opening scripture section title
  ///
  /// In en, this message translates to:
  /// **'Opening Scripture'**
  String get openingScripture;

  /// Key verse section title
  ///
  /// In en, this message translates to:
  /// **'Key Verse Spotlight'**
  String get keyVerseSpotlight;

  /// Life application section title
  ///
  /// In en, this message translates to:
  /// **'Life Application'**
  String get lifeApplication;

  /// Prayer section title
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get prayer;

  /// Action step section title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Action Step'**
  String get todaysActionStep;

  /// Extended section title for going deeper
  ///
  /// In en, this message translates to:
  /// **'Extended'**
  String get extended;

  /// Monthly progress indicator
  ///
  /// In en, this message translates to:
  /// **'{month} {year} Progress'**
  String monthYearProgress(String month, String year);

  /// Generic error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Prayer journal category filter label
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterByCategory;

  /// Clear category filter button
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// Generic loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Share button text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Category selection dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// Category loading error message
  ///
  /// In en, this message translates to:
  /// **'Error loading categories'**
  String get errorLoadingCategories;

  /// Prayer addition success message
  ///
  /// In en, this message translates to:
  /// **'Prayer added successfully'**
  String get prayerAddedSuccessfully;

  /// Prayer addition error message
  ///
  /// In en, this message translates to:
  /// **'Error adding prayer: {error}'**
  String errorAddingPrayer(String error);

  /// Prayer marked answered success message
  ///
  /// In en, this message translates to:
  /// **'Prayer marked as answered! 🙏'**
  String get prayerMarkedAnswered;

  /// Prayer share success message
  ///
  /// In en, this message translates to:
  /// **'Prayer shared successfully! 🙏'**
  String get prayerSharedSuccessfully;

  /// Prayer share error message
  ///
  /// In en, this message translates to:
  /// **'Unable to share prayer: {error}'**
  String unableToSharePrayer(String error);

  /// Delete prayer dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Prayer'**
  String get deletePrayer;

  /// Delete prayer confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String deletePrayerConfirmation(String title);

  /// Delete verse confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this verse from your library?'**
  String get deleteVerseConfirmation;

  /// Prayer deletion success message
  ///
  /// In en, this message translates to:
  /// **'Prayer deleted'**
  String get prayerDeleted;

  /// Prayer deletion error message
  ///
  /// In en, this message translates to:
  /// **'Error deleting prayer: {error}'**
  String errorDeletingPrayer(String error);

  /// Prayer loading error message
  ///
  /// In en, this message translates to:
  /// **'Unable to load prayers'**
  String get unableToLoadPrayers;

  /// Answered prayers loading error message
  ///
  /// In en, this message translates to:
  /// **'Unable to load answered prayers'**
  String get unableToLoadAnsweredPrayers;

  /// Paywall screen title
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get paywallTitle;

  /// Paywall screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Unlock Scripture Chat features'**
  String get paywallSubtitle;

  /// Trial days remaining badge
  ///
  /// In en, this message translates to:
  /// **'{days} trial days'**
  String paywallTrialDaysLeft(int days);

  /// Message shown when trial was already used
  ///
  /// In en, this message translates to:
  /// **'Trial period completed.\nSubscribe to continue using Scripture Chat.'**
  String get paywallTrialBlockedMessage;

  /// Message shown when trial has expired
  ///
  /// In en, this message translates to:
  /// **'Trial period completed.\nUpgrade to continue using Scripture Chat.'**
  String get paywallTrialEndedMessage;

  /// Messages remaining stat label
  ///
  /// In en, this message translates to:
  /// **'Messages\nLeft'**
  String get paywallMessagesLeft;

  /// Messages used this month label
  ///
  /// In en, this message translates to:
  /// **'Used This\nMonth'**
  String get paywallUsedThisMonth;

  /// Messages used in trial label
  ///
  /// In en, this message translates to:
  /// **'Used in\nTrial'**
  String get paywallUsedInTrial;

  /// Monthly message limit label
  ///
  /// In en, this message translates to:
  /// **'Monthly\nLimit'**
  String get paywallMonthlyLimit;

  /// Trial days remaining stat label
  ///
  /// In en, this message translates to:
  /// **'Trial Days\nLeft'**
  String get paywallTrialDaysLeft2;

  /// Per year pricing label
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get paywallPerYear;

  /// Pricing disclaimer
  ///
  /// In en, this message translates to:
  /// **'(pricing may vary by region and currency)'**
  String get paywallPricingDisclaimer;

  /// Monthly message limit feature
  ///
  /// In en, this message translates to:
  /// **'150 Scripture Chats per month'**
  String get paywall150MessagesPerMonth;

  /// Cost breakdown message
  ///
  /// In en, this message translates to:
  /// **'Less than \$3 per month'**
  String get paywallLessThan3PerMonth;

  /// Features section title
  ///
  /// In en, this message translates to:
  /// **'What\'s Included'**
  String get paywallWhatsIncluded;

  /// Feature title
  ///
  /// In en, this message translates to:
  /// **'Intelligent Scripture Chat'**
  String get paywallFeatureIntelligentChat;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Custom Real World Pastoral Training'**
  String get paywallFeatureIntelligentChatDesc;

  /// Feature title
  ///
  /// In en, this message translates to:
  /// **'150 Messages Monthly'**
  String get paywallFeature150Messages;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'More than enough for daily conversations'**
  String get paywallFeature150MessagesDesc;

  /// Feature title
  ///
  /// In en, this message translates to:
  /// **'Context-Aware Responses'**
  String get paywallFeatureContextAware;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Biblical intelligence tailored to provide insight'**
  String get paywallFeatureContextAwareDesc;

  /// Feature title
  ///
  /// In en, this message translates to:
  /// **'Crisis Detection'**
  String get paywallFeatureCrisisDetection;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Built-in safeguards and professional referrals'**
  String get paywallFeatureCrisisDetectionDesc;

  /// Feature title
  ///
  /// In en, this message translates to:
  /// **'Full Bible Access'**
  String get paywallFeatureFullBibleAccess;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'All free features remain available'**
  String get paywallFeatureFullBibleAccessDesc;

  /// Processing purchase button text
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get paywallProcessing;

  /// Start premium subscription button
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial'**
  String get paywallStartPremiumButton;

  /// Restore purchase button text
  ///
  /// In en, this message translates to:
  /// **'Restore Previous Purchase'**
  String get paywallRestorePurchase;

  /// Subscription terms and conditions for iOS
  ///
  /// In en, this message translates to:
  /// **'Payment will be charged to your App Store account. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. Cancel anytime in your App Store account settings.'**
  String get paywallSubscriptionTerms;

  /// Subscription terms and conditions for Android
  ///
  /// In en, this message translates to:
  /// **'Payment will be charged to your Google Play account. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. Cancel anytime in Google Play Store app under Payments & subscriptions.'**
  String get paywallSubscriptionTermsAndroid;

  /// Premium activation success message
  ///
  /// In en, this message translates to:
  /// **'Premium activated! 150 Messages Monthly.'**
  String get paywallPremiumActivatedSuccess;

  /// Purchase failure error message
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get paywallPurchaseFailed;

  /// Purchase restore success message
  ///
  /// In en, this message translates to:
  /// **'Purchase restored successfully!'**
  String get paywallPurchaseRestoredSuccess;

  /// No previous purchase error message
  ///
  /// In en, this message translates to:
  /// **'No previous purchase found.'**
  String get paywallNoPreviousPurchaseFound;

  /// Verse library subtitle
  ///
  /// In en, this message translates to:
  /// **'Everyday verses'**
  String get everydayVerses;

  /// Shared verses tab label
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get shared;

  /// Short label for shared verses tab (used at large text sizes)
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get sharedShort;

  /// Empty shared verses state title
  ///
  /// In en, this message translates to:
  /// **'No shared verses yet'**
  String get noSharedVersesYet;

  /// Empty saved verses state title
  ///
  /// In en, this message translates to:
  /// **'No saved verses yet'**
  String get noSavedVersesYet;

  /// Empty saved verses state subtitle
  ///
  /// In en, this message translates to:
  /// **'💡 Save verses while reading to build your collection'**
  String get saveVersesWhileReading;

  /// Generic error title
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Verse copied success message
  ///
  /// In en, this message translates to:
  /// **'Verse copied to clipboard'**
  String get verseCopiedToClipboard;

  /// Menu item: share as text
  ///
  /// In en, this message translates to:
  /// **'Share Text'**
  String get shareText;

  /// Verse share error message
  ///
  /// In en, this message translates to:
  /// **'Unable to share verse: {error}'**
  String unableToShareVerse(String error);

  /// Verse library options bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Verse Library Options'**
  String get verseLibraryOptions;

  /// About verse library menu option
  ///
  /// In en, this message translates to:
  /// **'About Verse Library'**
  String get aboutVerseLibrary;

  /// View shared history menu option
  ///
  /// In en, this message translates to:
  /// **'View shared history'**
  String get viewSharedHistory;

  /// Clear saved verses menu option
  ///
  /// In en, this message translates to:
  /// **'Clear saved verses'**
  String get clearSavedVerses;

  /// Clear shared history menu option
  ///
  /// In en, this message translates to:
  /// **'Clear shared history'**
  String get clearSharedHistory;

  /// Empty shared verses state subtitle
  ///
  /// In en, this message translates to:
  /// **'Share verses to keep a quick-access history here.'**
  String get shareVersesToQuickAccess;

  /// Saved verses menu option subtitle
  ///
  /// In en, this message translates to:
  /// **'Browse and manage your saved verses'**
  String get browseAndManageYourSavedVerses;

  /// View shared history menu option subtitle
  ///
  /// In en, this message translates to:
  /// **'Jump to your recently shared verses'**
  String get jumpToRecentlySharedVerses;

  /// Clear saved verses menu option subtitle
  ///
  /// In en, this message translates to:
  /// **'Remove all verses from your saved collection'**
  String get removeAllVersesFromSavedCollection;

  /// Clear shared history menu option subtitle
  ///
  /// In en, this message translates to:
  /// **'Remove every verse from shared activity'**
  String get removeEveryVerseFromSharedActivity;

  /// Shared verse deleted success message
  ///
  /// In en, this message translates to:
  /// **'Removed from shared history'**
  String get removedFromSharedHistory;

  /// Shared verse deletion error message
  ///
  /// In en, this message translates to:
  /// **'Unable to remove shared verse: {error}'**
  String unableToRemoveSharedVerse(String error);

  /// Verse deletion error message
  ///
  /// In en, this message translates to:
  /// **'Unable to remove verse: {error}'**
  String unableToRemoveVerse(String error);

  /// Clear shared history dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear shared history?'**
  String get clearSharedHistoryQuestion;

  /// Clear shared history dialog message
  ///
  /// In en, this message translates to:
  /// **'This removes every verse from your Shared tab. Future shares will continue to appear here.'**
  String get clearSharedHistoryConfirmation;

  /// Clear all button text
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Shared history cleared success message
  ///
  /// In en, this message translates to:
  /// **'Shared history cleared'**
  String get sharedHistoryCleared;

  /// Clear shared history error message
  ///
  /// In en, this message translates to:
  /// **'Unable to clear shared history: {error}'**
  String unableToClearSharedHistory(String error);

  /// Clear saved verses dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear saved verses?'**
  String get clearSavedVersesQuestion;

  /// Clear saved verses dialog message
  ///
  /// In en, this message translates to:
  /// **'This will remove every verse from your Saved list. You can always add them again later.'**
  String get clearSavedVersesConfirmation;

  /// Saved verses cleared success message
  ///
  /// In en, this message translates to:
  /// **'Saved verses cleared'**
  String get savedVersesCleared;

  /// Clear saved verses error message
  ///
  /// In en, this message translates to:
  /// **'Unable to clear saved verses: {error}'**
  String unableToClearSavedVerses(String error);

  /// Onboarding welcome title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Everyday Christian'**
  String get welcomeToEverydayChristian;

  /// Onboarding subtitle
  ///
  /// In en, this message translates to:
  /// **'Bible Study, Prayer, & Devotionals'**
  String get dailyScriptureGuidance;

  /// Legal agreements introduction
  ///
  /// In en, this message translates to:
  /// **'Before we begin, please review:'**
  String get beforeWeBeginReview;

  /// Terms checkbox label
  ///
  /// In en, this message translates to:
  /// **'I accept the Terms of Service'**
  String get acceptTermsOfService;

  /// Privacy checkbox label
  ///
  /// In en, this message translates to:
  /// **'I accept the Privacy Policy'**
  String get acceptPrivacyPolicy;

  /// Age confirmation checkbox label
  ///
  /// In en, this message translates to:
  /// **'I confirm I am 13+ years old'**
  String get confirmAge13Plus;

  /// Crisis resources section title
  ///
  /// In en, this message translates to:
  /// **'Crisis Resources'**
  String get crisisResources;

  /// Crisis resources contact information
  ///
  /// In en, this message translates to:
  /// **'If you\'re in crisis, please contact:\n\n988 Suicide & Crisis Lifeline\nCall or text 988\n\nCrisis Text Line\nText HOME to 741741\n\nRAINN National Sexual Assault Hotline\nCall 800-656-4673\n\nThis app provides structured tools for faith practices but is not a substitute for professional help.'**
  String get crisisResourcesText;

  /// Crisis notification snackbar title
  ///
  /// In en, this message translates to:
  /// **'Crisis Resources Available'**
  String get crisisResourcesAvailable;

  /// Crisis notification snackbar tap prompt
  ///
  /// In en, this message translates to:
  /// **'Tap to view resources →'**
  String get crisisResourcesTapToView;

  /// Crisis notification snackbar action button
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get crisisResourcesView;

  /// Legal agreements accept button
  ///
  /// In en, this message translates to:
  /// **'Accept & Continue'**
  String get acceptAndContinue;

  /// View document link text
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// Devotional demo page title
  ///
  /// In en, this message translates to:
  /// **'Try Your First Devotional'**
  String get tryYourFirstDevotional;

  /// Devotional demo page description
  ///
  /// In en, this message translates to:
  /// **'Here\'s a preview of a daily devotional to start your day with the word'**
  String get devotionalPreviewDesc;

  /// Demo devotional title line 1
  ///
  /// In en, this message translates to:
  /// **'Cultivating a'**
  String get demoDevotionalTitle1;

  /// Demo devotional title line 2
  ///
  /// In en, this message translates to:
  /// **'Thankful Heart'**
  String get demoDevotionalTitle2;

  /// Demo devotional opening scripture verse text
  ///
  /// In en, this message translates to:
  /// **'\"Give thanks to the LORD, for he is good, for his loving kindness endures forever.\"'**
  String get demoVerseText;

  /// Demo devotional opening scripture reference
  ///
  /// In en, this message translates to:
  /// **'Psalm 107:1'**
  String get demoVerseReference;

  /// Demo devotional reflection preview
  ///
  /// In en, this message translates to:
  /// **'Gratitude doesn\'t always come naturally—especially when life feels overwhelming. Yet Psalm 107 opens with a powerful invitation: give thanks...'**
  String get demoReflectionText;

  /// Completed button text
  ///
  /// In en, this message translates to:
  /// **'✓ Completed!'**
  String get completedExclamation;

  /// Next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// AI chat demo page title
  ///
  /// In en, this message translates to:
  /// **'Ask Me Anything'**
  String get askMeAnything;

  /// AI chat demo page subtitle
  ///
  /// In en, this message translates to:
  /// **'Intelligent Scripture Chat 24/7'**
  String get intelligentScriptureChat;

  /// Demo chat user message
  ///
  /// In en, this message translates to:
  /// **'What are some worry related scripture with details.'**
  String get demoChatUserMessage;

  /// Demo chat AI response
  ///
  /// In en, this message translates to:
  /// **'Great question! The Bible offers beautiful wisdom on overcoming worry. In Philippians 4:6-7, we\'re reminded to bring our concerns to God through prayer with thanksgiving, and His peace will guard our hearts...'**
  String get demoChatAIResponse;

  /// Chat input placeholder
  ///
  /// In en, this message translates to:
  /// **'Scripture Chat...'**
  String get scriptureChatPlaceholder;

  /// Final onboarding page title
  ///
  /// In en, this message translates to:
  /// **'You\'re All Set!'**
  String get youreAllSet;

  /// Final onboarding page subtitle
  ///
  /// In en, this message translates to:
  /// **'One last thing...'**
  String get oneLastThing;

  /// Name input prompt
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get whatShouldWeCallYou;

  /// Name input placeholder
  ///
  /// In en, this message translates to:
  /// **'First name (optional)'**
  String get firstNameOptional;

  /// Final onboarding encouragement
  ///
  /// In en, this message translates to:
  /// **'Your spiritual journey starts now!'**
  String get spiritualJourneyStartsNow;

  /// Subscription settings screen title
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionTitle;

  /// Subscription settings screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your premium access'**
  String get subscriptionSubtitle;

  /// Premium subscription active status
  ///
  /// In en, this message translates to:
  /// **'Premium Active'**
  String get subscriptionStatusPremiumActive;

  /// Premium subscription active description
  ///
  /// In en, this message translates to:
  /// **'150 Messages Monthly'**
  String get subscriptionStatusPremiumActiveDesc;

  /// Yearly subscription plan type
  ///
  /// In en, this message translates to:
  /// **'Yearly Plan'**
  String get subscriptionPlanYearly;

  /// Monthly subscription plan type
  ///
  /// In en, this message translates to:
  /// **'Monthly Plan'**
  String get subscriptionPlanMonthly;

  /// Yearly plan label
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get paywallPlanYearly;

  /// Monthly plan label
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallPlanMonthly;

  /// Best value badge
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get paywallBestValue;

  /// Flexible badge for monthly plan
  ///
  /// In en, this message translates to:
  /// **'FLEXIBLE'**
  String get paywallFlexible;

  /// Per month suffix
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get paywallPerMonth;

  /// Billed monthly text
  ///
  /// In en, this message translates to:
  /// **'Billed monthly'**
  String get paywallBilledMonthly;

  /// Save percentage text
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String paywallSavePercent(int percent);

  /// Free trial status
  ///
  /// In en, this message translates to:
  /// **'Free Trial'**
  String get subscriptionStatusFreeTrial;

  /// Trial days remaining status
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String subscriptionStatusTrialDaysRemaining(int days);

  /// Trial expired status
  ///
  /// In en, this message translates to:
  /// **'Trial Expired'**
  String get subscriptionStatusTrialExpired;

  /// Trial expired description
  ///
  /// In en, this message translates to:
  /// **'Upgrade to continue using Scripture Chat'**
  String get subscriptionStatusTrialExpiredDesc;

  /// Free version status
  ///
  /// In en, this message translates to:
  /// **'Free Version'**
  String get subscriptionStatusFreeVersion;

  /// Free version description
  ///
  /// In en, this message translates to:
  /// **'Start your free trial'**
  String get subscriptionStatusFreeVersionDesc;

  /// Messages remaining label
  ///
  /// In en, this message translates to:
  /// **'Messages\nLeft'**
  String get subscriptionMessagesLeft;

  /// Messages used this month label
  ///
  /// In en, this message translates to:
  /// **'Used This\nMonth'**
  String get subscriptionUsedThisMonth;

  /// Messages used today label
  ///
  /// In en, this message translates to:
  /// **'Used\nToday'**
  String get subscriptionUsedToday;

  /// Monthly message limit label
  ///
  /// In en, this message translates to:
  /// **'Monthly\nLimit'**
  String get subscriptionMonthlyLimit;

  /// Trial days remaining label
  ///
  /// In en, this message translates to:
  /// **'Trial Days\nLeft'**
  String get subscriptionTrialDaysLeft;

  /// Premium benefits section title
  ///
  /// In en, this message translates to:
  /// **'Your Premium Benefits'**
  String get subscriptionYourPremiumBenefits;

  /// Upgrade to premium section title
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get subscriptionUpgradeToPremium;

  /// Benefit title
  ///
  /// In en, this message translates to:
  /// **'Intelligent Scripture Chat'**
  String get subscriptionBenefitIntelligentChat;

  /// Benefit description
  ///
  /// In en, this message translates to:
  /// **'Custom Real World Pastoral Training'**
  String get subscriptionBenefitIntelligentChatDesc;

  /// Benefit title
  ///
  /// In en, this message translates to:
  /// **'150 Messages Monthly'**
  String get subscriptionBenefit150Messages;

  /// Benefit description
  ///
  /// In en, this message translates to:
  /// **'More than enough for daily conversations. Only {price}/year!'**
  String subscriptionBenefit150MessagesDesc(String price);

  /// Benefit title
  ///
  /// In en, this message translates to:
  /// **'Context-Aware Responses'**
  String get subscriptionBenefitContextAware;

  /// Benefit description
  ///
  /// In en, this message translates to:
  /// **'Biblical intelligence tailored to provide insight'**
  String get subscriptionBenefitContextAwareDesc;

  /// Benefit title
  ///
  /// In en, this message translates to:
  /// **'Crisis Detection'**
  String get subscriptionBenefitCrisisDetection;

  /// Benefit description
  ///
  /// In en, this message translates to:
  /// **'Built-in safeguards and referrals'**
  String get subscriptionBenefitCrisisDetectionDesc;

  /// Benefit title
  ///
  /// In en, this message translates to:
  /// **'Full Bible Access'**
  String get subscriptionBenefitFullBibleAccess;

  /// Benefit description
  ///
  /// In en, this message translates to:
  /// **'All free features remain available'**
  String get subscriptionBenefitFullBibleAccessDesc;

  /// Subscribe now button text
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now - {price}/year*'**
  String subscriptionSubscribeNowButton(String price);

  /// Start free trial button text
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial'**
  String get subscriptionStartFreeTrialButton;

  /// Manage subscription button text
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get subscriptionManageButton;

  /// Premium subscription renewal info
  ///
  /// In en, this message translates to:
  /// **'Your subscription automatically renews at {price}/year unless cancelled at least 24 hours before the end of the current period. Manage your subscription in App Store account settings.'**
  String subscriptionRenewalInfoPremium(String price);

  /// Trial subscription info
  ///
  /// In en, this message translates to:
  /// **'Start your 3-day free trial with 15 Scripture Chats total (use anytime). After trial: {price}/year for 150 chats per month. Cancel anytime in App Store settings.'**
  String subscriptionRenewalInfoTrial(String price);

  /// Error message when unable to open subscription settings
  ///
  /// In en, this message translates to:
  /// **'Unable to open subscription settings'**
  String get subscriptionUnableToOpenSettings;

  /// Legal agreements screen title
  ///
  /// In en, this message translates to:
  /// **'Legal Agreements'**
  String get legalAgreements;

  /// Legal agreements screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Please review and accept to continue'**
  String get pleaseReviewAndAccept;

  /// Legal agreements intro section title
  ///
  /// In en, this message translates to:
  /// **'Important Information'**
  String get importantInformation;

  /// Legal agreements intro section text
  ///
  /// In en, this message translates to:
  /// **'Before using Everyday Christian, please understand the following disclaimers and accept our terms of service.'**
  String get legalIntroText;

  /// Disclaimer section title
  ///
  /// In en, this message translates to:
  /// **'Not Professional Counseling'**
  String get notProfessionalCounseling;

  /// Disclaimer section description
  ///
  /// In en, this message translates to:
  /// **'This app provides biblical guidance and spiritual support. It is NOT a substitute for professional mental health services, medical advice, or crisis intervention.'**
  String get notProfessionalCounselingDesc;

  /// Disclaimer section title
  ///
  /// In en, this message translates to:
  /// **'No Medical or Legal Advice'**
  String get noMedicalLegalAdvice;

  /// Disclaimer section description
  ///
  /// In en, this message translates to:
  /// **'Information provided is for spiritual guidance only. Always consult qualified professionals for medical, legal, or financial matters.'**
  String get noMedicalLegalAdviceDesc;

  /// Disclaimer section title
  ///
  /// In en, this message translates to:
  /// **'AI Limitations'**
  String get aiLimitations;

  /// Disclaimer section description
  ///
  /// In en, this message translates to:
  /// **'Responses are generated by AI and may occasionally be inaccurate or incomplete. Use discernment and verify important information with trusted sources.'**
  String get aiLimitationsDesc;

  /// Disclaimer section title
  ///
  /// In en, this message translates to:
  /// **'Recommended Use'**
  String get recommendedUse;

  /// Disclaimer section description
  ///
  /// In en, this message translates to:
  /// **'Best used as a companion to regular prayer, Bible study, and fellowship with a local church community. Not a replacement for spiritual community.'**
  String get recommendedUseDesc;

  /// Crisis resource title
  ///
  /// In en, this message translates to:
  /// **'988 Suicide & Crisis Lifeline'**
  String get crisis988Title;

  /// Crisis resource description
  ///
  /// In en, this message translates to:
  /// **'Tap to call or text 988'**
  String get crisis988Desc;

  /// Crisis resource title
  ///
  /// In en, this message translates to:
  /// **'Crisis Text Line'**
  String get crisisTextLine;

  /// Crisis resource description
  ///
  /// In en, this message translates to:
  /// **'Tap to text HOME to 741741'**
  String get crisisTextLineDesc;

  /// Warning about immediate danger
  ///
  /// In en, this message translates to:
  /// **'If you are in immediate danger, call 911 or go to your nearest emergency room.'**
  String get crisisImmediateDanger;

  /// Button text to acknowledge crisis resources
  ///
  /// In en, this message translates to:
  /// **'I understand and have noted these resources'**
  String get crisisAcknowledge;

  /// Section header for additional crisis resources
  ///
  /// In en, this message translates to:
  /// **'Additional Resources:'**
  String get additionalResources;

  /// 988 Lifeline website resource title
  ///
  /// In en, this message translates to:
  /// **'988 Lifeline Website'**
  String get lifeline988Website;

  /// 988 Lifeline chat website URL
  ///
  /// In en, this message translates to:
  /// **'Chat online at 988lifeline.org'**
  String get lifeline988Chat;

  /// RAINN online chat resource title
  ///
  /// In en, this message translates to:
  /// **'RAINN Online Chat'**
  String get rainnOnlineChat;

  /// RAINN website URL
  ///
  /// In en, this message translates to:
  /// **'rainn.org/get-help'**
  String get rainnWebsite;

  /// Crisis resource title
  ///
  /// In en, this message translates to:
  /// **'Emergency Services'**
  String get emergencyServices;

  /// Crisis resource description
  ///
  /// In en, this message translates to:
  /// **'Tap to call 911'**
  String get emergencyServicesDesc;

  /// Consent section title
  ///
  /// In en, this message translates to:
  /// **'Acceptance Required'**
  String get acceptanceRequired;

  /// Checkbox label prefix for terms/privacy
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the '**
  String get haveReadAndAgree;

  /// Age confirmation checkbox label
  ///
  /// In en, this message translates to:
  /// **'I confirm that I am 18 years of age or older'**
  String get confirmAge18Plus;

  /// Validation error message
  ///
  /// In en, this message translates to:
  /// **'Please accept all required items to continue'**
  String get pleaseAcceptAllRequired;

  /// Error message for acceptance save failure
  ///
  /// In en, this message translates to:
  /// **'Failed to save acceptance. Please try again.'**
  String get failedToSaveAcceptance;

  /// Error message for 988 call failure
  ///
  /// In en, this message translates to:
  /// **'Unable to make call. Please dial 988 manually.'**
  String get unableToCall988;

  /// Error message for crisis text line failure
  ///
  /// In en, this message translates to:
  /// **'Unable to open messaging. Please text HOME to 741741 manually.'**
  String get unableToTextCrisisLine;

  /// Error message for 911 call failure
  ///
  /// In en, this message translates to:
  /// **'Unable to make call. Please dial 911 manually.'**
  String get unableToCall911;

  /// Error message when chat message fails to send
  ///
  /// In en, this message translates to:
  /// **'Failed to send message. Please try again.'**
  String get chatFailedToSend;

  /// Trial feature: message limit description
  ///
  /// In en, this message translates to:
  /// **'15 Scripture Chats over 3 days'**
  String get trialFeatureMessages;

  /// Trial feature: scripture interpretation
  ///
  /// In en, this message translates to:
  /// **'Scripture interpretation & guidance'**
  String get trialFeatureScripture;

  /// Trial feature: prayer support
  ///
  /// In en, this message translates to:
  /// **'Prayer support & encouragement'**
  String get trialFeaturePrayer;

  /// Trial pricing information shown in dialog
  ///
  /// In en, this message translates to:
  /// **'After trial: ~\$35.99/year for 150 chats/month'**
  String get trialPricingAfterTrial;

  /// FAQ dialog subtitle
  ///
  /// In en, this message translates to:
  /// **'Find answers to common questions'**
  String get faqSubtitle;

  /// FAQ section title
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get faqGettingStarted;

  /// FAQ section title
  ///
  /// In en, this message translates to:
  /// **'Bible Reading'**
  String get faqBibleReading;

  /// FAQ section title
  ///
  /// In en, this message translates to:
  /// **'Prayer Journal'**
  String get faqPrayerJournal;

  /// FAQ section title
  ///
  /// In en, this message translates to:
  /// **'Devotionals & Reading Plans'**
  String get faqDevotionalsPlans;

  /// FAQ section title
  ///
  /// In en, this message translates to:
  /// **'Scripture Chat & Support'**
  String get faqAIChatSupport;

  /// FAQ section title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get faqNotifications;

  /// FAQ section title
  ///
  /// In en, this message translates to:
  /// **'Settings & Customization'**
  String get faqSettingsCustomization;

  /// FAQ section title
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get faqDataPrivacy;

  /// FAQ question 1
  ///
  /// In en, this message translates to:
  /// **'How do I get started?'**
  String get faqQ1;

  /// FAQ answer 1
  ///
  /// In en, this message translates to:
  /// **'Welcome! Start by exploring the Home screen where you\'ll find daily devotionals, verse of the day, and quick access to prayer and Bible reading. Navigate using the menu in the top left corner.'**
  String get faqA1;

  /// FAQ question 2
  ///
  /// In en, this message translates to:
  /// **'Is the app free to use?'**
  String get faqQ2;

  /// FAQ answer 2
  ///
  /// In en, this message translates to:
  /// **'Yes! Everyday Christian offers a free trial with daily message limits for Scripture Chat. Upgrade to Premium for unlimited conversations and full access to all features.'**
  String get faqA2;

  /// FAQ question 3
  ///
  /// In en, this message translates to:
  /// **'Which Bible version is used?'**
  String get faqQ3;

  /// FAQ answer 3
  ///
  /// In en, this message translates to:
  /// **'The app uses the World English Bible (WEB), a modern public domain translation that\'s faithful to the original texts and easy to read.'**
  String get faqA3;

  /// FAQ question 4
  ///
  /// In en, this message translates to:
  /// **'Can I read the Bible offline?'**
  String get faqQ4;

  /// FAQ answer 4
  ///
  /// In en, this message translates to:
  /// **'Yes! The entire Bible is downloaded when you first install the app. You can read all 66 books, chapters, and verses without an internet connection.'**
  String get faqA4;

  /// FAQ question 5
  ///
  /// In en, this message translates to:
  /// **'How do I search for verses?'**
  String get faqQ5;

  /// FAQ answer 5
  ///
  /// In en, this message translates to:
  /// **'Navigate to the Bible section from the home menu. Use the search bar to find verses by keywords, or browse by book, chapter, and verse.'**
  String get faqA5;

  /// FAQ question 6
  ///
  /// In en, this message translates to:
  /// **'Can I change the Bible version?'**
  String get faqQ6;

  /// FAQ answer 6
  ///
  /// In en, this message translates to:
  /// **'The World English Bible (WEB) is currently the only version available. This ensures consistent offline access and optimal performance.'**
  String get faqA6;

  /// FAQ question 7
  ///
  /// In en, this message translates to:
  /// **'How do I add a prayer?'**
  String get faqQ7;

  /// FAQ answer 7
  ///
  /// In en, this message translates to:
  /// **'Open the Prayer Journal from the home menu and tap the floating + button. Enter your prayer title, description, and choose a category (Personal, Family, Health, etc.), then save.'**
  String get faqA7;

  /// FAQ question 8
  ///
  /// In en, this message translates to:
  /// **'Can I mark prayers as answered?'**
  String get faqQ8;

  /// FAQ answer 8
  ///
  /// In en, this message translates to:
  /// **'Yes! Open any prayer and tap \"Mark as Answered\". You can add a description of how God answered your prayer. View all answered prayers in the \"Answered\" tab.'**
  String get faqA8;

  /// FAQ question 9
  ///
  /// In en, this message translates to:
  /// **'How do I export my prayer journal?'**
  String get faqQ9;

  /// FAQ answer 9
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > Data & Privacy > Export Data. This creates a formatted text file containing all your prayers (both active and answered) that you can save or share.'**
  String get faqA9;

  /// FAQ question 10
  ///
  /// In en, this message translates to:
  /// **'Can I organize prayers by category?'**
  String get faqQ10;

  /// FAQ answer 10
  ///
  /// In en, this message translates to:
  /// **'Yes! Each prayer can be assigned to a category. Use the category filter at the top of the Prayer Journal to view prayers by specific categories.'**
  String get faqA10;

  /// FAQ question 11
  ///
  /// In en, this message translates to:
  /// **'Where can I find daily devotionals?'**
  String get faqQ11;

  /// FAQ answer 11
  ///
  /// In en, this message translates to:
  /// **'Daily devotionals appear on your Home screen. You can mark devotionals as completed to track your progress and build your devotional streak.'**
  String get faqA11;

  /// FAQ question 12
  ///
  /// In en, this message translates to:
  /// **'How do reading plans work?'**
  String get faqQ12;

  /// FAQ answer 12
  ///
  /// In en, this message translates to:
  /// **'Choose a reading plan from the Reading Plans section. Tap \"Start Plan\" to begin. The app tracks your progress as you complete daily readings. Only one plan can be active at a time.'**
  String get faqA12;

  /// FAQ question 13
  ///
  /// In en, this message translates to:
  /// **'Can I track my devotional streak?'**
  String get faqQ13;

  /// FAQ answer 13
  ///
  /// In en, this message translates to:
  /// **'Yes! The app automatically tracks how many consecutive days you\'ve completed devotionals. View your current streak on your Profile screen.'**
  String get faqA13;

  /// FAQ question 14
  ///
  /// In en, this message translates to:
  /// **'What can I ask the AI?'**
  String get faqQ14;

  /// FAQ answer 14
  ///
  /// In en, this message translates to:
  /// **'You can ask about Scripture interpretation, prayer requests, life challenges, faith questions, and daily encouragement. The AI provides biblically-grounded guidance and support.'**
  String get faqA14;

  /// FAQ question 15
  ///
  /// In en, this message translates to:
  /// **'How many messages can I send?'**
  String get faqQ15;

  /// FAQ answer 15
  ///
  /// In en, this message translates to:
  /// **'Free users have a daily message limit. Premium subscribers get unlimited messages. Check Settings > Subscription to see your current plan and remaining messages.'**
  String get faqA15;

  /// FAQ question 16
  ///
  /// In en, this message translates to:
  /// **'Are my conversations saved?'**
  String get faqQ16;

  /// FAQ answer 16
  ///
  /// In en, this message translates to:
  /// **'Yes! All your AI conversations are saved to your device. Each chat creates a new session that you can access from the conversation history.'**
  String get faqA16;

  /// FAQ question 17
  ///
  /// In en, this message translates to:
  /// **'How do I change notification times?'**
  String get faqQ17;

  /// FAQ answer 17
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > Notifications > Notification Time. Select your preferred time for daily reminders.'**
  String get faqA17;

  /// FAQ question 18
  ///
  /// In en, this message translates to:
  /// **'Can I turn off specific notifications?'**
  String get faqQ18;

  /// FAQ answer 18
  ///
  /// In en, this message translates to:
  /// **'Yes! In Settings > Notifications, you can toggle each notification type (Daily Devotional, Prayer Reminders, Verse of the Day) independently.'**
  String get faqA18;

  /// FAQ question 19
  ///
  /// In en, this message translates to:
  /// **'Why aren\'t I receiving notifications?'**
  String get faqQ19;

  /// FAQ answer 19
  ///
  /// In en, this message translates to:
  /// **'Check your device settings to ensure notifications are enabled for Everyday Christian. Also verify that each notification type is enabled in Settings > Notifications.'**
  String get faqA19;

  /// FAQ question 20
  ///
  /// In en, this message translates to:
  /// **'How do I adjust text size?'**
  String get faqQ20;

  /// FAQ answer 20
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > Appearance > Text Size. Use the slider to adjust text size throughout the app from 80% to 150% of normal size.'**
  String get faqA20;

  /// FAQ question 21
  ///
  /// In en, this message translates to:
  /// **'Can I add a profile picture?'**
  String get faqQ21;

  /// FAQ answer 21
  ///
  /// In en, this message translates to:
  /// **'Yes! Tap your profile avatar in Settings or on your Profile screen. Choose to take a photo or select one from your gallery.'**
  String get faqA21;

  /// FAQ question 22
  ///
  /// In en, this message translates to:
  /// **'What does offline mode do?'**
  String get faqQ22;

  /// FAQ answer 22
  ///
  /// In en, this message translates to:
  /// **'Offline mode allows you to use core features (Bible reading, viewing saved prayers and devotionals) without an internet connection. Scripture Chat requires internet.'**
  String get faqA22;

  /// FAQ question 23
  ///
  /// In en, this message translates to:
  /// **'Is my data private and secure?'**
  String get faqQ23;

  /// FAQ answer 23
  ///
  /// In en, this message translates to:
  /// **'Yes! Your prayers, notes, and personal data are stored securely on your device. We never sell your information to third parties.'**
  String get faqA23;

  /// FAQ question 24
  ///
  /// In en, this message translates to:
  /// **'What data is stored on my device?'**
  String get faqQ24;

  /// FAQ answer 24
  ///
  /// In en, this message translates to:
  /// **'The Bible content, your prayers, conversation history, reading plan progress, devotional completion records, and app preferences are all stored locally.'**
  String get faqA24;

  /// FAQ question 25
  ///
  /// In en, this message translates to:
  /// **'What\'s the difference between Clear Cache and Delete All Data?'**
  String get faqQ25;

  /// FAQ answer 25
  ///
  /// In en, this message translates to:
  /// **'Clear Cache removes temporary files (image cache, temp directories) to free up storage space. Your prayers, settings, and all personal data remain safe. Delete All Data permanently erases everything including prayers, conversations, settings, and resets the app to factory defaults.'**
  String get faqA25;

  /// FAQ question 26
  ///
  /// In en, this message translates to:
  /// **'How do I clear cached data?'**
  String get faqQ26;

  /// FAQ answer 26
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > Data & Privacy > Clear Cache. This removes temporary files and image cache to free up storage space. Your prayers, conversations, and personal data are NOT deleted - only temporary cache files are removed.'**
  String get faqA26;

  /// FAQ question 27
  ///
  /// In en, this message translates to:
  /// **'How do I delete all my data?'**
  String get faqQ27;

  /// FAQ answer 27
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > Data & Privacy > Delete All Data. You\'ll be asked to type \"DELETE\" to confirm. This permanently erases all prayers, conversations, reading plans, favorites, settings, and profile picture. Export your prayer journal first if you want to keep a backup. This action cannot be undone.'**
  String get faqA27;

  /// Label for answered prayer status in share images
  ///
  /// In en, this message translates to:
  /// **'Answered Prayer'**
  String get answeredPrayer;

  /// Label for prayer request status in share images
  ///
  /// In en, this message translates to:
  /// **'Prayer Request'**
  String get prayerRequest;

  /// Call to action in prayer share images
  ///
  /// In en, this message translates to:
  /// **'Join Me in Prayer'**
  String get joinMeInPrayer;

  /// Call to action to download app in share images
  ///
  /// In en, this message translates to:
  /// **'Download Everyday Christian'**
  String get downloadApp;

  /// Call to action in share images
  ///
  /// In en, this message translates to:
  /// **'Get Everyday Christian'**
  String get getApp;

  /// QR code instruction in share images
  ///
  /// In en, this message translates to:
  /// **'Scan to download'**
  String get scanToDownload;

  /// Subtitle for verse share images
  ///
  /// In en, this message translates to:
  /// **'Daily Scripture & Guidance'**
  String get dailyScriptureAndGuidance;

  /// Subtitle for chat share images
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Biblical Guidance'**
  String get aiPoweredBiblicalGuidance;

  /// Monthly message limit dialog title
  ///
  /// In en, this message translates to:
  /// **'Monthly Limit Reached'**
  String get monthlyLimitReached;

  /// Trial message limit dialog title
  ///
  /// In en, this message translates to:
  /// **'Trial Limit Reached'**
  String get trialLimitReached;

  /// Monthly limit reached message
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all 150 chats this month.\nUpgrade your plan or wait for the monthly reset.'**
  String get monthlyLimitMessage;

  /// Trial limit reached message
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all 15 trial chats.\nSubscribe now for 150 Scripture Chats per month!'**
  String get trialLimitMessage;

  /// Upgrade plan button
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgradePlan;

  /// Subscribe now button
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// Maybe later button
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// Free trial welcome dialog title
  ///
  /// In en, this message translates to:
  /// **'Welcome! Start Your Free Trial'**
  String get welcomeFreeTrial;

  /// Trial welcome subtitle
  ///
  /// In en, this message translates to:
  /// **'Experience Scripture Chat biblical guidance'**
  String get experienceAiGuidance;

  /// Pricing after trial
  ///
  /// In en, this message translates to:
  /// **'After trial: ~\$35.99/year for 150 chats/month'**
  String get afterTrialPricing;

  /// Regional pricing disclaimer
  ///
  /// In en, this message translates to:
  /// **'(pricing may vary by region and currency)'**
  String get pricingVariesDisclaimer;

  /// Start free trial button
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial'**
  String get startFreeTrial;

  /// Account suspension title
  ///
  /// In en, this message translates to:
  /// **'Account Suspended'**
  String get accountSuspended;

  /// Subscription required lockout title
  ///
  /// In en, this message translates to:
  /// **'Scripture Chat Requires\nSubscription'**
  String get aiChatRequiresSubscription;

  /// Account suspension message
  ///
  /// In en, this message translates to:
  /// **'Your Scripture Chat access has been temporarily suspended due to Terms of Service violations. This suspension will be automatically lifted after the specified period.'**
  String get suspensionMessage;

  /// Trial expired lockout message
  ///
  /// In en, this message translates to:
  /// **'Your free trial has ended. Subscribe to view your chat history and continue Scripture Chat conversations.'**
  String get trialExpiredMessage;

  /// Premium expired lockout message
  ///
  /// In en, this message translates to:
  /// **'Subscribe to view your chat history and continue conversations with personalized biblical guidance and support.'**
  String get premiumExpiredMessage;

  /// Suspension time remaining
  ///
  /// In en, this message translates to:
  /// **'Time Remaining: {duration}'**
  String timeRemaining(String duration);

  /// Suspension contact information
  ///
  /// In en, this message translates to:
  /// **'If you believe this suspension was issued in error, please contact:'**
  String get suspensionContactInfo;

  /// Premium benefit: message limit
  ///
  /// In en, this message translates to:
  /// **'150 Scripture Chats per month'**
  String get benefit150Messages;

  /// Premium benefit: chat history
  ///
  /// In en, this message translates to:
  /// **'Access to all your chat history'**
  String get benefitChatHistory;

  /// Premium benefit: personalization
  ///
  /// In en, this message translates to:
  /// **'Personalized biblical guidance'**
  String get benefitPersonalizedGuidance;

  /// List of free features
  ///
  /// In en, this message translates to:
  /// **'Prayer journal, Bible reading, and verses remain free and unlimited'**
  String get freeFeaturesList;

  /// App features subtitle
  ///
  /// In en, this message translates to:
  /// **'Bible Study, Prayer, & Devotionals'**
  String get appFeatureSubtitle;

  /// Crisis text line title with country label
  ///
  /// In en, this message translates to:
  /// **'Crisis Text Line'**
  String get crisisTextLineTitle;

  /// Biometric unlock prompt
  ///
  /// In en, this message translates to:
  /// **'Unlock Everyday Christian to access your spiritual content'**
  String get unlockBiometricPrompt;

  /// Biometric setup title
  ///
  /// In en, this message translates to:
  /// **'Protect Your App'**
  String get protectYourApp;

  /// Biometric setup description
  ///
  /// In en, this message translates to:
  /// **'Keep your prayers, devotionals, and spiritual conversations private with {biometricType}.'**
  String biometricSetupDescription(String biometricType);

  /// App lock enable reason
  ///
  /// In en, this message translates to:
  /// **'Enable app lock to protect your spiritual content'**
  String get enableAppLockReason;

  /// App lock enabled success message
  ///
  /// In en, this message translates to:
  /// **'App lock enabled. Your content is now protected.'**
  String get appLockEnabledSuccess;

  /// Enable biometric button
  ///
  /// In en, this message translates to:
  /// **'Enable {biometricType}'**
  String enableBiometric(String biometricType);

  /// Biometric settings note
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime from Settings'**
  String get biometricSettingsNote;

  /// Legal acceptance validation error
  ///
  /// In en, this message translates to:
  /// **'Please read and accept both documents'**
  String get acceptBothDocumentsError;

  /// Terms acceptance save error
  ///
  /// In en, this message translates to:
  /// **'Failed to save acceptance. Please try again.'**
  String get termsAcceptanceSaveFailed;

  /// Legal agreement dialog title
  ///
  /// In en, this message translates to:
  /// **'Legal Agreement'**
  String get legalAgreement;

  /// Legal review instruction
  ///
  /// In en, this message translates to:
  /// **'Please review and accept to continue'**
  String get reviewToAccept;

  /// Legal checkbox prefix
  ///
  /// In en, this message translates to:
  /// **'I have read and agree'**
  String get iHaveReadAndAgree;

  /// Legal acceptance requirement
  ///
  /// In en, this message translates to:
  /// **'You must accept both documents to use this app'**
  String get mustAcceptBothDocuments;

  /// Generic processing message
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// Subscription required for regeneration
  ///
  /// In en, this message translates to:
  /// **'Subscription required to regenerate responses'**
  String get chatSubscriptionRequiredRegenerate;

  /// Chat discussing verse title
  ///
  /// In en, this message translates to:
  /// **'Discussing {reference}'**
  String chatDiscussingVerse(String reference);

  /// New chat conversation title
  ///
  /// In en, this message translates to:
  /// **'New Conversation'**
  String get chatNewConversation;

  /// User message not found error
  ///
  /// In en, this message translates to:
  /// **'Could not find previous message'**
  String get chatCouldNotFindUserMessage;

  /// AI regeneration instruction
  ///
  /// In en, this message translates to:
  /// **'Please offer a different perspective or alternative response to the previous question.'**
  String get chatRegenerateInstruction;

  /// Response regenerated success message
  ///
  /// In en, this message translates to:
  /// **'✨ Response regenerated successfully'**
  String get chatResponseRegeneratedSuccess;

  /// Response regeneration error
  ///
  /// In en, this message translates to:
  /// **'Failed to regenerate response: {error}'**
  String chatFailedToRegenerateResponse(String error);

  /// No conversation error for export
  ///
  /// In en, this message translates to:
  /// **'No conversation to export'**
  String get chatNoConversationToExport;

  /// No messages error for export
  ///
  /// In en, this message translates to:
  /// **'No messages to export'**
  String get chatNoMessagesToExport;

  /// Export conversation menu option
  ///
  /// In en, this message translates to:
  /// **'Export Conversation'**
  String get chatExportConversation;

  /// Share chat menu option
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get chatShare;

  /// Chat export email subject
  ///
  /// In en, this message translates to:
  /// **'AI Biblical Conversation Export'**
  String get chatExportSubject;

  /// Conversation export success
  ///
  /// In en, this message translates to:
  /// **'Conversation exported successfully'**
  String get chatConversationExportedSuccess;

  /// Chat export error
  ///
  /// In en, this message translates to:
  /// **'Failed to export: {error}'**
  String chatFailedToExport(String error);

  /// No conversation error for sharing
  ///
  /// In en, this message translates to:
  /// **'No conversation to share'**
  String get chatNoConversationToShare;

  /// No messages error for sharing
  ///
  /// In en, this message translates to:
  /// **'No messages to share'**
  String get chatNoMessagesToShare;

  /// Chat share subject
  ///
  /// In en, this message translates to:
  /// **'AI Biblical Conversation'**
  String get chatShareSubject;

  /// Conversation share success
  ///
  /// In en, this message translates to:
  /// **'Conversation shared successfully'**
  String get chatConversationSharedSuccess;

  /// Chat share error
  ///
  /// In en, this message translates to:
  /// **'Failed to share: {error}'**
  String chatFailedToShare(String error);

  /// Conversation image share success
  ///
  /// In en, this message translates to:
  /// **'Conversation image shared successfully'**
  String get chatConversationImageSharedSuccess;

  /// Generic share failure message
  ///
  /// In en, this message translates to:
  /// **'Failed to share. Please try again.'**
  String get chatFailedToShareTryAgain;

  /// Question not found error
  ///
  /// In en, this message translates to:
  /// **'Could not find the question for this response'**
  String get chatCouldNotFindQuestion;

  /// Message exchange share success
  ///
  /// In en, this message translates to:
  /// **'Message exchange shared successfully!'**
  String get chatMessageExchangeSharedSuccess;

  /// Bottom sheet title for chat options
  ///
  /// In en, this message translates to:
  /// **'Chat Options'**
  String get chatOptions;

  /// Export conversation description
  ///
  /// In en, this message translates to:
  /// **'View and copy conversation text'**
  String get chatExportConversationDesc;

  /// Share as text option
  ///
  /// In en, this message translates to:
  /// **'Share Text'**
  String get chatShareText;

  /// Share text description
  ///
  /// In en, this message translates to:
  /// **'Share as plain text'**
  String get chatShareTextDesc;

  /// Share as image option
  ///
  /// In en, this message translates to:
  /// **'Share as Image'**
  String get chatShareAsImage;

  /// Share as image description
  ///
  /// In en, this message translates to:
  /// **'Share conversation as custom image'**
  String get chatShareAsImageDesc;

  /// AI service initialization message
  ///
  /// In en, this message translates to:
  /// **'Initializing AI service...'**
  String get chatAiServiceInitializing;

  /// AI service fallback message
  ///
  /// In en, this message translates to:
  /// **'Using fallback responses: {reason}'**
  String chatAiServiceFallback(String reason);

  /// AI service error message
  ///
  /// In en, this message translates to:
  /// **'AI service error: {message}'**
  String chatAiServiceError(String message);

  /// Message options bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Message Options'**
  String get chatMessageOptions;

  /// Copy message option
  ///
  /// In en, this message translates to:
  /// **'Copy Message'**
  String get chatCopyMessage;

  /// Copy message description
  ///
  /// In en, this message translates to:
  /// **'Copy message text to clipboard'**
  String get chatCopyMessageDesc;

  /// Message copied success
  ///
  /// In en, this message translates to:
  /// **'Message copied to clipboard'**
  String get chatMessageCopiedToClipboard;

  /// Regenerate response option
  ///
  /// In en, this message translates to:
  /// **'Regenerate Response'**
  String get chatRegenerateResponse;

  /// Regenerate response description
  ///
  /// In en, this message translates to:
  /// **'Generate a new response to this message'**
  String get chatRegenerateResponseDesc;

  /// Share exchange option
  ///
  /// In en, this message translates to:
  /// **'Share Exchange'**
  String get chatShareExchange;

  /// Share exchange description
  ///
  /// In en, this message translates to:
  /// **'Share this message exchange as image'**
  String get chatShareExchangeDesc;

  /// Chat input placeholder text
  ///
  /// In en, this message translates to:
  /// **'Scripture Chat...'**
  String get chatInputPlaceholder;

  /// AI fallback response for prayer topics
  ///
  /// In en, this message translates to:
  /// **'I sense you may be seeking guidance on prayer. The Bible teaches us in 1 Thessalonians 5:17 to \'pray without ceasing.\' Prayer is our direct line to God, and He invites us to bring all our concerns to Him. Would you like to share what\'s on your heart?'**
  String get chatFallbackPrayer;

  /// AI fallback response for love topics
  ///
  /// In en, this message translates to:
  /// **'Love is one of the most beautiful themes in Scripture. 1 Corinthians 13:4-7 describes love as patient, kind, and enduring. God\'s love for us is perfect and unconditional, demonstrated through Christ. How can I help you explore this topic further?'**
  String get chatFallbackLove;

  /// AI fallback response for forgiveness topics
  ///
  /// In en, this message translates to:
  /// **'Forgiveness is central to the Christian faith. Ephesians 4:32 encourages us to \'be kind to one another, tenderhearted, forgiving one another, as God in Christ forgave you.\' Is there a specific situation where you\'re seeking guidance on forgiveness?'**
  String get chatFallbackForgiveness;

  /// AI fallback response for purpose topics
  ///
  /// In en, this message translates to:
  /// **'Questions about purpose are deeply meaningful. Jeremiah 29:11 reminds us that God has plans for us - plans for welfare and hope. Your life has divine purpose. What aspect of purpose would you like to explore together?'**
  String get chatFallbackPurpose;

  /// AI default fallback response
  ///
  /// In en, this message translates to:
  /// **'I\'m here to provide biblical guidance and support. Feel free to ask me about Scripture, prayer, faith questions, or any spiritual concerns you have. How can I help you today?'**
  String get chatFallbackDefault;

  /// Conversation history title
  ///
  /// In en, this message translates to:
  /// **'Conversation History'**
  String get chatConversationHistory;

  /// Empty conversation history message
  ///
  /// In en, this message translates to:
  /// **'No conversation history yet'**
  String get chatNoConversationHistoryYet;

  /// Delete conversation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation?'**
  String get chatDeleteConversationTitle;

  /// Delete conversation dialog message
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this conversation and all its messages.'**
  String get chatDeleteConversationMessage;

  /// Conversation deleted success
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted'**
  String get chatConversationDeleted;

  /// Default conversation title
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get chatConversationDefault;

  /// Start new conversation dialog title
  ///
  /// In en, this message translates to:
  /// **'Start New Conversation?'**
  String get chatStartNewConversationTitle;

  /// Start new conversation dialog message
  ///
  /// In en, this message translates to:
  /// **'Your current conversation will be saved to history.\n\nStart a new conversation?'**
  String get chatStartNewConversationMessage;

  /// New chat button
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get chatNewChatButton;

  /// No internet error message
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get chatNoInternetConnection;

  /// Call hotline button
  ///
  /// In en, this message translates to:
  /// **'Call {hotline} Now'**
  String callHotlineNow(String hotline);

  /// Crisis text line instructions
  ///
  /// In en, this message translates to:
  /// **'Text HOME to 741741'**
  String get crisisTextInstructions;

  /// Unable to call error
  ///
  /// In en, this message translates to:
  /// **'Unable to make call. Please dial {hotline} manually.'**
  String unableToCallError(String hotline);

  /// Suicide crisis detection message with international resources
  ///
  /// In en, this message translates to:
  /// **'We detected you may be having suicidal thoughts. Your life matters. Please call 988 (Suicide & Crisis Lifeline) right now. They\'re available 24/7.\n\nOutside the US:\n• Mexico: 55-5259-8121 (Línea de la Vida)\n• Spain: 024 (Teléfono de la Esperanza)\n• Or search for local crisis services in your country'**
  String get crisisSuicideMessage;

  /// Self-harm crisis detection message with international resources
  ///
  /// In en, this message translates to:
  /// **'We detected you may be considering self-harm. You don\'t have to face this alone. Please text HOME to 741741 (Crisis Text Line) for immediate support.\n\nOutside the US:\n• Mexico: 55-5259-8121 (Línea de la Vida)\n• Spain: 024 (Teléfono de la Esperanza)\n• Or search for local crisis services in your country'**
  String get crisisSelfHarmMessage;

  /// Abuse crisis detection message with international resources
  ///
  /// In en, this message translates to:
  /// **'We detected you may be experiencing abuse. Your safety matters. Please call RAINN at 800-656-4673 for confidential support.\n\nOutside the US:\n• Mexico: 55-5259-8121 (Línea de la Vida)\n• Spain: 016 (Violencia de Género)\n• Or search for local help services in your country'**
  String get crisisAbuseMessage;

  /// Demo devotional full title
  ///
  /// In en, this message translates to:
  /// **'Cultivating a Thankful Heart'**
  String get demoDevotionalTitle;

  /// Empty shared verses instruction
  ///
  /// In en, this message translates to:
  /// **'Share verses to keep a quick-access history here.'**
  String get shareVersesToKeepHistory;

  /// Verse share partial success
  ///
  /// In en, this message translates to:
  /// **'Verse shared but couldn\'t remove from saved'**
  String get verseSharedButCouldntRemove;

  /// Verse shared and moved success
  ///
  /// In en, this message translates to:
  /// **'Verse shared and moved to Shared tab!'**
  String get verseSharedAndMovedToShared;

  /// Verse image shared and moved success
  ///
  /// In en, this message translates to:
  /// **'Verse shared as image and moved to Shared tab!'**
  String get verseSharedAsImageAndMoved;

  /// About saved verses description
  ///
  /// In en, this message translates to:
  /// **'Browse and manage your saved verses'**
  String get browseAndManageSavedVerses;

  /// View shared history description
  ///
  /// In en, this message translates to:
  /// **'Jump to your recently shared verses'**
  String get jumpToRecentlyShared;

  /// Clear saved verses description
  ///
  /// In en, this message translates to:
  /// **'Remove all verses from your saved collection'**
  String get removeAllFromSaved;

  /// Clear shared history description
  ///
  /// In en, this message translates to:
  /// **'Remove all verses from shared history'**
  String get removeAllFromShared;

  /// Verse progress indicator
  ///
  /// In en, this message translates to:
  /// **'Verse {current} of {total}'**
  String verseProgress(int current, int total);

  /// Empty active prayers subtitle
  ///
  /// In en, this message translates to:
  /// **'Add your prayers here to come back to them, reflect, and maintain your commitment'**
  String get noActivePrayersSubtitle;

  /// Highlight answered prayers option
  ///
  /// In en, this message translates to:
  /// **'Highlight Answered Prayers'**
  String get highlightPrayersAnswered;

  /// Answered prayers tab subtitle
  ///
  /// In en, this message translates to:
  /// **'Sometimes the answers we receive aren\'t what we wanted. Store them here to reflect better'**
  String get answeredPrayersSubtitle;

  /// Generic add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No progress empty state title
  ///
  /// In en, this message translates to:
  /// **'No Progress to Track'**
  String get noProgressToTrack;

  /// No progress empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Start a reading plan to see your progress and statistics'**
  String get noProgressSubtitle;

  /// Progress section title
  ///
  /// In en, this message translates to:
  /// **'Your Progress and Statistics'**
  String get yourProgressAndStatistics;

  /// Statistics loading error
  ///
  /// In en, this message translates to:
  /// **'Error loading statistics: {error}'**
  String errorLoadingStats(String error);

  /// Reading activity section title
  ///
  /// In en, this message translates to:
  /// **'Reading Activity'**
  String get readingActivity;

  /// Reading activity subtitle
  ///
  /// In en, this message translates to:
  /// **'Days with completed readings in the last 90 days'**
  String get readingActivitySubtitle;

  /// Activity data loading error
  ///
  /// In en, this message translates to:
  /// **'Error loading activity data: {error}'**
  String errorLoadingActivityData(String error);

  /// Only one plan active message
  ///
  /// In en, this message translates to:
  /// **'Only one reading plan can be active at a time. Reset your current plan to start a different one.'**
  String get onlyOnePlanActive;

  /// Estimated time per day
  ///
  /// In en, this message translates to:
  /// **'{time}/day'**
  String estimatedTimePerDay(String time);

  /// Streak days with pluralization
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{# days}}'**
  String streakDays(int count);

  /// Readings progress fraction
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String readingsProgress(int current, int total);

  /// Reset current plan tooltip
  ///
  /// In en, this message translates to:
  /// **'Reset your current plan before starting a new one'**
  String get resetCurrentPlanTooltip;

  /// Reading open error
  ///
  /// In en, this message translates to:
  /// **'Could not open reading: {error}'**
  String couldNotOpenReading(String error);

  /// Completed readings count with pluralization
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 completed reading} other{# completed readings}}'**
  String completedReadingsCount(int count);

  /// Streak with fire emoji
  ///
  /// In en, this message translates to:
  /// **'Your {streak} day streak 🔥'**
  String yourStreakDays(int streak);

  /// All progress history label
  ///
  /// In en, this message translates to:
  /// **'All progress history'**
  String get allProgressHistory;

  /// Irreversible action warning
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get actionCannotBeUndone;

  /// Messages remaining this month
  ///
  /// In en, this message translates to:
  /// **'{count} messages left this month'**
  String messagesLeftThisMonth(int count);

  /// Messages remaining today
  ///
  /// In en, this message translates to:
  /// **'{count} messages left today'**
  String messagesLeftToday(int count);

  /// Start free trial link
  ///
  /// In en, this message translates to:
  /// **'Start your free trial'**
  String get startYourFreeTrial;

  /// Notification time setting
  ///
  /// In en, this message translates to:
  /// **'Notify Time'**
  String get notificationTime;

  /// Biometric not available error
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not available on this device'**
  String get biometricNotAvailable;

  /// Verify identity for app lock
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to enable app lock'**
  String get verifyIdentityAppLock;

  /// App lock enabled success
  ///
  /// In en, this message translates to:
  /// **'App lock enabled. Your app is now protected.'**
  String get appLockEnabled;

  /// App lock disabled success
  ///
  /// In en, this message translates to:
  /// **'App lock disabled'**
  String get appLockDisabled;

  /// Cache clear failure
  ///
  /// In en, this message translates to:
  /// **'❌ Failed to clear cache: {error}'**
  String failedToClearCache(String error);

  /// Data export document title
  ///
  /// In en, this message translates to:
  /// **'EVERYDAY CHRISTIAN - DATA EXPORT'**
  String get dataExportTitle;

  /// Export date label
  ///
  /// In en, this message translates to:
  /// **'Export Date: {date}'**
  String exportDate(String date);

  /// Prayer journal export section header
  ///
  /// In en, this message translates to:
  /// **'📿 PRAYER JOURNAL'**
  String get prayerJournalExportSection;

  /// AI chat export section header
  ///
  /// In en, this message translates to:
  /// **'💬 AI CHAT CONVERSATIONS'**
  String get aiChatExportSection;

  /// Total sessions count
  ///
  /// In en, this message translates to:
  /// **'Total Sessions: {count}'**
  String totalSessions(int count);

  /// Archived session title
  ///
  /// In en, this message translates to:
  /// **'Session: {title} (Archived)'**
  String archivedSessionTitle(String title);

  /// No data to export error
  ///
  /// In en, this message translates to:
  /// **'No data to export'**
  String get noDataToExport;

  /// Data export email subject
  ///
  /// In en, this message translates to:
  /// **'Everyday Christian - Data Export'**
  String get dataExportSubject;

  /// Data export success summary
  ///
  /// In en, this message translates to:
  /// **'📤 Exported {prayerCount} prayer journal(s) and {chatCount} conversation(s)'**
  String dataExported(int prayerCount, int chatCount);

  /// Delete item: prayer journal
  ///
  /// In en, this message translates to:
  /// **'✝️ All prayer journal entries'**
  String get deleteItemPrayerJournal;

  /// Delete item: chat conversations
  ///
  /// In en, this message translates to:
  /// **'💬 All AI chat conversations'**
  String get deleteItemChatConversations;

  /// Delete item: reading plan
  ///
  /// In en, this message translates to:
  /// **'📖 Reading plan progress'**
  String get deleteItemReadingPlan;

  /// Delete item: favorite verses
  ///
  /// In en, this message translates to:
  /// **'🌟 Favorite verses'**
  String get deleteItemFavoriteVerses;

  /// Delete item: devotional history
  ///
  /// In en, this message translates to:
  /// **'📝 Devotional completion history'**
  String get deleteItemDevotionalHistory;

  /// Delete item: settings
  ///
  /// In en, this message translates to:
  /// **'⚙️ All app settings and preferences'**
  String get deleteItemSettings;

  /// Delete item: profile picture
  ///
  /// In en, this message translates to:
  /// **'👤 Profile picture'**
  String get deleteItemProfilePicture;

  /// Delete item: statistics
  ///
  /// In en, this message translates to:
  /// **'📊 All statistics and progress'**
  String get deleteItemStatistics;

  /// Delete all data warning header
  ///
  /// In en, this message translates to:
  /// **'⚠️ This will delete all local data including:'**
  String get deleteLocalDataWarning;

  /// Delete data bullet list
  ///
  /// In en, this message translates to:
  /// **'• Prayer journal entries\n• Chat history\n• Saved verses\n• Settings and preferences'**
  String get deleteDataBulletList;

  /// Subscription restoration notice
  ///
  /// In en, this message translates to:
  /// **'Your subscription will remain active and will be automatically restored on next app launch.'**
  String get subscriptionWillRestore;

  /// Type DELETE confirmation prompt
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm:'**
  String get typeDeleteToConfirm;

  /// Type DELETE placeholder
  ///
  /// In en, this message translates to:
  /// **'Type DELETE'**
  String get typeDeletePlaceholder;

  /// Type DELETE validation error
  ///
  /// In en, this message translates to:
  /// **'❌ You must type DELETE to confirm'**
  String get mustTypeDeleteToConfirm;

  /// Deleting all data progress message
  ///
  /// In en, this message translates to:
  /// **'Deleting all data...'**
  String get deletingAllData;

  /// All data deleted success
  ///
  /// In en, this message translates to:
  /// **'✅ All data deleted. App will restart.'**
  String get allDataDeleted;

  /// FAQ subtitle
  ///
  /// In en, this message translates to:
  /// **'Find answers to common questions'**
  String get findAnswersToCommonQuestions;

  /// Support request email subject
  ///
  /// In en, this message translates to:
  /// **'Everyday Christian Support Request'**
  String get supportRequestSubject;

  /// Support request email body
  ///
  /// In en, this message translates to:
  /// **'Please describe your issue or question:\n\n'**
  String get supportRequestBody;

  /// Email client open error with fallback
  ///
  /// In en, this message translates to:
  /// **'Could not open email client. Please email connect@everydaychristian.app'**
  String get couldNotOpenEmailClient;

  /// Email open generic error with fallback
  ///
  /// In en, this message translates to:
  /// **'Error opening email: Please email connect@everydaychristian.app'**
  String get errorOpeningEmail;

  /// Daily Bread achievement with streak
  ///
  /// In en, this message translates to:
  /// **'Complete 30 devotionals • 🔥 {count} day{plural} streak'**
  String achievementDailyBreadDescWithStreak(int count, String plural);

  /// Profile loading error
  ///
  /// In en, this message translates to:
  /// **'Error loading profile: {error}'**
  String errorLoadingProfile(String error);

  /// Oops error title
  ///
  /// In en, this message translates to:
  /// **'Oops!'**
  String get oops;

  /// Try again button
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Technical details header
  ///
  /// In en, this message translates to:
  /// **'Technical details:'**
  String get technicalDetails;

  /// App initialization message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get initializingApp;

  /// Initialization error title
  ///
  /// In en, this message translates to:
  /// **'Initialization Error'**
  String get initializationError;

  /// Unexpected error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// Messages left with pluralization
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no messages} =1{1 message left} other{# messages left}}'**
  String messagesLeftCount(int count);

  /// Full app name
  ///
  /// In en, this message translates to:
  /// **'Everyday Christian'**
  String get appNameFull;

  /// App tagline for marketing
  ///
  /// In en, this message translates to:
  /// **'AI Biblical Guidance'**
  String get appTaglineBiblical;

  /// Download CTA
  ///
  /// In en, this message translates to:
  /// **'Get Everyday Christian'**
  String get getEverydayChristian;

  /// Download CTA with arrow
  ///
  /// In en, this message translates to:
  /// **'Download Everyday Christian →'**
  String get downloadEverydayChristian;

  /// Daily devotional notification title
  ///
  /// In en, this message translates to:
  /// **'Daily Devotional: {title}'**
  String dailyDevotionalTitle(String title);

  /// Daily devotional notification fallback title
  ///
  /// In en, this message translates to:
  /// **'Daily Devotional'**
  String get dailyDevotionalFallback;

  /// Devotional notification body
  ///
  /// In en, this message translates to:
  /// **'Start your day with God\'s word'**
  String get startDayWithGodsWord;

  /// Daily devotional notification channel name
  ///
  /// In en, this message translates to:
  /// **'Daily Devotional'**
  String get dailyDevotionalChannelName;

  /// Daily devotional notification channel description
  ///
  /// In en, this message translates to:
  /// **'Daily devotional reminders'**
  String get dailyDevotionalChannelDesc;

  /// Daily verse notification channel name
  ///
  /// In en, this message translates to:
  /// **'Daily Verse'**
  String get dailyVerseChannelName;

  /// Daily verse notification channel description
  ///
  /// In en, this message translates to:
  /// **'Daily verse notifications'**
  String get dailyVerseChannelDesc;

  /// Prayer reminder notification title
  ///
  /// In en, this message translates to:
  /// **'Prayer Reminder'**
  String get prayerReminder;

  /// Prayer time notification title
  ///
  /// In en, this message translates to:
  /// **'Time to Pray'**
  String get timeToPray;

  /// Prayer reminder notification body with pluralization
  ///
  /// In en, this message translates to:
  /// **'You have {count, plural, =1{one prayer request} other{# prayer requests}} to lift up today'**
  String prayerReminderBody(int count);

  /// Prayer reminder alternative body
  ///
  /// In en, this message translates to:
  /// **'Take a moment to spend time with God'**
  String get timeWithGod;

  /// Prayer reminders notification channel name
  ///
  /// In en, this message translates to:
  /// **'Prayer Reminders'**
  String get prayerRemindersChannelName;

  /// Prayer reminders notification channel description
  ///
  /// In en, this message translates to:
  /// **'Prayer reminder notifications'**
  String get prayerRemindersChannelDesc;

  /// Bible reading notification title
  ///
  /// In en, this message translates to:
  /// **'Bible Reading: {title}'**
  String bibleReadingTitle(String title);

  /// Bible reading notification fallback title
  ///
  /// In en, this message translates to:
  /// **'Bible Reading'**
  String get bibleReadingFallback;

  /// Reading plan notification body
  ///
  /// In en, this message translates to:
  /// **'Continue your reading plan today'**
  String get continueReadingPlan;

  /// Start reading plan notification body
  ///
  /// In en, this message translates to:
  /// **'Start a reading plan to grow in God\'s word'**
  String get startReadingPlanNotification;

  /// Reading plan notification channel name
  ///
  /// In en, this message translates to:
  /// **'Reading Plan'**
  String get readingPlanChannelName;

  /// Reading plan notification channel description
  ///
  /// In en, this message translates to:
  /// **'Bible reading plan reminders'**
  String get readingPlanChannelDesc;

  /// Language change confirmation for English
  ///
  /// In en, this message translates to:
  /// **'Language changed to English'**
  String get languageChangedToEnglish;

  /// Language change confirmation for Spanish
  ///
  /// In en, this message translates to:
  /// **'Language changed to Spanish'**
  String get languageChangedToSpanish;

  /// Delete confirmation warning header
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete:'**
  String get thisWillPermanentlyDelete;

  /// Data deletion error message
  ///
  /// In en, this message translates to:
  /// **'❌ Failed to delete data: {error}'**
  String failedToDeleteData(String error);

  /// Email subject for verse sharing
  ///
  /// In en, this message translates to:
  /// **'Bible Verse - {reference}'**
  String verseShareSubject(String reference);

  /// Tooltip for chat options button
  ///
  /// In en, this message translates to:
  /// **'Chat Options'**
  String get chatOptionsTooltip;

  /// Tooltip for conversation history button
  ///
  /// In en, this message translates to:
  /// **'Conversation History'**
  String get conversationHistoryTooltip;

  /// Tooltip for new conversation button
  ///
  /// In en, this message translates to:
  /// **'New Conversation'**
  String get newConversationTooltip;

  /// Generic error message template
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String genericError(String error);

  /// Bible books loading error
  ///
  /// In en, this message translates to:
  /// **'Error loading books: {error}'**
  String errorLoadingBooks(String error);

  /// Data export success with counts
  ///
  /// In en, this message translates to:
  /// **'📤 Exported {prayerCount} prayer journal(s) and {chatCount} conversation(s)'**
  String exportedDataSuccessfully(int prayerCount, int chatCount);

  /// Cache clearing success message
  ///
  /// In en, this message translates to:
  /// **'✅ Cache cleared successfully'**
  String get cacheClearedSuccessfully;

  /// Biometric unlock prompt for app launch
  ///
  /// In en, this message translates to:
  /// **'Unlock Everyday Christian to access your spiritual content'**
  String get unlockAppPrompt;

  /// Biometric setup prompt reason
  ///
  /// In en, this message translates to:
  /// **'Enable app lock to protect your spiritual content'**
  String get enableAppLockPrompt;

  /// Legal documents acceptance validation error
  ///
  /// In en, this message translates to:
  /// **'Please read and accept both documents'**
  String get pleaseAcceptDocuments;

  /// Chat input placeholder text
  ///
  /// In en, this message translates to:
  /// **'Scripture Chat...'**
  String get scriptureChatHint;

  /// Current streak label in reading progress
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// Best/longest streak label in reading progress
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreak;

  /// Active days label in reading progress
  ///
  /// In en, this message translates to:
  /// **'Active Days'**
  String get activeDays;

  /// Completed readings label
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedReadings;

  /// Format for 'X of Y'
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String ofTotal(int total);

  /// Estimated completion date label
  ///
  /// In en, this message translates to:
  /// **'Estimated Completion'**
  String get estimatedCompletion;

  /// Explanation of how estimated completion date is calculated
  ///
  /// In en, this message translates to:
  /// **'Based on your current reading pace. Skipping days will adjust this estimate.'**
  String get estimatedCompletionExplanation;

  /// Format for 'in X days'
  ///
  /// In en, this message translates to:
  /// **'in {count} {days}'**
  String inDays(int count, String days);

  /// Today with exclamation
  ///
  /// In en, this message translates to:
  /// **'today!'**
  String get todayExclamation;

  /// Format for 'X days overdue'
  ///
  /// In en, this message translates to:
  /// **'{count} {days} overdue'**
  String daysOverdue(int count, String days);

  /// Singular 'day'
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// Heatmap legend label for less activity
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get heatmapLess;

  /// Heatmap legend label for more activity
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get heatmapMore;

  /// Month name
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthJanuary;

  /// Month name
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFebruary;

  /// Month name
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthMarch;

  /// Month name
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthApril;

  /// Month name
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// Month name
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthJune;

  /// Month name
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthJuly;

  /// Month name
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthAugust;

  /// Month name
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthSeptember;

  /// Month name
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthOctober;

  /// Month name
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthNovember;

  /// Month name
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthDecember;

  /// Bottom sheet title for message options
  ///
  /// In en, this message translates to:
  /// **'Message Options'**
  String get messageOptions;

  /// Bottom sheet title for conversation history
  ///
  /// In en, this message translates to:
  /// **'Conversation History'**
  String get conversationHistory;

  /// Menu item: export conversation
  ///
  /// In en, this message translates to:
  /// **'Export Conversation'**
  String get exportConversation;

  /// Menu item description: export conversation
  ///
  /// In en, this message translates to:
  /// **'View and copy conversation text'**
  String get exportConversationDesc;

  /// Menu item description: share as text
  ///
  /// In en, this message translates to:
  /// **'Share as plain text'**
  String get shareTextDesc;

  /// Menu item: share as image
  ///
  /// In en, this message translates to:
  /// **'Share as Image'**
  String get shareAsImage;

  /// Menu item description: share as image
  ///
  /// In en, this message translates to:
  /// **'Share conversation as branded image'**
  String get shareAsImageDesc;

  /// Menu item: copy message
  ///
  /// In en, this message translates to:
  /// **'Copy Message'**
  String get copyMessage;

  /// Menu item description: copy message
  ///
  /// In en, this message translates to:
  /// **'Copy message text to clipboard'**
  String get copyMessageDesc;

  /// Menu item: regenerate AI response
  ///
  /// In en, this message translates to:
  /// **'Regenerate Response'**
  String get regenerateResponse;

  /// Menu item description: regenerate response
  ///
  /// In en, this message translates to:
  /// **'Generate a new response to this message'**
  String get regenerateResponseDesc;

  /// Menu item: share message exchange
  ///
  /// In en, this message translates to:
  /// **'Share Exchange'**
  String get shareExchange;

  /// Menu item description: share exchange
  ///
  /// In en, this message translates to:
  /// **'Share this message exchange as image'**
  String get shareExchangeDesc;

  /// Error message when trying to regenerate without subscription
  ///
  /// In en, this message translates to:
  /// **'Subscription required to regenerate responses'**
  String get subscriptionRequiredRegenerate;

  /// Error message when regeneration fails
  ///
  /// In en, this message translates to:
  /// **'Failed to regenerate response: {error}'**
  String failedToRegenerate(String error);

  /// Info message when no conversation exists
  ///
  /// In en, this message translates to:
  /// **'No conversation to export'**
  String get noConversationToExport;

  /// Info message when no messages exist
  ///
  /// In en, this message translates to:
  /// **'No messages to export'**
  String get noMessagesToExport;

  /// Success message after exporting conversation
  ///
  /// In en, this message translates to:
  /// **'Conversation exported successfully'**
  String get conversationExported;

  /// Error message when export fails
  ///
  /// In en, this message translates to:
  /// **'Failed to export: {error}'**
  String failedToExport(String error);

  /// Info message when no conversation exists to share
  ///
  /// In en, this message translates to:
  /// **'No conversation to share'**
  String get noConversationToShare;

  /// Info message when no messages exist to share
  ///
  /// In en, this message translates to:
  /// **'No messages to share'**
  String get noMessagesToShare;

  /// Success message after sharing conversation
  ///
  /// In en, this message translates to:
  /// **'Conversation shared successfully'**
  String get conversationShared;

  /// Error message when sharing fails
  ///
  /// In en, this message translates to:
  /// **'Failed to share: {error}'**
  String failedToShare(String error);

  /// Success message after sharing conversation as image
  ///
  /// In en, this message translates to:
  /// **'Conversation image shared successfully'**
  String get conversationImageShared;

  /// Error message when sharing fails (generic)
  ///
  /// In en, this message translates to:
  /// **'Failed to share. Please try again.'**
  String get failedToShareTryAgain;

  /// Error message when user question not found
  ///
  /// In en, this message translates to:
  /// **'Could not find the question for this response'**
  String get questionNotFound;

  /// Success message after sharing message exchange
  ///
  /// In en, this message translates to:
  /// **'Message exchange shared successfully!'**
  String get messageExchangeShared;

  /// Success message after copying message
  ///
  /// In en, this message translates to:
  /// **'Message copied to clipboard'**
  String get messageCopied;

  /// Success message after deleting conversation
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted'**
  String get conversationDeleted;

  /// Export dialog title
  ///
  /// In en, this message translates to:
  /// **'Export Conversation'**
  String get exportConversationTitle;

  /// Delete conversation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation?'**
  String get deleteConversationTitle;

  /// Delete conversation dialog message
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this conversation and all its messages.'**
  String get deleteConversationMessage;

  /// New conversation dialog title
  ///
  /// In en, this message translates to:
  /// **'Start New Conversation?'**
  String get startNewConversationTitle;

  /// New conversation dialog message
  ///
  /// In en, this message translates to:
  /// **'Your current conversation will be saved to history.\n\nStart a fresh conversation?'**
  String get startNewConversationMessage;

  /// New chat button text
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// Full welcome message for new conversations
  ///
  /// In en, this message translates to:
  /// **'Peace be with you! 🙏\n\nI\'m here to provide intelligent scripture support directly from the word itself, for everyday Christian questions. Feel free to ask me about:\n\n• Scripture interpretation\n• Prayer requests\n• Life challenges\n• Faith questions\n• Daily encouragement\n\nHow can I help you today?'**
  String get chatWelcomeMessageFull;

  /// Error when previous message not found
  ///
  /// In en, this message translates to:
  /// **'Could not find previous user message'**
  String get errorPreviousMessage;

  /// Loading message while AI initializes
  ///
  /// In en, this message translates to:
  /// **'Initializing AI service...'**
  String get initializingAI;

  /// Message when using fallback responses
  ///
  /// In en, this message translates to:
  /// **'Using fallback responses: {reason}'**
  String usingFallback(String reason);

  /// AI service error message
  ///
  /// In en, this message translates to:
  /// **'AI service error: {message}'**
  String aiServiceError(String message);

  /// No internet error title
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// No internet error message
  ///
  /// In en, this message translates to:
  /// **'AI chat requires internet. Your Bible, prayers, and saved verses work offline.'**
  String get aiRequiresInternet;

  /// Empty state message for conversation history
  ///
  /// In en, this message translates to:
  /// **'No conversation history yet'**
  String get noConversationHistory;

  /// Default title for untitled conversations
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get conversationDefaultTitle;

  /// AppBar title when discussing a specific verse
  ///
  /// In en, this message translates to:
  /// **'Discussing {reference}'**
  String discussingVerse(String reference);

  /// AppBar title for new conversation
  ///
  /// In en, this message translates to:
  /// **'New Conversation'**
  String get newConversation;

  /// Fallback response about prayer when AI unavailable
  ///
  /// In en, this message translates to:
  /// **'Prayer is our direct line to God. As it says in Philippians 4:6-7: \"Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God. And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus.\"\n\nWhat specific area would you like prayer for?'**
  String get fallbackPrayerResponse;

  /// Fallback response about fear when AI unavailable
  ///
  /// In en, this message translates to:
  /// **'I understand you\'re feeling fearful. Remember what God says in Isaiah 41:10: \"Fear not, for I am with you; be not dismayed, for I am your God; I will strengthen you, I will help you, I will uphold you with my righteous right hand.\"\n\nGod is always with you, even in your darkest moments. What is causing you to feel this way?'**
  String get fallbackFearResponse;

  /// Fallback response about love when AI unavailable
  ///
  /// In en, this message translates to:
  /// **'Love is at the heart of the Christian faith. 1 John 4:19 tells us \"We love because he first loved us.\" God\'s love for us is unconditional and eternal.\n\nIn our relationships with others, we\'re called to love as Christ loved us - with patience, kindness, and forgiveness. How can I help you apply God\'s love in your situation?'**
  String get fallbackLoveResponse;

  /// Fallback response about forgiveness when AI unavailable
  ///
  /// In en, this message translates to:
  /// **'Forgiveness is one of God\'s greatest gifts to us. As Jesus taught us in Matthew 6:14-15: \"If you forgive other people when they sin against you, your heavenly Father will also forgive you.\"\n\nForgiveness doesn\'t mean forgetting or excusing wrong behavior, but it frees us from the burden of resentment. What situation are you struggling to forgive?'**
  String get fallbackForgivenessResponse;

  /// Fallback response about purpose when AI unavailable
  ///
  /// In en, this message translates to:
  /// **'God has a unique purpose for your life! Jeremiah 29:11 reminds us: \"For I know the plans I have for you,\" declares the Lord, \"plans to prosper you and not to harm you, to give you hope and a future.\"\n\nYour purpose is found in loving God and serving others. What gifts and passions has God given you that you could use to serve Him?'**
  String get fallbackPurposeResponse;

  /// Default fallback response when AI unavailable
  ///
  /// In en, this message translates to:
  /// **'Thank you for sharing with me. God cares deeply about every aspect of your life, both big and small. As it says in 1 Peter 5:7: \"Cast all your anxiety on him because he cares for you.\"\n\nRemember that you are loved, valued, and never alone. God is always listening and ready to help. Would you like to explore a specific Bible verse or topic related to your question?'**
  String get fallbackDefaultResponse;

  /// AI instruction for regenerating responses
  ///
  /// In en, this message translates to:
  /// **'Please provide a different perspective or alternative response to the previous question.'**
  String get aiRegenerateInstruction;

  /// Error message when user submits empty message
  ///
  /// In en, this message translates to:
  /// **'Message cannot be empty.'**
  String get securityMessageEmpty;

  /// Error message when message is too short
  ///
  /// In en, this message translates to:
  /// **'Message is too short. Please share what\'s on your heart.'**
  String get securityMessageTooShort;

  /// Error message when message exceeds max length
  ///
  /// In en, this message translates to:
  /// **'Message is too long. Please keep your message under {maxLength} characters.'**
  String securityMessageTooLong(int maxLength);

  /// Error message when user exceeds rate limit
  ///
  /// In en, this message translates to:
  /// **'Please slow down. You can send up to {maxMessages} messages per minute.'**
  String securityRateLimit(int maxMessages);

  /// Suspension message for jailbreak attempts - stern only, no guidance offer
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended due to violations of our community guidelines.'**
  String get securityJailbreakAttempt;

  /// Warning message for profanity detection
  ///
  /// In en, this message translates to:
  /// **'Please use respectful language. I\'m here to support you with compassion.'**
  String get securityProfanity;

  /// Respectful redirection message for faith-targeted offensive content
  ///
  /// In en, this message translates to:
  /// **'I respect where you\'re coming from. If you have doubts or questions about faith, I\'m happy to discuss them respectfully.'**
  String get securityFaithOffense;

  /// Psalm 107:1 verse text for devotional demo in onboarding
  ///
  /// In en, this message translates to:
  /// **'\"Give thanks to the LORD, for he is good, for his loving kindness endures forever.\"'**
  String get demoDevotionalVerseText;

  /// Psalm 107:1 reference for devotional demo in onboarding
  ///
  /// In en, this message translates to:
  /// **'Psalm 107:1'**
  String get demoDevotionalVerseReference;

  /// Semantic label for stop audio button
  ///
  /// In en, this message translates to:
  /// **'Stop audio'**
  String get stopAudio;

  /// Semantic label for play audio button
  ///
  /// In en, this message translates to:
  /// **'Play audio'**
  String get playAudio;

  /// Semantic label for pause audio button
  ///
  /// In en, this message translates to:
  /// **'Pause audio'**
  String get pauseAudio;

  /// Tooltip for back navigation button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// Tooltip for previous chapter navigation button
  ///
  /// In en, this message translates to:
  /// **'Previous chapter'**
  String get previousChapter;

  /// Tooltip for next chapter navigation button
  ///
  /// In en, this message translates to:
  /// **'Next chapter'**
  String get nextChapter;

  /// Tooltip for add to favorites button
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// Tooltip for remove from favorites button
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// Tooltip for verse options button
  ///
  /// In en, this message translates to:
  /// **'Verse options'**
  String get verseOptions;

  /// Tooltip for clear search button
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// Semantic label for app logo image
  ///
  /// In en, this message translates to:
  /// **'Everyday Christian app logo'**
  String get appLogo;

  /// Semantic label for AI assistant logo image
  ///
  /// In en, this message translates to:
  /// **'AI assistant logo'**
  String get aiAssistantLogo;

  /// Short label for active prayers tab (used at large text sizes)
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeShort;

  /// Short label for answered prayers tab (used at large text sizes)
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get answeredShort;

  /// Short label for verse library quick action (used at large text sizes)
  ///
  /// In en, this message translates to:
  /// **'Verse Library'**
  String get verseLibraryShort;

  /// Short label for add prayer quick action (used at large text sizes 130%-150%)
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get addPrayerShort;

  /// Short label for add prayer dialog button (used at large text sizes 130%-150%)
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get addPrayerButtonShort;

  /// Skip button text for tutorials
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialSkip;

  /// Next button text for tutorials
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNext;

  /// Previous button text for tutorials
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get tutorialPrevious;

  /// Finish button text for tutorials
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get tutorialFinish;

  /// Title for home screen FAB menu tutorial
  ///
  /// In en, this message translates to:
  /// **'Navigation Menu'**
  String get tutorialHomeTitle;

  /// Description for home screen FAB menu tutorial
  ///
  /// In en, this message translates to:
  /// **'Tap this menu to navigate between different sections of the app - Bible, Chat, Prayers, Devotionals, and more!'**
  String get tutorialHomeDescription;

  /// Title for Bible tap-to-select tutorial
  ///
  /// In en, this message translates to:
  /// **'Tap to Select Verses'**
  String get tutorialBibleTapTitle;

  /// Description for Bible tap-to-select tutorial
  ///
  /// In en, this message translates to:
  /// **'Tap any verse to select it. Long press to view options like bookmarking and sharing.'**
  String get tutorialBibleTapDescription;

  /// Title for Bible bookmark tutorial
  ///
  /// In en, this message translates to:
  /// **'Bookmark Your Favorites'**
  String get tutorialBibleBookmarkTitle;

  /// Description for Bible bookmark tutorial
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark icon to save verses for quick access later.'**
  String get tutorialBibleBookmarkDescription;

  /// Title for Bible verse chat tutorial
  ///
  /// In en, this message translates to:
  /// **'Intelligent Verse Chat'**
  String get tutorialBibleChatTitle;

  /// Description for Bible verse chat tutorial
  ///
  /// In en, this message translates to:
  /// **'Ask questions about any verse and get biblical insights and explanations.'**
  String get tutorialBibleChatDescription;

  /// Title for prayer screen add button tutorial
  ///
  /// In en, this message translates to:
  /// **'Add Your Prayers'**
  String get tutorialPrayerTitle;

  /// Description for prayer screen add button tutorial
  ///
  /// In en, this message translates to:
  /// **'Tap here to add a new prayer request. Track your prayers and mark them as answered!'**
  String get tutorialPrayerDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
