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


// ignore_for_file: unused_result

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comms_sdk/src/common/application/chat/chat_provider.dart';
import 'package:base_sdk/src/models/data/chat_message_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:comms_sdk/src/common/presentation/pages/chat/chat/widgets/chat_item.dart';

@RoutePage()
class ChatPage extends ConsumerStatefulWidget {
  final String roleId;
  final String name;

  const ChatPage({super.key, required this.roleId, required this.name});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    ref.refresh(chatProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).fetchChats(context, widget.roleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    final state = ref.watch(chatProvider);
    final notifier = ref.read(chatProvider.notifier);

    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: KeyboardDismisser(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              color: AppStyle.bgGrey.withOpacity(0.96),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              children: [
                8.verticalSpace,
                // Title and back button
                Row(
                  children: [
                    IconButton(
                      splashRadius: 18.r,
                      onPressed: context.maybePop,
                      icon: Icon(
                        isLtr
                            ? Remix.arrow_left_s_line
                            : Remix.arrow_right_s_line,
                        size: 24.r,
                        color: AppStyle.black,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.name,
                        style: AppStyle.interNormal(
                          size: 18,
                          color: AppStyle.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                16.verticalSpace,
                // Chat messages
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _fireStore
                        .collection('messages')
                        .where('chat_id', isEqualTo: state.chatId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3.r,
                            color: AppStyle.primary,
                          ),
                        );
                      }
                      final List<DocumentSnapshot> docs = snapshot.data!.docs;
                      final List<ChatMessageData> messages = docs.map((doc) {
                        final Map<String, dynamic> data =
                            doc.data() as Map<String, dynamic>;
                        final Timestamp t = data['created_at'];
                        final DateTime date = t.toDate();
                        return ChatMessageData(
                          messageOwner: data['sender'] == 0
                              ? MessageOwner.partner
                              : MessageOwner.you,
                          message: data['chat_content'],
                          time: '${date.hour}:${date.minute}',
                          date: date,
                          messageId: doc.id, // Ensure messageId is passed
                        );
                      }).toList();
                      messages.sort((a, b) => b.date.compareTo(a.date));
                      return ListView.builder(
                        itemCount: messages.length,
                        reverse: true,
                        controller: scrollController,
                        padding: REdgeInsets.only(
                          bottom: 20,
                          top: 20,
                          left: 15,
                          right: 15,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final chatData = messages[index];
                          return GestureDetector(
                            onLongPress: () {
                              // Long press to edit the message
                              if (chatData.messageOwner == MessageOwner.you) {
                                notifier.toggleEditMode(
                                  chatData.messageId,
                                  chatData.message,
                                );
                              }
                            },
                            child: ChatItem(chatData: chatData),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Input field - sticky at bottom
                SafeArea(
                  child: Container(
                    margin: REdgeInsets.all(16),
                    padding: REdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppStyle.black),
                      borderRadius: BorderRadius.circular(16.r),
                      color: AppStyle.white,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: state.textController,
                            cursorWidth: 1.r,
                            cursorColor: AppStyle.black,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintStyle: GoogleFonts.k2d(
                                fontWeight: FontWeight.w500,
                                fontSize: 12.sp,
                                letterSpacing: -0.5,
                                color: AppStyle.black,
                              ),
                              hintText: AppHelpers.getTranslation(
                                TrKeys.typeSomething,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: notifier.sendMessage,
                          child: Container(
                            width: 37,
                            height: 37,
                            decoration: BoxDecoration(
                              color: AppStyle.black,
                              borderRadius: BorderRadius.circular(37),
                            ),
                            child: Icon(
                              Remix.send_plane_2_line,
                              size: 18.r,
                              color: AppStyle.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
