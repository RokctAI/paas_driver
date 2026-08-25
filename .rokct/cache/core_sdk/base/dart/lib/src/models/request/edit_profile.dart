// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


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
