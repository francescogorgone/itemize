import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:itemize/pages/item_details.dart';
import 'package:itemize/providers/room_data_provider.dart';
import 'package:image_picker/image_picker.dart';

class RoomDetailsPage extends StatefulWidget { //StatefulWidget for dynamic updates
  final Map<String, dynamic> room; //room data passed as a parameter

  const RoomDetailsPage({super.key, required this.room}); //constructor with required room data

  @override
  State<RoomDetailsPage> createState() => _RoomDetailsPageState();
}

class _RoomDetailsPageState extends State<RoomDetailsPage> { //state class
  final ImagePicker _picker = ImagePicker(); //image picker instance
  File? _selectedImage; //selected image file (? meaning the variable can be null if no image was selected)
  String? _savedImagePath; //path of the selected image (? meaning the variable can be null if no image was selected)

  void _showRoomOptions() { //show 'Edit' and 'Delete' room options
    showModalBottomSheet(
      context: context,
      builder: (context) { //create bottom sheet content
        return SafeArea( //ensure content is within the safe area for correct displaying
          child: Column( //arrange content vertically
            children: [
              ListTile( //ListTile for room editing
                leading: const Icon(Icons.edit), //edit icon
                title: const Text('Edit room'),
                onTap: () {
                  Navigator.pop(context); //close the bottom sheet
                  setState(() { //update UI state
                    _selectedImage = null; //reset selected image
                    _savedImagePath = null; //reset saved image path
                  });
                  _showEditRoomDialog(); //show edit room dialog
                },
              ),
              ListTile( //ListTile for room deleting
                leading: const Icon(Icons.delete), //delete icon
                title: const Text('Delete room'),
                onTap: () {
                  Navigator.pop(context); //close the bottom sheet
                  setState(() {}); //update UI state
                  _showDeleteConfirmation(); //show delete confirmation dialog
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImageSourceDialog(Function(File, String) onImageSelected) { //callback function to handle the selected image
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select image source'), //dialog's title
          content: Column( //arrange content vertically
            mainAxisSize: MainAxisSize.min, //column takes up the minimum necessary space
            children: [
              ListTile( //ListTile for selecting the gallery
                leading: const Icon(Icons.photo_library), //icon on the left
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context); //close the dialog
                  final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) { //check if image was successfully picked
                    onImageSelected(File(pickedFile.path), pickedFile.path);  //callback with image file and image path
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
                    onImageSelected(File(pickedFile.path), pickedFile.path); //callback with image file and image path
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditRoomDialog() {
    final TextEditingController roomNameController =
    TextEditingController(text: widget.room['name']); //controller for room name input

    if (widget.room['image'] != null && widget.room['image'].isNotEmpty) { //check if a room image already exists
      setState(() { //update UI state
        _savedImagePath = widget.room['image'];
        _selectedImage = File(widget.room['image']);
      });
    }

    showDialog( //open dialog box
      context: context,
      builder: (BuildContext dialogContext) { //create dialog's content
        return StatefulBuilder( //allow updating the UI within the dialogue
            builder: (context, setDialogState) { //create dialog's content (setState updates the UI within the dialog)
              return AlertDialog( //create AlertDialog box
                title: const Text('Edit room'), //dialog's title
                content: Column( //arrange content vertically
                  mainAxisSize: MainAxisSize.min, //column takes up the minimum necessary space
                  children: [
                    TextField( //TextField for editing room's name
                      controller: roomNameController, // controller managing TextField's input
                      decoration: const InputDecoration(labelText: "Room's name"),
                    ),
                    const SizedBox(height: 16), //add vertical space
                    if (_selectedImage != null) //if _selectedImage is not null
                      Container(
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
                    ElevatedButton.icon( //ElevatedButton for selecting an image
                      onPressed: () {
                        _showImageSourceDialog((File file, String path) { //select an image from gallery of from camera
                          setState(() { //update UI state
                            _selectedImage = file; //set the selected image
                            _savedImagePath = path; //set the path of the selected image
                          });
                          setDialogState(() { //update dialog's state
                            _selectedImage = file; //set the selected image in the dialog
                            _savedImagePath = path; //set the path of the selected image in the dialog
                          });
                        });
                      },
                      icon: const Icon(Icons.image), //image icon
                      label: const Text('Choose image'),
                    ),
                  ],
                ),
                actions: [ //button at the bottom of the dialog
                  TextButton( //save changes button
                    onPressed: () {
                      final newRoomName = roomNameController.text; //retrieves the room name from the TextField

                      if (context.read<RoomDataProvider>().doesRoomExist(newRoomName) && //check if a room with the same name already exists
                          widget.room['name'] != newRoomName) { //check if the new name is different from the old one
                        ScaffoldMessenger.of(context).showSnackBar( //show snackbar
                          const SnackBar(
                            content: Text('The room already exists'),
                            duration: Duration(seconds: 2), //snackbar duration
                          ),
                        );
                      } else { //if the room name is unique
                        final updatedRoom = { //create a map containing the updated room data
                          'name': newRoomName, //new room name
                          'image': _savedImagePath ?? widget.room['image'], //new image path or old one no new image was selected
                          'items': widget.room['items'], //keep the items already existing in the room
                        };

                        context.read<RoomDataProvider>().updateRoom(widget.room['name'], updatedRoom); //update room data in the provider
                        Navigator.pop(context); //close the dialog
                        setState(() {}); //update UI state
                      }
                    },
                    child: const Text('Save'),
                  ),
                  TextButton( //cancel the changes button
                    onPressed: () => Navigator.pop(context), //close the dialog
                    child: const Text('Cancel'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  void _showDeleteConfirmation() { //confirmation dialog before deleting a room
    showDialog( //show dialog box
      context: context,
      builder: (context) {
        return AlertDialog( //create AlertDialog box
          title: const Text('Delete room'), //dialog's title
          content: const Text('Are you sure you want to delete this room and all its items?'),
          actions: [ //buttons at the bottom of the dialog
            TextButton(
              onPressed: () {
                context
                    .read<RoomDataProvider>() //access RoomDataProvider
                    .deleteRoom(widget.room['name']); //call deleteRoom
                Navigator.pop(context); //close the dialog
                Navigator.pop(context); //close RoomDetailsPage
              },
              child: const Text('Delete'),
            ),
            TextButton( //button to cancel deletion
              onPressed: () => Navigator.pop(context), //close the dialog box
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) { //build the UI of the widget
    return Scaffold(
      appBar: AppBar( //create AppBar
        title: Text(widget.room['name']), //set the AppBar's title as the room's name
        actions: [ //widget displayed on the right side of the AppBar
          IconButton(
            icon: const Icon(Icons.more_vert), //three vertical dots icon
            onPressed: _showRoomOptions, //call _showRoomOptions function
          ),
        ],
      ),
      body: ListView.builder( //create a scrollable list of items
        itemCount: widget.room['items'].length, //set number of items in the list
        itemBuilder: (context, index) { //build each item in the list
          final item = widget.room['items'][index]; //get the item at the specified index
          return ListTile( //create a ListTile for each item
            leading: SizedBox( //create SizedBox to contain item's image
              width: 50, // SizedBox width
              height: 50, //SizedBox height
              child: item['image'].toString().startsWith('assets/') //check if the image path starts with 'assets/'
                  ? Image.asset( //if the image path starts with 'assets/', load the image from the assets folder
                item['image'], //image path
                fit: BoxFit.cover, //ensure the image covers the entire SizedBox
              )
                  : Image.file( //if the image path doesn't start with 'assets/' load the image from a file
                File(item['image']), //image path
                fit: BoxFit.cover, //ensure the image covers the entire SizedBox
                errorBuilder: (context, error, stackTrace) { //handle image loading errors
                  return const Icon(Icons.error); //display error icon if the image fails to load
                },
              ),
            ),
            title: Text(item['name']), //set the ListTile's title as the item's name
            subtitle: Text(item['description']), //set ListTile's subtitle as the item's description
            onTap: () async {
              await Navigator.push( //push a new route
                context,
                MaterialPageRoute( //create MaterialPageRoute to navigate to ItemDetailsPage
                  builder: (context) => ItemDetailsPage( //build ItemDetailsPage widget
                    item: item, //pass selected item data to the ItemDetailsPage
                    onDelete: () { //callback function called when the item is deleted in ItemDetailsPage
                      setState(() {}); //update UI state
                    },
                  ),
                ),
              );
              setState(() {}); //update UI state
            },
          );
        },
      ),

    );
  }
}
