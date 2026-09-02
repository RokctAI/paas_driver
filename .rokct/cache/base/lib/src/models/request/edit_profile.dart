// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.


class EditProfile {
  String? firstname;
  String? lastname;
  String? birthday;
  String? gender;
  String? phone;
  String? secondPhone;
  String? images;
  String? email;
  String? password;
  String? confirmPassword;
  String? referral;

  EditProfile({
    this.firstname,
    this.lastname,
    this.birthday,
    this.gender,
    this.phone,
    this.secondPhone,
    this.password,
    this.referral,
    this.email,
    this.confirmPassword,
    this.images,
  });

  EditProfile.fromJson(Map<String, dynamic> json) {
    firstname = json['firstname'];
    lastname = json['lastname'];
    birthday = json['birthday'];
    gender = json['gender'];
    email = json['email'];
    password = json['password'];
    confirmPassword = json['password_confirmation'];
    referral = json['referral'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (firstname != null) data['firstname'] = firstname;
    if (lastname != null) data['lastname'] = lastname;
    if (email != null) data['email'] = email;
    if (password != null) data['password'] = password;
    if (referral != null) data['referral'] = referral;
    if (confirmPassword != null) {
      data['password_confirmation'] = confirmPassword;
    }
    if (birthday != null) {
      data['birthday'] = birthday!.contains(" ")
          ? birthday?.substring(0, birthday?.indexOf(" "))
          : birthday;
    }
    if (gender != null) data['gender'] = gender;
    if (images != null && images!.isNotEmpty) data["images"] = [images];
    data["phone"] = phone;
    return data;
  }
}
