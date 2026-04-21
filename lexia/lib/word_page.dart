import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WordPage extends StatefulWidget {
  const WordPage({super.key});

  @override
  State<WordPage> createState() => _WordPageState();
}

class _WordPageState extends State<WordPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  String difficulty = "";
  int score = 0;
  List<Map<String, dynamic>> rules = [];

  late AnimationController _controllerAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controllerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _controllerAnim, curve: Curves.easeIn);
  }

  Future<void> analyzeWord() async {
    String word = _controller.text.trim();
    if (word.isEmpty) return;

    final url = Uri.parse("http://10.0.2.2:10000/analyze");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"word": word}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      difficulty = data["difficulty"];
      score = data["total_score"];

      rules = (data["rules"] as List).map((r) {
        return {
          "name": r["rule"],
          "applied": r["triggered"],
          "desc": r["desc"],
          "detail": r["detail"],
        };
      }).toList();

      _controllerAnim.forward(from: 0);
      setState(() {});
    }
  }

  Color getColor() {
    switch (difficulty) {
      case "Easy":
        return Colors.green;
      case "Medium":
        return Colors.orange;
      case "Hard":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget buildRuleItem(Map<String, dynamic> rule, bool applied) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: applied
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            applied ? Icons.check_circle : Icons.cancel,
            color: applied ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule["name"],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(rule["desc"] ?? ""),
                Text(
                  rule["detail"] ?? "",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controllerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    final appliedRules =
        rules.where((r) => r["applied"] == true).toList();
    final notAppliedRules =
        rules.where((r) => r["applied"] == false).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF4F0FF),
              Color(0xFFEDE7F6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
          child: Column(
            children: [
              const SizedBox(height: 120),

              const Text(
                "Word Difficulty",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // 🔍 Search
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8)
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Enter a word...",
                    prefixIcon: Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✨ Button
              GestureDetector(
                onTap: analyzeWord,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF9C8CFF),
                        Color(0xFF6A5ACD),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Analyze",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 📊 Result with animation
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: difficulty.isEmpty
                      ? const SizedBox()
                      : Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12, blurRadius: 12)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Difficulty
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Difficulty"),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: getColor(),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      difficulty,
                                      style: const TextStyle(
                                          color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              Text(
                                "Score: $score",
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 20),

                              const Text(
                                "Analysis",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 10),

                              Expanded(
                                child: ListView(
                                  children: [
                                    if (appliedRules.isNotEmpty) ...[
                                      const Text("✔️ Applied Rules"),
                                      const SizedBox(height: 8),
                                      ...appliedRules.map(
                                          (r) => buildRuleItem(r, true)),
                                      const SizedBox(height: 15),
                                    ],
                                    if (notAppliedRules.isNotEmpty) ...[
                                      const Text("❌ Not Applied Rules"),
                                      const SizedBox(height: 8),
                                      ...notAppliedRules.map(
                                          (r) => buildRuleItem(r, false)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}