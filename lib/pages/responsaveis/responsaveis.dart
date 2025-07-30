import 'package:flutter/material.dart';

class Responsaveis extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Responsáveis')),
      body: Center(child: Text('Lista de responsáveis aqui')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/responsaveis/novo'),
        child: Icon(Icons.add),
      ),
    );
  }
}
