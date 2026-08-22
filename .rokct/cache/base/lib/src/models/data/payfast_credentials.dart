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


class PayFastCredentials {
  //final String merchantId;
  final String merchantKey;
  final String passphrase;
  final bool isSandbox;

  PayFastCredentials({
    //required this.merchantId,
    required this.merchantKey,
    required this.passphrase,
    this.isSandbox = true,
  });

  factory PayFastCredentials.fromJson(Map<String, dynamic> json) {
    return PayFastCredentials(
      // merchantId: json['merchant_id'] as String,
      merchantKey: json['merchant_key'] as String,
      passphrase: json['passphrase'] as String,
      isSandbox: json['is_sandbox'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'merchant_id': merchantId,
      'merchant_key': merchantKey,
      'passphrase': passphrase,
      'is_sandbox': isSandbox,
    };
  }
}
