import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home.dart';
import 'providers/room_data_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) { //build widget tree
    return ChangeNotifierProvider( //provider manages RoomDataProvider
      create: (context) => RoomDataProvider(),
      child: const MaterialApp(
        title: 'Itemize', //application title
        debugShowCheckedModeBanner: false, //hide debug banner
        home: HomePage(), //set HomePage as initial route
      ),
    );
  }
}
