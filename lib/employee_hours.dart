import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

final CollectionReference weeksCollection =
    FirebaseFirestore.instance.collection('worked_weeks');

class menuCustomEmployee extends StatelessWidget {
  const menuCustomEmployee({Key? key}) : super(key: key);

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
            leading: const Icon(Icons.calendar_today),
            title: const Text('Semanas trabajadas'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const EmployeeHoursScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Dias de Trabajo'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const UserHoursPage()),
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

class UserHoursPage extends StatefulWidget {
  const UserHoursPage({super.key});

  @override
  _UserHoursPageState createState() => _UserHoursPageState();
}

class _UserHoursPageState extends State<UserHoursPage> {
  Map<String, bool> closedDays = {
    "Lunes": false,
    "Martes": false,
    "Miercoles": false,
    "Jueves": false,
    "Viernes": false,
    "Sabado": false,
  };

  String? nombre = "Usuario";
  String? currentWeek;

  @override
  void initState() {
    super.initState();
    _getUserName();
    fetchLatestWeek().then((week) {
      if (week != null) {
        setState(() {
          currentWeek = week;
        });
        _fetchClosedDays(); // Ahora se ejecuta después de asignar currentWeek
      } else {
        print("No se encontró ninguna semana en Firestore.");
      }
    });
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

  Future<void> _fetchClosedDays() async {
    try {
      if (currentWeek == null) {
        print(
            "Semana actual no definida. Asegúrate de haber cargado las semanas correctamente.");
        return;
      }

      // Lógica actual del método
      DocumentSnapshot weekSnapshot = await FirebaseFirestore.instance
          .collection('worked_days')
          .doc(currentWeek)
          .get();

      if (weekSnapshot.exists) {
        Map<String, dynamic> weekData =
            weekSnapshot.data() as Map<String, dynamic>;

        Map<String, bool> tempClosedDays = {
          "Lunes": false,
          "Martes": false,
          "Miercoles": false,
          "Jueves": false,
          "Viernes": false,
          "Sabado": false,
        };

        if (weekData['days'] != null) {
          Map<String, dynamic> daysData =
              weekData['days'] as Map<String, dynamic>;

          daysData.forEach((day, details) {
            if (details is Map<String, dynamic> &&
                details.containsKey('cerrado')) {
              tempClosedDays[day] = details['cerrado'] ?? false;
            }
          });
        }

        setState(() {
          closedDays = tempClosedDays;
        });
      } else {
        print("Documento de la semana actual no encontrado en Firestore.");
      }
    } catch (e) {
      print("Error obteniendo los días cerrados: $e");
    }
  }

  Future<String?> fetchLatestWeek() async {
    try {
      QuerySnapshot snapshot = await weeksCollection.get();
      List<Map<String, dynamic>> weeks = snapshot.docs.map((doc) {
        return {
          'week': doc.id,
        };
      }).toList();

      weeks.sort((a, b) {
        int weekA =
            int.tryParse(a['week'].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        int weekB =
            int.tryParse(b['week'].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return weekA.compareTo(weekB);
      });

      if (weeks.isNotEmpty) {
        return weeks.last['week'];
      }
    } catch (e) {
      print("Error obteniendo la semana actual: $e");
    }
    return null;
  }

  Stream<String?> getLatestWeekStream() {
    return FirebaseFirestore.instance
        .collection('worked_weeks')
        .orderBy(FieldPath.documentId, descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.isNotEmpty ? snapshot.docs.first.id : null);
  }

  void _closeDay(String dia) async {
    try {
      if (closedDays[dia] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("El día $dia ya está cerrado.")),
        );
        return;
      }

      if (currentWeek == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Semana actual no definida. Intenta nuevamente.")),
        );
        return;
      }

      DocumentSnapshot weekSnapshot = await FirebaseFirestore.instance
          .collection('employee_hours')
          .doc(currentWeek)
          .get();

      if (weekSnapshot.exists) {
        Map<String, dynamic> weekData =
            weekSnapshot.data() as Map<String, dynamic>;

        if (weekData['days'] != null && weekData['days'][dia] != null) {
          int employeeCount = (weekData['days'][dia] as Map).length;

          if (employeeCount < 8) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      "Debe haber al menos 8 empleados registrados para cerrar el día.")),
            );
            return;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "No hay empleados registrados para cerrar el día $dia.")),
          );
          return;
        }

        DocumentReference weekDocRef = FirebaseFirestore.instance
            .collection('worked_days')
            .doc(currentWeek);

        await weekDocRef.update({
          'days.$dia': {
            'cerrado': true,
            'cerradoPor': nombre,
            'horaCierre': TimeOfDay.now().format(context),
          },
        });

        setState(() {
          closedDays[dia] = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Día $dia cerrado exitosamente.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Datos de la semana actual no encontrados.")),
        );
      }
    } catch (e) {
      print("Error cerrando el día $dia: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cerrando el día $dia.")),
      );
    }
  }

  void _showEmployees(String day) async {
    List<Map<String, dynamic>> employees = await _fetchEmployees(day);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Empleados para $day'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                return ListTile(
                  title: Text(employee['nombre']),
                  subtitle: Text(
                      "Entrada: ${employee['entrada']} - Salida: ${employee['salida']}"),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            if (!(closedDays[day] ?? false))
              TextButton(
                onPressed: () => _addEmployeePopup(context, day),
                child: const Text('Agregar empleado'),
              ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchEmployees(String day) async {
    try {
      if (currentWeek == null) {
        print("Semana actual no definida.");
        return [];
      }

      DocumentSnapshot weekSnapshot = await FirebaseFirestore.instance
          .collection('employee_hours')
          .doc(currentWeek)
          .get();

      if (weekSnapshot.exists) {
        Map<String, dynamic> weekData =
            weekSnapshot.data() as Map<String, dynamic>;

        if (weekData['days'] != null && weekData['days'][day] != null) {
          Map<String, dynamic> employees =
              weekData['days'][day] as Map<String, dynamic>;

          return employees.entries.map((entry) {
            Map<String, dynamic> employeeData =
                entry.value as Map<String, dynamic>;
            return {
              'nombre': entry.key,
              'entrada': employeeData['entrada'] ?? 'No especificada',
              'salida': employeeData['salida'] ?? 'No especificada',
            };
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print("Error obteniendo empleados para $day: $e");
      return [];
    }
  }

  void _addEmployeePopup(BuildContext context, String day) {
    TextEditingController nombreController = TextEditingController();
    TimeOfDay? horaEntrada;
    TimeOfDay? horaSalida;

    void _selectEntryTime(
        BuildContext context, Function(TimeOfDay) onTimeSelected) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        initialEntryMode:
            TimePickerEntryMode.input, // Modo de entrada de texto por defecto
      );
      if (picked != null) {
        onTimeSelected(picked);
      }
    }

    void _selectExitTime(
        BuildContext context, Function(TimeOfDay) onTimeSelected) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        initialEntryMode:
            TimePickerEntryMode.input, // Modo de entrada de texto por defecto
      );
      if (picked != null) {
        onTimeSelected(picked);
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Agregar empleado"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: "Nombre"),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text("Hora de entrada"),
                    subtitle: Text(
                      horaEntrada != null
                          ? horaEntrada!.format(context)
                          : "Selecciona una hora",
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () {
                      _selectEntryTime(context, (selectedTime) {
                        setState(() {
                          horaEntrada = selectedTime;
                        });
                      });
                    },
                  ),
                  ListTile(
                    title: const Text("Hora de salida"),
                    subtitle: Text(
                      horaSalida != null
                          ? horaSalida!.format(context)
                          : "Selecciona una hora",
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () {
                      _selectEntryTime(context, (selectedTime) {
                        setState(() {
                          horaSalida = selectedTime;
                        });
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nombreController.text.isNotEmpty &&
                        horaEntrada != null &&
                        horaSalida != null) {
                      try {
                        DocumentReference weekDocRef = FirebaseFirestore
                            .instance
                            .collection('employee_hours')
                            .doc(currentWeek);

                        DocumentSnapshot weekSnapshot = await weekDocRef.get();

                        if (weekSnapshot.exists) {
                          await weekDocRef.update({
                            'days.$day.${nombreController.text}': {
                              'entrada': horaEntrada!.format(context),
                              'salida': horaSalida!.format(context),
                            },
                          });
                        } else {
                          await weekDocRef.set({
                            'week': currentWeek,
                            'days': {
                              day: {
                                nombreController.text: {
                                  'entrada': horaEntrada!.format(context),
                                  'salida': horaSalida!.format(context),
                                },
                              },
                            },
                          });
                        }

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Empleado agregado exitosamente: ${nombreController.text}"),
                          ),
                        );
                        _fetchEmployees(day);
                      } catch (e) {
                        print("Error agregando empleado: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Error al agregar el empleado: ${e.toString()}"),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Por favor, completa todos los campos antes de guardar.")),
                      );
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
  }

  void _closeWeekAndResetDays() async {
    try {
      if (closedDays.values.any((isClosed) => !isClosed)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "No puedes cerrar la semana. Asegúrate de cerrar todos los días primero.")),
        );
        return;
      }

      DocumentReference weekDocRef =
          FirebaseFirestore.instance.collection('worked_days').doc(currentWeek);

      await weekDocRef.update({'closed': true});

      String newWeekId =
          'Semana #${int.parse(currentWeek!.split('#').last) + 1}';
      await FirebaseFirestore.instance
          .collection('worked_days')
          .doc(newWeekId)
          .set({
        'week': newWeekId,
        'days': {
          "Lunes": {'cerrado': false},
          "Martes": {'cerrado': false},
          "Miercoles": {'cerrado': false},
          "Jueves": {'cerrado': false},
          "Viernes": {'cerrado': false},
          "Sabado": {'cerrado': false},
        },
      });

      setState(() {
        closedDays = {
          "Lunes": false,
          "Martes": false,
          "Miercoles": false,
          "Jueves": false,
          "Viernes": false,
          "Sabado": false,
        };
        currentWeek = newWeekId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Semana cerrada con éxito. ¡Puedes comenzar una nueva semana!")),
      );
    } catch (e) {
      print("Error al cerrar la semana: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Ocurrió un error al cerrar la semana. Intenta de nuevo.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Hola $nombre - Semana actual: ${currentWeek ?? "Cargando..."}'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const menuCustomEmployee(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: closedDays.keys.map((day) {
                return Card(
                  child: ListTile(
                    title: Text(
                      day,
                      style: TextStyle(
                        color: closedDays[day]! ? Colors.grey : Colors.black,
                        fontWeight: closedDays[day]!
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: closedDays[day]!
                        ? const Text(
                            "Día cerrado",
                            style: TextStyle(color: Colors.red),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: closedDays[day]! ? null : () => _closeDay(day),
                    ),
                    onTap: () => _showEmployees(day),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _closeWeekAndResetDays(),
              icon: const Icon(Icons.calendar_today),
              label: const Text("Cerrar semana"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
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
              child: Text(
                'Menu ArchiTask',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Semanas Trabajadas'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EmployeeHoursScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Dias de Trabajo'),
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
