import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Folder_Screen.dart';

class HomeScreen extends StatelessWidget{
  const HomeScreen({super.key});


  @override
  Widget build(BuildContext context) {
       return  Scaffold(
         appBar: AppBar(
           title:const   Text("File Manager System") ,
           backgroundColor: Colors.blueAccent,
         ),
         body:  Column(
           children: [
             ListTile(
               title: const Text('Internal Storage'),
               trailing: const  Icon(Icons.folder),
               onTap: (){
                 Navigator.of(context).push(MaterialPageRoute(builder: (context)=> FolderScreen()),);
               },
             ),
           const   SizedBox(
               height: 20,

             ),
            ListTile(
               title:const  Text('External Storage'),
               trailing:const  Icon(Icons.folder),
            onTap: (){
              AlertDialog alert =  AlertDialog(
                title:  const Text("Warning!!!"),
                content: const Text("No External Device is connected"),
                actions: [
               ElevatedButton(onPressed:(){
                 Navigator.of(context).pop();
               } , child:const  Text('OK'))

                ],
              );

              // show the dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return alert;
                },
              );
            },
             ),
           ],
         ) ,


       );


  }



}