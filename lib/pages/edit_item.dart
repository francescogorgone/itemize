import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:itemize/providers/room_data_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class EditItemPage extends StatefulWidget { //StatefulWidget for dynamic updates
  final Map<String, dynamic> item; //item data passed as a parameter

  const EditItemPage({super.key, required this.item}); //constructor with required item data

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  late TextEditingController nameController; //controller for item's name
  late TextEditingController categoryController; //controller for item's category
  late TextEditingController descriptionController; //controller for item's description
  late TextEditingController roomController; //controller for item's room
  late String selectedRoom; //store currently selected room

  final ImagePicker _picker = ImagePicker(); //select images
  File? _selectedImage; //variable for storing selected image file
  String? _savedImagePath; //variable for storing the path of saved image

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item['name']); //initialize nameController with the item's name
    categoryController = TextEditingController(text: widget.item['category']); //initialize categoryController with the item's category
    descriptionController = TextEditingController(text: widget.item['description']); //initialize descriptionController with the item's description
    roomController = TextEditingController(text: widget.item['room']); //initialize roomController with the item's room
    selectedRoom = widget.item['room']; //set the item's room as selectedRoom

    if (widget.item['image'] != null && widget.item['image'].isNotEmpty) { //check if the item has an image path and if that path is not empty
      _savedImagePath = widget.item['image']; //store the image's path
      _selectedImage = File(widget.item['image']); //create File object representing image file
    }
  }

  @override
  void dispose() {
    nameController.dispose(); //release resources of nameController
    categoryController.dispose(); //release resources of categoryController
    descriptionController.dispose(); //release resources of descriptionController
    roomController.dispose(); //release resources of roomController
    super.dispose(); //release resources of the superclass State<EditItemPage>
  }

  Future<void> pickAndSaveImage(XFile pickedFile) async { //asynchronous function to pick and save an image
    try { //handle errors
 //check if an image has been picked
      final imageBytes = await pickedFile.readAsBytes(); //readAsBytes the image
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}'; //create unique file name
      final filePath = '${directory.path}/$fileName'; //create full file path
      final imageFile = File(filePath); //create File object
      await imageFile.writeAsBytes(imageBytes); //writeAsBytes the image

      setState(() { //update UI state
        _selectedImage = imageFile; //set selected image
        _savedImagePath = filePath; //set saved image path
      });
        } catch (e) { //catch exceptions during image saving
      if (mounted) { //if _EditItemPageState is mounted
        ScaffoldMessenger.of(context).showSnackBar( //show snackbar if an error occurs
          const SnackBar(content: Text('Error saving image')),
        );
      }
    }
  }

void _showImageSourceDialog() { //display dialog allowing the user to choose between selecting an image from gallery or camera
    showDialog( //open dialog box
      context: context, //specified context (current build) for the dialog
      builder: (BuildContext context) { //create dialog's content
        return AlertDialog( //create AlertDialog widget
          title: const Text('Select image source'), //dialog's title
          content: Column( //arrange content vertically
            mainAxisSize: MainAxisSize.min, //column takes up the minimum necessary space
            children: [
              ListTile( //list for selecting the gallery
                leading: const Icon(Icons.photo_library), //icon on the left
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context); //close the dialog
                  final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery); //pick image from the gallery
                  if (pickedFile != null) {pickAndSaveImage(pickedFile); //check if image was successfully picked
                  }
                },
              ),
              ListTile( //ListTile for selecting the camera
                leading: const Icon(Icons.camera_alt), //icon on the left
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context); //close the dialog
                  final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera); //pick image from the camera
                  if (pickedFile != null) { //check if image was successfully picked
                    await pickAndSaveImage(pickedFile); //save picked image and update the dialog
                  }
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
    final rooms = context.watch<RoomDataProvider>().rooms; //retrieve list of rooms from RoomDataProvider
    //context.watch rebuilds the widget when the provider's data changes

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit item'), //title of the AppBar
        backgroundColor: Colors.white, //set background color to white
        elevation: 0, //no shadow from the AppBar
      ),
      body: SingleChildScrollView( //allow scrolling if context exceed available space
        padding: //add padding around the content
          const EdgeInsets.all(20), //padding of 20 pixels
        child: Column( //arrange content vertically
          children: [ //list of widgets to display in the Column
            TextField( //item's name
              controller: nameController,
              decoration: const InputDecoration( //set decoration for text field
                labelText: 'Name',
                border: OutlineInputBorder(), //border style
              ),
            ),
            const SizedBox(height: 16), //add vertical space
            TextField( //item's category
              controller: categoryController,
              decoration: const InputDecoration( //set decoration for text field
                labelText: 'Category',
                border: OutlineInputBorder(), //border style
              ),
            ),
            const SizedBox(height: 16), //add vertical space
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration( //set decoration for text field
                labelText: 'Description',
                border: OutlineInputBorder(), //border style
              ),
            ),
            const SizedBox(height: 16), //add vertical space
            DropdownButtonFormField<String>(  //Dropdown menu for selecting the room
              decoration: const InputDecoration( //set decoration for text field
                labelText: 'Room',
                border: OutlineInputBorder(), //border style
              ),
              value: selectedRoom, //currently selected room
              items: rooms.map((room) { //create the dropdown items from the rooms list
                return DropdownMenuItem<String>( //create a dropdown item
                  value: room['name'],
                  child: Text(room['name']),
                );
              }).toList(), //convert the iterable to a list
              onChanged: (value) {  //called when the selected room changes
                setState(() { //update UI state
                  selectedRoom = value!; //update selectedRoom variable
                });
              },
            ),
            const SizedBox(height: 16), //add vertical space
            if (_selectedImage != null) //render a preview if an image was selected
              Container( //container to show selected image
                height: 100, //container height
                width: 100, //container width
                decoration: BoxDecoration( //set container decoration
                  image: DecorationImage( //set image decoration
                    image: FileImage(_selectedImage!), //FileImage widget in order to show the selected image
                    fit: BoxFit.cover, //ensure image covers the entire container
                  ),
                  borderRadius: BorderRadius.circular(8), //round corners for the container
                ),
              ),
            ElevatedButton.icon(  //ElevatedButton for selecting an image
              onPressed: _showImageSourceDialog, //show ImageSourceDialog and update the UI
              icon: const Icon(Icons.image), //image icon
              label: const Text('Select image'),
            ),
            const SizedBox(height: 24), //add vertical space
            ElevatedButton( //button to save changes
              onPressed: () {
                final updatedItem = { //create a map containing the update item data
                  'name': nameController.text, //name from TextField
                  'category': categoryController.text, //category from TextField
                  'room': selectedRoom, //selected room
                  'description': descriptionController.text, //description from TextField
                  'image': _savedImagePath ?? widget.item['image'], //new image path or old one no new image was selected
                };

                context.read<RoomDataProvider>().updateItem(
                  widget.item['room'],
                  widget.item['name'],
                  updatedItem, //update item data in the provider
                );

                Navigator.pop(context, updatedItem); //close EditItemPage
              },
              style: ElevatedButton.styleFrom( //button style
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), //padding of the button
              ),
              child: const Text('Save changes'),
            ),
            const SizedBox(height: 16), //add vertical space
          ],
        ),
      ),
    );
  }
}
