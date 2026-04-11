import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'responsive_helper.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<List<Color>> _bgGradients = [
    [const Color(0xFFEBF5FF), Colors.white],
    [const Color(0xFFF3FAF0), Colors.white],
    [const Color(0xFFFFFDF5), Colors.white],
  ];

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Welcome to Lexia",
      "desc":
          "A specialized world designed to help children with dyslexia thrive through play.",
      "image": "assets/e_happy.png",
    },
    {
      "title": "Interactive Learning",
      "desc":
          "Engaging games that turn reading challenges into exciting adventures.",
      "image": "assets/charchter2.png",
    },
    {
      "title": "Track Progress",
      "desc":
          "Detailed insights for parents to monitor growth and celebrate every win.",
      "image": "assets/Lexia.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final sw = R.sw;
    final sh = R.sh;
    final hPad = R.pagePadWide;
    final bool isLastPage = _currentPage == _onboardingData.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _bgGradients[_currentPage],
          ),
        ),
        child: SafeArea(
          child: R.pageWrap(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: sw,
                              height: sh * 0.30,
                              child: Image.asset(
                                _onboardingData[index]['image']!,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: R.space(22)),
                            Text(
                              _onboardingData[index]['title']!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: R.text(18),
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2D3142),
                              ),
                            ),
                            SizedBox(height: R.space(10)),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: R.space(8),
                              ),
                              child: Text(
                                _onboardingData[index]['desc']!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: R.text(11.5),
                                  color: Colors.black54,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, R.space(26)),
                  child: Column(
                    children: [
                      if (!isLastPage)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [_buildDots(), _buildNextButton()],
                        )
                      else
                        Column(
                          children: [
                            _actionButton(
                              "Create Account",
                              const Color(0xFF6A5ACD),
                              Colors.white,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignUpScreen(),
                                ),
                              ),
                            ),
                            SizedBox(height: R.space(12)),
                            _actionButton(
                              "I Already Have an Account",
                              Colors.white,
                              const Color(0xFF2D3142),
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              ),
                              border: Border.all(color: Colors.black12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      children: List.generate(
        _onboardingData.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.only(right: R.space(6)),
          width: _currentPage == index ? R.space(18) : R.space(7),
          height: R.space(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _currentPage == index
                ? const Color(0xFF6A5ACD)
                : Colors.black12,
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: () => _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      ),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF6A5ACD),
        shape: const CircleBorder(),
        padding: EdgeInsets.all(R.space(12)),
      ),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        size: R.icon(15),
        color: Colors.white,
      ),
    );
  }

  Widget _actionButton(
    String title,
    Color bg,
    Color fg,
    VoidCallback onTap, {
    Border? border,
  }) {
    return SizedBox(
      width: double.infinity,
      height: R.buttonH(46),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(R.radius(18)),
            side: border?.top ?? BorderSide.none,
          ),
        ),
        onPressed: onTap,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            maxLines: 1,
            softWrap: false,
            style: GoogleFonts.montserrat(
              fontSize: R.text(12),
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
