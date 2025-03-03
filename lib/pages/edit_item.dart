import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:itemize/providers/room_data_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class EditItemPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const EditItemPage({Key? key, required this.item}) : super(key: key);

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  late TextEditingController nameController;
  late TextEditingController categoryController;
  late TextEditingController descriptionController;
  late TextEditingController roomController;
  late String selectedRoom;

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _savedImagePath;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item['name']);
    categoryController = TextEditingController(text: widget.item['category']);
    descriptionController = TextEditingController(text: widget.item['description']);
    roomController = TextEditingController(text: widget.item['room']);
    selectedRoom = widget.item['room'];

    // Inizializza l'immagine se esiste
    if (widget.item['image'] != null && widget.item['image'].isNotEmpty) {
      _savedImagePath = widget.item['image'];
      _selectedImage = File(widget.item['image']);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    roomController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        await pickAndSaveImage(pickedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore durante la selezione dell\'immagine')),
        );
      }
    }
  }

  Future<void> pickAndSaveImage(XFile pickedFile) async {
    try {
      final imageBytes = await pickedFile.readAsBytes();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
      final filePath = '${directory.path}/$fileName';
      final imageFile = File(filePath);
      await imageFile.writeAsBytes(imageBytes);

      setState(() {
        _selectedImage = imageFile;
        _savedImagePath = filePath;
      });
    } catch (e) {
      print('Errore nel salvataggio dell\'immagine: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nel salvataggio dell\'immagine')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleziona sorgente immagine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galleria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Fotocamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<RoomDataProvider>().rooms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifica Oggetto'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrizione',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Stanza',
                border: OutlineInputBorder(),
              ),
              value: selectedRoom,
              items: rooms.map((room) {
                return DropdownMenuItem<String>(
                  value: room['name'],
                  child: Text(room['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRoom = value!;
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
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.image),
              label: const Text('Seleziona Immagine'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final updatedItem = {
                  'name': nameController.text,
                  'category': categoryController.text,
                  'room': selectedRoom,
                  'description': descriptionController.text,
                  'image': _savedImagePath ?? widget.item['image'],
                };

                context.read<RoomDataProvider>().updateItem(
                  widget.item['room'],
                  widget.item['name'],
                  updatedItem,
                );

                Navigator.pop(context, updatedItem); // chiude EditItemPage e ritorna updatedItem
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('Salva Modifiche'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}