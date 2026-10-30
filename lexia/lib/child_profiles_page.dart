import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'auth_identity.dart';
import 'main_wrapper.dart';

/// Only children are displayed. The parent account never appears here.
class ChildProfilesPage extends StatelessWidget {
  final String familyCode;
  final List<Map<String, String>> profiles;

  const ChildProfilesPage({
    super.key,
    required this.familyCode,
    required this.profiles,
  });

  static const purple = Color(0xFF6A5ACD);

  Widget _avatar(String source) {
    final value = source.isEmpty ? 'assets/lexiaAv.png' : source;
    if (value.startsWith('https://')) {
      return Image.network(value, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset('assets/lexiaAv.png'));
    }
    if (value.endsWith('.svg')) return SvgPicture.asset(value, fit: BoxFit.contain);
    return Image.asset(value, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/lexiaAv.png'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCFF),
      appBar: AppBar(backgroundColor: Colors.transparent,
          title: const Text('Who’s learning today?')),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: profiles.isEmpty
            ? const Text('No child profiles found. Ask a parent to add one.')
            : GridView.builder(
                padding: const EdgeInsets.all(22),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 18,
                  crossAxisSpacing: 18, childAspectRatio: .88,
                ),
                itemCount: profiles.length,
                itemBuilder: (context, index) {
                  final child = profiles[index];
                  return InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChildPicturePinPage(
                        familyCode: familyCode,
                        childId: child['childId'] ?? '',
                        childName: child['name'] ?? '',
                      ),
                    )),
                    borderRadius: BorderRadius.circular(22),
                    child: Column(children: [
                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(22),
                        child: _avatar(child['avatarUrl'] ?? ''))),
                      const SizedBox(height: 8),
                      Text(child['name'] ?? '', textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    ]),
                  );
                },
              ),
      ))),
    );
  }
}

class ChildPicturePinPage extends StatefulWidget {
  final String familyCode;
  final String childId;
  final String childName;
  const ChildPicturePinPage({super.key, required this.familyCode,
    required this.childId, required this.childName});

  @override
  State<ChildPicturePinPage> createState() => _ChildPicturePinPageState();
}

class _ChildPicturePinPageState extends State<ChildPicturePinPage> {
  static const purple = Color(0xFF6A5ACD);
  final List<int> _pin = [];
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (_pin.length != 3 || _loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await FirebaseFunctions.instanceFor(region: 'me-central1')
          .httpsCallable('loginChild').call({
        'familyCode': widget.familyCode,
        'childId': widget.childId,
        'pin': List<int>.from(_pin),
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final token = data['customToken'] as String;
      final parentUid = data['parentUid'] as String;
      final childId = data['childId'] as String;
      await FirebaseAuth.instance.signInWithCustomToken(token);
      AuthIdentity.configureChild(parentUid, childId);
      AuthIdentity.familyCode = widget.familyCode;
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainWrapper(
          isChildMode: true, childId: childId,
        )), (route) => false,
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? 'Could not sign in. Try again.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not sign in. Check your connection.');
    } finally {
      if (mounted) setState(() { _loading = false; _pin.clear(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCFF),
      appBar: AppBar(title: Text('Hello, ${widget.childName}!'),
          backgroundColor: Colors.transparent),
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
          child: Column(children: [
            const Text('Choose your three secret pictures in order',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Container(
                width: 65, height: 65, margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFF0EBFF),
                  borderRadius: BorderRadius.circular(13)),
                child: i < _pin.length
                  ? Image.asset('assets/pin_photos/pin_${_pin[i]}.png')
                  : const Icon(Icons.lock_outline, color: purple),
              )),
            ),
            TextButton(onPressed: _loading ? null : () => setState(() {
              _pin.clear(); _error = null;
            }), child: const Text('Clear selection')),
            GridView.builder(shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 10,
                mainAxisSpacing: 10, childAspectRatio: 1,
              ),
              itemCount: 9,
              itemBuilder: (context, index) => InkWell(
                onTap: (_loading || _pin.length >= 3) ? null : () => setState(() {
                  _pin.add(index + 1); _error = null;
                }),
                child: Container(padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white,
                    border: Border.all(color: const Color(0xFFDCD3FC)),
                    borderRadius: BorderRadius.circular(16)),
                  child: Image.asset('assets/pin_photos/pin_${index + 1}.png',
                    fit: BoxFit.contain),
                ),
              ),
            ),
            if (_error != null) Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(_error!, style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
            ),
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: (_pin.length == 3 && !_loading) ? _login : null,
              style: ElevatedButton.styleFrom(backgroundColor: purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _loading ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white,
                  strokeWidth: 2)) : const Text('Enter Lexia'),
            )),
          ]),
        ),
      ))),
    );
  }
}
