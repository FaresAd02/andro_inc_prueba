import 'package:flutter/material.dart';

class WorkWeekPage extends StatefulWidget {
  const WorkWeekPage({super.key});

  @override
  _WorkWeekPageState createState() => _WorkWeekPageState();
}

class _WorkWeekPageState extends State<WorkWeekPage> {
  final List<Map<String, dynamic>> days = [
    {'day': 'Monday', 'project': 'Project A', 'hours': 0, 'submitted': false},
    {'day': 'Tuesday', 'project': 'Project B', 'hours': 0, 'submitted': false},
    {
      'day': 'Wednesday',
      'project': 'Project C',
      'hours': 0,
      'submitted': false
    },
    {'day': 'Thursday', 'project': 'Project D', 'hours': 0, 'submitted': false},
    {'day': 'Friday', 'project': 'Project E', 'hours': 0, 'submitted': false},
    {'day': 'Saturday', 'project': 'Project F', 'hours': 0, 'submitted': false},
  ];

  bool isWeekSubmitted = false; // Para deshabilitar la semana completa

  void _incrementHours(int index) {
    setState(() {
      if (days[index]['hours'] < 10) {
        days[index]['hours']++;
      }
    });
  }

  void _decrementHours(int index) {
    setState(() {
      if (days[index]['hours'] > 0) {
        days[index]['hours']--;
      }
    });
  }

  void _submitDay(int index) {
    setState(() {
      days[index]['submitted'] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${days[index]['day']} submitted')),
    );
  }

  void _submitWeek() {
    bool allDaysSubmitted = days.every((day) => day['submitted'] == true);
    if (allDaysSubmitted) {
      setState(() {
        isWeekSubmitted = true;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Submit Week'),
            content: const Text(
                'Are you sure you want to submit the week? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Week submitted!')),
                  );
                },
                child: const Text('Yes'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('No'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please submit all days first')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Week #35 - Worked Hours'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(
                  Icons.menu), // Botón de hamburguesa para abrir menú
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
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
              leading: const Icon(Icons.home),
              title: const Text('Home Page'),
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: days.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('${days[index]['day']} - ${days[index]['project']}'),
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Hours: ', style: TextStyle(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: days[index]['submitted'] || isWeekSubmitted
                            ? null
                            : () => _incrementHours(index),
                      ),
                      Text(
                        '${days[index]['hours']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: days[index]['submitted'] || isWeekSubmitted
                            ? null
                            : () => _decrementHours(index),
                      ),
                    ],
                  ),
                  if (!days[index]['submitted'])
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: (days[index]['hours'] > 0 &&
                              days[index]['hours'] <= 10)
                          ? () => _submitDay(index)
                          : null,
                    )
                  else
                    const Text('Submitted',
                        style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: isWeekSubmitted ? null : _submitWeek,
          child: const Text('Submit Week'),
        ),
      ),
    );
  }
}
