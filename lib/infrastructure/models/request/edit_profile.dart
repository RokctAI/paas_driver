class EditProfile {
  String? firstname;
  String? lastname;
  String? birthday;
  String? gender;
  String? phone;
  String? secondPhone;
  List<String>? images;

  EditProfile(
      {this.firstname,
        this.lastname,
        this.birthday,
        this.gender,
        this.phone,
        this.secondPhone,
        this.images
        });

  EditProfile.fromJson(Map<String, dynamic> json) {
    firstname = json['firstname'];
    lastname = json['lastname'];
    birthday = json['birthday'];
    gender = json['gender'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['firstname'] = firstname;
    data['lastname'] = lastname;
    data['birthday'] = birthday;
    data['gender'] = gender;
    data["images"] = images;
    return data;
  }
}