import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'responsive_helper.dart';

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
  String? _wordFieldError;

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
    final String word = _controller.text.trim();

    if (word.isEmpty) {
      setState(() {
        difficulty = "";
        score = 0;
        rules = [];
        errorMessage = null;
        _wordFieldError = "Please enter a word first.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      _wordFieldError = null;
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
      margin: EdgeInsets.symmetric(vertical: R.space(6)),
      padding: EdgeInsets.all(R.space(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(R.radius(18)),
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
            size: R.icon(22),
          ),
          SizedBox(width: R.space(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule["name"] ?? "",
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: R.text(13),
                    color: textDark,
                  ),
                ),
                SizedBox(height: R.space(4)),
                Text(
                  rule["desc"] ?? "",
                  style: GoogleFonts.montserrat(
                    fontSize: R.text(12),
                    color: textDark.withOpacity(0.65),
                    height: 1.35,
                  ),
                ),
                if ((rule["detail"] ?? "").toString().isNotEmpty) ...[
                  SizedBox(height: R.space(4)),
                  Text(
                    rule["detail"] ?? "",
                    style: GoogleFonts.montserrat(
                      fontSize: R.text(11),
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
    R.init(context);

    final double horizontalPad = R.pagePad;
    final double topMargin = R.safeTop + R.space(95);
    final double bottomMargin = R.safeBottom + R.space(140);

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
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: R.maxContentWidth),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                topMargin,
                horizontalPad,
                bottomMargin,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Word Analyzer",
                    style: GoogleFonts.montserrat(
                      fontSize: R.text(21),
                      fontWeight: FontWeight.w500,
                      color: textDark.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: R.space(2)),
                  Text(
                    "Check the difficulty score of any word",
                    style: GoogleFonts.montserrat(
                      fontSize: R.text(12),
                      color: Colors.black45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: R.space(28)),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(R.radius(22)),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.025),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                      ],
                      onChanged: (value) {
                        if (_wordFieldError != null &&
                            value.trim().isNotEmpty) {
                          setState(() => _wordFieldError = null);
                        }
                      },
                      style: GoogleFonts.montserrat(
                        fontSize: R.text(15),
                        fontWeight: FontWeight.w500,
                        color: textDark,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter a word...",
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: R.text(14),
                          color: Colors.black26,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: primaryPurple.withOpacity(0.65),
                          size: R.icon(22),
                        ),
                        errorText: _wordFieldError,
                        errorStyle: GoogleFonts.montserrat(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                          fontSize: R.text(12),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(R.radius(22)),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(R.radius(22)),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(R.radius(22)),
                          borderSide: BorderSide(
                            color: primaryPurple.withOpacity(0.45),
                            width: 1.4,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(R.radius(22)),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.3,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(R.radius(22)),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: R.space(18),
                          vertical: R.space(18),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: R.space(18)),

                  GestureDetector(
                    onTap: isLoading ? null : analyzeWord,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: R.space(16)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(R.radius(18)),
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
                            ? SizedBox(
                                height: R.icon(20),
                                width: R.icon(20),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "Analyze",
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: R.text(15),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),

                  SizedBox(height: R.space(24)),

                  if (errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(R.space(14)),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(R.radius(16)),
                      ),
                      child: Text(
                        errorMessage!,
                        style: GoogleFonts.montserrat(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                          fontSize: R.text(13),
                        ),
                      ),
                    ),
                    SizedBox(height: R.space(18)),
                  ],

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: difficulty.isEmpty
                        ? const SizedBox()
                        : Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(R.space(18)),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(R.radius(22)),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.025),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _controller.text.trim(),
                                            style: GoogleFonts.montserrat(
                                              fontSize: R.text(20),
                                              fontWeight: FontWeight.w600,
                                              color: textDark,
                                            ),
                                          ),
                                          Text(
                                            "Total score: $score",
                                            style: GoogleFonts.montserrat(
                                              fontSize: R.text(12),
                                              color: Colors.black45,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: R.space(14),
                                        vertical: R.space(7),
                                      ),
                                      decoration: BoxDecoration(
                                        color: getColor(),
                                        borderRadius: BorderRadius.circular(
                                          R.radius(20),
                                        ),
                                      ),
                                      child: Text(
                                        difficulty,
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontSize: R.text(12),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: R.space(22)),

                                Text(
                                  "Analysis",
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600,
                                    fontSize: R.text(15),
                                    color: textDark,
                                  ),
                                ),

                                SizedBox(height: R.space(12)),

                                if (appliedRules.isNotEmpty) ...[
                                  Text(
                                    "Applied Rules",
                                    style: GoogleFonts.montserrat(
                                      fontSize: R.text(12),
                                      fontWeight: FontWeight.w600,
                                      color: green,
                                    ),
                                  ),
                                  SizedBox(height: R.space(8)),
                                  ...appliedRules.map(
                                    (r) => buildRuleItem(r, true),
                                  ),
                                  SizedBox(height: R.space(16)),
                                ],

                                if (notAppliedRules.isNotEmpty) ...[
                                  Text(
                                    "Not Applied Rules",
                                    style: GoogleFonts.montserrat(
                                      fontSize: R.text(12),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.redAccent.withOpacity(0.75),
                                    ),
                                  ),
                                  SizedBox(height: R.space(8)),
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
      ),
    );
  }
}
