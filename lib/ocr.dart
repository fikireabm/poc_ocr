import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transparent_image/transparent_image.dart'
    show kTransparentImage;
import 'package:flutter/material.dart';

class OcrHome extends StatefulWidget {
  const OcrHome({super.key});

  @override
  _OcrHomeState createState() => _OcrHomeState();
}

class _OcrHomeState extends State<OcrHome> {
  File? _imageFile;
  String _mlResult = '';
  final _picker = ImagePicker();

  Future<bool> _pickImage() async {
    setState(() => _imageFile = null);
    final File? imageFile = await showDialog<File>(
      context: context,
      builder: (ctx) => SimpleDialog(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take picture'),
            onTap: () async {
              final XFile? pickedFile =
                  await _picker.pickImage(source: ImageSource.camera);
              if (mounted && pickedFile != null) {
                Navigator.pop(ctx, File(pickedFile.path));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Pick from gallery'),
            onTap: () async {
              try {
                final XFile? pickedFile =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (mounted && pickedFile != null) {
                  Navigator.pop(ctx, File(pickedFile.path));
                }
              } catch (e) {
                Navigator.pop(ctx, null);
              }
            },
          ),
        ],
      ),
    );
    if (mounted && imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick one image first.')),
      );
      return false;
    }
    setState(() => _imageFile = imageFile);
    return true;
  }

  Future<void> _textOcr() async {
    setState(() => _mlResult = '<no result>');
    if (await _pickImage() == false) {
      return;
    }
    String result = '';
    final InputImage inputImage = InputImage.fromFile(_imageFile!);
    final TextRecognizer textDetector = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText =
        await textDetector.processImage(inputImage);
    final String text = recognizedText.text;
    debugPrint('Recognized text: "$text"');
    for (final TextBlock block in recognizedText.blocks) {
      // final Rect boundingBox = block.boundingBox;
      // final List<Point<int>> cornerPoints = block.cornerPoints;
      final String text = block.text;

      if (text.contains("B.No.") || text.contains("B.No. ")) {
        result = '\n$text\n';
      } else {
        print("Substring not found.");
      }
    }
    if (result.isNotEmpty) {
      setState(() => _mlResult = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    String subString = "B.No.";
    String desiredSubstring = "";
    int startIndex = _mlResult.indexOf(subString);
    if (startIndex != -1) {
      desiredSubstring = _mlResult.substring(startIndex);
    }
    return Scaffold(
      body: ListView(
        children: <Widget>[
          if (_imageFile == null)
            const Placeholder(
              fallbackHeight: 200.0,
            )
          else
            FadeInImage(
              placeholder: MemoryImage(kTransparentImage),
              image: FileImage(_imageFile!),
              // Image.file(, fit: BoxFit.contain),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            child: ElevatedButton(
              onPressed: _textOcr,
              child: const Text('Check B.No.'),
            ),
          ),
          const Divider(),
          Text('Result:', style: Theme.of(context).textTheme.titleSmall),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
              child: Text(
                desiredSubstring,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
