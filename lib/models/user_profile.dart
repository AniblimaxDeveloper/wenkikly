class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String tier; // free, go, plus, pro, max
  final String phone;
  final String address;

  UserProfile({
    required this.uid, required this.email, required this.displayName, 
    this.photoUrl, this.tier = 'free', this.phone = '', this.address = '',
  });

  Map<String, dynamic> toJson() => {
    'uid': uid, 'email': email, 'displayName': displayName, 
    'photoUrl': photoUrl, 'tier': tier, 'phone': phone, 'address': address
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'] ?? '', email: json['email'] ?? '', displayName: json['displayName'] ?? '',
    photoUrl: json['photoUrl'], tier: json['tier'] ?? 'free', phone: json['phone'] ?? '', address: json['address'] ?? ''
  );
}
