import 'package:flutter/material.dart';

class Categorias extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Categorias')),
      body: Center(child: Text('Lista de categorias aqui')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/categorias/nova'),
        child: Icon(Icons.add),
      ),
    );
  }
}
