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


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:base_sdk/src/models/data/chat_message_data.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class ChatItem extends StatelessWidget {
  final ChatMessageData chatData;

  const ChatItem({super.key, required this.chatData});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: chatData.messageOwner == MessageOwner.partner
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.r),
              topRight: Radius.circular(25.r),
              bottomLeft: Radius.circular(
                chatData.messageOwner == MessageOwner.partner ? 0 : 25.r,
              ),
              bottomRight: Radius.circular(
                chatData.messageOwner == MessageOwner.you ? 0 : 25.r,
              ),
            ),
            color: chatData.messageOwner == MessageOwner.you
                ? AppStyle.primary
                : AppStyle.bgGrey,
          ),
          constraints: BoxConstraints(maxWidth: 256.r),
          padding: REdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Text(
            chatData.message,
            style: GoogleFonts.k2d(
              fontWeight: FontWeight.w500,
              fontSize: 16.sp,
              color: AppStyle.black,
              letterSpacing: -0.5,
            ),
          ),
        ),
        4.verticalSpace,
        Text(
          chatData.time,
          style: GoogleFonts.k2d(
            fontWeight: FontWeight.w500,
            fontSize: 10.sp,
            color: AppStyle.black,
            letterSpacing: -0.5,
          ),
        ),
        35.verticalSpace,
      ],
    );
  }
}
