import 'package:freezed_annotation/freezed_annotation.dart';

part 'prayer_request.freezed.dart';
part 'prayer_request.g.dart';

@freezed
class PrayerRequest with _$PrayerRequest {
  const factory PrayerRequest({
    required String id,
    required String title,
    required String description,
    required String categoryId,  // Changed from PrayerCategory to String categoryId
    required DateTime dateCreated,
    @Default(false) bool isAnswered,
    DateTime? dateAnswered,
    String? answerDescription,
  }) = _PrayerRequest;

  factory PrayerRequest.fromJson(Map<String, dynamic> json) =>
      _$PrayerRequestFromJson(json);
}