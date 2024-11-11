import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const String apiKey = "AIzaSyCSODG2Bohy9_tSYKXAtrL6s3KEEk-smeI";

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  bool _isListening = false;
  bool _isConnected = true;
  bool _audioEnabled = true;
  String _speechText = '';
  String _selectedLanguage = "en-US";
  String _lastBotMessage = '';
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    _chatSession = _model.startChat();

    await _requestMicrophonePermission();
    await _checkInternetConnection();
    await _loadMessages();
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _checkInternetConnection() async {
    try {
      final response = await http.get(Uri.parse('https://google.com'));
      setState(() {
        _isConnected = response.statusCode == 200;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
      });
    }
  }

  Future<void> _startListening() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done') {
            _stopListening();
          }
        },
        onError: (val) => print('Error: $val'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _speechText = val.recognizedWords;
              _controller.text = _speechText;
            });
          },
          localeId: _selectedLanguage,
        );
      }
    } else {
      print("Permisos de micrófono denegados");
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  Future<void> _resetChat() async {
    setState(() {
      _messages.clear();
      _lastBotMessage = '';
    });
    await _saveMessages();
  }

  Future<void> _scanQR() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text("Escanear QR")),
          body: MobileScanner(
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code == "reiniciar") {
                  _resetChat();
                  Navigator.pop(context);
                  break;
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    await _checkInternetConnection();

    if (!_isConnected) {
      setState(() {
        _messages.add(ChatMessage(
          text: "No se puede enviar el mensaje. Conéctate a Internet.",
          isUser: false,
        ));
      });
      return;
    }

    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(text: _controller.text, isUser: true));
      });
      String userMessage = _controller.text;
      _controller.clear();

      setState(() {
        _messages.add(ChatMessage(text: "Analizando...", isUser: false));
      });

      try {
        String context = _getContext();
        final response = await _chatSession.sendMessage(
          Content.text("$context\nUsuario: $userMessage"),
        );
        final botResponse = response.text?.replaceFirst("Bot: ", "") ?? "No se recibió respuesta";

        setState(() {
          _messages.removeLast();
          _messages.add(ChatMessage(text: botResponse, isUser: false));
          _lastBotMessage = botResponse;
        });

        await _saveMessages();
        if (_audioEnabled) await _speak(_lastBotMessage);
      } catch (e) {
        setState(() {
          _messages.removeLast();
          _messages.add(ChatMessage(text: "Error: $e", isUser: false));
        });
      }
    }
  }

  String _getContext() {
    int numberOfMessages = _messages.length < 10 ? _messages.length : 10;
    return _messages
        .take(numberOfMessages)
        .map((msg) => "${msg.isUser ? 'Usuario' : 'Bot'}: ${msg.text}")
        .join("\n");
  }

Future<void> _speak(String text) async {
  // Cambia el idioma del TTS según el botón seleccionado
  if (_selectedLanguage == "en-US") {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setVoice({"name": "en-us-x-sfg#male_1-local", "locale": "en-US"});
  } else if (_selectedLanguage == "es-MX") {
    await _flutterTts.setLanguage("es-MX");
    await _flutterTts.setVoice({"name": "es-mx-x-sfb#male_1-local", "locale": "es-MX"});
  }
  await _flutterTts.speak(text);
}
  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
  }

  void _toggleAudio() {
    setState(() {
      _audioEnabled = !_audioEnabled;
    });
    if (!_audioEnabled) {
      _stopSpeaking();
    }
  }

  void _replayLastMessage() {
    if (_audioEnabled && _lastBotMessage.isNotEmpty) {
      _speak(_lastBotMessage);
    }
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _selectedLanguage = languageCode;
    });
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> messagesToSave = _messages
        .take(100)
        .map((msg) => "${msg.isUser ? 'user:' : 'bot:'}${msg.text}")
        .toList();
    await prefs.setStringList('chatMessages', messagesToSave);
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedMessages = prefs.getStringList('chatMessages');

    if (savedMessages != null) {
      setState(() {
        _messages.clear();
        _messages.addAll(savedMessages.map((msg) {
          bool isUser = msg.startsWith('user:');
          String text = msg.replaceFirst(isUser ? 'user:' : 'bot:', '');
          return ChatMessage(text: text, isUser: isUser);
        }).toList());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Chatbot', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          if (_messages.isEmpty)
            Center(
              child: Text(
                "Bienvenido al Chatbot. ¿En qué puedo ayudarte hoy?",
                style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
            ),
          Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final isUserMessage = _messages[index].isUser;
                    return Row(
                      mainAxisAlignment: isUserMessage
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isUserMessage)
                          CircleAvatar(
                            child: Icon(Icons.smart_toy, color: const Color.fromARGB(255, 255, 255, 255)), // Cambia el color del ícono a negro
                            backgroundColor: const Color.fromARGB(255, 0, 0, 0), 
                          ),
                        if (isUserMessage) // Muestra imagen solo en los mensajes del usuario
                          CircleAvatar(
                            backgroundImage: AssetImage('assets/images/joel.jpg'),
                            radius: 20,
                          ),
                        Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          constraints: BoxConstraints(maxWidth: 300),
                          decoration: BoxDecoration(
                            color: isUserMessage ? Colors.blueAccent : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _messages[index].text,
                            style: TextStyle(
                              color: isUserMessage ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.black),
                      onPressed: _isListening ? _stopListening : _startListening,
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.black),
                      onPressed: _scanQR,
                    ),
                    IconButton(
                      icon: Icon(Icons.replay, color: Colors.black),
                      onPressed: _replayLastMessage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.blueAccent),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _changeLanguage("en-US"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedLanguage == "en-US"
                          ? Colors.grey[700]
                          : Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text("Inglés"),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _changeLanguage("es-MX"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedLanguage == "es-MX"
                          ? Colors.grey[700]
                          : Colors.greenAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text("Español"),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _toggleAudio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _audioEnabled ? Colors.blueAccent : Colors.grey[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(_audioEnabled ? "Audio: ON" : "Audio: OFF"),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}




