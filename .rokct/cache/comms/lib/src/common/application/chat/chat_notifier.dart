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


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:comms_sdk/src/common/application/chat/chat_state.dart';

class ChatNotifier extends StateNotifier<ChatState> {
  // cloud_firestore has no Windows/Linux implementation — on desktop
  // Firebase is (correctly) never initialized, so an eager
  // FirebaseFirestore.instance field initializer throws [core/no-app] while
  // the provider is being constructed, before any try/catch can run. `late`
  // defers the throw to first access — fetchChats' and sendMessage's
  // existing try/catch blocks — which surface
  // errorWithConnectingToFirebase instead of crashing the route.
  late final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  String roleId = "";

  ChatNotifier()
      : super(ChatState(textController: TextEditingController(), chatId: ''));

  // Method to fetch chats based on user and role
  Future<void> fetchChats(BuildContext context, String roleId) async {
    state = state.copyWith(isLoading: true);
    this.roleId = roleId;
    final userId = LocalStorage.getUser()?.id;
    QuerySnapshot? query;
    try {
      query = await _fireStore
          .collection('chats')
          .where('user.id', isEqualTo: userId)
          .where("roleId", isEqualTo: roleId)
          .get();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      if (context.mounted) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.errorWithConnectingToFirebase),
        );
      }
    }

    if (query?.size == 0) {
      final CollectionReference chats = _fireStore.collection('chats');
      final res = await chats.add({
        'shop_id': -1,
        'created_at': Timestamp.now(),
        "roleId": roleId,
        'user': {
          'firstname': LocalStorage.getUser()?.firstname,
          'id': LocalStorage.getUser()?.id,
          'img': LocalStorage.getUser()?.img,
          'lastname': LocalStorage.getUser()?.lastname,
        },
      });
      final String chatId = res.id;
      state = state.copyWith(chatId: chatId, isLoading: false);
    } else {
      state = state.copyWith(
        chatId: query?.docs.first.id ?? '',
        isLoading: false,
      );
    }
  }

  // Method to send a new message or update the latest message
  Future<void> sendMessage() async {
    final text = state.textController?.text.trim();
    if (text != null && text.isNotEmpty) {
      debugPrint('===> send message chat id ${state.chatId}');
      try {
        CollectionReference message = _fireStore.collection('messages');
        final messageData = {
          'chat_content': text,
          "chat_id": state.chatId,
          "created_at": Timestamp.now(),
          "sender": 1,
          "roleId": roleId,
          'unread': true,
        };

        if (state.isEditing && state.editingMessageId != null) {
          // Update the latest message (only the most recent message can be edited)
          await message.doc(state.editingMessageId!).update(messageData);
        } else {
          // Add a new message
          await message.add(messageData);
        }
        state.textController?.clear();
        state = state.copyWith(isEditing: false, editingMessageId: null);
      } catch (e) {
        debugPrint('==> send message error: $e');
      }
    }
  }

  // Method to toggle edit mode for the latest message only
  void toggleEditMode(String? messageId, String content) {
    // Only allow editing of the latest message
    if (state.chats.isNotEmpty) {
      final latestMessageId = state.chats.first.messageId;
      if (messageId == latestMessageId) {
        state = state.copyWith(
          isEditing: !state.isEditing,
          editingMessageId: messageId,
        );
        if (state.isEditing) {
          state.textController?.text = content;
        } else {
          state.textController?.clear();
        }
      }
    }
  }

  // Additional method to check if the user is authorized or logged in
  void checkAuthorized(BuildContext context) {
    // if (LocalStorage.instance.getUserId() == null) {
    //   AppHelpers.showCheckTopSnackBar(
    //     context,
    //     AppHelpers.getTranslation(TrKeys.youNeedToLoginFirst),
    //   );
    //   context.router.pushAndPopUntil(
    //     const LoginRoute(),
    //     predicate: (route) => false,
    //   );
    // } else {
    //   context.router.popAndPush(const ChatRoute());
    // }
  }
}
