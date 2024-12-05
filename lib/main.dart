import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase Initialized");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "ArchiTask",
      debugShowCheckedModeBanner: false,
      home: AuthCheck(),
    );
  }
}

class menuCustom extends StatelessWidget {
  const menuCustom({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menu ArchiTask',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AdminPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Semanas trabajadas'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const WorkedWeeksPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Creacion de Usuarios'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const UserPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Cuadrillas'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const WorkedCuadrillaPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String? nombre = "Administrador";

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
        if (userDoc.exists && userDoc['name'] != null) {
          setState(() {
            nombre = userDoc['name'];
          });
        } else {
          setState(() {
            nombre = "Administrador";
          });
        }
      } catch (e) {
        print("Error obteniendo el nombre del usuario: $e");
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
    return WillPopScope(
      onWillPop: () async {
        // Impide regresar a la pantalla anterior
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Hola $nombre'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 120,
              ),
              const Text(
                'ARCHITASK',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 80),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const WorkedWeeksPage()),
                    (Route<dynamic> route) => false,
                  );
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Semanas trabajadas'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const UserPage()),
                    (Route<dynamic> route) => false,
                  );
                },
                icon: const Icon(Icons.person),
                label: const Text('Creacion de Usuarios'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const WorkedCuadrillaPage()),
                    (Route<dynamic> route) => false,
                  );
                },
                icon: const Icon(Icons.group),
                label: const Text('Cuadrillas'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await _logout(context);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkedWeeksPage extends StatefulWidget {
  const WorkedWeeksPage({super.key});

  @override
  _WorkedWeeksPageState createState() => _WorkedWeeksPageState();
}

class _WorkedWeeksPageState extends State<WorkedWeeksPage> {
  List<Map<String, dynamic>> localWeeks = [];
  final CollectionReference weeksCollection =
      FirebaseFirestore.instance.collection('worked_weeks');

  @override
  void initState() {
    super.initState();
    _fetchWeeksFromFirestore();
  }

  void _fetchWeeksFromFirestore() async {
    try {
      QuerySnapshot snapshot = await weeksCollection.get();
      setState(() {
        localWeeks = snapshot.docs.map((doc) {
          return {
            'week': doc.id,
            'description': doc['description'],
            'completed': doc['completed'],
            'jobs': doc['jobs'] ?? [],
          };
        }).toList();

        // Si la colección está vacía, crear la primera semana
        if (localWeeks.isEmpty) {
          _createFirstWeek();
        } else {
          // Ordenar las semanas en base al número en el ID de la semana
          localWeeks.sort((a, b) {
            int weekA =
                int.tryParse(a['week'].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            int weekB =
                int.tryParse(b['week'].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return weekA.compareTo(weekB);
          });
        }
      });
    } catch (error) {
      print("Error al cargar las semanas: $error");
    }
  }

  Future<void> _createFirstWeek() async {
    try {
      await weeksCollection.doc('Semana #1').set({
        'week': 'Semana #1',
        'description': 'Primera semana de trabajo',
        'completed': false,
        'jobs': [],
      });
      setState(() {
        localWeeks.add({
          'week': 'Semana #1',
          'description': 'Primera semana de trabajo',
          'completed': false,
          'jobs': [],
        });
      });

      print("Primera semana creada exitosamente");
    } catch (error) {
      print("Error al crear la primera semana: $error");
    }
  }

  void _editDescription(int index) {
    TextEditingController controller = TextEditingController();
    controller.text = localWeeks[index]['description'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar semana ${localWeeks[index]['week']}'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
                hintText: 'Ingrese una nueva descripción'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await weeksCollection.doc(localWeeks[index]['week']).update({
                    'description': controller.text,
                  });
                  setState(() {
                    localWeeks[index]['description'] = controller.text;
                  });
                  Navigator.of(context).pop();
                } catch (error) {
                  print("Error al actualizar la descripción: $error");
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _addJobToWeek(int index) {
    TextEditingController jobNameController = TextEditingController();
    bool isJobCompleted = false;
    String? selectedCuadrillaId;
    Map<String, dynamic>? selectedCuadrillaDetails;
    List<Map<String, dynamic>> cuadrillas = [];

    final CollectionReference cuadrillasCollection =
        FirebaseFirestore.instance.collection('worked_cuadrillas');

    Future<List<Map<String, dynamic>>> _loadCuadrillas() async {
      try {
        QuerySnapshot snapshot = await cuadrillasCollection.get();
        return snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'description': doc['description'],
            'responsable': doc['responsable'],
          };
        }).toList();
      } catch (e) {
        print("Error al cargar cuadrillas: $e");
        return [];
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadCuadrillas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text('No se pudieron cargar las cuadrillas'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            }

            cuadrillas = snapshot.data!;

            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return AlertDialog(
                  title: Text(
                      'Agregar trabajo a la semana ${localWeeks[index]['week']}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: jobNameController,
                        decoration: const InputDecoration(
                          hintText: 'Nombre del trabajo',
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButton<String>(
                        value: selectedCuadrillaId,
                        hint: const Text('Seleccionar Cuadrilla'),
                        isExpanded: true,
                        items: cuadrillas.map((cuadrilla) {
                          return DropdownMenuItem<String>(
                            value: cuadrilla['id'],
                            child: Text(
                                "${cuadrilla['description']} - Responsable: ${cuadrilla['responsable']}"),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedCuadrillaId = value;
                            selectedCuadrillaDetails = cuadrillas.firstWhere(
                                (cuadrilla) => cuadrilla['id'] == value);
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (jobNameController.text.isNotEmpty &&
                            selectedCuadrillaId != null) {
                          await weeksCollection
                              .doc(localWeeks[index]['week'])
                              .update({
                            'jobs': FieldValue.arrayUnion([
                              {
                                'name': jobNameController.text.trim(),
                                'completed': isJobCompleted,
                                'cuadrillaId': selectedCuadrillaId,
                                'cuadrillaDescription':
                                    selectedCuadrillaDetails!['description'],
                                'cuadrillaResponsable':
                                    selectedCuadrillaDetails!['responsable'],
                              }
                            ])
                          });

                          setState(() {
                            localWeeks[index]['jobs'].add({
                              'name': jobNameController.text.trim(),
                              'completed': isJobCompleted,
                              'cuadrillaId': selectedCuadrillaId,
                              'cuadrillaDescription':
                                  selectedCuadrillaDetails!['description'],
                              'cuadrillaResponsable':
                                  selectedCuadrillaDetails!['responsable'],
                            });
                          });

                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Agregar'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _editJobOfLastWeek(int weekIndex, int jobIndex) {
    var job = localWeeks[weekIndex]['jobs'][jobIndex];
    TextEditingController jobNameController =
        TextEditingController(text: job['name']);
    String? selectedCuadrillaId = job['cuadrillaId'];
    Map<String, dynamic>? selectedCuadrillaDetails;

    final CollectionReference cuadrillasCollection =
        FirebaseFirestore.instance.collection('worked_cuadrillas');

    Future<List<Map<String, dynamic>>> _loadCuadrillas() async {
      try {
        QuerySnapshot snapshot = await cuadrillasCollection.get();
        return snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'description': doc['description'],
            'responsable': doc['responsable'],
          };
        }).toList();
      } catch (e) {
        print("Error al cargar cuadrillas: $e");
        return [];
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadCuadrillas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text('No se pudieron cargar las cuadrillas'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            }

            var cuadrillas = snapshot.data!;

            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return AlertDialog(
                  title: const Text('Editar trabajo'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: jobNameController,
                        decoration: const InputDecoration(
                            hintText: 'Nombre del trabajo'),
                      ),
                      const SizedBox(height: 20),
                      DropdownButton<String>(
                        value: selectedCuadrillaId,
                        hint: const Text('Seleccionar Cuadrilla'),
                        isExpanded: true,
                        items: cuadrillas.map((cuadrilla) {
                          return DropdownMenuItem<String>(
                            value: cuadrilla['id'],
                            child: Text(
                                "${cuadrilla['description']} - Responsable: ${cuadrilla['responsable']}"),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedCuadrillaId = value;
                            selectedCuadrillaDetails = cuadrillas.firstWhere(
                                (cuadrilla) => cuadrilla['id'] == value);
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (jobNameController.text.isNotEmpty &&
                            selectedCuadrillaId != null) {
                          var updatedJob = {
                            'name': jobNameController.text.trim(),
                            'completed': job['completed'],
                            'cuadrillaId': selectedCuadrillaId,
                            'cuadrillaDescription':
                                selectedCuadrillaDetails?['description'] ??
                                    job['cuadrillaDescription'],
                            'cuadrillaResponsable':
                                selectedCuadrillaDetails?['responsable'] ??
                                    job['cuadrillaResponsable'],
                          };

                          await weeksCollection
                              .doc(localWeeks[weekIndex]['week'])
                              .update({
                            'jobs': FieldValue.arrayRemove([job]),
                          });
                          await weeksCollection
                              .doc(localWeeks[weekIndex]['week'])
                              .update({
                            'jobs': FieldValue.arrayUnion([updatedJob]),
                          });

                          setState(() {
                            localWeeks[weekIndex]['jobs'][jobIndex] =
                                updatedJob;
                          });

                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showJobsDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Trabajos para la semana ${localWeeks[index]['week']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: localWeeks[index]['jobs'].length,
              itemBuilder: (BuildContext context, int jobIndex) {
                var job = localWeeks[index]['jobs'][jobIndex];
                return ListTile(
                  title: Text(job['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (job['cuadrillaDescription'] != null &&
                          job['cuadrillaResponsable'] != null)
                        Text(
                          'Cuadrilla: ${job['cuadrillaDescription']} - Responsable: ${job['cuadrillaResponsable']}',
                        )
                      else
                        const Text('Cuadrilla: No asignada'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        job['completed']
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        color: job['completed'] ? Colors.green : Colors.red,
                      ),
                      if (index == localWeeks.length - 1)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editJobOfLastWeek(index, jobIndex),
                        ),
                    ],
                  ),
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

  void _closeWeek(int index) async {
    if (index >= localWeeks.length) {
      print("Índice fuera de rango");
      return;
    }

    if (localWeeks[index]['completed']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("La ${localWeeks[index]['week']} ya está cerrada."),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    List<Map<String, dynamic>> jobs =
        List<Map<String, dynamic>>.from(localWeeks[index]['jobs']);
    List<Map<String, dynamic>> incompleteJobs =
        jobs.where((job) => !job['completed']).toList();

    bool hasPendingJobs = incompleteJobs.isNotEmpty;

    if (hasPendingJobs) {
      await _showJobSelectionDialog(context, incompleteJobs, index);
    } else {
      _createNextWeekWithJobs([], index);
    }
  }

  Future<void> _showJobSelectionDialog(BuildContext context,
      List<Map<String, dynamic>> jobs, int currentIndex) async {
    Map<String, bool> selectedJobs = {for (var job in jobs) job['name']: false};

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Seleccionar trabajos completados'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView(
                  children: jobs.map((job) {
                    return CheckboxListTile(
                      title: Text(job['name']),
                      subtitle: Text(
                          'Cuadrilla: ${job['cuadrillaDescription'] ?? 'No asignada'}'),
                      value: selectedJobs[job['name']],
                      onChanged: (bool? value) {
                        setState(() {
                          selectedJobs[job['name']] = value!;
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                List<Map<String, dynamic>> completedJobs =
                    jobs.where((job) => selectedJobs[job['name']]!).toList();

                List<Map<String, dynamic>> jobsToCarryOver =
                    jobs.where((job) => !selectedJobs[job['name']]!).map((job) {
                  return {
                    'name': job['name'],
                    'completed': false,
                    'cuadrillaId': job['cuadrillaId'],
                    'cuadrillaDescription': job['cuadrillaDescription'],
                    'cuadrillaResponsable': job['cuadrillaResponsable']
                  };
                }).toList();

                for (var job in completedJobs) {
                  job['completed'] = true;
                }

                _createNextWeekWithJobs(jobsToCarryOver, currentIndex);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _createNextWeekWithJobs(
      List<Map<String, dynamic>> jobs, int currentIndex) async {
    String currentWeekId = localWeeks[currentIndex]['week'];

    await FirebaseFirestore.instance
        .collection('worked_weeks')
        .doc(currentWeekId)
        .update({
      'completed': true,
      'jobs': localWeeks[currentIndex]['jobs'].map((job) {
        return {
          'name': job['name'],
          'completed': job['completed'],
          'cuadrillaId': job['cuadrillaId'],
          'cuadrillaDescription': job['cuadrillaDescription'],
          'cuadrillaResponsable': job['cuadrillaResponsable']
        };
      }).toList(),
    });

    String newWeekId = 'Semana #${localWeeks.length + 1}';
    await FirebaseFirestore.instance
        .collection('worked_weeks')
        .doc(newWeekId)
        .set({
      'week': newWeekId,
      'description': 'Nueva semana laboral',
      'completed': false,
      'jobs': jobs,
    });

    setState(() {
      localWeeks[currentIndex]['completed'] = true;

      localWeeks.add({
        'week': newWeekId,
        'description': 'Nueva semana laboral',
        'completed': false,
        'jobs': jobs,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const menuCustom(),
      body: ListView.builder(
        itemCount: localWeeks.length,
        itemBuilder: (context, index) {
          bool isCompleted = localWeeks[index]['completed'] ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text(
                localWeeks[index]['week'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isCompleted ? Colors.grey : Colors.black,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(localWeeks[index]['description']),
                  if (isCompleted)
                    const Text(
                      "Semana Cerrada",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: isCompleted ? null : () => _addJobToWeek(index),
                    color: isCompleted ? Colors.grey : null,
                  ),
                  PopupMenuButton<String>(
                    enabled: !isCompleted,
                    onSelected: (String? item) {
                      if (item == 'close') {
                        _closeWeek(index);
                      } else if (item == 'edit') {
                        _editDescription(index);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'close',
                          child: Text('Cerrar'),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              onTap: () => _showJobsDialog(context, index),
            ),
          );
        },
      ),
    );
  }
}

class WorkedCuadrillaPage extends StatefulWidget {
  const WorkedCuadrillaPage({super.key});

  @override
  _WorkedCuadrillaPageState createState() => _WorkedCuadrillaPageState();
}

class _WorkedCuadrillaPageState extends State<WorkedCuadrillaPage> {
  List<Map<String, dynamic>> localCuadrillas = [];
  List<String> responsables = [];
  String? selectedResponsable;
  final CollectionReference cuadrillasCollection =
      FirebaseFirestore.instance.collection('worked_cuadrillas');
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCuadrillasFromFirestore();
    _fetchResponsablesFromFirestore();
  }

  void _fetchCuadrillasFromFirestore() async {
    try {
      QuerySnapshot snapshot = await cuadrillasCollection.get();
      setState(() {
        localCuadrillas = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'numeroCuadrilla': doc['numeroCuadrilla'],
            'description': doc['description'],
            'responsable': doc['responsable'],
          };
        }).toList();

        localCuadrillas.sort(
            (a, b) => a['numeroCuadrilla'].compareTo(b['numeroCuadrilla']));
      });
    } catch (error) {
      print("Error al cargar cuadrillas: $error");
    }
  }

  void _fetchResponsablesFromFirestore() async {
    try {
      QuerySnapshot snapshot =
          await usersCollection.where('rol', isEqualTo: 'user').get();
      setState(() {
        responsables =
            snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (error) {
      print("Error al cargar responsables: $error");
    }
  }

  void _addCuadrilla() async {
    try {
      int maxNumeroCuadrilla = 0;
      if (localCuadrillas.isNotEmpty) {
        maxNumeroCuadrilla = localCuadrillas
            .map((e) => e['numeroCuadrilla'])
            .reduce((a, b) => a > b ? a : b);
      }

      await cuadrillasCollection.add({
        'numeroCuadrilla': maxNumeroCuadrilla + 1,
        'description': descriptionController.text,
        'responsable': selectedResponsable,
      });

      descriptionController.clear();
      selectedResponsable = null;
      _fetchCuadrillasFromFirestore();
    } catch (error) {
      print("Error al agregar cuadrilla: $error");
    }
  }

  void _editCuadrilla(
      String id, String currentDescription, String currentResponsable) {
    descriptionController.text = currentDescription;
    selectedResponsable = currentResponsable;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Editar Cuadrilla"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(hintText: 'Descripción'),
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: selectedResponsable,
                items: responsables.map((String responsable) {
                  return DropdownMenuItem<String>(
                    value: responsable,
                    child: Text(responsable),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedResponsable = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Seleccionar Responsable',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await cuadrillasCollection.doc(id).update({
                    'description': descriptionController.text,
                    'responsable': selectedResponsable,
                  });
                  _fetchCuadrillasFromFirestore();
                  Navigator.of(context).pop();
                } catch (error) {
                  print("Error al actualizar cuadrilla: $error");
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void _deleteCuadrilla(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Eliminar Cuadrilla"),
          content: const Text(
              "¿Estás seguro de que deseas eliminar esta cuadrilla?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await cuadrillasCollection.doc(id).delete();
                  _fetchCuadrillasFromFirestore();
                  Navigator.of(context).pop();
                } catch (error) {
                  print("Error al eliminar cuadrilla: $error");
                }
              },
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  void _openAddCuadrillaDialog() {
    descriptionController.clear();
    selectedResponsable = null;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Agregar Cuadrilla"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(hintText: 'Descripción'),
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: selectedResponsable,
                items: responsables.map((String responsable) {
                  return DropdownMenuItem<String>(
                    value: responsable,
                    child: Text(responsable),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedResponsable = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Seleccionar Responsable',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                _addCuadrilla();
                Navigator.of(context).pop();
              },
              child: const Text("Guardar"),
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
        title: const Text('Cuadrillas de Trabajado'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const menuCustom(),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: ListView.builder(
          itemCount: localCuadrillas.length,
          itemBuilder: (context, index) {
            final cuadrilla = localCuadrillas[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(
                  'Cuadrilla #${cuadrilla['numeroCuadrilla']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  'Descripción: ${cuadrilla['description']}\nResponsable: ${cuadrilla['responsable']}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _editCuadrilla(
                          cuadrilla['id'],
                          cuadrilla['description'],
                          cuadrilla['responsable'],
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _deleteCuadrilla(cuadrilla['id']);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddCuadrillaDialog,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
// Controladores para los campos del formulario de creación
  final TextEditingController _createNameController = TextEditingController();
  final TextEditingController _createEmailController = TextEditingController();
  final TextEditingController _createPasswordController =
      TextEditingController();
  String _createSelectedRole = 'Seleccione';

  // Controladores para los campos del diálogo de edición
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editEmailController = TextEditingController();
  String _editSelectedRole = 'Seleccione';

  // Listado local de usuarios
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsersFromFirestore();
  }

  // Método para cargar usuarios desde Firestore
  void _fetchUsersFromFirestore() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        users = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
            'email': doc['email'],
            'rol': doc['rol'],
          };
        }).toList();
      });
    } catch (error) {
      print("Error al cargar usuarios: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar usuarios: $error")),
      );
    }
  }

  void _createUser() async {
    String name = _createNameController.text;
    String email = _createEmailController.text;
    String password = _createPasswordController.text;
    String role = _createSelectedRole;

    if (name.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty &&
        role != 'Seleccione') {
      try {
        // Verificar si el nombre de usuario ya existe en Firestore
        QuerySnapshot existingUsers = await FirebaseFirestore.instance
            .collection('users')
            .where('name', isEqualTo: name)
            .get();

        if (existingUsers.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('El nombre de usuario ya está en uso')),
          );
          return; // Salir del método si el nombre ya existe
        }
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        String userId = userCredential.user!.uid;

        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': name,
          'email': email,
          'rol': role,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario $name creado como $role con éxito')),
        );

        // Limpiar los campos del formulario
        _createNameController.clear();
        _createEmailController.clear();
        _createPasswordController.clear();
        setState(() {
          _createSelectedRole = 'Seleccione';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el usuario: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos')),
      );
    }
  }

  // Función para editar un usuario
  void _editUser(String userId, String name, String email, String role) {
    // Asignar valores a los controladores y la variable local de rol
    _editNameController.text = name;
    _editEmailController.text = email;
    _editSelectedRole = role;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Editar Usuario'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _editNameController,
                    decoration: InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: _editEmailController,
                    decoration:
                        InputDecoration(labelText: 'Correo electrónico'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  DropdownButton<String>(
                    value: _editSelectedRole,
                    onChanged: (String? newValue) {
                      setState(() {
                        _editSelectedRole = newValue!;
                      });
                    },
                    items: <String>['Seleccione', 'user', 'admin']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .update({
                        'name': _editNameController.text,
                        'email': _editEmailController.text,
                        'rol': _editSelectedRole,
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Usuario actualizado con éxito')),
                      );
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Error al actualizar el usuario: $e')),
                      );
                    }
                  },
                  child: Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Método para eliminar un usuario
  void _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario eliminado con éxito')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el usuario: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const menuCustom(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campos de creación de usuario
            TextField(
              controller: _createNameController,
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _createEmailController,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _createPasswordController,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _createSelectedRole,
              decoration: InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _createSelectedRole = newValue!;
                });
              },
              items: <String>['Seleccione', 'user', 'admin']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _createUser,
              child: Center(
                // Asegura que el texto esté centrado
                child: Text(
                  'Crear Usuario',
                  textAlign: TextAlign
                      .center, // Opcional, para asegurarte de que el texto esté centrado
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16), // Ajusta el padding
              ),
            ),

            SizedBox(height: 20),
            // Lista de usuarios
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              user['name'][0],
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            user['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Email: ${user['email']} \nRol: ${user['rol']}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () => _editUser(
                                  user.id,
                                  user['name'],
                                  user['email'],
                                  user['rol'],
                                ),
                              ),
                              IconButton(
                                icon:
                                    Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteUser(user.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _createNameController.dispose();
    _createEmailController.dispose();
    _createPasswordController.dispose();
    _editNameController.dispose();
    _editEmailController.dispose();
    super.dispose();
  }
}
