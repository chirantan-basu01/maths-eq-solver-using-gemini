import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  XFile? _image;
  String _responseBody = "";
  bool isSending = false;
  String customPrompt = "";
  final TextEditingController _controller = TextEditingController();

  void disposeController(BuildContext context) {
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gemini Maths"),
        centerTitle: true,
        backgroundColor: Colors.grey[300],
      ),
      backgroundColor: Colors.grey[300],
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _image == null
                    ? const Center(child: Text("No image is selected!"))
                    : Image.file(File(_image!.path)),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _controller,
                    onChanged: (value) => customPrompt = value,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Type something to search",
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _responseBody,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          if (isSending)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _image == null ? _openCamera() : sendImage(_image);
        },
        tooltip: _image == null ? "Pick Image" : "Send Image",
        child: Icon(_image == null ? Icons.camera_alt : Icons.send),
      ),
    );
  }

  Future<void> sendImage(XFile? imageFile) async {
    if (imageFile == null) return;

    setState(() {
      isSending = true;
    });

    String base64Image = base64Encode(File(imageFile.path).readAsBytesSync());
    String apiKey = "AIzaSyCsTuObLaoT8_rh9D4X-HzOXlWkyMsNWO4";
    String requestBody = json.encode({
      "contents": [
        {
          "parts": [
            {
              "inlineData": {"mimeType": "image/jpeg", "data": base64Image}
            },
            {
              "text": customPrompt == ""
                  ? "Solve this maths function and write step by step details and the reason behind that step"
                  : customPrompt
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.4,
        "topK": 32,
        "topP": 1,
        "maxOutputTokens": 4096,
        "stopSequences": []
      },
      "safetySettings": [
        {
          "category": "HARM_CATEGORY_HARASSMENT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_HATE_SPEECH",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        }
      ]
    });
    http.Response response = await http.post(
      Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro-vision-latest:generateContent?key=$apiKey"),
      headers: {"Content-Type": "application/json"},
      body: requestBody,
    );

    if (kDebugMode) {
      print("Sent: $customPrompt");
    }

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonBody = json.decode(response.body);
      setState(() {
        _responseBody =
            jsonBody["candidates"][0]["content"]["parts"][0]["text"];
        isSending = false;
      });
      if (kDebugMode) {
        print("Image sent successfully");
        print(response.body);
      }
    } else {
      setState(() {
        isSending = false;
      });
      if (kDebugMode) {
        print("Request failed");
      }
    }
  }

  Future<void> _getImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      ImageCropper cropper = ImageCropper();
      final croppedImage = await cropper.cropImage(
        sourcePath: image.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
      );
      setState(() {
        _image = croppedImage != null ? XFile(croppedImage.path) : null;
      });
    }
  }

  _openCamera() {
    if (_image == null) {
      _getImageFromCamera();
    }
  }
}
