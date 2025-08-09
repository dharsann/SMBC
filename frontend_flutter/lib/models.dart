class UserModel {
  final String id;
  final String walletAddress;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.walletAddress,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        walletAddress: json['wallet_address'] as String,
        username: json['username'] as String?,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class AuthResponseModel {
  final String token;
  final UserModel user;

  AuthResponseModel({required this.token, required this.user});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) => AuthResponseModel(
        token: json['access_token'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class MessageModel {
  final String id;
  final Map<String, dynamic> sender; // {id, wallet_address, username, display_name}
  final String recipientId;
  final String content;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.sender,
    required this.recipientId,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        sender: json['sender'] as Map<String, dynamic>,
        recipientId: json['recipient_id'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}