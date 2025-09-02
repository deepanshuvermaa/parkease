class User {
  final String id;
  final String username;
  final String password; // Will be hashed
  final String fullName;
  final String role; // admin, operator, guest
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isGuest;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final bool isPaid;
  final String? subscriptionId;
  final DateTime? subscriptionEndDate;
  final String? currentDeviceId;
  final String? lastDeviceId;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
    this.isGuest = false,
    this.trialStartDate,
    this.trialEndDate,
    this.isPaid = false,
    this.subscriptionId,
    this.subscriptionEndDate,
    this.currentDeviceId,
    this.lastDeviceId,
  });

  bool get isTrialActive {
    if (!isGuest || trialEndDate == null) return false;
    return DateTime.now().isBefore(trialEndDate!);
  }

  bool get isSubscriptionActive {
    if (!isPaid || subscriptionEndDate == null) return false;
    return DateTime.now().isBefore(subscriptionEndDate!);
  }

  bool get canAccess {
    if (role == 'admin' || role == 'operator') return isActive;
    if (isGuest) return isTrialActive || isSubscriptionActive;
    return isActive;
  }

  int get remainingTrialDays {
    if (!isGuest || trialEndDate == null) return 0;
    final remaining = trialEndDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullName': fullName,
      'role': role,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLogin': lastLogin?.millisecondsSinceEpoch,
      'isGuest': isGuest ? 1 : 0,
      'trialStartDate': trialStartDate?.millisecondsSinceEpoch,
      'trialEndDate': trialEndDate?.millisecondsSinceEpoch,
      'isPaid': isPaid ? 1 : 0,
      'subscriptionId': subscriptionId,
      'subscriptionEndDate': subscriptionEndDate?.millisecondsSinceEpoch,
      'currentDeviceId': currentDeviceId,
      'lastDeviceId': lastDeviceId,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      fullName: json['fullName'],
      role: json['role'],
      isActive: (json['isActive'] ?? 1) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      lastLogin: json['lastLogin'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastLogin'])
          : null,
      isGuest: (json['isGuest'] ?? 0) == 1,
      trialStartDate: json['trialStartDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['trialStartDate'])
          : null,
      trialEndDate: json['trialEndDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['trialEndDate'])
          : null,
      isPaid: (json['isPaid'] ?? 0) == 1,
      subscriptionId: json['subscriptionId'],
      subscriptionEndDate: json['subscriptionEndDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['subscriptionEndDate'])
          : null,
      currentDeviceId: json['currentDeviceId'],
      lastDeviceId: json['lastDeviceId'],
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? password,
    String? fullName,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isGuest,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    bool? isPaid,
    String? subscriptionId,
    DateTime? subscriptionEndDate,
    String? currentDeviceId,
    String? lastDeviceId,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isGuest: isGuest ?? this.isGuest,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      isPaid: isPaid ?? this.isPaid,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      currentDeviceId: currentDeviceId ?? this.currentDeviceId,
      lastDeviceId: lastDeviceId ?? this.lastDeviceId,
    );
  }
}