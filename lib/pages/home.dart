import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mind_mash/pages/service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool music = true,
      geography = false,
      fooddrink = false,
      sciencenature = false,
      entertainment = false,
      answernow = false;

  String? question, answer;
  List<String> option = [];

  @override
  void initState() {
    super.initState();
    fetchQuiz("");
    fetchRandomOptions();
  }

  Future<void> fetchQuiz(String category) async {
    final response = await http.get(
      Uri.parse("https://api.api-ninjas.com/v1/trivia?category=$category"),
      headers: {
        'content-type': 'application/json',
        'X-Api-Key': APIKEY,
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> jsonData = jsonDecode(response.body);
      if (jsonData.isNotEmpty) {
        Map<String, dynamic> quiz = jsonData[0];
        question = quiz["question"];
        answer = quiz["answer"];

        option = [answer!]; // Start with the correct answer
        await fetchRandomOptions(); // Fetch additional random options
        shuffleList(); // Shuffle options for display
      }
      setState(() {});
    }
  }

  Future<void> fetchRandomOptions() async {
    // Clear previous options if any
    option = [answer!]; // Include the correct answer first

    while (option.length < 4) {
      final response = await http.get(
        Uri.parse("https://api.api-ninjas.com/v1/randomword"),
        headers: {
          'content-type': 'application/json',
          'X-Api-Key': APIKEY,
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = jsonDecode(response.body);
        if (jsonData.isNotEmpty) {
          String word = jsonData["word"].toString();
          if (!option.contains(word)) {
            option.add(word); // Ensure no duplicate options
          }
        }
      }
    }
    shuffleList(); // Shuffle to randomize positions
    setState(() {});
  }

  void shuffleList() {
    option.shuffle(Random());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Quiz Time',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: option.length < 4
          ? const Center(
              child: CircularProgressIndicator.adaptive(),
            )
          : Stack(
              children: [
                // Gradient background with a blur effect
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue[400]!,
                        Colors.blue[600]!,
                        Colors.blue[800]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Container(
                  // padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 25),
                      _buildCategorySelection(),
                      const SizedBox(height: 50),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              question ?? "Loading question...",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ...option.map((opt) => _buildOptionButton(opt)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 70)
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategorySelection() {
    return SizedBox(
      height: 45,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryButton(
              "🎵 Music", music, () => _selectCategory("music")),
          _buildCategoryButton(
              "🌍 Geography", geography, () => _selectCategory("geography")),
          _buildCategoryButton(
              "🍔 Food & Drink", fooddrink, () => _selectCategory("fooddrink")),
          _buildCategoryButton("🧪 Science & Nature", sciencenature,
              () => _selectCategory("sciencenature")),
          _buildCategoryButton("🎬 Entertainment", entertainment,
              () => _selectCategory("entertainment")),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(
      String label, bool isSelected, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          backgroundColor: isSelected ? Colors.blue[700] : Colors.blue[100],
          padding: const EdgeInsets.symmetric(horizontal: 20),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
              color: isSelected ? Colors.white : Colors.blue[900],
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
      ),
    );
  }

  void _selectCategory(String category) async {
    setState(() {
      music = category == "music";
      geography = category == "geography";
      fooddrink = category == "fooddrink";
      sciencenature = category == "sciencenature";
      entertainment = category == "entertainment";
      answernow = false;
      option = [];
    });
    await fetchRandomOptions();
    await fetchQuiz(category);
  }

  Widget _buildOptionButton(String optionText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: BorderSide(
            color: answernow
                ? (answer == optionText ? Colors.green : Colors.red)
                : Colors.blue[200]!,
            width: 2,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        onPressed: () {
          setState(() {
            answernow = true;
          });

          // Wait 5 seconds, then fetch a new question
          Future.delayed(const Duration(seconds: 3), () async {
            setState(() {
              answernow = false;
              option = [];
            });
            await fetchQuiz(""); // Fetch a new question in the current category
          });
        },
        child: Text(
          optionText.replaceAll(RegExp(r'[\[\]/]'), ""),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
