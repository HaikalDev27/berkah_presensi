/// models/update_info.dart
class UpdateInfo {
  final int versionCode;
  final String versionName;
  final String apkUrl;
  final bool isMandatory;
  final String changelog;

  UpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    required this.isMandatory,
    required this.changelog,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      versionCode: json['version_code'] as int,
      versionName: json['version_name'] as String,
      apkUrl: json['apk_url'] as String,
      isMandatory: json['is_mandatory'] as bool? ?? false,
      changelog: json['changelog'] as String? ?? '',
    );
  }
}
