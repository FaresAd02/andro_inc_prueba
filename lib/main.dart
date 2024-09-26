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
              title: const Text('Worked Weeks'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WorkedWeeksPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Work Days'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WorkedDaysPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Logout'),
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
      });
    } catch (error) {
      print("Error al cargar las semanas: $error");
    }
  }

  void _editDescription(int index) {
    TextEditingController controller = TextEditingController();
    controller.text = localWeeks[index]['description'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Week ${localWeeks[index]['week']}'),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(hintText: 'Enter new description'),
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
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _addJobToWeek(int index) {
    TextEditingController jobNameController = TextEditingController();
    bool _isJobCompleted = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Job to Week ${localWeeks[index]['week']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: jobNameController,
                decoration: const InputDecoration(hintText: 'Enter job name'),
              ),
              CheckboxListTile(
                title: Text("Completed"),
                value: _isJobCompleted,
                onChanged: (bool? value) {
                  setState(() {
                    _isJobCompleted = value ?? false;
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
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (jobNameController.text.isNotEmpty) {
                  // Add the new job to the jobs list for the current week
                  await weeksCollection.doc(localWeeks[index]['week']).update({
                    'jobs': FieldValue.arrayUnion([
                      {
                        'name': jobNameController.text.trim(),
                        'completed': _isJobCompleted
                      }
                    ])
                  });
                  setState(() {
                    localWeeks[index]['jobs'].add({
                      'name': jobNameController.text.trim(),
                      'completed': _isJobCompleted
                    });
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showJobsDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Jobs for Week ${localWeeks[index]['week']}'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: localWeeks[index]['jobs'].length,
              itemBuilder: (BuildContext context, int jobIndex) {
                return ListTile(
                  title: Text(localWeeks[index]['jobs'][jobIndex]['name']),
                  trailing: Icon(
                    localWeeks[index]['jobs'][jobIndex]['completed']
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    color: localWeeks[index]['jobs'][jobIndex]['completed']
                        ? Colors.green
                        : Colors.red,
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
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _closeWeek(int index) async {
    if (index >= localWeeks.length) {
      print("Index out of range");
      return;
    }

    if (localWeeks[index]['completed']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(" ${localWeeks[index]['week']} is already closed."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    List<Map<String, dynamic>> jobs =
        List<Map<String, dynamic>>.from(localWeeks[index]['jobs']);
    List<Map<String, dynamic>> incompleteJobs =
        jobs.where((job) => !job['completed']).toList();

    // Check for pending jobs before proceeding
    bool hasPendingJobs = incompleteJobs.isNotEmpty;

    if (hasPendingJobs) {
      // Show dialog to select which jobs to carry over to the next week
      await _showJobSelectionDialog(context, incompleteJobs, index);
    } else {
      // No pending jobs, just create the next week
      _createNextWeekWithJobs([], index);
    }
  }

  Future<void> _showJobSelectionDialog(BuildContext context,
      List<Map<String, dynamic>> jobs, int currentIndex) async {
    // Creating a new map to track selected jobs
    Map<String, bool> selectedJobs = {
      for (var job in jobs) job['name']: job['completed']
    };

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Select Jobs to Carry Over'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: double.maxFinite,
                child: ListView(
                  children: jobs.map((job) {
                    return CheckboxListTile(
                      title: Text(job['name']),
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
              child: Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                List<Map<String, dynamic>> jobsToCarryOver =
                    jobs.where((job) => !selectedJobs[job['name']]!).toList();
                _createNextWeekWithJobs(jobsToCarryOver, currentIndex);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _createNextWeekWithJobs(
      List<Map<String, dynamic>> jobs, int currentIndex) async {
    // Marca la semana actual como completada
    String currentWeekId = localWeeks[currentIndex]['week'];
    await FirebaseFirestore.instance
        .collection('worked_weeks')
        .doc(currentWeekId)
        .update({
      'completed': true,
      'jobs': localWeeks[currentIndex]['jobs'].map((job) {
        return {
          'name': job['name'],
          // Marcar como completado si no se transfiere a la siguiente semana
          'completed': !jobs.contains(job)
        };
      }).toList(),
    });

    // Prepara la nueva semana
    String newWeekId = 'Week #${localWeeks.length + 1}';
    await FirebaseFirestore.instance
        .collection('worked_weeks')
        .doc(newWeekId)
        .set({
      'week': newWeekId,
      'description': 'New work week',
      'completed': false,
      'jobs': jobs.map((job) {
        return {
          'name': job['name'],
          'completed':
              false // Inicializar como no completado para la nueva semana
        };
      }).toList(),
    });

    setState(() {
      localWeeks[currentIndex]['completed'] = true;
      localWeeks[currentIndex]['jobs'] =
          localWeeks[currentIndex]['jobs'].map((job) {
        return {'name': job['name'], 'completed': !jobs.contains(job)};
      }).toList();

      localWeeks.add({
        'week': newWeekId,
        'description': 'New work week',
        'completed': false,
        'jobs': jobs.map((job) {
          return {'name': job['name'], 'completed': false};
        }).toList(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worked Weeks'),
      ),
      body: ListView.builder(
        itemCount: localWeeks.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text(
                localWeeks[index]['week'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(localWeeks[index]['description']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => _addJobToWeek(index),
                  ),
                  PopupMenuButton<String>(
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
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'close',
                          child: Text('Close'),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              onTap: () => _showMenuOptions(context, index),
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
                title: const Text('Check Hours'),
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
                title: const Text('View Jobs'),
                onTap: () {
                  Navigator.pop(context);
                  _showJobsDialog(context, index);
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
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
          title: Text('Edit Day ${localDays[index]['day']}'),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(hintText: 'Enter new description'),
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
              child: const Text('Save'),
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
        title: const Text('Worked Days'),
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
                    icon: Icon(Icons.add),
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
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'close',
                          child: Text('Close'),
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

class EmployeeHoursPage extends StatefulWidget {
  final String week;

  const EmployeeHoursPage({required this.week});

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
