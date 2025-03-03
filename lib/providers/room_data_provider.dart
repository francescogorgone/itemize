import 'package:flutter/material.dart';

  class RoomDataProvider with ChangeNotifier {
  List<Map<String, dynamic>> _rooms = [
  {
  'name': 'Bedroom',
  'image': 'assets/images/bedroom.png',
  'items': [
  {
  'name': 'Laptop',
  'image': 'assets/images/laptop.png',
  'category': 'Electronics',
  'room': 'Bedroom',
  'description': 'Linux machine with games on it'
  },
  {
  'name': 'Chair',
  'image': 'assets/images/chair.png',
  'category': 'Furniture',
  'room': 'Bedroom',
  'description': 'Gaming chair'
  },
  {
  'name': 'Book',
  'image': 'assets/images/book.png',
  'category': 'Books',
  'room': 'Bedroom',
  'description': 'Animal Farm by George Orwell'
  },
  {
  'name': 'Videogame',
  'image': 'assets/images/game.png',
  'category': 'Games',
  'room': 'Bedroom',
  'description': 'Super Smash Bros Brawl for Nintendo Wii'
  },
  ],
  },
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
  },
  {
  'name': 'Car',
  'image': 'assets/images/car.png',
  'category': 'Vehicles',
  'room': 'Garage',
  'description': 'Still needs to be fully paid'
  },
  ],
  },
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
  },
  ],
  },
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
  },
  ],
  },
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
    },
    ],
    },
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
     },
     ],
    },
  ];

  List<Map<String, dynamic>> get rooms => _rooms;

  // Metodo per aggiungere un elemento a una stanza
  bool addItem(String name, String description, String category, String image, String roomName) {
  int selectedRoomIndex = _rooms.indexWhere((r) => r['name'].toLowerCase() == roomName.toLowerCase());
  if (selectedRoomIndex != -1) {
  _rooms[selectedRoomIndex]['items'].add({
  'name': name,
  'description': description,
  'category': category,
  'image': image,
  'room': roomName,
  });
  notifyListeners();
  return true;
  }
  return false;
  }

  // Metodo per aggiungere una nuova stanza
  bool addRoom(String name, String image) {
  bool roomNameExists = _rooms.any((room) => room['name'].toLowerCase() == name.toLowerCase());
  if (!roomNameExists) {
  _rooms.add({
  'name': name,
  'image': image,
  'items': [],
  });
  notifyListeners();
  return true;
  }
  return false;
  }

  bool doesRoomExist(String roomName) {
    return _rooms.any((room) => room['name'].toLowerCase() == roomName.toLowerCase());
  }




  // Metodo per eliminare un elemento da una stanza
  void deleteItem(String roomName, String itemName) {
  int roomIndex = _rooms.indexWhere((r) => r['name'].toLowerCase() == roomName.toLowerCase());
  if (roomIndex != -1) {
  _rooms[roomIndex]['items'].removeWhere((item) => item['name'] == itemName);
  notifyListeners();
  }
  }

  // Metodo per aggiornare un elemento
  void updateItem(String oldRoomName, String oldItemName, Map<String, dynamic> updatedItem) {
    int roomIndex = _rooms.indexWhere((r) => r['name'].toLowerCase() == oldRoomName.toLowerCase());
    if (roomIndex != -1) {
      var items = _rooms[roomIndex]['items'] as List;
      int itemIndex = items.indexWhere((item) => item['name'] == oldItemName);
      if (itemIndex != -1 && oldRoomName.toLowerCase() == updatedItem['room'].toLowerCase()) {
        // Se la stanza non è cambiata, aggiorna direttamente l'item in-place per mantenere la reference
        items[itemIndex]['name'] = updatedItem['name'];
        items[itemIndex]['category'] = updatedItem['category'];
        items[itemIndex]['description'] = updatedItem['description'];
        items[itemIndex]['image'] = updatedItem['image'];
        // La room resta invariata
      } else {
        // Se la stanza è cambiata o l'item non viene trovato (ad esempio, perché il nome è stato cambiato)
        // elimina comunque l'eventuale item vecchio e aggiunge il nuovo
        deleteItem(oldRoomName, oldItemName);
        addItem(
          updatedItem['name'],
          updatedItem['description'],
          updatedItem['category'],
          updatedItem['image'],
          updatedItem['room'],
        );
      }
    }
    notifyListeners();
  }

  // Metodo per aggiornare una stanza esistente
  void updateRoom(String oldRoomName, Map<String, dynamic> updatedRoom) {
  int index = _rooms.indexWhere((room) => room['name'].toLowerCase() == oldRoomName.toLowerCase());
  if (index != -1) {
  _rooms[index]['name'] = updatedRoom['name'];
  _rooms[index]['image'] = updatedRoom['image'];
  for (var item in _rooms[index]['items']) {
    item['room'] = updatedRoom['name'];
  }
  notifyListeners();
  }
  }

  // Metodo per eliminare una stanza esistente
  void deleteRoom(String roomName) {
  _rooms.removeWhere((room) => room['name'].toLowerCase() == roomName.toLowerCase());
  notifyListeners();
  }
  }
