import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'employee_hours.dart';

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
    return MaterialApp(
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc['rol'] != null) {
        setState(() {
          _role = userDoc['rol'];
          _isLoading = false;
        });
      } else {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (FirebaseAuth.instance.currentUser == null) {
      return LoginPage();
    } else if (_role == 'admin') {
      return const AdminPage();
    } else {
      return const UserHoursPage();
    }
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      print("Usuario autenticado, UID: ${userCredential.user!.uid}");

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        print("Documento del usuario encontrado en Firestore");

        String rol = userDoc['rol'];
        print("Rol del usuario: $rol");

        if (rol == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const AdminPage(),
            ),
          );
        } else if (rol == 'user') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const UserHoursPage(),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Rol no reconocido.';
          });
          print("Error: Rol no reconocido.");
        }
      } else {
        setState(() {
          _errorMessage = 'El documento del usuario no existe en Firestore.';
        });
        print("Error: El documento del usuario no existe en Firestore.");
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'Usuario no encontrado.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Contraseña incorrecta.';
        } else {
          _errorMessage = 'Error: ${e.message}';
        }
      });
      print("Error de autenticación: ${e.message}");
    } catch (e) {
      setState(() {
        _errorMessage = 'Error obteniendo datos del usuario: $e';
      });
      print("Error obteniendo datos del usuario: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login con Firebase'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration:
                  const InputDecoration(labelText: 'Correo electrónico'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Iniciar sesión'),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        title: Text('Hola $nombre'),
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
              title: const Text('Semanas trabajadas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WorkedWeeksPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Días laborados'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WorkedDaysPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Cuadrillas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WorkedCuadrillaPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Cerrar sesión'),
              onTap: () {
                _logout(context);
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Bienvenido a la administración'),
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
                  trailing: Icon(
                    job['completed']
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    color: job['completed'] ? Colors.green : Colors.red,
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
        title: const Text('Semanas trabajadas'),
      ),
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

  void _showMenuOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Week ${localWeeks[index]['week']}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Consultar Horarios'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EmployeeHoursPage(week: localWeeks[index]['week']),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Ver trabajos'),
                onTap: () {
                  Navigator.pop(context);
                  _showJobsDialog(context, index);
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              )
            ],
          ),
        );
      },
    );
  }
}

class WorkedDaysPage extends StatefulWidget {
  const WorkedDaysPage({super.key});

  @override
  _WorkedDaysPageState createState() => _WorkedDaysPageState();
}

class _WorkedDaysPageState extends State<WorkedDaysPage> {
  List<Map<String, dynamic>> localDays = [];
  final CollectionReference daysCollection =
      FirebaseFirestore.instance.collection('worked_days');

  @override
  void initState() {
    super.initState();
    _fetchDaysFromFirestore();
  }

  void _fetchDaysFromFirestore() async {
    try {
      QuerySnapshot snapshot = await daysCollection.get();
      setState(() {
        localDays = snapshot.docs.map((doc) {
          return {
            'day': doc.id,
            'description': doc['description'],
            'completed': doc['completed'],
          };
        }).toList();
      });
    } catch (error) {
      print("Error al cargar los dias: $error");
    }
  }

  void _editDescription(int index) {
    TextEditingController controller = TextEditingController();
    controller.text = localDays[index]['description'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar dia ${localDays[index]['day']}'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
                hintText: 'Ingrese una nueva descripción'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await daysCollection.doc(localDays[index]['day']).update({
                    'description': controller.text,
                  });
                  setState(() {
                    localDays[index]['description'] = controller.text;
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

  void _closeDay(int index) async {
    try {
      await daysCollection.doc(localDays[index]['day']).update({
        'completed': true,
      });

      setState(() {
        localDays[index]['completed'] = true;
      });

      print("Dia cerrado");
    } catch (error) {
      print("Error al cerrar el dia: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Días trabajados'),
      ),
      body: ListView.builder(
        itemCount: localDays.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text(
                localDays[index]['day'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(localDays[index]['description']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {},
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String item) {
                      if (item == 'close') {
                        _closeDay(index);
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
              onTap: () {},
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
  final CollectionReference cuadrillasCollection =
      FirebaseFirestore.instance.collection('worked_cuadrillas');
  TextEditingController descriptionController = TextEditingController();
  TextEditingController responsableController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCuadrillasFromFirestore();
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
        'responsable': responsableController.text,
      });

      descriptionController.clear();
      responsableController.clear();
      _fetchCuadrillasFromFirestore();
    } catch (error) {
      print("Error al agregar cuadrilla: $error");
    }
  }

  void _deleteCuadrilla(String cuadrillaId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmación"),
          content: const Text(
              "¿Estás seguro de que deseas eliminar esta cuadrilla?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await cuadrillasCollection.doc(cuadrillaId).delete();
                  Navigator.of(context).pop();
                  _fetchCuadrillasFromFirestore();
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

  void _editCuadrilla(String id, String description, String responsable) async {
    descriptionController.text = description;
    responsableController.text = responsable;

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
              TextField(
                controller: responsableController,
                decoration: const InputDecoration(hintText: 'Responsable'),
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
                    'responsable': responsableController.text,
                  });
                  Navigator.of(context).pop();
                  _fetchCuadrillasFromFirestore();
                } catch (error) {
                  print("Error al editar cuadrilla: $error");
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void _openAddCuadrillaDialog() {
    descriptionController.clear();
    responsableController.clear();
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
              TextField(
                controller: responsableController,
                decoration: const InputDecoration(hintText: 'Responsable'),
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
      ),
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
          onPressed: _openAddCuadrillaDialog, child: const Icon(Icons.add)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class EmployeeHoursPage extends StatefulWidget {
  final String week;

  const EmployeeHoursPage({super.key, required this.week});

  @override
  _EmployeeHoursPageState createState() => _EmployeeHoursPageState();
}

class _EmployeeHoursPageState extends State<EmployeeHoursPage> {
  final CollectionReference employeeHoursCollection =
      FirebaseFirestore.instance.collection('employee_hours');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Horas de la semana ${widget.week}'),
        leading: BackButton(onPressed: () {
          Navigator.pop(context);
        }),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: employeeHoursCollection
            .where('week', isEqualTo: widget.week)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text('Error al cargar los datos.');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          final List<DocumentSnapshot> employees = snapshot.data!.docs;

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> employee =
                  employees[index].data()! as Map<String, dynamic>;
              return Dismissible(
                key: Key(employee['name']),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  employeeHoursCollection.doc(employees[index].id).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${employee['name']} removed'),
                    ),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  title: Text(employee['name']),
                  subtitle: Text('${employee['hours']} hours'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuario'),
      ),
      body: const Center(
        child: Text('Estás en usuario'),
      ),
    );
  }
}
