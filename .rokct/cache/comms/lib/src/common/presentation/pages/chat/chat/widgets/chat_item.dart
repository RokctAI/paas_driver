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
