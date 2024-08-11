import 'dart:convert';
import 'dart:math';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSessions();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveCurrentSession();
    }
    super.didChangeAppLifecycleState(state);
  }

  //=====================================================
  // create variable for gemini
  final Gemini gemini = Gemini.instance;
  //chat message
  List<ChatMessage> messages = [];
  //History
  List<List<ChatMessage>> sessionHistory = [];

  //chat User
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Chat Now",
    profileImage: "assets/images/chatnow.png",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Chat Now"),
      ),
      drawer: Drawer(
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: sessionHistory.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const DrawerHeader(
                decoration: BoxDecoration(color: Colors.amberAccent),
                child: Text("Session History"),
              );
            } else {
              int sessionIndex = index - 1;
              return ListTile(
                title: Text("session ${sessionIndex + 1}"),
                onTap: () {
                  Navigator.of(context);
                  _loadSession(sessionIndex);
                },
              );
            }
          },
        ),
      ),
      body: DashChat(
        currentUser: currentUser,
        onSend: _sendMessage,
        messages: messages,
      ),
    );
  }

  //=================================================

  void _saveCurrentSession() async {
    if (messages.isNotEmpty) {
      sessionHistory.insert(0, List.from(messages));
      if (sessionHistory.length > 10) {
        sessionHistory.removeLast();
      }
      messages.clear();
      await _saveSessionsToPreferences();
    }
  }

// ========================================================
  Future<void> _loadSessions() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    List<String>? sessionStrings = preferences.getStringList("sessionHistory");
    print('Loaded sessions: $sessionStrings');
    if (sessionStrings != null) {
      sessionHistory = sessionStrings.map(
        (sessionString) {
          List<dynamic> decoded = jsonDecode(sessionString);
          return decoded
              .map(
                (messageJson) => ChatMessage.fromJson(messageJson),
              )
              .toList();
        },
      ).toList();
      setState(() {});
    }
  }

  Future<void> _saveSessionsToPreferences() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    List<String> sessionStrings = sessionHistory.map(
      (session) {
        return jsonEncode(session
            .map(
              (message) => message.toJson(),
            )
            .toList());
      },
    ).toList();
    print("Saving sessions : $sessionStrings");

    await preferences.setStringList("sessionHistory", sessionStrings);
  }

//===========================================
  void _loadSession(int index) {
    setState(() {
      messages = List.from(sessionHistory[index]);
    });
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];

      try {
        String question = chatMessage.text;

        gemini.streamGenerateContent(question).listen(
          (event) {
            ChatMessage? lastMessage = messages.firstOrNull;
            if (lastMessage != null && lastMessage.user == geminiUser) {
              lastMessage = messages.removeAt(0);
              String response = event.content?.parts?.fold(
                    "",
                    (previous, current) => "$previous ${current.text}",
                  ) ??
                  "";
              lastMessage.text += response;
              setState(() {
                messages = [lastMessage!, ...messages];
              });
            } else {
              String response = event.content?.parts?.fold(
                    "",
                    (previous, current) => "$previous ${current.text}",
                  ) ??
                  "";
              ChatMessage message = ChatMessage(
                user: geminiUser,
                createdAt: DateTime.now(),
                text: response,
              );
              setState(() {
                messages = [message, ...messages];
              });
            }
          },
        );
      } catch (e) {
        print(e);
      }
    });
  }
}
