import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/skeleton_loader.dart';
import 'item_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'Semua';

  static const Color bcaNavy = Color(0xFF003D79);
  static const Color bcaBlue = Color(0xFF0060AF);
  static const Color bcaCyan = Color(0xFF00AEEF);

  static final Map<int, Uint8List> _base64Cache = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildItemImage(String imageUrl,
      {double width = 60, double height = 60}) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final int cacheKey = imageUrl.hashCode;
        final Uint8List bytes = _base64Cache.putIfAbsent(
          cacheKey,
          () => base64Decode(imageUrl.split(',').last),
        );
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      } catch (_) {
        return _fallbackImage(width, height);
      }
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _fallbackImage(width, height),
    );
  }

  Widget _fallbackImage(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE3F2FD),
      alignment: Alignment.center,
      child: const Icon(Icons.devices, color: bcaBlue),
    );
  }

  InputDecoration _myBcaInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      prefixIcon: Icon(icon, color: bcaBlue, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: bcaBlue, width: 1.8),
      ),
    );
  }

  void _showItemFormDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? existingData,
  }) {
    HapticFeedback.selectionClick();
    final isEdit = docId != null;
    final nameController =
        TextEditingController(text: existingData?['item_name'] ?? '');
    final categoryController =
        TextEditingController(text: existingData?['category'] ?? '');
    final codeController =
        TextEditingController(text: existingData?['code'] ?? '');
    final imageController = TextEditingController(
      text: (existingData?['image'] ?? '').toString().startsWith('http')
          ? existingData!['image']
          : '',
    );
    final specController =
        TextEditingController(text: existingData?['spesification'] ?? '');
    String status = existingData?['status'] ?? 'Available';
    String currentImageValue = existingData?['image'] ?? '';
    bool isPickingImage = false;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> pickImage() async {
              try {
                final picker = ImagePicker();
                final XFile? picked = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 500,
                  maxHeight: 500,
                  imageQuality: 65,
                );
                if (picked == null) return;

                setStateDialog(() => isPickingImage = true);
                final Uint8List bytes = await picked.readAsBytes();
                final String base64Str =
                    'data:image/jpeg;base64,${base64Encode(bytes)}';

                setStateDialog(() {
                  currentImageValue = base64Str;
                  imageController.clear();
                  isPickingImage = false;
                });
              } catch (e) {
                setStateDialog(() => isPickingImage = false);
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. HEADER DIALOG GRADASI BIRU myBCA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [bcaNavy, bcaBlue],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEdit
                                  ? Icons.edit_note_rounded
                                  : Icons.add_box_rounded,
                              color: bcaCyan,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit
                                      ? 'Edit Alat Inventaris'
                                      : 'Tambah Alat Baru',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Lengkapi informasi perangkat lab',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    // 2. ISI FORMULIR DENGAN KOTAK INPUT SERAGAM
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Preview Gambar
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: bcaBlue.withOpacity(0.2),
                                    width: 1.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14.5),
                                child: currentImageValue.isNotEmpty
                                    ? _buildItemImage(currentImageValue,
                                        width: double.infinity, height: 135)
                                    : Container(
                                        height: 135,
                                        width: double.infinity,
                                        color: const Color(0xFFEBF3FA),
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.image_outlined,
                                                size: 40, color: bcaBlue),
                                            SizedBox(height: 6),
                                            Text(
                                              'Pratinjau Foto Perangkat',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: bcaNavy,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Tombol Upload Galeri
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: bcaBlue,
                                  backgroundColor: const Color(0xFFF0F6FC),
                                  side: BorderSide(
                                      color: bcaBlue.withOpacity(0.45)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isPickingImage ? null : pickImage,
                                icon: const Icon(Icons.upload_file_rounded,
                                    size: 19),
                                label: Text(
                                  isPickingImage
                                      ? 'Memproses Foto...'
                                      : 'Pilih Foto dari Galeri',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            TextField(
                              controller: imageController,
                              onChanged: (val) {
                                setStateDialog(() {
                                  currentImageValue = val.trim();
                                });
                              },
                              decoration: _myBcaInputDecoration(
                                label: 'Atau Paste URL Gambar',
                                hint: 'https://...',
                                icon: Icons.link_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: nameController,
                              decoration: _myBcaInputDecoration(
                                label: 'Nama Alat',
                                hint: 'Contoh: Router Mikrotik RB941',
                                icon: Icons.devices_other_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: categoryController,
                              decoration: _myBcaInputDecoration(
                                label: 'Kategori',
                                hint: 'Contoh: Networking / Tools',
                                icon: Icons.category_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: codeController,
                              decoration: _myBcaInputDecoration(
                                label: 'Kode Serial / Rak',
                                hint: 'Contoh: LAB-5(ROBOTIK)-01',
                                icon: Icons.qr_code_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),

                            DropdownButtonFormField<String>(
                              value:
                                  (status == 'Available' || status == 'Borrowed')
                                      ? status
                                      : 'Available',
                              decoration: _myBcaInputDecoration(
                                label: 'Status Ketersediaan',
                                icon: Icons.check_circle_outline_rounded,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Available',
                                    child: Text('Available (Tersedia)')),
                                DropdownMenuItem(
                                    value: 'Borrowed',
                                    child: Text('Borrowed (Dipinjam)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setStateDialog(() => status = val);
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: specController,
                              maxLines: 2,
                              decoration: _myBcaInputDecoration(
                                label: 'Spesifikasi Alat',
                                hint: 'Keterangan detail atau kelengkapan...',
                                icon: Icons.description_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. FOOTER TOMBOL AKSI SERAGAM
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Batal',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: isSaving
                                  ? null
                                  : () async {
                                      if (nameController.text.trim().isEmpty) {
                                        return;
                                      }
                                      HapticFeedback.lightImpact();
                                      setStateDialog(() => isSaving = true);

                                      final itemsCollection = FirebaseFirestore
                                          .instance
                                          .collection('items');
                                      final finalImage = currentImageValue
                                              .isNotEmpty
                                          ? currentImageValue
                                          : 'https://images.pexels.com/photos/1181244/pexels-photo-1181244.jpeg?auto=compress&cs=tinysrgb&w=600';

                                      if (isEdit) {
                                        await itemsCollection
                                            .doc(docId)
                                            .update({
                                          'item_name':
                                              nameController.text.trim(),
                                          'category':
                                              categoryController.text.trim(),
                                          'code': codeController.text.trim(),
                                          'status': status,
                                          'image': finalImage,
                                          'spesification':
                                              specController.text.trim(),
                                        });
                                      } else {
                                        final newDoc = itemsCollection.doc();
                                        await newDoc.set({
                                          'item_id': newDoc.id,
                                          'item_name':
                                              nameController.text.trim(),
                                          'category':
                                              categoryController.text.trim(),
                                          'code': codeController.text.trim(),
                                          'status': status,
                                          'image': finalImage,
                                          'spesification':
                                              specController.text.trim(),
                                          'created_at':
                                              FieldValue.serverTimestamp(),
                                        });
                                      }

                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          backgroundColor: bcaNavy,
                                          content: Text(isEdit
                                              ? 'Data berhasil diperbarui!'
                                              : 'Data berhasil ditambahkan!'),
                                        ),
                                      );
                                    },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [bcaNavy, bcaBlue],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: bcaBlue.withOpacity(0.28),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Simpan Data',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
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
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String docId, String itemName) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Konfirmasi Hapus',
                  style: TextStyle(
                      color: bcaNavy,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
          content: Text(
              'Apakah kamu yakin ingin menghapus "$itemName" dari inventaris?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal',
                  style: TextStyle(color: Colors.grey.shade700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('items')
                    .doc(docId)
                    .delete();
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data alat berhasil dihapus')),
                );
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderStat(String label, int count, Color dotColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$count Alat',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bcaNavy,
        foregroundColor: Colors.white,
        title: const Text(
          'Inventaris Alat Lab',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76),
        child: FloatingActionButton.extended(
          backgroundColor: bcaNavy,
          foregroundColor: Colors.white,
          elevation: 6,
          onPressed: () => _showItemFormDialog(context),
          icon: const Icon(Icons.add_rounded, color: bcaCyan),
          label: const Text('Tambah Alat',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('items').snapshots(),
        builder: (context, snapshot) {
          final allDocs = snapshot.data?.docs ?? [];

          final int totalCount = allDocs.length;
          final int availableCount = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? '').toString().trim().toLowerCase() ==
                'available';
          }).length;
          final int borrowedCount = totalCount - availableCount;

          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['item_name'] ?? '').toString().toLowerCase();
            final code = (data['code'] ?? '').toString().toLowerCase();
            final category = (data['category'] ?? '').toString().toLowerCase();
            final status = (data['status'] ?? '').toString().trim();

            final matchesSearch =
                name.contains(_searchQuery.toLowerCase()) ||
                    code.contains(_searchQuery.toLowerCase()) ||
                    category.contains(_searchQuery.toLowerCase());

            final matchesStatus = _statusFilter == 'Semua' ||
                status.toLowerCase() == _statusFilter.toLowerCase();

            return matchesSearch && matchesStatus;
          }).toList();

          return Column(
            children: [
              // 1. HEADER GRADASI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bcaNavy, bcaBlue],
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(26)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildHeaderStat('Total', totalCount, bcaCyan),
                        const SizedBox(width: 8),
                        _buildHeaderStat(
                            'Tersedia', availableCount, Colors.greenAccent),
                        const SizedBox(width: 8),
                        _buildHeaderStat(
                            'Dipinjam', borrowedCount, Colors.amberAccent),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Cari nama, kode, atau kategori alat...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: bcaBlue),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. FILTER CHIP STATUS
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: ['Semua', 'Available', 'Borrowed'].map((label) {
                    final isSelected = _statusFilter == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: bcaBlue,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : bcaNavy,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? bcaBlue
                                : Colors.grey.shade300,
                          ),
                        ),
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _statusFilter = label);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 3. DAFTAR ALAT
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const VerticalListSkeleton(itemCount: 5)
                    : filteredDocs.isEmpty
                        ? const Center(
                            child: Text(
                              'Tidak ada data alat yang sesuai.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 145),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final docId = filteredDocs[index].id;
                              final data = filteredDocs[index].data()
                                  as Map<String, dynamic>;
                              final isAvailable = (data['status'] ?? '')
                                      .toString()
                                      .trim()
                                      .toLowerCase() ==
                                  'available';

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
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
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
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _buildItemImage(data['image'] ?? '',
                                        width: 58, height: 58),
                                  ),
                                  title: Text(
                                    data['item_name'] ?? 'Tanpa Nama',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: bcaNavy),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            data['code'] ?? '-',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isAvailable
                                                ? const Color(0xFFE3F2FD)
                                                : Colors.amber.shade50,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            (data['status'] ?? '-')
                                                .toString()
                                                .trim(),
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
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.edit_rounded,
                                            color: bcaBlue, size: 21),
                                        tooltip: 'Edit',
                                        onPressed: () => _showItemFormDialog(
                                          context,
                                          docId: docId,
                                          existingData: data,
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(Icons.delete_rounded,
                                            color: Colors.red.shade600,
                                            size: 21),
                                        tooltip: 'Hapus',
                                        onPressed: () => _confirmDelete(
                                          context,
                                          docId,
                                          data['item_name'] ?? 'alat ini',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}