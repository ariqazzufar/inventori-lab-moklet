import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/skeleton_loader.dart';
import 'item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  final PageController _pageController = PageController(viewportFraction: 0.92);
  final ValueNotifier<int> _currentBannerNotifier = ValueNotifier<int>(0);
  Timer? _bannerTimer;
  bool _isUserScrollingBanner = false;

  static const Color bcaNavy = Color(0xFF003D79);
  static const Color bcaBlue = Color(0xFF0060AF);
  static const Color bcaCyan = Color(0xFF00AEEF);

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Peminjaman Alat Praktikum',
      'subtitle': 'Cek ketersediaan perangkat sebelum praktikum dimulai',
      'image':
          'https://images.pexels.com/photos/1181244/pexels-photo-1181244.jpeg?auto=compress&cs=tinysrgb&w=800',
    },
    {
      'title': 'Jaga Kebersihan & Kerapian Lab',
      'subtitle': 'Kembalikan alat sesuai kode rak masing-masing',
      'image':
          'https://images.pexels.com/photos/2881229/pexels-photo-2881229.jpeg?auto=compress&cs=tinysrgb&w=800',
    },
    {
      'title': 'Inventaris Real-Time',
      'subtitle': 'Data alat terpantau langsung oleh laboran',
      'image':
          'https://images.pexels.com/photos/3861969/pexels-photo-3861969.jpeg?auto=compress&cs=tinysrgb&w=800',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startBannerAutoScroll();
  }

  // Auto-scroll banner setiap 4 detik, otomatis berhenti jika user sedang menggeser manual
  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_isUserScrollingBanner || !_pageController.hasClients) return;
      final int nextPage =
          (_currentBannerNotifier.value + 1) % _banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _searchController.dispose();
    _pageController.dispose();
    _currentBannerNotifier.dispose();
    super.dispose();
  }

  String _getTimePhase() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return 'pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'siang';
    } else if (hour >= 15 && hour < 18) {
      return 'sore';
    } else {
      return 'malam';
    }
  }

  Map<String, dynamic> _getGreetingInfo(String phase) {
    switch (phase) {
      case 'pagi':
        return {'text': 'Selamat Pagi', 'icon': Icons.wb_twilight};
      case 'siang':
        return {'text': 'Selamat Siang', 'icon': Icons.wb_sunny};
      case 'sore':
        return {'text': 'Selamat Sore', 'icon': Icons.wb_sunny_outlined};
      default:
        return {'text': 'Selamat Malam', 'icon': Icons.nightlight_round};
    }
  }

  List<Color> _getSkyColors(String phase) {
    switch (phase) {
      case 'pagi':
        return [
          const Color(0xFF003D79),
          const Color(0xFF0077C8),
          const Color(0xFF64B5F6)
        ];
      case 'siang':
        return [
          const Color(0xFF003D79),
          const Color(0xFF0060AF),
          const Color(0xFF0091EA)
        ];
      case 'sore':
        return [
          const Color(0xFF003366),
          const Color(0xFF4A4E8C),
          const Color(0xFFE65100)
        ];
      default:
        return [
          const Color(0xFF030E21),
          const Color(0xFF00264D),
          const Color(0xFF003D79)
        ];
    }
  }

  List<Widget> _buildSkyElements(String phase) {
    if (phase == 'pagi') {
      return [
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0.18, -0.35),
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD54F).withOpacity(0.28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withOpacity(0.45),
                    blurRadius: 28,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.wb_sunny_rounded,
                    color: Color(0xFFFFCA28), size: 38),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(-0.08, -0.75),
            child: Icon(Icons.cloud,
                color: Colors.white.withOpacity(0.22), size: 42),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0.38, -0.18),
            child: Icon(Icons.cloud,
                color: Colors.white.withOpacity(0.32), size: 38),
          ),
        ),
      ];
    } else if (phase == 'siang') {
      return [
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0.18, -0.72),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amberAccent.withOpacity(0.25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellowAccent.withOpacity(0.4),
                    blurRadius: 26,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.wb_sunny, color: Color(0xFFFFEE58), size: 40),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(-0.06, -0.35),
            child: Icon(Icons.cloud,
                color: Colors.white.withOpacity(0.26), size: 46),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0.40, -0.65),
            child: Icon(Icons.cloud,
                color: Colors.white.withOpacity(0.18), size: 34),
          ),
        ),
      ];
    } else if (phase == 'sore') {
      return [
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0.18, -0.30),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF7043).withOpacity(0.3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withOpacity(0.55),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.wb_sunny_rounded,
                    color: Color(0xFFFF8A65), size: 42),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(-0.08, -0.70),
            child: Icon(Icons.cloud,
                color: const Color(0xFFFFCCBC).withOpacity(0.25), size: 44),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0.38, -0.15),
            child: Icon(Icons.cloud,
                color: const Color(0xFFFFAB91).withOpacity(0.35), size: 40),
          ),
        ),
      ];
    } else {
      return [
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0.18, -0.68),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.shade100.withOpacity(0.12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.shade100.withOpacity(0.25),
                    blurRadius: 22,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.nightlight_round,
                    color: Color(0xFFFFF59D), size: 32),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: Align(
            alignment: Alignment(-0.08, -0.78),
            child: Icon(Icons.star_rounded, color: Color(0xFFFFF9C4), size: 14),
          ),
        ),
        const Positioned.fill(
          child: Align(
            alignment: Alignment(-0.18, -0.35),
            child: Icon(Icons.star_rounded, color: Colors.white70, size: 10),
          ),
        ),
        const Positioned.fill(
          child: Align(
            alignment: Alignment(0.36, -0.75),
            child: Icon(Icons.star_rounded, color: Color(0xFFFFF59D), size: 12),
          ),
        ),
        const Positioned.fill(
          child: Align(
            alignment: Alignment(0.02, -0.22),
            child: Icon(Icons.star_rounded, color: Colors.white54, size: 11),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0.34, -0.32),
            child: Icon(Icons.cloud,
                color: Colors.white.withOpacity(0.14), size: 42),
          ),
        ),
      ];
    }
  }

  String _getTodayDate() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  ImageProvider _buildAvatarImage(String fotoUrl) {
    if (fotoUrl.startsWith('data:image')) {
      try {
        final base64Str = fotoUrl.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {}
    }
    return NetworkImage(fotoUrl);
  }

  bool _checkAvailable(dynamic status) {
    return (status ?? '').toString().trim().toLowerCase() == 'available';
  }

  Widget _buildCardImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Str = imageUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
          gaplessPlayback: true, // Mencegah gambar berkedip/refresh saat scroll
        );
      } catch (_) {
        return _fallbackCardImage();
      }
    }

    return Image.network(
      imageUrl,
      height: 100,
      width: double.infinity,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _fallbackCardImage(),
    );
  }

  Widget _fallbackCardImage() {
    return Container(
      height: 100,
      width: double.infinity,
      color: const Color(0xFFE3F2FD),
      alignment: Alignment.center,
      child: const Icon(Icons.devices, size: 36, color: bcaBlue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final timePhase = _getTimePhase();
    final greetingInfo = _getGreetingInfo(timePhase);
    final skyColors = _getSkyColors(timePhase);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: skyColors.first,
        foregroundColor: Colors.white,
        title: const Text(
          'Inventaris Lab RPL',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 95),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. HEADER LANGIT REAL-TIME
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: skyColors,
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Stack(
                children: [
                  ..._buildSkyElements(timePhase),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
                    child: Column(
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: user != null
                              ? FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .snapshots()
                              : null,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return ShimmerSkeleton(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          SkeletonBox(width: 140, height: 12),
                                          SizedBox(height: 8),
                                          SkeletonBox(width: 180, height: 22),
                                          SizedBox(height: 8),
                                          SkeletonBox(
                                              width: 90,
                                              height: 20,
                                              radius: 8),
                                        ],
                                      ),
                                    ),
                                    const SkeletonBox(
                                        width: 56, height: 56, radius: 28),
                                  ],
                                ),
                              );
                            }

                            String userName = 'Siswa';
                            String userClass = '-';
                            String userFoto =
                                'https://ui-avatars.com/api/?name=Siswa&background=00AEEF&color=fff';

                            if (snapshot.hasData && snapshot.data!.exists) {
                              final userData = snapshot.data!.data()
                                  as Map<String, dynamic>;
                              userName = userData['name'] ?? 'Siswa';
                              userClass = userData['kelas'] ?? '-';
                              userFoto = userData['foto'] ??
                                  'https://ui-avatars.com/api/?name=$userName&background=00AEEF&color=fff';
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            greetingInfo['icon'],
                                            color: Colors.amberAccent,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${greetingInfo['text']} • ${_getTodayDate()}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        userName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.22),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.35),
                                          ),
                                        ),
                                        child: Text(
                                          'Kelas $userClass',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                  child: CircleAvatar(
                                    radius: 27,
                                    backgroundColor: Colors.white,
                                    backgroundImage:
                                        _buildAvatarImage(userFoto),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // SEARCH BAR
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau kode alat...',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade500, fontSize: 14),
                            prefixIcon:
                                const Icon(Icons.search, color: bcaBlue),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. AUTO-SCROLL CAROUSEL BANNER (Tanpa Tombol Next/Prev + Tetap Bisa Geser Manual)
            SizedBox(
              height: 160,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification &&
                      notification.dragDetails != null) {
                    _isUserScrollingBanner = true;
                  } else if (notification is ScrollEndNotification) {
                    _isUserScrollingBanner = false;
                  }
                  return true; // Menahan gestur agar tidak bentrok dengan swipe pindah tab
                },
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    // Hanya update ValueNotifier tanpa memicu rebuild seluruh HomeScreen
                    _currentBannerNotifier.value = index;
                  },
                  itemCount: _banners.length,
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: bcaNavy,
                        image: DecorationImage(
                          image: NetworkImage(banner['image']!),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            bcaNavy.withOpacity(0.55),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner['subtitle']!,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Indikator Titik Banner (Hanya indikator ini yang animasi tanpa refresh halaman)
            ValueListenableBuilder<int>(
              valueListenable: _currentBannerNotifier,
              builder: (context, currentBanner, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _banners.length,
                    (index) => GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        width: currentBanner == index ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: currentBanner == index
                              ? bcaBlue
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // 3. DATA FIRESTORE (Terisolasi dari animasi banner)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('items').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const HomeSectionSkeleton();
                }

                final allDocs = snapshot.data?.docs ?? [];

                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                      (data['item_name'] ?? '').toString().toLowerCase();
                  final code = (data['code'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '').toString();

                  final matchesSearch =
                      name.contains(_searchQuery.toLowerCase()) ||
                          code.contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == null ||
                      category == _selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                final availableDocs = filteredDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _checkAvailable(data['status']);
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      _selectedCategory == null
                          ? 'Semua Data Alat'
                          : 'Data Alat: $_selectedCategory',
                    ),
                    _buildHorizontalItemList(filteredDocs),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('Kategori Peralatan'),
                        if (_selectedCategory != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _selectedCategory = null),
                              child: const Text(
                                'Reset Filter',
                                style: TextStyle(color: bcaBlue),
                              ),
                            ),
                          ),
                      ],
                    ),
                    _buildHorizontalCategoryList(allDocs),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Status: Available (Tersedia)'),
                    _buildHorizontalItemList(availableDocs),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: bcaNavy,
        ),
      ),
    );
  }

  Widget _buildHorizontalItemList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child:
            Text('Data tidak ditemukan.', style: TextStyle(color: Colors.grey)),
      );
    }

    return SizedBox(
      height: 195,
      child: NotificationListener<ScrollNotification>(
        // Menahan gestur scroll horizontal agar tidak menarik PageView utama
        onNotification: (_) => true,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final docId = docs[index].id;
            final data = docs[index].data() as Map<String, dynamic>;
            final isAvailable = _checkAvailable(data['status']);

            return GestureDetector(
              key: ValueKey(docId),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailScreen(
                      docId: docId,
                      itemData: data,
                    ),
                  ),
                );
              },
              child: Container(
                width: 155,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: bcaNavy.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14)),
                      child: _buildCardImage((data['image'] ?? '').toString()),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['item_name'] ?? 'Tanpa Nama',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: bcaNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['code'] ?? '-',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? const Color(0xFFE3F2FD)
                                  : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (data['status'] ?? '-').toString().trim(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isAvailable
                                    ? bcaBlue
                                    : Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHorizontalCategoryList(List<QueryDocumentSnapshot> docs) {
    final categories = docs
        .map((doc) =>
            (doc.data() as Map<String, dynamic>)['category']?.toString() ??
            'Umum')
        .toSet()
        .toList();

    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child:
            Text('Belum ada kategori.', style: TextStyle(color: Colors.grey)),
      );
    }

    return SizedBox(
      height: 46,
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) => true,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategory == category;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = isSelected ? null : category;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? bcaCyan : bcaBlue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: bcaCyan.withOpacity(0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}