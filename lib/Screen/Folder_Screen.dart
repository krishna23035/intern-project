import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_manager/file_manager.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({Key? key}) : super(key: key);

  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  late FileManagerController controller;
  bool isGridView = false;


  Set<FileSystemEntity> selectedItems = {};
  FileSystemEntity? _cutEntity;
  bool _isSelectionMode = false;



  Future<void> copyDirectory(String source, String destination) async {
    try {
      final sourceDir = Directory(source);
      final destinationDir = Directory(destination);

      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      await for (final entity in sourceDir.list(recursive: true)) {
        final newPath = destinationDir.path + '/' + entity.path.split('/').last;
        if (entity is Directory) {
          await copyDirectory(entity.path, newPath);
        } else if (entity is File) {
          await entity.copy(newPath);
        }
      }
    } catch (e) {
      print('Error copying directory: $e');
    }
  }




  @override
  void initState() {
    super.initState();
    controller = FileManagerController();
    loadViewMode();
  }

  Future<void> loadViewMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isGridView = prefs.getBool('isGridView') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: _isSelectionMode ? _buildSelectionActions() : _buildRegularActions(),
        title: _buildAppBarTitle(),
        leading: _isSelectionMode
            ? null
            : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FileManager(
        controller: controller,
        builder: (context, snapshot) {
          final List<FileSystemEntity>? entities = snapshot;
          return entities != null
              ? isGridView
              ? buildGridView(entities)
              : buildListView(entities)
              : Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await requestStoragePermission();
        },
        label: const Text("Request File Access Permission"),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return ValueListenableBuilder<String>(
      valueListenable: controller.titleNotifier,
      builder: (context, title, _) {
        List<String> folders = title.split('/');
        List<Widget> folderWidgets = [];
        String folderPath = '';
        for (int i = 0; i < folders.length; i++) {
          folderPath += (i > 0 ? '/' : '') + folders[i];
          folderWidgets.add(
            InkWell(
              onTap: () {
                controller.openDirectory(Directory(folderPath));
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  folders[i],
                  style: TextStyle(
                    fontWeight: i == folders.length - 1 ? FontWeight.bold : null,
                    fontSize: 14.0,
                  ),
                ),
              ),
            ),
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: folderWidgets,
        );
      },
    );
  }

  List<Widget> _buildRegularActions() {
    return [
      IconButton(
        onPressed: () {
          toggleView();
        },
        icon: Icon(isGridView ? Icons.list : Icons.grid_view),
      ),
      IconButton(
        onPressed: () => createFolder(context),
        icon: const Icon(Icons.create_new_folder_outlined),
      ),
      IconButton(
        onPressed: () => sort(context),
        icon: const Icon(Icons.sort_rounded),
      ),
      IconButton(
        onPressed: () => selectStorage(context),
        icon: const Icon(Icons.sd_storage_rounded),
      ),
    ];
  }

  List<Widget> _buildSelectionActions() {
    return [
      IconButton(
        onPressed: copy,
        icon: const Icon(Icons.content_copy),
      ),
      IconButton(
        onPressed: cut,
        icon: const Icon(Icons.content_cut),
      ),
      IconButton(
        onPressed: paste,
        icon: const Icon(Icons.content_paste),
      ),
    ];
  }

  Widget buildListView(List<FileSystemEntity> entities) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      itemCount: entities.length,
      itemBuilder: (context, index) {
        FileSystemEntity entity = entities[index];
        return buildListItem(entity);
      },
    );
  }

  Widget buildGridView(List<FileSystemEntity> entities) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
        childAspectRatio: 1.0,
      ),
      itemCount: entities.length,
      itemBuilder: (context, index) {
        FileSystemEntity entity = entities[index];
        return buildGridItem(entity);
      },
    );
  }

  Widget buildListItem(FileSystemEntity entity) {
    final isSelected = selectedItems.contains(entity);
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          selectedItems.add(entity);
        });
      },
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              selectedItems.remove(entity);
              if (selectedItems.isEmpty) _isSelectionMode = false;
            } else {
              selectedItems.add(entity);
            }
          });
        } else {
          if (FileManager.isDirectory(entity)) {
            controller.openDirectory(entity);
          } else {
            openFile(entity);
          }
        }
      },
      child: Card(
        color: isSelected ? Colors.blue.withOpacity(0.5) : null,
        child: ListTile(
          leading: FileManager.isFile(entity) ? const Icon(Icons.feed_outlined) : const Icon(Icons.folder),
          title: Text(
            FileManager.basename(entity, showFileExtension: true),
          ),
          subtitle: subtitle(entity),
        ),
      ),
    );
  }

  Widget buildGridItem(FileSystemEntity entity) {
    final isSelected = selectedItems.contains(entity);
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          selectedItems.add(entity);
        });
      },
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              selectedItems.remove(entity);
              if (selectedItems.isEmpty) _isSelectionMode = false;
            } else {
              selectedItems.add(entity);
            }
          });
        } else {
          if (FileManager.isDirectory(entity)) {
            controller.openDirectory(entity);
          } else {
            openFile(entity);
          }
        }
      },
      child: Card(
        color: isSelected ? Colors.blue.withOpacity(0.5) : null,
        child: InkWell(
          onTap: () async {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  selectedItems.remove(entity);
                  if (selectedItems.isEmpty) _isSelectionMode = false;
                } else {
                  selectedItems.add(entity);
                }
              });
            } else {
              if (FileManager.isDirectory(entity)) {
                controller.openDirectory(entity);
              } else {
                openFile(entity);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FileManager.isFile(entity) ? const Icon(Icons.feed_outlined) : const Icon(Icons.folder),
                const SizedBox(height: 8.0),
                Text(
                  FileManager.basename(entity, showFileExtension: true),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget subtitle(FileSystemEntity entity) {
    return FutureBuilder<FileStat>(
      future: entity.stat(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (entity is File) {
            int size = snapshot.data!.size;
            return Text(
              "${FileManager.formatBytes(size)}",
            );
          }
          return Text(
            "${snapshot.data!.modified}".substring(0, 10),
          );
        } else {
          return Text("");
        }
      },
    );
  }

  Future<void> selectStorage(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: FutureBuilder<List<Directory>>(
          future: FileManager.getStorageList(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final List<FileSystemEntity> storageList = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: storageList
                      .map(
                        (e) => ListTile(
                      title: Text(
                        "${FileManager.basename(e)}",
                      ),
                      onTap: () {
                        controller.openDirectory(e);
                        Navigator.pop(context);
                      },
                    ),
                  )
                      .toList(),
                ),
              );
            }
            return const Dialog(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  void sort(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Name"),
                onTap: () {
                  controller.sortBy(SortBy.name);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Size"),
                onTap: () {
                  controller.sortBy(SortBy.size);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Date"),
                onTap: () {
                  controller.sortBy(SortBy.date);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("type"),
                onTap: () {
                  controller.sortBy(SortBy.type);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void createFolder(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController folderName = TextEditingController();
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: TextField(
                    controller: folderName,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await FileManager.createFolder(controller.getCurrentPath, folderName.text);
                      controller.setCurrentPath=controller.getCurrentPath + "/" + folderName.text;
                    } catch (e) {
                      print('Error creating folder: $e');
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Create Folder'),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void openFile(FileSystemEntity entity) async {
    try {
      String filePath = entity.path;
      OpenResult result = await OpenFile.open(filePath);
      if (result.type == ResultType.done) {
        print('File opened successfully');
      } else {
        print('Error opening file: ${result.message}');
      }
    } catch (e) {
      print('Error opening file: $e');
    }
  }

  Future<void> cut() async {
    _cutEntity = selectedItems.isNotEmpty ? selectedItems.first : null;
    _isSelectionMode = false;
    setState(() {
      if (_cutEntity != null) {
        selectedItems.remove(_cutEntity);
      }
    });
  }

  Future<void> copy() async {
    _cutEntity = selectedItems.isNotEmpty ? selectedItems.first : null;
    _isSelectionMode = false;
  }
  Future<void> paste() async {
    if (_cutEntity != null) {
      try {
        final String newPath = '${controller.getCurrentPath}/${FileManager.basename(_cutEntity!.path)}';
        if (_cutEntity is Directory) {
          // Copy the directory
          await copyDirectory(_cutEntity!.path, newPath);
          // Remove the following line to keep the original directory after copying
          // await (_cutEntity as Directory).delete(recursive: true);
        } else if (_cutEntity is File) {
          // Copy the file
          await (_cutEntity as File).copy(newPath);
          // Remove the following line to keep the original file after copying
          // await (_cutEntity as File).delete();
        }
        setState(() {
          _cutEntity = null;
        });
      } catch (e) {
        print('Error pasting file/folder: $e');
      }
    }
  }



  void toggleView() {
    setState(() {
      isGridView = !isGridView;
      saveViewMode(isGridView);
    });
  }

  Future<void> requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) {
      // Permission granted, you can proceed with your logic here
    } else {
      // Permission denied, handle accordingly (show a message, disable functionality, etc.)
    }
  }

  void saveViewMode(bool isGridView) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGridView', isGridView);
  }
}
