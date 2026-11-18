import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/skeleton_loader.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  static const Color bcaNavy = Color(0xFF003D79);
  static const Color bcaBlue = Color(0xFF0060AF);
  static const Color bcaCyan = Color(0xFF00AEEF);

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Baru saja';
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickAndUploadImage(String uid) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 65,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final Uint8List imageBytes = await pickedFile.readAsBytes();
      final String base64Image =
          'data:image/jpeg;base64,${base64Encode(imageBytes)}';

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'foto': base64Image,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: bcaNavy,
          content: Text('Foto profil berhasil diperbarui!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showPhotoOptions(BuildContext context, String uid, String currentFoto) {
    HapticFeedback.selectionClick();
    final urlController = TextEditingController(
      text: currentFoto.startsWith('http') ? currentFoto : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ubah Foto Profil',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: bcaNavy),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: bcaBlue,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Pilih dari Galeri / File'),
                subtitle: const Text('Upload gambar langsung dari perangkat'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(uid);
                },
              ),
              const Divider(height: 24),
              const Text(
                'Atau masukkan URL Gambar:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: urlController,
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bcaNavy,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (urlController.text.trim().isEmpty) return;
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({'foto': urlController.text.trim()});
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  ImageProvider _buildProfileImage(String fotoUrl) {
    if (fotoUrl.startsWith('data:image')) {
      final base64Str = fotoUrl.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    }
    return NetworkImage(fotoUrl);
  }

  Future<void> _kembalikanAlat(
    BuildContext context,
    DocumentReference borrowDocRef,
    String itemId,
    String itemName,
  ) async {
    HapticFeedback.lightImpact();
    try {
      final directDoc =
          FirebaseFirestore.instance.collection('items').doc(itemId);
      final directSnap = await directDoc.get();
      if (directSnap.exists) {
        await directDoc.update({'status': 'Available'});
      } else {
        final query = await FirebaseFirestore.instance
            .collection('items')
            .where('item_id', isEqualTo: itemId)
            .get();
        for (var doc in query.docs) {
          await doc.reference.update({'status': 'Available'});
        }
      }

      await borrowDocRef.update({
        'is_returned': true,
        'return_date': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: bcaNavy,
          content:
              Text('$itemName berhasil dikembalikan & dicatat ke riwayat!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengembalikan: $e')),
      );
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String count,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: bcaNavy.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: accentColor, size: 22),
            const SizedBox(height: 4),
            Text(
              count,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: bcaNavy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowList({
    required List<QueryDocumentSnapshot> docs,
    required bool isHistoryTab,
  }) {
    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHistoryTab
                      ? Icons.history_rounded
                      : Icons.inventory_2_outlined,
                  size: 40,
                  color: bcaBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isHistoryTab
                    ? 'Belum ada riwayat peminjaman'
                    : 'Tidak ada tanggungan alat',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: bcaNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isHistoryTab
                    ? 'Alat yang sudah kamu kembalikan akan tercatat rapi di sini.'
                    : 'Semua alat sudah dikembalikan. Kamu bisa meminjam alat baru di menu Beranda atau Inventaris.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: bcaNavy.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data['item_name'] ?? 'Alat Tanpa Nama',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: bcaNavy,
                        ),
                      ),
                    ),
                    if (!isHistoryTab)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bcaBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _kembalikanAlat(
                          context,
                          doc.reference,
                          data['item_id'] ?? '',
                          data['item_name'] ?? 'Alat',
                        ),
                        child: const Text('Kembalikan',
                            style: TextStyle(fontSize: 12)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Dikembalikan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: bcaBlue,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Keperluan: ${data['keperluan'] ?? '-'}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tanggal Pinjam: ${_formatDate(data['borrow_date'] as Timestamp?).split(' ').first} '
                  '(${data['jam_pinjam'] ?? '-'})',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (!isHistoryTab && data['batas_kembali'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Batas Kembali: Pukul ${data['batas_kembali']} WIB',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
                if (isHistoryTab && data['return_date'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Dikembalikan pada: ${_formatDate(data['return_date'] as Timestamp?)}',
                    style: const TextStyle(fontSize: 12, color: bcaBlue),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User tidak ditemukan')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: bcaNavy,
          foregroundColor: Colors.white,
          title: const Text('Profil Siswa',
              style: TextStyle(fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('borrowings')
              .orderBy('borrow_date', descending: true)
              .snapshots(),
          builder: (context, borrowSnapshot) {
            final allBorrowDocs = borrowSnapshot.data?.docs ?? [];

            final unreturnedDocs = allBorrowDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['is_returned'] != true;
            }).toList();

            final historyDocs = allBorrowDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['is_returned'] == true;
            }).toList();

            return Column(
              children: [
                // 1. HEADER IDENTITAS SISWA DENGAN SKELETON
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [bcaNavy, bcaBlue],
                          ),
                          borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(26)),
                        ),
                        child: ShimmerSkeleton(
                          child: Row(
                            children: [
                              const SkeletonBox(
                                  width: 78, height: 78, radius: 39),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    SkeletonBox(width: 160, height: 20),
                                    SizedBox(height: 8),
                                    SkeletonBox(width: 190, height: 12),
                                    SizedBox(height: 10),
                                    SkeletonBox(
                                        width: 90, height: 22, radius: 10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final userData =
                        snapshot.data?.data() as Map<String, dynamic>? ?? {};
                    final name = userData['name'] ?? 'Nama Siswa';
                    final kelas = userData['kelas'] ?? '-';
                    final email = userData['email'] ?? user.email ?? '-';
                    final foto = userData['foto'] ??
                        'https://ui-avatars.com/api/?name=$name&background=00AEEF&color=fff';

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [bcaNavy, bcaBlue],
                        ),
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(26)),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _isUploading
                                ? null
                                : () =>
                                    _showPhotoOptions(context, user.uid, foto),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: bcaCyan,
                                  ),
                                  child: CircleAvatar(
                                    radius: 38,
                                    backgroundColor: Colors.white,
                                    backgroundImage: _buildProfileImage(foto),
                                    child: _isUploading
                                        ? const CircularProgressIndicator()
                                        : null,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: bcaCyan,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: bcaCyan.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: bcaCyan.withOpacity(0.6)),
                                  ),
                                  child: Text(
                                    'Kelas $kelas',
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
                        ],
                      ),
                    );
                  },
                ),

                // 2. STATISTIK RINGKAS PEMINJAMAN
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.pending_actions_rounded,
                        label: 'Dipinjam',
                        count: '${unreturnedDocs.length}',
                        accentColor: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Selesai',
                        count: '${historyDocs.length}',
                        accentColor: bcaBlue,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        icon: Icons.bar_chart_rounded,
                        label: 'Total Pinjam',
                        count: '${allBorrowDocs.length}',
                        accentColor: bcaCyan,
                      ),
                    ],
                  ),
                ),

                // 3. TAB BAR
                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: bcaNavy,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: bcaBlue,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(
                        text: 'Belum Kembali (${unreturnedDocs.length})',
                      ),
                      Tab(
                        text: 'Riwayat (${historyDocs.length})',
                      ),
                    ],
                  ),
                ),

                // 4. ISI TAB DENGAN SKELETON LOADER
                Expanded(
                  child: borrowSnapshot.connectionState ==
                          ConnectionState.waiting
                      ? const VerticalListSkeleton(itemCount: 3)
                      : TabBarView(
                          children: [
                            _buildBorrowList(
                                docs: unreturnedDocs, isHistoryTab: false),
                            _buildBorrowList(
                                docs: historyDocs, isHistoryTab: true),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}