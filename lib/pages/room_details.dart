import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:itemize/pages/item_details.dart';
import 'package:itemize/providers/room_data_provider.dart';
import 'package:image_picker/image_picker.dart';

class RoomDetailsPage extends StatefulWidget {
  final Map<String, dynamic> room;

  const RoomDetailsPage({super.key, required this.room});

  @override
  State<RoomDetailsPage> createState() => _RoomDetailsPageState();
}

class _RoomDetailsPageState extends State<RoomDetailsPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _savedImagePath;

  // Mostra il menu con le opzioni "Edit" e "Delete"
  void _showRoomOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Room'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _savedImagePath = null;
                  }); // Reset image state
                  _showEditRoomDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Room'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {}); // Refresh UI with updated data
                  _showDeleteConfirmation();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Dialog per scegliere la sorgente dell'immagine
  void _showImageSourceDialog(Function(File, String) onImageSelected) {
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
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    onImageSelected(File(pickedFile.path), pickedFile.path);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Fotocamera'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    onImageSelected(File(pickedFile.path), pickedFile.path);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Dialog per modificare il nome della room
  void _showEditRoomDialog() {
    final TextEditingController roomNameController =
    TextEditingController(text: widget.room['name']);

    // Inizializza l'immagine se esiste
    if (widget.room['image'] != null && widget.room['image'].isNotEmpty) {
      setState(() {
        _savedImagePath = widget.room['image'];
        _selectedImage = File(widget.room['image']);
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Modifica stanza'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: roomNameController,
                      decoration: const InputDecoration(labelText: 'Nome della stanza'),
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
                        _showImageSourceDialog((File file, String path) {
                          setState(() {
                            _selectedImage = file;
                            _savedImagePath = path;
                          });
                          setDialogState(() {
                            _selectedImage = file;
                            _savedImagePath = path;
                          });
                        });
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Seleziona Immagine'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      final newRoomName = roomNameController.text;

                      // Ensure the room name doesn't already exist
                      if (context.read<RoomDataProvider>().doesRoomExist(newRoomName) &&
                          widget.room['name'] != newRoomName) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('La stanza esiste già'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        // Update the room details
                        final updatedRoom = {
                          'name': newRoomName,
                          'image': _savedImagePath ?? widget.room['image'],
                          'items': widget.room['items'], // Keep existing items
                        };

                        // Update room data in the provider
                        context.read<RoomDataProvider>().updateRoom(widget.room['name'], updatedRoom);
                        Navigator.pop(context); // Close the dialog
                        setState(() {}); // Refresh UI with updated data
                      }
                    },
                    child: const Text('Salva'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  // Dialog di conferma per eliminare la roorm
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Room'),
          content: const Text(
              'Are you sure you want to delete this room and all its items?'),
          actions: [
            TextButton(
              onPressed: () {
                context
                    .read<RoomDataProvider>()
                    .deleteRoom(widget.room['name']);
                Navigator.pop(context); // chiude il dialog
                Navigator.pop(context); // torna indietro dopo la cancellazione
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar con i tre puntini in alto a destra
        title: Text(widget.room['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showRoomOptions,
          ),
        ],
      ),
      body: ListView.builder(
        // Lista scrollabile degli item della room
        itemCount: widget.room['items'].length,
        itemBuilder: (context, index) {
          final item = widget.room['items'][index];
          return ListTile(
            leading: SizedBox(
              width: 50,
              height: 50,
              child: item['image'].toString().startsWith('assets/')
                  ? Image.asset(
                item['image'],
                fit: BoxFit.cover,
              )
                  : Image.file(
                File(item['image']),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error);
                },
              ),
            ),
            title: Text(item['name']),
            subtitle: Text(item['description']),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailsPage(
                    item: item,
                    onDelete: () {
                      setState(() {});
                    },
                  ),
                ),
              );
              setState(() {});
            },
          );
        },
      ),

    );
  }
}