import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Port Flow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, String>> items = [];
  List<List<bool>> grid =
      List.generate(5, (_) => List.generate(5, (_) => false));
  List<List<Color>> gridColors = List.generate(
    5,
    (i) => List.generate(5, (j) {
      if (i == 0 && j <= 4)
        return const Color.fromARGB(255, 255, 255, 255); // İlk 5 kutunun rengi
      return Colors.white;
    }),
  );

  int? selectedX;
  int? selectedY;
  final TextEditingController containerNameController = TextEditingController();
  final TextEditingController xController = TextEditingController();
  final TextEditingController yController = TextEditingController();

  bool _isLoading = false;
  Color selectedColor = Colors.blue; // Default color is blue
  String serverIp = '';
  String serverIp2 = '';
  String serverIp3 = '';
  int port1 = 8080;
  int port2 = 8080;
  int port3 = 3000;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _loadIpAndPorts();
  }

  Future<void> _loadIpAndPorts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      serverIp = prefs.getString('server_ip') ?? '';
      serverIp2 = prefs.getString('server_ip2') ?? '';
      serverIp3 = prefs.getString('server_ip3') ?? '';
      port1 = prefs.getInt('port1') ?? 8080;
      port2 = prefs.getInt('port2') ?? 8080;
      port3 = prefs.getInt('port3') ?? 3000;
    });
  }

  Future<void> _saveIpAndPorts(String ip, String ip2, String ip3, int port1,
      int port2, int port3) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
    await prefs.setString('server_ip2', ip2);
    await prefs.setString('server_ip3', ip3);
    await prefs.setInt('port1', port1);
    await prefs.setInt('port2', port2);
    await prefs.setInt('port3', port3);
    setState(() {
      serverIp = ip;
      serverIp2 = ip2;
      serverIp3 = ip3;
      this.port1 = port1;
      this.port2 = port2;
      this.port3 = port3;
    });
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedItems = prefs.getString('items');
    final savedGridColors = prefs.getString('gridColors');
    final savedGrid = prefs.getString('grid');

    if (savedItems != null) {
      setState(() {
        items = List<Map<String, String>>.from(jsonDecode(savedItems));
      });
    }

    if (savedGridColors != null) {
      setState(() {
        List<List<String>> tempGridColors =
            List<List<String>>.from(jsonDecode(savedGridColors));
        for (int i = 0; i < 5; i++) {
          for (int j = 0; j < 5; j++) {
            gridColors[i][j] = Color(int.parse(tempGridColors[i][j]));
          }
        }
      });
    }

    if (savedGrid != null) {
      setState(() {
        grid = List<List<bool>>.from(
            jsonDecode(savedGrid).map((row) => List<bool>.from(row)));
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('items', jsonEncode(items));
    await prefs.setString('grid', jsonEncode(grid));
    await prefs.setString(
        'gridColors',
        jsonEncode(gridColors
            .map((row) => row.map((color) => color.value.toString()).toList())
            .toList()));
  }

  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildTextField(
                      controller: containerNameController,
                      label: 'Container Name'),
                  _buildTextField(
                      controller: xController,
                      label: 'X Value',
                      isNumeric: true),
                  _buildTextField(
                      controller: yController,
                      label: 'Y Value',
                      isNumeric: true),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            if (containerNameController.text.isEmpty) {
                              _showErrorDialog(
                                  'Container name cannot be empty.');
                              return;
                            }
                            if (items.any((item) =>
                                item['container_name'] ==
                                containerNameController.text)) {
                              _showErrorDialog(
                                  'A container with this name already exists.');
                              return;
                            }
                            if (xController.text.isEmpty ||
                                yController.text.isEmpty) {
                              _showErrorDialog(
                                  'X and Y values cannot be empty.');
                              return;
                            }
                            int x = int.tryParse(xController.text) ?? 0;
                            int y = int.tryParse(yController.text) ?? 0;
                            if (x < 0 || x > 4 || y < 0 || y > 4) {
                              _showErrorDialog(
                                  'X and Y values must be between 0 and 4.');
                              return;
                            }
                            int gridNumber = y * 5 + x + 1;
                            if (gridNumber > 5) {
                              _showErrorDialog(
                                  'Containers can only be added to cells 1, 2, 3, 4, and 5.');
                              return;
                            }
                            if (grid[y][x]) {
                              _showErrorDialog(
                                  'This cell is already occupied.');
                              return;
                            }

                            String containerName = containerNameController.text;

                            setState(() {
                              items.add({
                                'container_name': containerName,
                                'x': x.toString(),
                                'y': y.toString(),
                              });
                              grid[y][x] = true;
                              gridColors[y][x] = selectedColor;
                              containerNameController.clear();
                              xController.clear();
                              yController.clear();
                            });
                            _sendAddContainerQuery(
                              containerName,
                              x,
                              y,
                            );
                            _sendAddContainerSimulation(
                              x,
                              y,
                            );
                            _saveData();
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Add',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 68, 224, 73),
                          )),
                      ElevatedButton(
                        onPressed: () {
                          containerNameController.clear();
                          xController.clear();
                          yController.clear();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 238, 98, 88)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendAddContainerQuery(
      String containerName, int x, int y) async {
    final url3 = Uri.parse('http://$serverIp3:$port3/query');
    print('Sending add container query to URL3: $containerName, $x, $y');

    try {
      final response3 = await http.post(
        url3,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': "INSERT INTO portflow (name, container_x, container_y) "
              "VALUES ('$containerName', $x, $y)",
        }),
      );

      print('Response status for URL3: ${response3.statusCode}');
      if (response3.statusCode == 200) {
        print('Container added successfully to URL3');
        print('Response body: ${response3.body}');
      } else {
        print('Failed to add container to URL3: ${response3.statusCode}');
        print('Response body: ${response3.body}');
      }
    } catch (e) {
      print('Error occurred while sending to URL3: $e');
    }
  }

  Future<void> _sendDeleteContainerQuery(int x, int y) async {
    final url3 = Uri.parse('http://$serverIp3:$port3/query');
    print('Sending delete container query to URL3: $x, $y');

    try {
      final response3 = await http.post(
        url3,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query':
              "DELETE FROM portflow WHERE container_x = $x AND container_y = $y",
        }),
      );

      print('Response status for URL3: ${response3.statusCode}');
      if (response3.statusCode == 200) {
        print('Container deleted successfully from URL3');
        print('Response body: ${response3.body}');
      } else {
        print('Failed to delete container from URL3: ${response3.statusCode}');
        print('Response body: ${response3.body}');
      }
    } catch (e) {
      print('Error occurred while sending to URL3: $e');
    }
  }

  Future<void> _sendCoordinates2(
      String pickupX, String pickupY, String dropX, String dropY) async {
    final url2 = Uri.parse('http://$serverIp2:$port2/move');
    print('Sending coordinates to URL2: $pickupX, $pickupY to $dropX, $dropY');

    try {
      final response2 = await http.post(
        url2,
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'pickup_x': pickupY,
          'pickup_y': pickupX,
          'drop_x': dropY,
          'drop_y': dropX,
        },
      );

      print('Response status for URL2: ${response2.statusCode}');
      if (response2.statusCode == 200) {
        print('Coordinates sent successfully to URL2');
        print('Response body: ${response2.body}');
      } else {
        print('Failed to send coordinates to URL2: ${response2.statusCode}');
        print('Response body: ${response2.body}');
      }
    } catch (e) {
      print('Error occurred while sending to URL2: $e');
    }
  }

  Future<void> _sendAddContainerSimulation(int X, int Y) async {
    final url2 = Uri.parse('http://$serverIp2:$port2/add');
    print('Sending coordinates to URL2: $X, $Y');

    try {
      final response2 = await http.post(
        url2,
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'X': Y.toString(),
          'Y': X.toString(),
        },
      );

      print('Response status for URL2: ${response2.statusCode}');
      if (response2.statusCode == 200) {
        print('Coordinates sent successfully to URL2');
        print('Response body: ${response2.body}');
      } else {
        print('Failed to send coordinates to URL2: ${response2.statusCode}');
        print('Response body: ${response2.body}');
      }
    } catch (e) {
      print('Error occurred while sending to URL2: $e');
    }
  }

  Future<void> _sendDeleteContainerSimulation(int X, int Y) async {
    final url2 = Uri.parse('http://$serverIp2:$port2/remove');
    print('AAA Sending coordinates to URL2: $X, $Y');

    try {
      final response2 = await http.post(
        url2,
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'X': Y.toString(),
          'Y': X.toString(),
        },
      );

      print('AAA Response status for URL2: ${response2.statusCode}');
      if (response2.statusCode == 200) {
        print('AAA Coordinates sent successfully to URL2');
        print('AAA Response body: ${response2.body}');
      } else {
        print(
            'AAA Failed to send coordinates to URL2: ${response2.statusCode}');
        print('AAA Response body: ${response2.body}');
      }
    } catch (e) {
      print('AAA Error occurred while sending to URL2: $e');
    }
  }

  Future<void> _sendCoordinates3(
      String pickupX, String pickupY, String dropX, String dropY) async {
    final url3 = Uri.parse('http://$serverIp3:$port3/query');
    print('Sending coordinates to URL3: $pickupX, $pickupY to $dropX, $dropY');

    try {
      final response3 = await http.post(
        url3,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query':
              "UPDATE portflow SET container_x = $dropX, container_y = $dropY "
                  "WHERE container_x = $pickupX AND container_y = $pickupY",
        }),
      );

      print('Response status for URL3: ${response3.statusCode}');
      if (response3.statusCode == 200) {
        print('Coordinates sent successfully to URL3');
        print('Response body: ${response3.body}');
      } else {
        print('Failed to send coordinates to URL3: ${response3.statusCode}');
        print('Response body: ${response3.body}');
      }
    } catch (e) {
      print('Error occurred while sending to URL3: $e');
    }
  }

  Future<bool> _sendCoordinates(
      String pickupX, String pickupY, String dropX, String dropY) async {
    await _sendCoordinates2(pickupX, pickupY, dropX, dropY);
    await _sendCoordinates3(pickupX, pickupY, dropX, dropY);

    final url1 = Uri.parse('http://$serverIp:$port1/move');
    print('Sending coordinates: $pickupX, $pickupY to $dropX, $dropY');

    try {
      final response1 = await http.post(
        url1,
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'pickup_x': pickupY,
          'pickup_y': pickupX,
          'drop_x': dropY,
          'drop_y': dropX,
        },
      );

      print('Response status: ${response1.statusCode}');
      if (response1.statusCode == 200) {
        print('Coordinates sent successfully');
        print('Response body: ${response1.body}');
        return true;
      } else {
        print('Failed to send coordinates: ${response1.statusCode}');
        print('Response body: ${response1.body}');
        return false;
      }
    } catch (e) {
      print('Error occurred: $e');
      return false;
    }
  }

  Future<void> _fetchDataAndUpdateGrid() async {
    final url3 = Uri.parse('http://$serverIp3:$port3/query');

    setState(() {
      _isLoading = true;
    });

    try {
      final response3 = await http.post(
        url3,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'query': 'SELECT * FROM portflow',
        }),
      );

      if (response3.statusCode == 200) {
        List<dynamic> data = jsonDecode(response3.body);
        setState(() {
          items.clear();
          grid = List.generate(5, (_) => List.generate(5, (_) => false));
          gridColors = List.generate(
              5,
              (i) => List.generate(5, (j) {
                    if (i == 0 && j <= 4) return Colors.grey[300]!;
                    return Colors.white;
                  }));

          for (var item in data) {
            String name = item['name'];
            int containerX = item['container_x'];
            int containerY = item['container_y'];

            items.add({
              'container_name': name,
              'x': containerX.toString(),
              'y': containerY.toString(),
            });
            grid[containerY][containerX] = true;
            gridColors[containerY][containerX] = selectedColor;
          }
        });
        _saveData();
      } else {
        _showErrorDialog('Failed to fetch data: ${response3.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error occurred while fetching data: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _deleteItem(int index) {
    setState(() {
      int x = int.parse(items[index]['x']!);
      int y = int.parse(items[index]['y']!);

      if (selectedX == x && selectedY == y) {
        selectedX = null;
        selectedY = null;
      }

      grid[y][x] = false;
      gridColors[y][x] = Colors.white;
      items.removeAt(index);
      _sendDeleteContainerQuery(x, y);
      _sendDeleteContainerSimulation(x, y);
      _saveData();
    });
  }

  Future<bool?> _confirmMove(int x, int y) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Move'),
          content: Text(
              'Are you sure you want to move the container to this position?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Confirm', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _updateGridItem(int x, int y) async {
    if (grid[y][x]) {
      setState(() {
        if (selectedX == x && selectedY == y) {
          selectedX = null;
          selectedY = null;
        } else {
          selectedX = x;
          selectedY = y;
        }
      });
    } else {
      if (selectedX != null && selectedY != null) {
        bool? confirm = await _confirmMove(x, y);
        if (confirm == true) {
          setState(() {
            _isLoading = true;
          });

          bool success = await _sendCoordinates(selectedX!.toString(),
              selectedY!.toString(), x.toString(), y.toString());

          if (success) {
            setState(() {
              grid[selectedY!][selectedX!] = false;
              String containerName = items.firstWhere((item) =>
                  item['x'] == selectedX.toString() &&
                  item['y'] == selectedY.toString())['container_name']!;
              items.removeWhere((item) =>
                  item['x'] == selectedX.toString() &&
                  item['y'] == selectedY.toString());
              items.add({
                'container_name': containerName,
                'x': x.toString(),
                'y': y.toString(),
              });
              grid[y][x] = true;
              gridColors[y][x] = selectedColor;
              selectedX = null;
              selectedY = null;
              _isLoading = false;
            });
            _saveData();
          } else {
            setState(() {
              _isLoading = false;
            });
            _showErrorDialog('Failed to send coordinates');
          }
        }
      } else {
        _addItemToGrid(x, y);
      }
    }
  }

  void _addItemToGrid(int x, int y) {
    int gridNumber = y * 5 + x + 1;
    if (gridNumber > 5) {
      _showErrorDialog(
          'Containers can only be added to cells 1, 2, 3, 4, and 5.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildTextField(
                      controller: containerNameController,
                      label: 'Container Name'),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (containerNameController.text.isEmpty) {
                            _showErrorDialog('Container name cannot be empty.');
                            return;
                          }
                          if (items.any((item) =>
                              item['container_name'] ==
                              containerNameController.text)) {
                            _showErrorDialog(
                                'A container with this name already exists.');
                            return;
                          }
                          if (grid[y][x]) {
                            _showErrorDialog('This cell is already occupied.');
                            return;
                          }

                          String containerName = containerNameController.text;

                          setState(() {
                            items.add({
                              'container_name': containerName,
                              'x': x.toString(),
                              'y': y.toString(),
                            });
                            grid[y][x] = true;
                            gridColors[y][x] = selectedColor;
                            containerNameController.clear();
                          });
                          _sendAddContainerQuery(
                            containerName,
                            x,
                            y,
                          );
                          _sendAddContainerSimulation(
                            x,
                            y,
                          );
                          _saveData();
                          Navigator.of(context).pop();
                        },
                        child:
                            Text('Add', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 68, 224, 73)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          containerNameController.clear();
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 238, 98, 88)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error', style: TextStyle(color: Colors.red)),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sortAndMoveItems() async {
    // Check if there are any items in cells 1 to 5
    bool hasItemsInTopRow = items.any((item) {
      int x = int.parse(item['x']!);
      int y = int.parse(item['y']!);
      int gridNumber = y * 5 + x + 1;
      return gridNumber <= 5;
    });

    // Check if there are any items in cells 21 to 25
    bool hasItemsInBottomRow = items.any((item) {
      int x = int.parse(item['x']!);
      int y = int.parse(item['y']!);
      int gridNumber = y * 5 + x + 1;
      return gridNumber >= 21;
    });

    if (!hasItemsInTopRow) {
      _showErrorDialog('There are no items in cells 1 to 5 to sort and move.');
      return;
    }

    if (hasItemsInBottomRow) {
      _showErrorDialog(
          'Cannot sort and move items because cells 21 to 25 are not empty.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Get items from cells 1 to 5
    List<Map<String, String>> selectedItems = items.where((item) {
      int x = int.parse(item['x']!);
      int y = int.parse(item['y']!);
      int gridNumber = y * 5 + x + 1;
      return gridNumber <= 5;
    }).toList();

    // Sort items alphabetically by container_name
    selectedItems.sort((a, b) => a['container_name']!
        .toLowerCase()
        .compareTo(b['container_name']!.toLowerCase()));

    // Move sorted items to cells 21 to 25
    for (int i = 0; i < selectedItems.length; i++) {
      int x = 4 - (i % 5);
      int y = 4;
      int oldX = int.parse(selectedItems[i]['x']!);
      int oldY = int.parse(selectedItems[i]['y']!);

      // Send coordinates to move the container
      bool success = await _sendCoordinates(
          oldX.toString(), oldY.toString(), x.toString(), y.toString());

      if (success) {
        setState(() {
          // Clear old positions
          grid[oldY][oldX] = false;
          gridColors[oldY][oldX] = Colors.grey[300]!;

          // Set new positions
          grid[y][x] = true;
          gridColors[y][x] = selectedColor;

          // Update item coordinates
          selectedItems[i]['x'] = x.toString();
          selectedItems[i]['y'] = y.toString();
        });
      } else {
        _showErrorDialog('Failed to send coordinates');
      }
    }

    setState(() {
      items = selectedItems;
      _isLoading = false;
    });

    _saveData();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.blueGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.blue),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (y) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (x) {
            int displayX = 4 - x;
            int displayY = y;
            return GestureDetector(
              onTap:
                  _isLoading ? null : () => _updateGridItem(displayX, displayY),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 60,
                height: 60,
                margin: EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: grid[displayY][displayX]
                      ? gridColors[displayY][displayX]
                      : Colors.white,
                  border: Border.all(color: Colors.black),
                  boxShadow: selectedX == displayX && selectedY == displayY
                      ? [BoxShadow(color: Colors.yellow, spreadRadius: 3)]
                      : [],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${displayY * 5 + (4 - displayX) + 1}', // Display the cell number
                    style: TextStyle(
                      color: grid[displayY][displayX]
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildAvatar(int x, int y) {
    int gridNumber = y * 5 + (4 - x) + 1;
    Color color = gridColors[y][x];
    return CircleAvatar(
      backgroundColor: color,
      child: Text(
        '$gridNumber',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  void _showIpDialog() {
    final TextEditingController ipController =
        TextEditingController(text: serverIp);
    final TextEditingController ipController2 =
        TextEditingController(text: serverIp2);
    final TextEditingController ipController3 =
        TextEditingController(text: serverIp3);
    final TextEditingController port1Controller =
        TextEditingController(text: port1.toString());
    final TextEditingController port2Controller =
        TextEditingController(text: port2.toString());
    final TextEditingController port3Controller =
        TextEditingController(text: port3.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                            controller: ipController,
                            label: 'Embedded IP Address'),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                            controller: port1Controller,
                            label: 'Embedded Port Number',
                            isNumeric: true),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                            controller: ipController2,
                            label: 'Simulation IP Address'),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                            controller: port2Controller,
                            label: 'Simulation Port Number',
                            isNumeric: true),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                            controller: ipController3,
                            label: 'Database IP Address'),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                            controller: port3Controller,
                            label: 'Database Port Number',
                            isNumeric: true),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          int port1 =
                              int.tryParse(port1Controller.text) ?? 8080;
                          int port2 =
                              int.tryParse(port2Controller.text) ?? 8080;
                          int port3 =
                              int.tryParse(port3Controller.text) ?? 8080;
                          _saveIpAndPorts(ipController.text, ipController2.text,
                              ipController3.text, port1, port2, port3);
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 68, 224, 73)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 238, 98, 88),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 40,
            ),
            SizedBox(width: 10),
            Text('Port Flow'),
          ],
        ),
        backgroundColor: Color.fromARGB(
            128, 147, 232, 247), // Add this line to change the background color
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showIpDialog,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background3.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: <Widget>[
                SizedBox(height: 16),
                _buildGrid(),
                Divider(color: Colors.white),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sortAndMoveItems,
                          child: Text('Sort and Move Items',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: Size(150, 40),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _fetchDataAndUpdateGrid,
                          child: Text('Fetch and Update Grid',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.black, fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: Size(150, 40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 2.0,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          leading: _buildAvatar(int.parse(items[index]['x']!),
                              int.parse(items[index]['y']!)),
                          title: Text(
                            'Container: ${items[index]['container_name']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // Removed coordinates from subtitle
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed:
                                _isLoading ? null : () => _deleteItem(index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _addItem,
        tooltip: 'Add Item',
        child: Icon(Icons.add, color: Colors.black),
        backgroundColor: Colors.white,
      ),
    );
  }
}
