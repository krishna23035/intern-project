import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Folder_Screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Scaffold(
        appBar: AppBar(
          title: const Text("File Manager System"),
          backgroundColor: Colors.blueAccent,
        ),
        body: Column(
          children: [
            ListTile(
              title: const Text('Internal Storage'),
              trailing: const Icon(Icons.folder),
              onTap: () async {
                final PermissionStatus status = await Permission.storage.request();
                if (status.isGranted) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => FolderScreen()));
                } else {
                  _showPermissionDeniedDialog(context);
                }
              },
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('External Storage'),
              trailing: const Icon(Icons.folder),
              onTap: () {
                _showAlertDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Permission Denied"),
          content: const Text("You denied the file access permission."),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Warning!!!"),
          content: const Text("No External Device is connected"),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }
}
