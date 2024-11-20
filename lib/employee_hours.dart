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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
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
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EmployeeHoursScreen()),
                );
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Semanas trabajadas'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
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

class EmployeeHoursScreen extends StatefulWidget {
  const EmployeeHoursScreen({super.key});

  @override
  _EmployeeHoursScreenState createState() => _EmployeeHoursScreenState();
}

class _EmployeeHoursScreenState extends State<EmployeeHoursScreen> {
  List<Map<String, dynamic>> filteredWeeks = [];
  final CollectionReference weeksCollection =
      FirebaseFirestore.instance.collection('worked_weeks');
  String? userName;

  @override
  void initState() {
    super.initState();
    _getUserName().then((_) {
      if (userName != null) {
        _fetchFilteredWeeks();
      }
    });
  }

  Future<void> _getUserName() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String uid = currentUser.uid;
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            userName = userDoc['name']?.toString().trim();
          });
        }
      }
    } catch (e) {
      print("Error obteniendo el nombre del usuario: $e");
    }
  }

  Future<void> _fetchFilteredWeeks() async {
    if (userName == null) return;

    try {
      QuerySnapshot snapshot = await weeksCollection.get();
      List<Map<String, dynamic>> tempWeeks = [];

      for (var doc in snapshot.docs) {
        List<dynamic> jobs = doc['jobs'] ?? [];
        List<dynamic> filteredJobs = jobs
            .where((job) =>
                job['cuadrillaResponsable']?.toString().trim().toLowerCase() ==
                userName!.toLowerCase())
            .toList();

        if (filteredJobs.isNotEmpty) {
          tempWeeks.add({
            'week': doc.id,
            'description': doc['description'],
            'completed': doc['completed'],
            'jobs': filteredJobs,
          });
        }
      }

      setState(() {
        filteredWeeks = tempWeeks;
      });
    } catch (error) {
      print("Error al cargar las semanas: $error");
    }
  }

  void _showJobsDialog(BuildContext context, int index) {
    List<int> selectedJobs = [];
    bool isClosed = filteredWeeks[index]['completed'] ?? false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text('Trabajos para la semana ${filteredWeeks[index]['week']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredWeeks[index]['jobs'].length,
              itemBuilder: (BuildContext context, int jobIndex) {
                var job = filteredWeeks[index]['jobs'][jobIndex];

                return StatefulBuilder(
                  builder: (context, setState) {
                    return MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          job['hovered'] = true;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          job['hovered'] = false;
                        });
                      },
                      child: Container(
                        color: job['hovered'] == true
                            ? const Color.fromARGB(255, 212, 211, 211)
                            : null,
                        child: ListTile(
                          title: Text(job['name']),
                          subtitle: job['cuadrillaDescription'] != null &&
                                  job['cuadrillaResponsable'] != null
                              ? Text(
                                  'Cuadrilla: ${job['cuadrillaDescription']} - Responsable: ${job['cuadrillaResponsable']}',
                                )
                              : const Text('Cuadrilla: No asignada'),
                          trailing: isClosed
                              ? const Icon(Icons.check_circle_outline,
                                  color: Colors.green)
                              : Checkbox(
                                  value: job['EstadoJobsUser'] ?? false,
                                  onChanged: (bool? value) async {
                                    if (!isClosed) {
                                      setState(() {
                                        job['EstadoJobsUser'] = value ?? false;
                                      });
                                      try {
                                        // Actualiza el trabajo en Firestore
                                        List<dynamic> updatedJobs = List.from(
                                            filteredWeeks[index]['jobs']);
                                        updatedJobs[jobIndex]
                                            ['EstadoJobsUser'] = value;

                                        await weeksCollection
                                            .doc(filteredWeeks[index]['week'])
                                            .update({
                                          'jobs': updatedJobs,
                                        });

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Estado del trabajo actualizado.')),
                                        );
                                      } catch (e) {
                                        print(
                                            "Error al actualizar el estado del trabajo: $e");
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'No se pudo actualizar el estado.')),
                                        );
                                      }
                                    }
                                  },
                                ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Semanas Trabajadas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFilteredWeeks, // Cargar los datos más recientes
          ),
        ],
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
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Página principal'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UserHoursPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: filteredWeeks.isEmpty
          ? const Center(child: Text('No hay trabajos asignados para ti.'))
          : ListView.builder(
              itemCount: filteredWeeks.length,
              itemBuilder: (context, index) {
                bool isClosed = filteredWeeks[index]['completed'] ?? false;
                return Card(
                  child: ListTile(
                    title: Text('Semana: ${filteredWeeks[index]['week']}'),
                    subtitle: Text(
                        'Descripción: ${filteredWeeks[index]['description']}'),
                    trailing: isClosed
                        ? const Icon(Icons.check_circle_outline,
                            color: Colors.green)
                        : const Icon(Icons.radio_button_unchecked),
                    onTap: () {
                      _showJobsDialog(context, index);
                    },
                    tileColor: isClosed ? Colors.grey.shade300 : null,
                  ),
                );
              },
            ),
    );
  }
}
