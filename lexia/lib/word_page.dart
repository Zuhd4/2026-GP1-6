import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

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
  bool isLoading = false;
  String? errorMessage;

  late AnimationController _controllerAnim;
  late Animation<double> _fadeAnim;

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);
  static const Color green = Color(0xFF59A685);
  static const Color softPeach = Color(0xFFF1B4AF);

  @override
  void initState() {
    super.initState();
    _controllerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _controllerAnim, curve: Curves.easeIn);
  }

  Future<void> analyzeWord() async {
    String word = _controller.text.trim();
    if (word.isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse("https://analyzer-u8yc.onrender.com/analyze");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"word": word}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          difficulty = data["difficulty"] ?? "";
          score = data["total_score"] ?? 0;

          rules = ((data["rules"] ?? []) as List).map((r) {
            return {
              "name": r["rule"],
              "applied": r["triggered"],
              "desc": r["desc"],
              "detail": r["detail"],
            };
          }).toList();

          isLoading = false;
        });

        _controllerAnim.forward(from: 0);
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Connection error. Please try again.";
      });
    }
  }

  Color getColor() {
    switch (difficulty) {
      case "Easy":
        return green;
      case "Medium":
        return Colors.orange;
      case "Hard":
        return Colors.redAccent;
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
        borderRadius: BorderRadius.circular(18),
        color: applied ? green.withOpacity(0.10) : softPeach.withOpacity(0.16),
        border: Border.all(
          color: applied
              ? green.withOpacity(0.18)
              : softPeach.withOpacity(0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            applied ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: applied ? green : Colors.redAccent.withOpacity(0.75),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule["name"] ?? "",
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rule["desc"] ?? "",
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: textDark.withOpacity(0.65),
                    height: 1.35,
                  ),
                ),
                if ((rule["detail"] ?? "").toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    rule["detail"] ?? "",
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: Colors.black38,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _controllerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    final appliedRules = rules.where((r) => r["applied"] == true).toList();
    final notAppliedRules = rules.where((r) => r["applied"] == false).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [ivoryWhite, paleBlush, softCream, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(sw * 0.06, 110, sw * 0.06, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Word Analyzer",
                  style: GoogleFonts.montserrat(
                    fontSize: 27,
                    fontWeight: FontWeight.w500,
                    color: textDark.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Check the difficulty score of any word",
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.black45,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 26),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.025),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter a word...",
                      hintStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.black26,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: primaryPurple.withOpacity(0.65),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                GestureDetector(
                  onTap: isLoading ? null : analyzeWord,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B7CF6), primaryPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Analyze",
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      errorMessage!,
                      style: GoogleFonts.montserrat(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                FadeTransition(
                  opacity: _fadeAnim,
                  child: difficulty.isEmpty
                      ? const SizedBox()
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.025),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: primaryPurple.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Icon(
                                      Icons.psychology_alt_rounded,
                                      color: primaryPurple.withOpacity(0.75),
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _controller.text.trim(),
                                          style: GoogleFonts.montserrat(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: textDark,
                                          ),
                                        ),
                                        Text(
                                          "Total score: $score",
                                          style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            color: Colors.black45,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getColor(),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      difficulty,
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 22),

                              Text(
                                "Analysis",
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: textDark,
                                ),
                              ),

                              const SizedBox(height: 12),

                              if (appliedRules.isNotEmpty) ...[
                                Text(
                                  "Applied Rules",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...appliedRules.map(
                                  (r) => buildRuleItem(r, true),
                                ),
                                const SizedBox(height: 16),
                              ],

                              if (notAppliedRules.isNotEmpty) ...[
                                Text(
                                  "Not Applied Rules",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.redAccent.withOpacity(0.75),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...notAppliedRules.map(
                                  (r) => buildRuleItem(r, false),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
