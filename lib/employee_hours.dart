import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class UserHoursPage extends StatefulWidget {
  const UserHoursPage({super.key});

  @override
  _UserHoursPageState createState() => _UserHoursPageState();
}

class _UserHoursPageState extends State<UserHoursPage> {
  Map<String, int> workedHours = {
    "Monday": 0,
    "Tuesday": 0,
    "Wednesday": 0,
    "Thursday": 0,
    "Friday": 0,
    "Saturday": 0
  };
  String? nombre = "Usuario";

  @override
  void initState() {
    super.initState();
    _getUserName();
  }

  Future<void> _getUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            nombre = userDoc['name'] ?? "Usuario";
          });
        }
      } catch (e) {
        print("Error obteniendo el nombre del usuario: $e");
      }
    }
  }

  void increment(String day) {
    setState(() {
      workedHours[day] = workedHours[day]! + 1;
    });
  }

  void decrement(String day) {
    if (workedHours[day]! > 0) {
      setState(() {
        workedHours[day] = workedHours[day]! - 1;
      });
    }
  }

  void _submitHours() async {
    int totalHours = workedHours.values.reduce((a, b) => a + b);
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('employee_hours').add({
          'hours': totalHours,
          'name': nombre,
          'week': 35,
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Horas enviadas correctamente")));
      } catch (e) {
        print("Error al enviar las horas: $e");
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola $nombre'), // Saludo personalizado
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Menu'),
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () {
                _logout(context); // Cerrar sesión
              },
            ),
          ],
        ),
      ),
      body: ListView(
        children: workedHours.keys.map((day) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: ListTile(
                title: Text(day),
                subtitle: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => decrement(day),
                    ),
                    Text(workedHours[day].toString()),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => increment(day),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _submitHours,
          child: const Text('Submit Hours'),
        ),
      ),
    );
  }
}
