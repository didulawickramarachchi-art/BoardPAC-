class SettingModel {
  final int id;
  final String settingGroup;
  final String settingKey;
  final String settingValue;
  final String? description;

  SettingModel({
    required this.id,
    required this.settingGroup,
    required this.settingKey,
    required this.settingValue,
    this.description,
  });

  factory SettingModel.fromJson(Map<String, dynamic> json) {
    return SettingModel(
      id: json['id'],
      settingGroup: json['settingGroup'] ?? '',
      settingKey: json['settingKey'] ?? '',
      settingValue: json['settingValue'] ?? '',
      description: json['description'],
    );
  }
}
