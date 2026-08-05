import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'케이메디웰'**
  String get appTitle;

  /// No description provided for @bookingTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약하기'**
  String get bookingTitle;

  /// No description provided for @selectTreatment.
  ///
  /// In ko, this message translates to:
  /// **'시술 선택'**
  String get selectTreatment;

  /// No description provided for @selectDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜 선택'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In ko, this message translates to:
  /// **'시간 선택'**
  String get selectTime;

  /// No description provided for @patientName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get patientName;

  /// No description provided for @phone.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get email;

  /// No description provided for @confirmBooking.
  ///
  /// In ko, this message translates to:
  /// **'예약 확인'**
  String get confirmBooking;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @checkReservation.
  ///
  /// In ko, this message translates to:
  /// **'예약 조회'**
  String get checkReservation;

  /// No description provided for @confirmCode.
  ///
  /// In ko, this message translates to:
  /// **'예약 확인번호'**
  String get confirmCode;

  /// No description provided for @enterConfirmCode.
  ///
  /// In ko, this message translates to:
  /// **'확인번호를 입력하세요'**
  String get enterConfirmCode;

  /// No description provided for @search.
  ///
  /// In ko, this message translates to:
  /// **'조회'**
  String get search;

  /// No description provided for @status.
  ///
  /// In ko, this message translates to:
  /// **'상태'**
  String get status;

  /// No description provided for @treatment.
  ///
  /// In ko, this message translates to:
  /// **'시술'**
  String get treatment;

  /// No description provided for @date.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get date;

  /// No description provided for @time.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get time;

  /// No description provided for @cancelReservation.
  ///
  /// In ko, this message translates to:
  /// **'예약 취소'**
  String get cancelReservation;

  /// No description provided for @payment.
  ///
  /// In ko, this message translates to:
  /// **'결제'**
  String get payment;

  /// No description provided for @payNow.
  ///
  /// In ko, this message translates to:
  /// **'결제하기'**
  String get payNow;

  /// No description provided for @totalAmount.
  ///
  /// In ko, this message translates to:
  /// **'결제 금액'**
  String get totalAmount;

  /// No description provided for @bookingComplete.
  ///
  /// In ko, this message translates to:
  /// **'예약 완료'**
  String get bookingComplete;

  /// No description provided for @bookingCancelled.
  ///
  /// In ko, this message translates to:
  /// **'예약 취소 완료'**
  String get bookingCancelled;

  /// No description provided for @noSlots.
  ///
  /// In ko, this message translates to:
  /// **'예약 가능한 슬롯이 없습니다.'**
  String get noSlots;

  /// No description provided for @noTreatments.
  ///
  /// In ko, this message translates to:
  /// **'시술 목록을 불러올 수 없습니다.'**
  String get noTreatments;

  /// No description provided for @loading.
  ///
  /// In ko, this message translates to:
  /// **'로딩 중...'**
  String get loading;

  /// No description provided for @errorOccurred.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다.'**
  String get errorOccurred;

  /// No description provided for @required.
  ///
  /// In ko, this message translates to:
  /// **'필수 입력 항목입니다.'**
  String get required;

  /// No description provided for @invalidPhone.
  ///
  /// In ko, this message translates to:
  /// **'올바른 연락처를 입력하세요.'**
  String get invalidPhone;

  /// No description provided for @invalidEmail.
  ///
  /// In ko, this message translates to:
  /// **'올바른 이메일을 입력하세요.'**
  String get invalidEmail;

  /// No description provided for @statusPending.
  ///
  /// In ko, this message translates to:
  /// **'예약 완료'**
  String get statusPending;

  /// No description provided for @statusArrived.
  ///
  /// In ko, this message translates to:
  /// **'내원 확인'**
  String get statusArrived;

  /// No description provided for @statusDone.
  ///
  /// In ko, this message translates to:
  /// **'시술 완료'**
  String get statusDone;

  /// No description provided for @statusCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소됨'**
  String get statusCancelled;

  /// No description provided for @min.
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get min;

  /// No description provided for @won.
  ///
  /// In ko, this message translates to:
  /// **'원'**
  String get won;

  /// No description provided for @languageSelect.
  ///
  /// In ko, this message translates to:
  /// **'언어 선택'**
  String get languageSelect;

  /// No description provided for @points.
  ///
  /// In ko, this message translates to:
  /// **'포인트'**
  String get points;

  /// No description provided for @coupon.
  ///
  /// In ko, this message translates to:
  /// **'쿠폰'**
  String get coupon;

  /// No description provided for @couponCode.
  ///
  /// In ko, this message translates to:
  /// **'쿠폰 코드'**
  String get couponCode;

  /// No description provided for @applyCoupon.
  ///
  /// In ko, this message translates to:
  /// **'쿠폰 적용'**
  String get applyCoupon;

  /// No description provided for @discount.
  ///
  /// In ko, this message translates to:
  /// **'할인'**
  String get discount;

  /// No description provided for @finalAmount.
  ///
  /// In ko, this message translates to:
  /// **'최종 금액'**
  String get finalAmount;

  /// No description provided for @writeReview.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 작성'**
  String get writeReview;

  /// No description provided for @rating.
  ///
  /// In ko, this message translates to:
  /// **'평점'**
  String get rating;

  /// No description provided for @reviewComment.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 내용 (선택)'**
  String get reviewComment;

  /// No description provided for @submitReview.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 등록'**
  String get submitReview;

  /// No description provided for @duration.
  ///
  /// In ko, this message translates to:
  /// **'소요 시간'**
  String get duration;
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
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
