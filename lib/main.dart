import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/match_provider.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://woqlrmmlhluaeaizrizg.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndvcWxybW1saGx1YWVhaXpyaXpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2NTAwOTUsImV4cCI6MjA5ODIyNjA5NX0.OLkvc5RWv5EQ--nCixs61HD8jculYiGKqijYqO-BxPQ',
  );
  runApp(const FaceMatchApp());
}

class FaceMatchApp extends StatelessWidget {
  const FaceMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MatchProvider()..init(),
      child: MaterialApp(
        title: '颜摹',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Supabase.instance.client.auth.currentUser != null
            ? const MainShell()
            : const LoginScreen(),
      ),
    );
  }
}
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _pages = const [HomeScreen(), AnalysisScreen(), HistoryScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.neutral400,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.face_retouching_natural_outlined),
                activeIcon: Icon(Icons.face_retouching_natural),
                label: '仿妆',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.visibility_outlined),
                activeIcon: Icon(Icons.visibility),
                label: '分析',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: '历史',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
