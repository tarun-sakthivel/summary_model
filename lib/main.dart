import 'dart:convert';
import 'dart:io';

import 'package:open_file/open_file.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: pdfpicker(),
    );
  }
}

class pdfpicker extends StatefulWidget {
  const pdfpicker({super.key});

  @override
  State<pdfpicker> createState() => _pdfpickerState();
}

class _pdfpickerState extends State<pdfpicker> {
  String? _fileName;
  FilePickerResult? result;
  PlatformFile? pickedfile;
  bool isLOading = false;
  File? fileToDisplay;
  List pickedfiles = [];
  String pathofFile = '';
  String _output = '';
  String base64String = '';
  String manual_text =
      'Projectile motion refers to the motion of an object that is projected into the air and then allowed to move under the influence of gravity. It is a classic example of two-dimensional motion. During projectile motion, the object follows a curved path known as a trajectory. The trajectory consists of two components: horizontal motion and vertical motion. The horizontal motion remains constant, while the vertical motion is influenced by gravity. The object reaches its maximum height at the peak of its trajectory before descending back to the ground. The time of flight, maximum height, and range of the projectile can be calculated using specific equations derived from the principles of kinematics. Projectile motion is utilized in various real-world scenarios, such as sports, engineering, and physics experiments. Understanding projectile motion is essential for predicting the behavior of objects in flight and designing effective systems and structures';
  void pickFile() async {
    try {
      setState(() {
        isLOading = true;
      });

      result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['ppt', 'pdf'],
          allowMultiple: true);
      if (result != null) {
        _fileName = result!.files.first.name;
        pickedfile = result!.files.first;
        fileToDisplay = File(pickedfile!.path.toString());
        pathofFile = pickedfile!.path.toString();
        print("File name: $_fileName");
        base64String = base64Encode(File(pathofFile).readAsBytesSync());
      }
      if (result != null) {
        setState(() {
          pickedfiles = result!.files.map((file) => File(file.path!)).toList();
        });
      }

      setState(() {
        isLOading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  openFile(File) {
    OpenFile.open(File.path);
  }

  Future fetchData() async {
    print("hi");
    var url = 'https://karthiksagar.us-east-1.modelbit.com/v1/run_model/latest';
    var headers = {'Content-Type': 'application/json'};
    print(base64String);
    var body = json.encode({
      "data": [base64String, manual_text],
    });
    print("stage2");
    var response =
        await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      print("success");
      // Request successful, do something with the response.
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      // Access the value of the "response" key
      String botResponse = jsonResponse['data'];
      // Print or return the bot response
      print("Bot response: $botResponse");
      return botResponse;
    } else {
      // Request failed, handle error.
      print('Request failed with status: ${response.statusCode}');
    }
  }

  Future<File> saveFilePermanently(PlatformFile file) async {
    final appStorage = await getApplicationDocumentsDirectory();
    final newFile = File('${appStorage.path}/${file.name}');
    return File(file.path!).copy(newFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(40, 60),
                    backgroundColor: Colors.orange),
                onPressed: () {
                  pickFile();
                },
                child: const Text("Pick the file")),
          ),
          if (pickedfile != null)
            pickedfiles.isNotEmpty
                ? ListView.builder(
                    itemCount: pickedfiles.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => openFile(pickedfiles[index]),
                        child: Card(
                          child: ListTile(
                            leading: returnLogo(pickedfiles[index]),
                            subtitle: Text(
                              'File: ${pickedfiles[index].path}',
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Container(),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(40, 60),
                  backgroundColor: Color.fromARGB(255, 61, 255, 7)),
              onPressed: () {
                fetchData();
              },
              child: const Text("Pick the file")),
        ],
      ),
    );
  }

  returnLogo(file) {
    var ex = extension(file.path);
    if (ex == 'ppt') {
      return const Icon(Icons.pause_presentation);
    }
    if (ex == 'pdf') {
      return const Icon(Icons.picture_as_pdf);
    }
  }
}
