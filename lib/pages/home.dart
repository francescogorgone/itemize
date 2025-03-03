import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; //import for handling image selection from gallery or camera
import 'package:itemize/pages/item_details.dart';
import 'package:itemize/pages/room_details.dart';
import 'package:provider/provider.dart';
import 'package:itemize/providers/room_data_provider.dart'; //import for room data management
import 'package:path_provider/path_provider.dart'; //import for accessing device's file system
import 'package:path/path.dart' as path; //import for path manipulation

class HomePage extends StatefulWidget { //StatefulWidget because it needs to update dynamically the UI
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); //access Scaffold widget
  final ImagePicker _picker = ImagePicker(); //select images
  File? _selectedImage; //variable for storing selected image file
  String? _savedImagePath; //variable for storing the path of saved image

  // Text controllers
  final TextEditingController _itemNameController = TextEditingController(); //controller for item name input
  final TextEditingController _itemDescriptionController = TextEditingController(); //controller for item description input
  final TextEditingController _itemCategoryController = TextEditingController(); //controller for item category input
  final TextEditingController _itemImageController = TextEditingController(); //controller for item image input
  final TextEditingController _roomNameController = TextEditingController(); //controller for room name input
  final TextEditingController _roomImageController = TextEditingController(); //controller for room image input
  late String? selectedRoom; //store currently selected room

  // Variables for searching
  bool _isSearching = false; //check if search is active
  String _searchQuery = ""; //store current search query
  List<Map<String, dynamic>> _filteredItems = []; //store filtered items based on search

  @override
  void initState() {
    super.initState();
    selectedRoom = null; //initialize selectedRoom ro null
  }

  void _searchRooms(String query) {
    setState(() {
      _searchQuery = query; //update current search text
      if (query.isEmpty) {
        _filteredItems = []; //clear item list
      } else {
        List<Map<String, dynamic>> items = []; //temporary list for matching items
        for (var room in context.read<RoomDataProvider>().rooms) { //iterates through each room
          for (var item in room['items']) { //iterates through each item in the room
            if (item['name'].toLowerCase().contains(query.toLowerCase()) || //check if the query matches item's name
                item['description'].toLowerCase().contains(query.toLowerCase()) || //check if the query matches item's description
                item['category'].toLowerCase().contains(query.toLowerCase())) { //check if the query matches item's category
              items.add(item); //add matching item to the temporary list
            }
          }
        }
        _filteredItems = items; //update filtered items list with matching items
      }
    });
  }

  Future<void> pickAndSaveImage(XFile pickedFile, {
    Function(void Function())? dialogSetState}) async { //asynchronously save picked image
    try {
      final imageBytes = await pickedFile.readAsBytes(); //read image data
      final directory = await getApplicationDocumentsDirectory(); //get the application's document directory
      final fileName = path.basename(pickedFile.path); //extracts from provided file path its filename
      final filePath = '${directory.path}/$fileName'; //constructs the path where the image will be saved
      final imageFile = File(filePath); //create File object representing image file
      await imageFile.writeAsBytes(imageBytes); //save image to the device

      setState(() {
        _selectedImage = imageFile; //update _selectedImage variable with new imageFile
        _savedImagePath = filePath; //update _savedImagePath variable with full path of the saved image
        _roomImageController.text = filePath; // Update text controller for room image input with the new file path
      });

      if (dialogSetState != null) {
        dialogSetState(() {}); //when called refresh the dialog's UI
      }

    } catch (e) { //catch exceptions during image saving
      ScaffoldMessenger.of(context).showSnackBar( //show snackbar if an error occurs
        const SnackBar(content: Text('Error saving image')),
      );
    }
  }

  void _showImageSourceDialog({ //display dialog allowing the user to choose between selecting an image from gallery or camera
    Function(void Function())? dialogSetState}) { //dialogSetState updates the dialog's UI after image selection
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
                  if (pickedFile != null) { //check if image was successfully picked
                    await pickAndSaveImage(pickedFile, dialogSetState: dialogSetState); //save picked image and update the dialog
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
                    await pickAndSaveImage(pickedFile, dialogSetState: dialogSetState); //save picked image and update the dialog
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addNewItem() { //display dialog allowing the user to add a new item
    showDialog( //show dialog box
      context: context, //specified context (current build) for the dialog
      builder: (BuildContext context) { //create dialog's content
        return AlertDialog( //create AlertDialog widget
          title: const Text('Add new item'), //dialog's title
          content: SingleChildScrollView( //allow scrolling if context exceed available space
            child: StatefulBuilder( //allow updating the UI within the dialogue
                builder: (context, setState) { //create dialog's content (setState updates the UI within the dialog)
                  return Column( //arrange content vertically
                    mainAxisSize: MainAxisSize.min, //column takes up the minimum necessary space
                    children: [
                      TextField( //item's name
                        controller: _itemNameController,
                        decoration: const InputDecoration(labelText: 'Item name'),
                      ),
                      TextField( //item's category
                        controller: _itemCategoryController,
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                      TextField( //item's description
                        controller: _itemDescriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      DropdownButtonFormField<String?>( //Dropdown menu for selecting the room
                        value: selectedRoom, //currently selected room
                        decoration: const InputDecoration(labelText: 'Room'),
                        items: context.watch<RoomDataProvider>().rooms.map((room) { //iterates through rooms from RoomDataProvider and transforms each into a list item
                          return DropdownMenuItem<String?>( //create a DropDownMenu item for each room
                            value: room['name'], //set value of the DropDown item to the room's name
                            child: Text(room['name']), //show room's name in the DropDown
                          );
                        }).toList(), //convert mapped list to list
                        onChanged: (value) { //called when the selected room changes
                          setState(() { //update UI state
                            selectedRoom = value; //update selectedRoom variable
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
                      ElevatedButton.icon( //ElevatedButton for selecting an image
                        onPressed: () {
                          _showImageSourceDialog(dialogSetState: setState); //show ImageSourceDialog and update the UI
                        },
                        icon: const Icon(Icons.image), //image icon
                        label: const Text('Select image'),
                      ),
                    ],
                  );
                }
            ),
          ),
          actions: [ //list of actions for the dialog
            TextButton( //add item button
              onPressed: () {
                Navigator.of(context).pop(); //close the dialog
                if (selectedRoom != null && _itemNameController.text.trim().isNotEmpty) { //check if a room is selected and the item name is not empty
                  bool itemAdded = context.read<RoomDataProvider>().addItem( //add the item using RoomDataProvider
                    _itemNameController.text, //item name
                    _itemDescriptionController.text, //item description
                    _itemCategoryController.text, //item category
                    _savedImagePath ?? '', //item image path (or empty string if there is no image)
                    selectedRoom!, //selected room
                  );
                  if (!itemAdded) { //check if the item was successfully added
                    ScaffoldMessenger.of(context).showSnackBar( //show snackbar if an error occurs
                      const SnackBar(content: Text('Error adding item')),
                    );
                  }
                } else { //if a room is not selected or the item name is empty
                  ScaffoldMessenger.of(context).showSnackBar( //show snackbar
                    const SnackBar(content: Text('Please enter a name and select a room')),
                  );
                }
                _itemNameController.clear(); //clear item's name text field
                _itemDescriptionController.clear(); //clear item's description text field
                _itemCategoryController.clear(); //clear item's category text field
                _itemImageController.clear(); //clear item's image path text field
                Navigator.pop(context); //close the dialog
                setState(() { //update UI state
                  _selectedImage = null; //reset selected image
                  _savedImagePath = null; //reset saved image path
                  selectedRoom = null; //reset selected room
                });
              },
              child: const Text('Add item'),
            ),
            TextButton( //cancel button (item)
              onPressed: () {
                setState(() { //update UI state
                  _selectedImage = null; //reset selected image
                  _savedImagePath = null; //reset saved image path
                  selectedRoom = null; //reset selected room
                });
                _itemNameController.clear(); //clear item's name text field
                _itemDescriptionController.clear(); //clear item's description text field
                _itemCategoryController.clear(); //clear item's category text field
                _itemImageController.clear(); //clear item's image path text field
                Navigator.of(context).pop(); //close the dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _addNewRoom() { //display dialog allowing the user to add a new room
    showDialog( //show dialog box
        context: context, //specified context (current build) for the dialog
        builder: (BuildContext context) { //create dialog's content
      return StatefulBuilder( //allow updating the UI within the dialog
          builder: (context, setState) { //create dialog's content (setState updates the UI within the dialog)
        return AlertDialog( //create AlertDialog widget
            title: const Text('Add new room'), //dialog's title
            content: Column( //arrange content vertically
              mainAxisSize: MainAxisSize.min, //column takes up the minimum necessary space
              children: [
                TextField( //room's name
                  controller: _roomNameController,
                  decoration: const InputDecoration(labelText: 'Room name'),
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
                ElevatedButton.icon( //ElevatedButton for selecting an image
                  onPressed: () {
                    _showImageSourceDialog(dialogSetState: setState); //show ImageSourceDialog and update the UI
                  },
                  icon: const Icon(Icons.image), //image icon
                  label: const Text('Select image'),
                ),
              ],
            ),
            actions: [ //list of actions for the dialog
            TextButton( //add room button
            onPressed: () {
          if (_roomNameController.text.trim().isEmpty) { //check if room name is empty
            ScaffoldMessenger.of(context).showSnackBar( //show snackbar if the room name is empty
              const SnackBar(content: Text('Please enter a room name')),
            );
            return; //exit the function if the room name is empty
          }

          bool roomAdded = context.read<RoomDataProvider>().addRoom( //add the room using RoomDataProvider
            _roomNameController.text, //room name
            _savedImagePath ?? '',  //room image path (or empty string if there is no image)
          );

          if (!roomAdded) { //check if the room was successfully added
            ScaffoldMessenger.of(context).showSnackBar( //show snackbar if an error occurs
              const SnackBar(content: Text('Room already exists')),
            );
          } else { //if the room was successfully added
            _roomNameController.clear(); //clear room's name text field
            _roomImageController.clear(); //clear room's image path text field
            Navigator.of(context).pop(); //close the dialog
            setState(() { //update UI state
              _selectedImage = null; //reset selected image
              _savedImagePath = null; //reset saved image path
            });
            Navigator.of(context).pop(); //close the dialog
          }
        },
    child: const Text('Add room'),
    ),
              TextButton( //cancel button (room)
                onPressed: () {
                  setState(() { //update UI state
                    _selectedImage = null; //reset selected image
                    _savedImagePath = null; //reset saved image path
                  });
                  _roomNameController.clear(); //clear room's name text field
                  _roomImageController.clear(); //clear room's image path text field
                  Navigator.of(context).pop(); //close the dialog
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
      backgroundColor: Colors.white, //set background color to white
      key: _scaffoldKey,
      appBar: _buildAppBar(), //build the AppBar
      drawer: _buildDrawer(), //build the Drawer
      body: Column( //arrange content vertically
        children: [
          const SizedBox(height: 20), //add vertical space
          if (_isSearching) //conditionally render a search bar if _isSearching is true
            Padding( //add padding around the search bar
              padding: const EdgeInsets.all(16.0), //padding of 16 pixels
              child: TextField( //TextField for searching
                autofocus: true, //automatically focus on the searchbar
                style: const TextStyle(color: Colors.black), //search bar text color set to black
                decoration: const InputDecoration( //set decoration for text field
                  hintText: 'Search your items...', //hint text
                  hintStyle: TextStyle(color: Colors.grey), //hint text color set to grey
                  border: OutlineInputBorder(), //border style
                  filled: true, //fill the text field with a background color
                  fillColor: Colors.white, //white fill color
                ),
                onChanged: _searchRooms, //call _searchRooms function when the text changes
              ),
            ),
          Expanded( //expand the GridView to fill the available space
            child: GridView.builder( //create a GridView
              padding: //add padding around the GridView
                const EdgeInsets.all(20), //padding of 20 pixels
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( //set GridView layout
                crossAxisCount: 2, //number of columns
                crossAxisSpacing: 16, //spacing between columns
                mainAxisSpacing: 16, //spacing between rows
                childAspectRatio: 1, //aspect ratio of the grid items (same height and width)
              ),
              itemCount: _searchQuery.isNotEmpty //number of items to display based on whether a search query is active
                  ? _filteredItems.length //number of filtered items to display if a search query is active
                  : context.watch<RoomDataProvider>().rooms.length, //number of rooms to display if no search query is active
              itemBuilder: (context, index) { //create each grid item
                if (_searchQuery.isNotEmpty) { //if a search query contains text
                  final item = _filteredItems[index];  //get item as specified index from the _filteredItems list
                  return GestureDetector( //create GestureDetector to handle taps on the item
                    onTap: () {
                      Navigator.push( //push a new route
                        context, //provide build context
                        MaterialPageRoute( //create MaterialPageRoute to navigate to ItemDetailsPage
                          builder: (context) => ItemDetailsPage( //build ItemDetailsPage widget
                            item: item, //pass selected item data to the ItemDetailsPage
                            onDelete: () { //callback function called when the item is deleted in ItemDetailsPage
                              setState(() { //update UI state
                                _searchRooms(_searchQuery); //refresh search results (the searched item has been now deleted so it shows no more)
                              });
                            },
                          ),
                        ),
                      );
                    },
                    child: ClipRRect( //clip the widget to a rounded rectangle
                      borderRadius: BorderRadius.circular(12), //set border radius
                      child: Stack( //arrange widgets in a stack
                        fit: StackFit.expand, //expand the widgets to fill the available space
                        children: [
                          item['image'].toString().startsWith('assets/') //check if the image path starts with 'assets/'
                            ? Image.asset( //if the image path starts with 'assets/', load the image from the assets folder
                              item['image'], //image path
                              fit: BoxFit.cover, //ensure image covers the entire container
                          )
                            : Image.file( //if the image path doesn't start with 'assets/' load the image from a file
                              File(item['image']), //image path
                              fit: BoxFit.cover, //ensure the image covers the entire container
                              errorBuilder: (context, object, stackTrace) { //handle image loading errors
                                return const Icon(Icons.error); //display error icon if the image fails to load
                            },
                          ),
                          Container( //container to add a gradient overlay
                            decoration: BoxDecoration( //container decoration
                              gradient: LinearGradient( //create a linear gradient
                                begin: Alignment.topCenter, //starting point of the gradient
                                end: Alignment.bottomCenter, //ending point of the gradient
                                colors: [ //list of colors for the gradient
                                  Colors.transparent, //transparent at the top
                                  Colors.black.withAlpha(100), //semi-transparent black at the bottom (0 being completely transparent and 255 completely opaque)
                                ],
                              ),
                            ),
                          ),
                          Positioned( //position the item name on top of the image
                            bottom: 12, //bottom position
                            left: 12, //left position
                            right: 12, //right position
                            child: Text( //display the item name
                              item['name'],
                              style: const TextStyle( //text style
                                color: Colors.white, //white text color
                                fontSize: 16, //font size
                                fontWeight: FontWeight.bold, //bold font weight
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else { //if  no search query is active
                  final room = context.watch<RoomDataProvider>().rooms[index]; //get the room at the specified index from RoomDataProvider
                  return GestureDetector( //create GestureDetector to handle taps on the room
                    onTap: () {
                      Navigator.push( //push a new route
                        context, //provide build context
                        MaterialPageRoute( //create MaterialPageRoute to navigate to RoomDetailsPage
                          builder: (context) => RoomDetailsPage(room: room), //build RoomDetailsPage widget
                        ),
                      );
                    },
                    child: ClipRRect( //clip the widget to a rounded rectangle
                      borderRadius: BorderRadius.circular(12), //set border radius
                      child: Stack( //arrange widgets in a stack
                        fit: StackFit.expand, //expand the widgets to fill the available space
                        children: [
                          room['image'].toString().startsWith('assets/') //check if the image path starts with 'assets/'
                            ? Image.asset( //if the image path starts with 'assets/', load the image from the assets folder
                              room['image'], //image path
                              fit: BoxFit.cover, //ensure image covers the entire container
                          )
                            : Image.file( //if the image path doesn't start with 'assets/' load the image from a file
                              File(room['image']), //image path
                              fit: BoxFit.cover, //ensure the image covers the entire container
                              errorBuilder: (context, object, stackTrace) { //handle image loading errors
                                return const Icon(Icons.error); //display error icon if the image fails to load
                            },
                          ),
                          Container( //container to add a gradient overlay
                            decoration: BoxDecoration( //container decoration
                              gradient: LinearGradient( //create a linear gradient
                                begin: Alignment.topCenter, //starting point of the gradient
                                end: Alignment.bottomCenter, //ending point of the gradient
                                colors: [ //list of colors for the gradient
                                  Colors.transparent, //transparent at the top
                                  Colors.black.withAlpha(200), //semi-transparent black at the bottom (0 being completely transparent and 255 completely opaque)
                                ],
                              ),
                            ),
                          ),
                          Positioned(  //position the room name on top of the image
                            bottom: 12, //bottom position
                            left: 12, //left position
                            right: 12, //right position
                            child: Text( //display the room name
                              room['name'],
                              style: const TextStyle( //text style
                                color: Colors.white, //white text color
                                fontSize: 16, //font size
                                fontWeight: FontWeight.bold, //bold font weight
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
      floatingActionButton: FloatingActionButton( //create a FloatingActionButton
        onPressed: () {
          showDialog( //show a dialog box
            context: context, //provide build context for the dialog
            builder: (BuildContext context) { //builder functions that creates the dialog's content
              return AlertDialog( //create AlertDialog widget
                title: const Text('Add new'), //title of the dialog
                content: const Text('Choose an option:'), //content of the dialog
                actions: [ //list of actions for the dialog
                  TextButton( //add new item button
                    onPressed: _addNewItem, //call _addNewItem function when pressed
                    child: const Text('Add new item'),
                  ),
                  TextButton( //add new room button
                    onPressed: _addNewRoom, //call _addNewRoom function when pressed
                    child: const Text('Add new room'),
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Colors.blue, //set button's background color to blue
        child: const Icon(Icons.add), //add icon
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar( //create AppBar widget
      title: const Text( //title of the AppBar
        'Itemize', //title text
        style: TextStyle(
            fontSize: 24, //font size
            fontWeight: FontWeight.bold //bold font weight
        ),
      ),
      backgroundColor: Colors.white, //set background color to white
      elevation: 0, //no shadow from the AppBar
      centerTitle: true, //center the title
      leading: IconButton( //IconButton on the leading (left) of the AppBar
        icon: const Icon(Icons.menu, color: Colors.black), //black menu icon
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer(); //open the drawer
        },
      ),
      actions: [
        IconButton( //IconButton automatically added to the trailing (right) of the AppBar
          icon: Icon(_isSearching //if _isSearching is active
              ? Icons.close //show close icon
              : Icons.search, //if _isSearching is not active show search icon
              color: Colors.black //set icon color to black
          ),
          onPressed: () {
            setState(() { //update UI state
              _isSearching = !_isSearching; //inverts _isSearching boolean value (from True to False, from IS searching to IS NOT searching)
              if (!_isSearching) { //if _isSearching is not active
                _searchRooms(""); //clear the search
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Consumer<RoomDataProvider>( //access RoomDataProvider through Consumer
        builder: (context, roomData, child) { //build the drawer based on RoomDataProvider data
          int totalObjects = roomData.rooms.fold(0, (sum, room) { //calculate the total number of objects using fold to sum the lengths of all 'items' lists in each room
            //fold iterates on a list and sums the result. 0 is the initial value and iterates for each element of the list
            return sum + (room['items'] as List).length; //get the length (number of elements) of the list room['items'] and adds it to sum returning the new accumulator value
          }
          );

          Set<String> uniqueCategories = {}; //Set automatically handles uniqueness
          for (var room in roomData.rooms) { //iterates through each room
            for (var item in room['items'] as List) { //iterates through each item in the room
              if (item['category'] != null && item['category'].toString().isNotEmpty) { //check if the category is valid
                uniqueCategories.add(item['category'].toString()); //add the category to the set
              }
            }
          }

          int totalRooms = roomData.rooms.length; //length of the rooms list

          return Drawer( //create drawer widget
            child: ListView( //display the drawer items
              padding: EdgeInsets.zero, //remove default padding
              children: [ //list of widgets to display in the drawer
                const UserAccountsDrawerHeader( //user account header
                  decoration: BoxDecoration(
                    color: Colors.blue, //header's background color set to blue
                  ),
                  accountName: Text('User name'), //user's name
                  accountEmail: Text('username@example.com'), //user's email
                  currentAccountPicture: CircleAvatar( //circular avatar picture
                    backgroundColor: Colors.white, //circular avatar picture background color set to white
                    child: Icon(
                      Icons.person, //person icon
                      size: 50, //icon size
                      color: Colors.blue, //icon color set to blue
                    ),
                  ),
                ),
                ListTile( //ListTile for total objects
                  leading: const Icon(Icons.inventory), //inventory icon
                  title: const Text('Objects: '),
                  trailing: Text(
                    totalObjects.toString(), //number of total objects
                    style: const TextStyle( //text style
                        fontSize: 16, //font size
                        fontWeight: FontWeight.bold //bold font weight
                    ),
                  ),
                ),
                ListTile( //ListTile for unique categories
                  leading: const Icon(Icons.category), //category icon
                  title: const Text('Categories: '),
                  trailing: Text(
                    uniqueCategories.length.toString(), //number of unique categories
                    style: const TextStyle( //text style
                        fontSize: 16, //font size
                        fontWeight: FontWeight.bold //bold font weight
                    ),
                  ),
                ),
                ListTile( //ListTile for total rooms
                  leading: const Icon(Icons.room), //room icon
                  title: const Text('Rooms: '),
                  trailing: Text(
                    totalRooms.toString(), //number of total rooms
                    style: const TextStyle( //text style
                        fontSize: 16, //font size
                        fontWeight: FontWeight.bold //bold font weight
                    ),
                  ),
                ),
                const Divider(), //create a divider
                ListTile( //ListTile for credits
                  leading: const Icon(Icons.info), //info icon
                  title: const Text('Credits'),
                  onTap: () {
                    Navigator.pop(context); //close the drawer
                    ScaffoldMessenger.of(context).showSnackBar( //show snackbar with credits
                      const SnackBar(
                        content: Text(
                            'Made by Francesco Gorgone for University project'),
                        duration: Duration(seconds: 2), //snackbar duration
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
