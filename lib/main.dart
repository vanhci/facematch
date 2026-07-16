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
  // Supabase anon key (base64 encoded)
  await Supabase.initialize(
    url: 'https://woqlrmmlhluaeaizrizg.supabase.co',
    publishableKey: String.fromCharCodes([
      101,
      121,
      74,
      104,
      98,
      71,
      99,
      105,
      79,
      105,
      74,
      73,
      85,
      122,
      73,
      49,
      78,
      105,
      73,
      115,
      73,
      110,
      82,
      53,
      99,
      67,
      73,
      54,
      73,
      107,
      112,
      88,
      86,
      67,
      74,
      57,
      46,
      101,
      121,
      74,
      112,
      99,
      51,
      77,
      105,
      79,
      105,
      74,
      122,
      100,
      88,
      66,
      104,
      89,
      109,
      70,
      122,
      90,
      83,
      73,
      115,
      73,
      110,
      74,
      108,
      90,
      105,
      73,
      54,
      73,
      110,
      100,
      118,
      99,
      87,
      120,
      121,
      98,
      87,
      49,
      115,
      97,
      71,
      120,
      49,
      89,
      87,
      86,
      104,
      97,
      88,
      112,
      121,
      97,
      88,
      112,
      110,
      73,
      105,
      119,
      105,
      99,
      109,
      57,
      115,
      90,
      83,
      73,
      54,
      73,
      109,
      70,
      117,
      98,
      50,
      52,
      105,
      76,
      67,
      74,
      112,
      89,
      88,
      81,
      105,
      79,
      106,
      69,
      51,
      79,
      68,
      73,
      50,
      78,
      84,
      65,
      119,
      79,
      84,
      85,
      115,
      73,
      109,
      86,
      52,
      99,
      67,
      73,
      54,
      77,
      106,
      65,
      53,
      79,
      68,
      73,
      121,
      78,
      106,
      65,
      53,
      78,
      88,
      48,
      46,
      79,
      76,
      107,
      118,
      99,
      53,
      82,
      87,
      118,
      53,
      69,
      81,
      45,
      45,
      110,
      67,
      105,
      120,
      115,
      54,
      49,
      72,
      68,
      56,
      106,
      99,
      117,
      108,
      89,
      105,
      71,
      75,
      113,
      105,
      106,
      89,
      113,
      79,
      45,
      66,
      120,
      80,
      81,
    ]),
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
        home: StreamBuilder(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.data?.session != null) return const MainShell();
            return const LoginScreen();
          },
        ),
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
    // Listen for pending tab switches from MatchProvider
    final provider = context.watch<MatchProvider>();
    if (provider.pendingTabSwitch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentIndex = provider.pendingTabSwitch!;
            provider.clearPendingTabSwitch();
          });
        }
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCEEE9), Color(0xFFFDF6F3), Color(0xFFFBF0EC)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: _pages[_currentIndex],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomNav(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
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
            icon: Icon(Icons.brush_outlined, size: 22),
            activeIcon: Icon(Icons.brush, size: 22),
            label: '仿妆',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.remove_red_eye_outlined, size: 22),
            activeIcon: Icon(Icons.remove_red_eye, size: 22),
            label: '分析',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined, size: 22),
            activeIcon: Icon(Icons.history, size: 22),
            label: '历史',
          ),
        ],
      ),
    );
  }
}
