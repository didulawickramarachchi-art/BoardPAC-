class SettingRequest {
  final String settingGroup;
  final String settingKey;
  final String settingValue;
  final String? description;

  SettingRequest({
    required this.settingGroup,
    required this.settingKey,
    required this.settingValue,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'settingGroup': settingGroup,
      'settingKey': settingKey,
      'settingValue': settingValue,
      'description': description,
    };
  }
}
