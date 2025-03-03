import 'package:flutter/material.dart';

  class RoomDataProvider with ChangeNotifier { //ChangeNotifier is used for efficient UI updates when data changes
  final List<Map<String, dynamic>> _rooms = [ //store room data as a list of maps
  {
  'name': 'Bedroom', //room's name
  'image': 'assets/images/bedroom.png', //room's image path
  'items': [ //list of items in the room
    {
    'name': 'Laptop', //item's name
    'image': 'assets/images/laptop.png', //item's image path
    'category': 'Electronics', //item's category
    'room': 'Bedroom', //item's room
    'description': 'Linux machine with games on it' //item's description
    }, //laptop
    {
    'name': 'Chair',
    'image': 'assets/images/chair.png',
    'category': 'Furniture',
    'room': 'Bedroom',
    'description': 'Gaming chair'
    }, //chair
    {
    'name': 'Book',
    'image': 'assets/images/book.png',
    'category': 'Books',
    'room': 'Bedroom',
    'description': 'Animal Farm by George Orwell'
    }, //book
    {
    'name': 'Videogame',
    'image': 'assets/images/game.png',
    'category': 'Games',
    'room': 'Bedroom',
    'description': 'Super Smash Bros Brawl for Nintendo Wii'
    }, //videogame
  ], //bedroom's item list
  }, //bedroom
  {
  'name': 'Garage',
  'image': 'assets/images/garage.png',
  'items': [
    {
    'name': 'Lawn mower',
    'image': 'assets/images/lawnmower.png',
    'category': 'Electronics',
    'room': 'Garage',
    'description': "Dad's lawn mower"
    }, //lawn mower
    {
    'name': 'Car',
    'image': 'assets/images/car.png',
    'category': 'Vehicles',
    'room': 'Garage',
    'description': 'Still needs to be fully paid'
    }, //car
  ], //garage's item list
  }, //garage
  {
  'name': 'Kitchen',
  'image': 'assets/images/kitchen.png',
  'items': [
    {
    'name': 'Potato chips',
    'image': 'assets/images/chips.png',
    'category': 'Food',
    'room': 'Kitchen',
    'description': 'Expiration date: 27/02/2025'
    }, //potato chips
  ], //kitchen's item list
  }, //kitchen
  {
  'name': 'Living Room',
  'image': 'assets/images/livingroom.png',
  'items': [
    {
    'name': 'Sofa',
    'image': 'assets/images/sofa.png',
    'category': 'Furniture',
    'room': 'Living room',
    'description': 'Yellow sofa'
    }, //sofa
  ], //living room's item list
  }, //living room
  {
  'name': 'Bathroom',
  'image': 'assets/images/bathroom.png',
  'items': [
    {
    'name': 'Toothbrush',
    'image': 'assets/images/toothbrush.png',
    'category': 'Hygiene',
    'room': 'Bathroom',
    'description': 'Cyan toothbrush'
    }, //toothbrush
  ], //bathroom's item list
  }, //bathroom
  {
  'name': 'Office',
  'image': 'assets/images/office.png',
  'items': [
    {
    'name': 'Lamp',
    'image': 'assets/images/lamp.png',
    'category': 'Furniture',
    'room': 'Office',
    'description': 'Green lantern found for cheap'
    }, //lamp
  ], //office's item list
  }, //office
  ]; //_rooms

  List<Map<String, dynamic>> get rooms => _rooms; //access _rooms list (read-only access)

  //add new item to specified room (returns true if successful, false if not)
  bool addItem(String name, String description, String category, String image, String roomName) {
  //find the room index in order to add the item (case-insensitive)
  int selectedRoomIndex = _rooms.indexWhere((r) => r['name'].toLowerCase() == roomName.toLowerCase());
  if (selectedRoomIndex != -1) { //check if the room exists
  _rooms[selectedRoomIndex]['items'].add({ //add the new item to the room's item list
  'name': name, //item's name
  'description': description, //item's description
  'category': category, //item's category
  'image': image, //item's image path
  'room': roomName, //item's room
  });
  notifyListeners(); //notify listeners of changes
  return true; //return true if the item was added successfully
  }
  return false; //return false if the item was not added successfully
  }

  bool addRoom(String name, String image) { //add new room
  //check if a room with the same name already exists (case-insensitive)
  bool roomNameExists = _rooms.any((room) => room['name'].toLowerCase() == name.toLowerCase());
  if (!roomNameExists) { //proceed only if it doesn't already exist a room with the same name
  _rooms.add({ //add new room to the list
  'name': name, //room's name
  'image': image, //room's image
  'items': [], //room's item list (empty list at the start)
  });
  notifyListeners(); //notify listeners of changes
  return true; //return true if the item was added successfully
  }
  return false; //return false if the item was not added successfully
  }

  bool doesRoomExist(String roomName) { //check if a room with the given name exists (needed for room_details.dart)
    //return true if a room with the same name (case-insensitive) is found, false if not
    return _rooms.any((room) => room['name'].toLowerCase() == roomName.toLowerCase());
  }

  void deleteItem(String roomName, String itemName) { //delete item from specified room
  int roomIndex = _rooms.indexWhere((r) => r['name'].toLowerCase() == roomName.toLowerCase()); //find the index of the room
  if (roomIndex != -1) { //check if the room exists
  _rooms[roomIndex]['items'].removeWhere((item) => item['name'] == itemName); //remove the item from the room's list
  notifyListeners(); //notify listeners of changes
  }
  }

  void updateItem(String oldRoomName, String oldItemName, Map<String, dynamic> updatedItem) { //update an existing item
    int roomIndex = _rooms.indexWhere((r) => r['name'].toLowerCase() == oldRoomName.toLowerCase()); //find the index of the room containing the item
    if (roomIndex != -1) { //check if the room exists
      var items = _rooms[roomIndex]['items'] as List; //get the list of the items in the room
      int itemIndex = items.indexWhere((item) => item['name'] == oldItemName); //find the index of the item to update
      if (itemIndex != -1 && oldRoomName.toLowerCase() == updatedItem['room'].toLowerCase()) { //check if the item exists and if it hasn't been moved to a different room (case-insensitive)
        items[itemIndex]['name'] = updatedItem['name']; //update item's name
        items[itemIndex]['category'] = updatedItem['category']; //update item's category
        items[itemIndex]['description'] = updatedItem['description']; //update item's description
        items[itemIndex]['image'] = updatedItem['image']; //update item's image path
      } else {
        deleteItem(oldRoomName, oldItemName); //delete the old item
        addItem( //add the new one
          updatedItem['name'], //update item's name
          updatedItem['description'], //update item's description
          updatedItem['category'], //update item's category
          updatedItem['image'], //update item's image path
          updatedItem['room'], //update item's room
        );
      }
    }
    notifyListeners(); //notify listeners of changes
  }

  void updateRoom(String oldRoomName, Map<String, dynamic> updatedRoom) { //update an existing room
  int index = _rooms.indexWhere((room) => room['name'].toLowerCase() == oldRoomName.toLowerCase()); //find the index of the room
  if (index != -1) { //check if the room exists
  _rooms[index]['name'] = updatedRoom['name']; //update room's name
  _rooms[index]['image'] = updatedRoom['image']; //update room's image path
  for (var item in _rooms[index]['items']) { //iterates through the items in the room
    item['room'] = updatedRoom['name']; //update room's name for each item in the room
  }
  notifyListeners(); //notify listeners of changes
  }
  }

  void deleteRoom(String roomName) { //delete an existing room
  _rooms.removeWhere((room) => room['name'].toLowerCase() == roomName.toLowerCase()); //remove the room from the list
  notifyListeners(); //notify listeners of changes
  }
  }
