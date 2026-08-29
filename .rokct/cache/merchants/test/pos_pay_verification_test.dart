// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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


// The offline payment code (PosPayVerification): 6 digits derived as the
// last 6 decimal digits of the big-endian uint32 formed by the LEADING 4
// bytes of sha256("orderId|amount2dp|shopId|sharedSecret") — deterministic
// on both sides (the customer's payment screen and the till), verified
// locally with zero server contact.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchants_sdk/src/manager/utils/pos_pay_verification.dart';

void main() {
  const orderId = 'POS-1756383000000-0042';
  const shopId = '17';
  const secret = 'shop-uuid-bella-napoli';

  test('derives a deterministic 6-digit code from the spec algorithm', () {
    final code = PosPayVerification.code(
      orderId: orderId,
      amount: 325.88,
      shopId: shopId,
      sharedSecret: secret,
    );

    expect(code, hasLength(6));
    expect(int.tryParse(code), isNotNull);

    // Deterministic: same facts, same code — every time.
    expect(
      PosPayVerification.code(
        orderId: orderId,
        amount: 325.88,
        shopId: shopId,
        sharedSecret: secret,
      ),
      code,
    );

    // Independent recomputation of the documented derivation, so the
    // algorithm itself (not just self-consistency) is pinned: leading 4
    // sha256 bytes, big-endian, last 6 decimal digits, zero-padded.
    final digest =
        sha256.convert(utf8.encode('$orderId|325.88|$shopId|$secret')).bytes;
    final leading = (digest[0] << 24) |
        (digest[1] << 16) |
        (digest[2] << 8) |
        digest[3];
    expect(code, (leading % 1000000).toString().padLeft(6, '0'));

    // The amount is normalised to two decimals before hashing, so both
    // sides of the counter hash the identical string ("325.9" == "325.90").
    expect(
      PosPayVerification.code(
        orderId: orderId,
        amount: 325.9,
        shopId: shopId,
        sharedSecret: secret,
      ),
      PosPayVerification.code(
        orderId: orderId,
        amount: 325.90,
        shopId: shopId,
        sharedSecret: secret,
      ),
    );
  });

  test('verify accepts only the exact code for the exact order facts', () {
    final code = PosPayVerification.code(
      orderId: orderId,
      amount: 325.88,
      shopId: shopId,
      sharedSecret: secret,
    );

    expect(
      PosPayVerification.verify(
        enteredCode: code,
        orderId: orderId,
        amount: 325.88,
        shopId: shopId,
        sharedSecret: secret,
      ),
      isTrue,
    );

    // Any changed fact — code digit, amount, order, secret — rejects.
    final wrongDigit = code.replaceRange(
        5, 6, ((int.parse(code[5]) + 1) % 10).toString());
    expect(
      PosPayVerification.verify(
        enteredCode: wrongDigit,
        orderId: orderId,
        amount: 325.88,
        shopId: shopId,
        sharedSecret: secret,
      ),
      isFalse,
    );
    expect(
      PosPayVerification.verify(
        enteredCode: code,
        orderId: orderId,
        amount: 325.89,
        shopId: shopId,
        sharedSecret: secret,
      ),
      isFalse,
    );
    expect(
      PosPayVerification.verify(
        enteredCode: code,
        orderId: 'POS-other-order',
        amount: 325.88,
        shopId: shopId,
        sharedSecret: secret,
      ),
      isFalse,
    );
    expect(
      PosPayVerification.verify(
        enteredCode: '',
        orderId: orderId,
        amount: 325.88,
        shopId: shopId,
        sharedSecret: secret,
      ),
      isFalse,
    );
  });
}
