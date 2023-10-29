import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sign_note/welcome_screeen.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import "package:universal_html/html.dart" show AnchorElement;
import 'package:form_field_validator/form_field_validator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomeScreen> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();

  File _selectedFile = File('');
  String _enteredTitle = '';
  String _enteredDescription = '';
  final title = TextEditingController();
  final description = TextEditingController();
  Color _selectedStrokeColor = Colors.white;
  Color _selectedCanvasColor = Colors.grey;

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Stroke Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedStrokeColor,
              onColorChanged: (Color color) {
                setState(() {
                  _selectedStrokeColor = color;
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Discard Canvas'),
          content: const Text(
              'Do you want to discard the current canvas and start over?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                );
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                _signaturePadKey.currentState!.clear();
                title.clear(); // Clear the title field
                description.clear(); // Clear the description field
                _enteredTitle = '';
                _enteredDescription = '';
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showCanvasColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Canvas Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedCanvasColor,
              onColorChanged: (Color color) {
                setState(() {
                  _selectedCanvasColor = color;
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _saveImage() async {
    ui.Image data =
        await _signaturePadKey.currentState!.toImage(pixelRatio: 2.0);
    final byteData = await data.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List imageBytes = byteData!.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);

    if (kIsWeb) {
      AnchorElement(
        href:
            'data:application/octet-stream;charset=utf-16le;base64,${base64.encode(imageBytes)}',
      )
        ..setAttribute('download', 'Output.png')
        ..click();
    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      final String fileName =
          Platform.isWindows ? '$path\\Output.png' : '$path/Output.png';
      final File file = File(fileName);
      _selectedFile = file;
      await file.writeAsBytes(imageBytes, flush: true);
      OpenFile.open(fileName);
    }

    print('Started uploading');
    _enteredTitle = title.text;
    _enteredDescription = description.text;

    final url = Uri.https('notesapp-i6yf.onrender.com', '/user/createNotes');
    await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: json.encode(
        {
          'title': _enteredTitle,
          'description': _enteredDescription,
          'attachment': _selectedFile.path,
        },
      ),
    );
    print(_enteredTitle);
    print(_enteredDescription);
    print(_selectedFile);
    print('It\'s done');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(_enteredTitle),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const SizedBox(height: 10),
                const Text('  1. Enter Title:'),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextFormField(
                    controller: title,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Title is required'),
                      MinLengthValidator(3,
                          errorText: 'Minimum 3 characters for title'),
                    ]),
                    decoration: const InputDecoration(
                      hintText: 'Enter complaint Title',
                      labelText: 'Title',
                      errorStyle: TextStyle(fontSize: 18.0),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.all(
                          Radius.circular(9.0),
                        ),
                      ),
                    ),
                    onChanged: (newTitle) {
                      setState(() {
                        _enteredTitle = newTitle;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                const Text('  2. Enter Description:'),
                // Description Input
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: description,
                    textInputAction: TextInputAction.done,
                    maxLines: null,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Description is required'),
                      MinLengthValidator(10,
                          errorText: 'Minimum 10 characters for description'),
                    ]),
                    decoration: const InputDecoration(
                      hintText: 'Enter Description',
                      labelText: 'Description',
                      errorStyle: TextStyle(fontSize: 18.0),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.all(
                          Radius.circular(9.0),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: SizedBox(
                    height: 450,
                    width: 300,
                    child: SfSignaturePad(
                      key: _signaturePadKey,
                      backgroundColor: _selectedCanvasColor,
                      strokeColor: _selectedStrokeColor,
                      minimumStrokeWidth: 2.0,
                      maximumStrokeWidth: 4.0,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        _showColorPicker(context);
                      },
                      child: const Column(
                        children: [
                          Icon(Icons.palette),
                          Text('Pen Color'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () {
                        _signaturePadKey.currentState!.clear();
                      },
                      child: const Column(
                        children: [
                          Icon(Icons.brush),
                          Text('Clear'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 30),
                    InkWell(
                      onTap: _saveImage,
                      child: const Column(
                        children: [
                          Icon(Icons.save),
                          Text('Save'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () {
                        _showCanvasColorPicker(context);
                      },
                      child: const Column(
                        children: [
                          Icon(Icons.format_paint),
                          Text('Canvas Color'),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _clearCanvas,
          tooltip: 'New Canvas',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
