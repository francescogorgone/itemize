import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itemize/pages/item_details.dart';
import 'package:itemize/pages/room_details.dart';
import 'package:provider/provider.dart';
import 'package:itemize/providers/room_data_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Dichiarazioni per image_picker e scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _savedImagePath;

  // Controllers e variabili per gestione item e room
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemDescriptionController = TextEditingController();
  final TextEditingController _itemCategoryController = TextEditingController();
  final TextEditingController _itemRoomController = TextEditingController();
  final TextEditingController _itemImageController = TextEditingController();
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomImageController = TextEditingController();
  late String? selectedRoom;

  bool _isSearching = false;
  String _searchQuery = "";
  List<Map<String, dynamic>> _filteredRooms = [];
  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredRooms = context.read<RoomDataProvider>().rooms;
    selectedRoom = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _filteredRooms = context.watch<RoomDataProvider>().rooms;
  }

  // Quando la query è vuota vengono visualizzate le stanze, altrimenti si filtrano gli oggetti (items)
  void _searchRooms(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredRooms = context.read<RoomDataProvider>().rooms;
        _filteredItems = [];
      } else {
        List<Map<String, dynamic>> items = [];
        for (var room in context.read<RoomDataProvider>().rooms) {
          for (var item in room['items']) {
            if (item['name'].toLowerCase().contains(query.toLowerCase()) ||
                item['description'].toLowerCase().contains(query.toLowerCase()) ||
                item['category'].toLowerCase().contains(query.toLowerCase())) {
              items.add(item);
            }
          }
        }
        _filteredItems = items;
        _filteredRooms = [];
      }
    });
  }

  // Modifica: aggiunto parametro opzionale dialogSetState per aggiornare anche il dialog
  Future<void> _pickImage(ImageSource source, {Function(void Function())? dialogSetState}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        await pickAndSaveImage(pickedFile, dialogSetState: dialogSetState);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error picking image')),
      );
    }
  }

  // Modifica: aggiunto parametro opzionale dialogSetState per aggiornare anche il dialog
  Future<void> pickAndSaveImage(XFile pickedFile, {Function(void Function())? dialogSetState}) async {
    try {
      final imageBytes = await pickedFile.readAsBytes();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final filePath = '${directory.path}/$fileName';
      final imageFile = File(filePath);
      await imageFile.writeAsBytes(imageBytes);

      setState(() {
        _selectedImage = imageFile;
        _savedImagePath = filePath;
        _roomImageController.text = filePath; // Update room image controller
      });

      if (dialogSetState != null) {
        dialogSetState(() {});
      }

      print('Immagine salvata in: $filePath');
    } catch (e) {
      print('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving image')),
      );
    }
  }

  // Modifica: aggiunto parametro opzionale dialogSetState per aggiornare anche il dialog
  void _showImageSourceDialog({Function(void Function())? dialogSetState}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, dialogSetState: dialogSetState);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, dialogSetState: dialogSetState);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addNewItem() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Item'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _itemNameController,
                        decoration: const InputDecoration(labelText: 'Item Name'),
                      ),
                      TextField(
                        controller: _itemCategoryController,
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                      TextField(
                        controller: _itemDescriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      DropdownButtonFormField<String?>(
                        value: selectedRoom,
                        decoration: const InputDecoration(labelText: 'Room'),
                        items: context.watch<RoomDataProvider>().rooms.map((room) {
                          return DropdownMenuItem<String?>(
                            value: room['name'],
                            child: Text(room['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRoom = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_selectedImage != null)
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showImageSourceDialog(dialogSetState: setState);
                        },
                        icon: const Icon(Icons.image),
                        label: const Text('Select Image'),
                      ),
                    ],
                  );
                }
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (selectedRoom != null && _itemNameController.text.trim().isNotEmpty) {
                  bool itemAdded = context.read<RoomDataProvider>().addItem(
                    _itemNameController.text,
                    _itemDescriptionController.text,
                    _itemCategoryController.text,
                    _savedImagePath ?? '',
                    selectedRoom!,
                  );
                  if (!itemAdded) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error adding item')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name and select a room')),
                  );
                }
                _itemNameController.clear();
                _itemDescriptionController.clear();
                _itemCategoryController.clear();
                _itemImageController.clear();
                Navigator.pop(context);
                setState(() {
                  _selectedImage = null;
                  _savedImagePath = null;
                  selectedRoom = null;
                });
              },
              child: const Text('Add Item'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _savedImagePath = null;
                  selectedRoom = null;
                });
                _itemNameController.clear();
                _itemDescriptionController.clear();
                _itemCategoryController.clear();
                _itemImageController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _addNewRoom() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Room'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _roomNameController,
                    decoration: const InputDecoration(labelText: 'Room Name'),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedImage != null)
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showImageSourceDialog(dialogSetState: setState);
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Select Image'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_roomNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a room name')),
                      );
                      return;
                    }

                    bool roomAdded = context.read<RoomDataProvider>().addRoom(
                      _roomNameController.text,
                      _savedImagePath ?? '',  // Use saved image path
                    );

                    if (!roomAdded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Room already exists')),
                      );
                    } else {
                      _roomNameController.clear();
                      _roomImageController.clear();
                      Navigator.of(context).pop();
                      setState(() {
                        _selectedImage = null;
                        _savedImagePath = null;
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add Room'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                      _savedImagePath = null;
                    });
                    _roomNameController.clear();
                    _roomImageController.clear();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          const SizedBox(height: 20),
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Search your items...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _searchRooms,
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: _searchQuery.isNotEmpty
                  ? _filteredItems.length
                  : _filteredRooms.length,
              itemBuilder: (context, index) {
                if (_searchQuery.isNotEmpty) {
                  final item = _filteredItems[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailsPage(
                            item: item,
                            onDelete: () {
                              setState(() {
                                _searchRooms(_searchQuery);
                              });
                            },
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          item['image'].toString().startsWith('assets/')
                              ? Image.asset(
                            item['image'],
                            fit: BoxFit.cover,
                          )
                              : Image.file(
                            File(item['image']),
                            fit: BoxFit.cover,
                            errorBuilder: (context, object, stackTrace) {
                              return const Icon(Icons.error);
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withAlpha(100),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Text(
                              item['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  final room = _filteredRooms[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomDetailsPage(room: room),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          room['image'].toString().startsWith('assets/')
                              ? Image.asset(
                            room['image'],
                            fit: BoxFit.cover,
                          )
                              : Image.file(
                            File(room['image']),
                            fit: BoxFit.cover,
                            errorBuilder: (context, object, stackTrace) {
                              return const Icon(Icons.error);
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withAlpha(200),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Text(
                              room['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Add New'),
                content: const Text('Choose an option:'),
                actions: [
                  TextButton(
                    onPressed: _addNewItem,
                    child: const Text('Add new item'),
                  ),
                  TextButton(
                    onPressed: _addNewRoom,
                    child: const Text('Add new room'),
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Itemize',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0.0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchRooms("");
              }
            });
          },
        ),
      ],
    );
  }
  Widget _buildDrawer() {
    return Consumer<RoomDataProvider>(
        builder: (context, roomData, child) {
          // Calcolo il numero totale di oggetti
          int totalObjects = roomData.rooms.fold(0, (sum, room) {
            return sum + (room['items'] as List).length;
          });

          // Calcolo il numero di categorie uniche
          Set<String> uniqueCategories = {};
          for (var room in roomData.rooms) {
            for (var item in room['items'] as List) {
              if (item['category'] != null && item['category'].toString().isNotEmpty) {
                uniqueCategories.add(item['category'].toString());
              }
            }
          }

          // Numero di stanze
          int totalRooms = roomData.rooms.length;

          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  accountName: Text('User name'),
                  accountEmail: Text('username@example.com'),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.blue,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('Objects: '),
                  trailing: Text(
                    totalObjects.toString(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Categories: '),
                  trailing: Text(
                    uniqueCategories.length.toString(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.room),
                  title: const Text('Rooms: '),
                  trailing: Text(
                    totalRooms.toString(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Credits'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Made by Francesco Gorgone for University project'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }
    );
  }
}