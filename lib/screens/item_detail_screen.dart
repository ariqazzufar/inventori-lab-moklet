import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/skeleton_loader.dart';

class ItemDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> itemData;

  const ItemDetailScreen({
    super.key,
    required this.docId,
    required this.itemData,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _isLoading = false;
  final TextEditingController _keperluanController = TextEditingController();

  static const Color bcaNavy = Color(0xFF003D79);
  static const Color bcaBlue = Color(0xFF0060AF);

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 14, minute: 0);

  bool _checkAvailable(dynamic status) {
    return (status ?? '').toString().trim().toLowerCase() == 'available';
  }

  String _getDeadlineString(TimeOfDay end) {
    final totalMinutes = end.hour * 60 + end.minute + 30;
    final deadlineHour = (totalMinutes ~/ 60) % 24;
    final deadlineMinute = totalMinutes % 60;
    return '${deadlineHour.toString().padLeft(2, '0')}:${deadlineMinute.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateOnly(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTimestampDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Widget _buildDetailImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Str = imageUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (_) {
        return _fallbackImage();
      }
    }

    return Image.network(
      imageUrl,
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallbackImage(),
    );
  }

  Widget _fallbackImage() {
    return Container(
      height: 220,
      width: double.infinity,
      color: const Color(0xFFE3F2FD),
      child: const Icon(Icons.devices, size: 72, color: bcaBlue),
    );
  }

  Future<void> _ajukanPinjam() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu!')),
      );
      return;
    }

    if (_keperluanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Harap isi keperluan peminjaman terlebih dahulu!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final borrowDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final jamMulaiStr = _formatTime(_startTime);
      final jamSelesaiStr = _formatTime(_endTime);
      final batasKembaliStr = _getDeadlineString(_endTime);

      final borrowRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('borrowings')
          .doc();

      await borrowRef.set({
        'borrow_id': borrowRef.id,
        'item_id': widget.itemData['item_id'] ?? widget.docId,
        'item_name': widget.itemData['item_name'] ?? 'Tanpa Nama',
        'borrow_date': Timestamp.fromDate(borrowDateTime),
        'keperluan': _keperluanController.text.trim(),
        'jam_pinjam': '$jamMulaiStr - $jamSelesaiStr',
        'batas_kembali': batasKembaliStr,
        'is_returned': false,
      });

      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.docId)
          .update({'status': 'Borrowed'});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: bcaNavy,
          content: Text(
            'Berhasil meminjam! Wajib dikembalikan maksimal pukul $batasKembaliStr WIB.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengajukan pinjam: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildActiveBorrowerInfo() {
    final targetItemId =
        (widget.itemData['item_id'] ?? widget.docId).toString();
    final targetItemName = (widget.itemData['item_name'] ?? '').toString();

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collectionGroup('borrowings').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BorrowerInfoSkeleton();
        }

        final docs = snapshot.data?.docs ?? [];

        QueryDocumentSnapshot? activeBorrowDoc;
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final isNotReturned = data['is_returned'] != true;
          final matchesId =
              data['item_id'] == targetItemId || data['item_id'] == widget.docId;
          final matchesName = data['item_name'] == targetItemName;

          if (isNotReturned && (matchesId || matchesName)) {
            activeBorrowDoc = doc;
            break;
          }
        }

        if (activeBorrowDoc == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Text(
              'Alat ini sedang berstatus Borrowed.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          );
        }

        final borrowData = activeBorrowDoc.data() as Map<String, dynamic>;
        final userDocRef = activeBorrowDoc.reference.parent.parent;

        return FutureBuilder<DocumentSnapshot>(
          future: userDocRef?.get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const BorrowerInfoSkeleton();
            }

            String borrowerName = 'Tanpa Nama';
            String borrowerClass = '-';

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              borrowerName = userData['name'] ?? 'Tanpa Nama';
              borrowerClass = userData['kelas'] ?? '-';
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bcaBlue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: bcaNavy, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Informasi Peminjam Saat Ini',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: bcaNavy,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  _buildInfoRow(
                      Icons.person, 'Peminjam', '$borrowerName ($borrowerClass)'),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.edit_note,
                    'Keperluan',
                    (borrowData['keperluan'] ?? '-').toString(),
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Jadwal',
                    '${_formatTimestampDate(borrowData['borrow_date'] as Timestamp?)} '
                        '(${borrowData['jam_pinjam'] ?? '-'})',
                  ),
                  if (borrowData['batas_kembali'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'Estimasi Kembali: Pukul ${borrowData['batas_kembali']} WIB',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: bcaBlue),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _keperluanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = _checkAvailable(widget.itemData['status']);
    final batasKembali = _getDeadlineString(_endTime);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bcaNavy,
        foregroundColor: Colors.white,
        title: const Text('Detail Inventaris'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailImage((widget.itemData['image'] ?? '').toString()),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.itemData['item_name'] ?? 'Tanpa Nama',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: bcaNavy,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? const Color(0xFFE3F2FD)
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (widget.itemData['status'] ?? '-').toString().trim(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isAvailable ? bcaBlue : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kode Serial',
                                style: TextStyle(color: Colors.grey)),
                            Text(
                              widget.itemData['code'] ?? '-',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kategori',
                                style: TextStyle(color: Colors.grey)),
                            Text(
                              widget.itemData['category'] ?? '-',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Spesifikasi Alat',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: bcaNavy),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      widget.itemData['spesification'] ??
                          'Tidak ada keterangan spesifikasi.',
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isAvailable) ...[
                    const Text(
                      'Formulir Peminjaman',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: bcaNavy),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _keperluanController,
                      decoration: InputDecoration(
                        labelText: 'Keperluan Peminjaman',
                        hintText: 'Contoh: Praktikum Pemrograman Mobile',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon:
                            const Icon(Icons.edit_note, color: bcaBlue),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 20, color: bcaBlue),
                                const SizedBox(width: 10),
                                Text(
                                  'Tanggal: ${_formatDateOnly(_selectedDate)}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const Text(
                              'Ubah',
                              style: TextStyle(
                                  color: bcaBlue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(isStart: true),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Jam Mulai',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 18, color: bcaBlue),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatTime(_startTime),
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(isStart: false),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Jam Selesai',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_filled,
                                          size: 18, color: bcaBlue),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatTime(_endTime),
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.amber.shade900, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Toleransi pengembalian 30 menit. Alat sudah harus dikembalikan maksimal pukul $batasKembali WIB.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _buildActiveBorrowerInfo(),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isAvailable ? bcaNavy : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          (isAvailable && !_isLoading) ? _ajukanPinjam : null,
                      icon: Icon(isAvailable
                          ? Icons.assignment_turned_in
                          : Icons.lock_clock),
                      label: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isAvailable
                                  ? 'Pengajuan Pinjam'
                                  : 'Sedang Dipinjam (Borrowed)',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
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
  }
}