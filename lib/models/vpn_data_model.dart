class VpnData {
  final String id;
  final String username;
  final String serverName;
  final String profileName;
  final String userProfile;
  final String password;
  final String vpnConfigPath;

  VpnData({
    required this.id,
    required this.username,
    required this.serverName,
    required this.profileName,
    required this.userProfile,
    required this.password,
    required this.vpnConfigPath,
  });

factory VpnData.fromJson(Map<String, dynamic> json, int index) {
  return VpnData(
    id: json['id'] ?? '',
    username: json['username'] ?? '',
    serverName: json['serverName'] ?? '',
    profileName: json['profileName'] ?? '',
    userProfile: json['userProfile'] ?? 'test $index',
    password: json['password'] ?? '',
    vpnConfigPath: json['vpnConfigPath'] ?? '',
  );
}

  Map<String, String> toJson() {
    return {
      'id': id,
      'username': username,
      'userProfile':userProfile,
      'serverName': serverName,
      'profileName': profileName,
      'password': password,
      'vpnConfigPath': vpnConfigPath,
    };
  }
}
