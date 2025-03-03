import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:itemize/pages/edit_item.dart';
import 'package:itemize/providers/room_data_provider.dart';

class ItemDetailsPage extends StatefulWidget { //StatefulWidget for dynamic updates
  final Map<String, dynamic> item; //item data to show
  final VoidCallback onDelete; //callback function to handle item deletion

  const ItemDetailsPage({super.key, required this.item, required this.onDelete}); //item data and onDelete callback are required parameters

  @override
  _ItemDetailsPageState createState() => _ItemDetailsPageState(); //create state
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  late Map<String, dynamic> item; //store item details in a map

  @override
  void initState() { //initialize the state
    super.initState();
    item = widget.item; //copy the item data from widget's constructor
  }

  @override
  Widget build(BuildContext context) { //build the UI
    return Scaffold(
      appBar: AppBar(
        title: Text('${item['name']} details'), //item's name as AppBar's title
      ),
      body: Padding( //add padding around the content
        padding: const EdgeInsets.all(20.0),
        child: Column( //arrange content vertically
          crossAxisAlignment: CrossAxisAlignment.start, //align widgets to the start of the column
          children: [
            Text(
              item['name'], //item's name
              style: const TextStyle( //text style
                  fontSize: 24, //font size
                  fontWeight: FontWeight.bold //bold font weight
              ),
            ),
            const SizedBox(height: 8), //add vertical space
            Container( //container to show item's image
              height: 350, //container height
              width: 350, //container width
              decoration: BoxDecoration( //set container decoration
                border: Border.all(color: Colors.grey), //grey border
                borderRadius: BorderRadius.circular(8), //round corners for the container
                image: DecorationImage( //set image decoration
                  image: item['image'].toString().startsWith('assets/') //check if image path starts with 'assets/'
                      ? AssetImage(item['image']) //if the image path starts with 'assets/', load the image from assets folder
                      : FileImage(File(item['image'])) as ImageProvider, //if the image path doesn't start with 'assets/', load the image from a file
                  fit: BoxFit.cover, //ensure image covers the entire container
                ),
              ),
            ),
            const SizedBox(height: 8), //add vertical space
            Text(
              'Category: ${item['category']}', //item's category
              style: const TextStyle(fontSize: 16), //font size
            ),
            const SizedBox(height: 8), //add vertical space
            Text(
              'Description: ${item['description']}', //item's description
              style: const TextStyle(fontSize: 16), //font size
            ),
            const SizedBox(height: 8), //add vertical space
            Text(
              'Room: ${item['room']}', //item's room
              style: const TextStyle(fontSize: 16), //font size
            ),
            const SizedBox(height: 8), //add vertical space
            Row( //arrange buttons horizontally
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, //distribute buttons evenly across the row
              children: [
                SizedBox( //edit button container
                  height: 50, //container height
                  width: 100, //container width
                  child: ElevatedButton( //ElevatedButton to edit the item
                    onPressed: () async { //asynchronous function
                      final updated = await Navigator.push( //push a new route
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditItemPage(item: item), //build EditItemPage widget
                        ),
                      );
                      if (updated != null) { //if changes were made
                        setState(() { //update UI state
                          item = updated; //update item data
                        });
                      }
                    },
                    child: const Text('Edit'), //edit button's text
                  ),
                ),
                SizedBox( //delete button container
                  height: 50, //container height
                  width: 100, //container width
                  child: ElevatedButton( //ElevatedButton to delete the item
                    onPressed: () {
                      _showDeleteConfirmation(context); //show delete confirmation dialog
                    },
                    child: const Text('Delete'), //delete button's text
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) { //show delete confirmation dialog
    showDialog( //open dialog box
      context: context,
      builder: (context) { //create dialog's content
        return AlertDialog( //create AlertDialog box
          title: const Text('Delete item'), //dialog's title
          content: const Text('Are you sure you want to delete this item?'), //dialog's message
          actions: [
            TextButton( //confirm deletion button
              onPressed: () {
                context.read<RoomDataProvider>().deleteItem(item['room'], item['name']); //delete item from RoomDataProvider
                widget.onDelete(); //calls onDelete callback provided to the ItemDetailsPage widget
                Navigator.pop(context); //close the dialog
                Navigator.pop(context); //close ItemDetailsPage
              },
              child: const Text('Delete'), //confirm deletion button's text
            ),
            TextButton( //cancel deletion button
              onPressed: () {
                Navigator.pop(context); //close the AlertDialog
              },
              child: const Text('Cancel'), //cancel deletion button's text
            ),
          ],
        );
      },
    );
  }
}
