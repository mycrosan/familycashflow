import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Smart Family')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.list_alt),
              title: Text('Listar Lançamentos'),
              onTap: () => Navigator.pushNamed(context, '/lancamentos'),
            ),
            ListTile(
              leading: Icon(Icons.category),
              title: Text('Categorias'),
              onTap: () => Navigator.pushNamed(context, '/categorias'),
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Responsáveis'),
              onTap: () => Navigator.pushNamed(context, '/responsaveis'),
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          'Bem-vindo ao Fluxo Família!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
