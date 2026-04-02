import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  static const Color primaryBlue = Color(0xFF5B96CA);
  static const Color primaryGreen = Color(0xFF59A685);
  static const Color softPeach = Color(0xFFF1B4AF);
  static const Color softYellow = Color(0xFFFCDA81);
  static const Color softPurple = Color(0xFFD8BDD9);
  static const Color softGrey = Color(0xFFF3F4F8);
  static const Color textDark = Color(0xFF2D3142);

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54.r,
                height: 54.r,
                decoration: BoxDecoration(
                  color: softYellow.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('🚀', style: TextStyle(fontSize: 26.sp)),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'Coming Soon!',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'This feature will be available soon!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 44.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Got it!',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.sp,
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

  Widget _actionButton(BuildContext context, String text, IconData icon) {
    return SizedBox(
      height: 46.h,
      child: ElevatedButton.icon(
        onPressed: () => _showComingSoon(context),
        icon: Icon(icon, size: 18.r),
        label: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: softGrey,
          foregroundColor: textDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: softPurple.withOpacity(0.3), width: 1),
          ),
        ),
      ),
    );
  }

  Widget _stepItem(String emoji, String text, Color dotColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: dotColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: 16.sp)),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textDark,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 247, 248),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        // Increased bottom padding to 160.h to ensure clear space above the nav bar
        padding: EdgeInsets.fromLTRB(22.w, 120.h, 22.w, 160.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Books',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                color: textDark,
              ),
            ),
            Text(
              'Scan or upload any text image',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
                border: Border.all(color: softPurple.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 24.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF8F5FF), Color(0xFFF2F8FF)],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20.r),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64.r,
                          height: 64.r,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: softPurple.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.document_scanner_rounded,
                            color: const Color(0xFF6A5ACD),
                            size: 30.r,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            'Scan or upload\nan image',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              color: textDark,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: softGrey,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🗺️ How it works',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.sp,
                                  color: textDark,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              _stepItem(
                                '📸',
                                'Scan text from a book',
                                softPeach,
                              ),
                              _stepItem('🖼️', 'Upload an image', primaryBlue),
                              _stepItem(
                                '🔤',
                                'Convert to readable text',
                                primaryGreen,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                context,
                                'Scan',
                                Icons.camera_alt_rounded,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _actionButton(
                                context,
                                'Upload',
                                Icons.file_upload_outlined,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Extra bottom spacer for smooth scrolling
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
