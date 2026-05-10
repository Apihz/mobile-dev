import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 17, 124, 29),
        ),
      ),
      home: const MyHomePage(title: 'BMI Calculator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Stores the entered weight in kilograms.
  double _weight = 0.0;
  // Stores the entered height in centimeters.
  double _height = 0.0;
  // Stores the calculated BMI result.
  double _bmi = 0.0;

  // Update weight from the weight input field.
  void _setWeight(String weight) {
    setState(() {
      _weight = double.tryParse(weight) ?? 0.0;
    });
  }

  // Update height from the height input field.
  void _setHeight(String height) {
    setState(() {
      _height = double.tryParse(height) ?? 0.0;
    });
  }

  // Calculate BMI and show a SnackBar with the status message.
  void _calculateBMI() {
    setState(() {
      _bmi = (_height > 0) ? (_weight / pow(_height, 2)) * 10000 : 0.0;
    });

    String status;
    if (_bmi <= 0) {
      status = 'Enter valid weight and height first.';
    } else if (_bmi < 18.5) {
      status = 'You are underweight!';
    } else if (_bmi <= 24.9) {
      status = 'You are having normal weight. Well done!';
    } else if (_bmi <= 29.9) {
      status = 'You are overweight!';
    } else {
      status = 'You are obese. Please watch your diet!';
    }

    _showSnackBar(status);
  }

  // Display status as a temporary SnackBar at the bottom of the screen.
  void _showSnackBar(String status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(status), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.all(20),
              child: TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Weight (kg)',
                ),
                onChanged: _setWeight,
                keyboardType: TextInputType.number,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(20),
              child: TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Height (cm)',
                ),
                onChanged: _setHeight,
                keyboardType: TextInputType.number,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(20),
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _calculateBMI,
                child: const Text('Calculate'),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(20),
              child: Text(_bmi.toStringAsFixed(2)),
            ),
          ],
        ),
      ),
    );
  }
}
