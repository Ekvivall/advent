import 'dart:io';
import 'package:advent/data/advent_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/advent_model.dart';
import 'gift_dialog.dart';

class EditDayDialog extends StatefulWidget {
  final AdventDay day;

  const EditDayDialog({super.key, required this.day});

  @override
  State<EditDayDialog> createState() => _EditDayDialogState();
}

class _EditDayDialogState extends State<EditDayDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late bool _hasGift;
  bool _isLoading = false;

  File? _pickedImageFile;
  final ImagePicker _imagePicker = ImagePicker();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  late String _currentAudioUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.day.title);
    _descController = TextEditingController(text: widget.day.description);
    _hasGift = widget.day.hasGift;
    _currentAudioUrl = widget.day.audioUrl;

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (_currentAudioUrl.isEmpty) return;

    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
    } else {
      try {
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play(UrlSource(_currentAudioUrl));
        setState(() => _isPlaying = true);
      } catch (e) {
        _showError("Не вдалося відтворити: $e");
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _pickedImageFile = File(image.path);
      });
    }
  }

  Future<void> _pickAndUploadAudio() async {
    if (_isPlaying) await _toggleAudio();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      _uploadAudioImmediately(File(result.files.single.path!));
    }
  }

  Future<void> _uploadAudioImmediately(File file) async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<AdventService>();
      String url = await repo.uploadAudio(file);

      await repo.updateDayData(widget.day.id, {'audioUrl': url});

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Музику збережено! 🎵")));

        setState(() {
          _currentAudioUrl = url;
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAllChanges() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<AdventService>();
      String currentImageUrl = widget.day.hintImageUrl;

      if (_pickedImageFile != null) {
        currentImageUrl = await repo.uploadFile(_pickedImageFile!, 'images');
      }

      await repo.updateDayData(widget.day.id, {
        'title': _titleController.text,
        'description': _descController.text,
        'hasGift': _hasGift,
        'hintImageUrl': currentImageUrl,
        'audioUrl': _currentAudioUrl,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError("Помилка збереження: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasOldImage = widget.day.hintImageUrl.isNotEmpty;
    bool hasAudio = _currentAudioUrl.isNotEmpty;

    return AlertDialog(
      title: Text("Редагування: День ${widget.day.dayNum}"),
      scrollable: true,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Заголовок",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Текст",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Фізичний подарунок?",
                style: TextStyle(fontSize: 14),
              ),
              value: _hasGift,
              onChanged: (val) => setState(() => _hasGift = val),
              activeColor: Colors.green,
            ),
            const Divider(),

            const Text(
              "📸 Картинка:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Center(child: _buildImagePreview(hasOldImage)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(
                      _pickedImageFile != null
                          ? "Змінити вибір"
                          : (hasOldImage
                          ? "Замінити старе фото"
                          : "Вибрати фото"),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            const Text(
              "🎵 Музика:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickAndUploadAudio,
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      hasAudio ? "Змінити трек" : "Завантажити",
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[50],
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                if (hasAudio)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _toggleAudio,
                      icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                      label: Text(_isPlaying ? "Стоп" : "Play"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPlaying ? Colors.red[50] : Colors.green[50],
                        foregroundColor: _isPlaying ? Colors.red : Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
              ],
            ),
            if (hasAudio && !_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text("Аудіофайл прикріплено", style: TextStyle(fontSize: 12, color: Colors.green)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _showPreview,
          icon: const Icon(Icons.visibility, color: Colors.blue),
          label: const Text("Тест"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Скасувати"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAllChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Text(
            "ЗБЕРЕГТИ ВСЕ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(bool hasOldImage) {
    if (_pickedImageFile != null) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _pickedImageFile!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(4.0),
            child: Text(
              "Нове фото (ще не збережено)",
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
        ],
      );
    } else if (hasOldImage) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.day.hintImageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, o, s) => Container(
                height: 180,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(4.0),
            child: Text(
              "Поточне збережене фото",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      );
    } else {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.grey,
          size: 40,
        ),
      );
    }
  }

  void _showPreview() {
    final previewDay = AdventDay(
      id: widget.day.id,
      dayNum: widget.day.dayNum,
      title: _titleController.text,
      description: _descController.text,
      hintImageUrl: widget.day.hintImageUrl,
      hasGift: _hasGift,
      isFound: false,
      audioUrl: _currentAudioUrl,
    );

    showDialog(
      context: context,
      builder: (_) => GiftDialog(
        day: previewDay,
        previewImage: _pickedImageFile,
        isPreview: true,
      ),
    );
  }
}