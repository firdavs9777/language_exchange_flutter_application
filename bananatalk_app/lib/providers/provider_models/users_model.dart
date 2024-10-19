// Category Object Blueprint
class User {
  const User({
    required this.name,
    required this.password,
    required this.email,
    required this.bio,
    required this.image,
    required this.birth_day,
    required this.birth_month,
    required this.gender,
    required this.birth_year,
    required this.native_language,
    required this.language_to_learn,
  });

  final String name;
  final String password;
  final String email;
  final String bio;
  final String image;
  final String gender;
  final String native_language;
  final String language_to_learn;
  final String birth_year;
  final String birth_month;
  final String birth_day;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'password': password,
      'email': email,
      'birth_year': birth_year,
      'birth_month': birth_month,
      'birth_day': birth_day,
      'image': image,
      'bio': bio,
      'gender': gender,
      'native_language': native_language,
      'language_to_learn': language_to_learn,
    };
  }
}
