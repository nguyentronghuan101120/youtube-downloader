import 'package:flutter/material.dart';
import 'package:youtube_downloader_flutter/utils/enums/select_status.dart';
import 'package:youtube_downloader_flutter/utils/models/video_info_model.dart';

class PlaylistViewScreen extends StatefulWidget {
  final List<VideoInfoModel> videos;
  final Function(List<String> selectedUrls)? onSubmit;

  const PlaylistViewScreen({
    super.key,
    required this.videos,
    this.onSubmit,
  });

  @override
  State<PlaylistViewScreen> createState() => _PlaylistViewScreenState();
}

class _PlaylistViewScreenState extends State<PlaylistViewScreen> {
  late List<VideoInfoModel> _filteredVideos;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUrls = {};
  SelectStatus _selectStatus = SelectStatus.none;

  @override
  void initState() {
    super.initState();
    _filteredVideos = widget.videos;
    _searchController.addListener(_filterVideos);
    _updateSelectStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterVideos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVideos = widget.videos.where((video) {
        return video.title?.toLowerCase().contains(query) ?? false;
      }).toList();
    });
  }

  void _toggleSelection(String url) {
    setState(() {
      if (_selectedUrls.contains(url)) {
        _selectedUrls.remove(url);
      } else {
        _selectedUrls.add(url);
      }
      _updateSelectStatus();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectStatus == SelectStatus.all) {
        _selectedUrls.clear();
      } else {
        _selectedUrls.clear();
        _selectedUrls.addAll(_filteredVideos.map((video) => video.url!));
      }
      _updateSelectStatus();
    });
  }

  void _updateSelectStatus() {
    if (_selectedUrls.isEmpty) {
      _selectStatus = SelectStatus.none;
    } else if (_selectedUrls.length == _filteredVideos.length) {
      _selectStatus = SelectStatus.all;
    } else {
      _selectStatus = SelectStatus.some;
    }
  }

  void _submitSelection() {
    if (widget.onSubmit != null) {
      widget.onSubmit!(_selectedUrls.toList());
    }
    Navigator.pop(context, _selectedUrls.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Videos from Playlist'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search videos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _selectStatus.value,
                  tristate: true,
                  onChanged: (_) => _toggleSelectAll(),
                ),
                Text('${_selectedUrls.length} selected'),
                const Spacer(),
                Text('${_filteredVideos.length} videos found'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemCount: _filteredVideos.length,
                itemBuilder: (context, index) {
                  final video = _filteredVideos[index];
                  final isSelected = _selectedUrls.contains(video.url);
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          video.thumbnailUrl != null &&
                                  video.thumbnailUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16.0),
                                  child: Image.network(
                                    video.thumbnailUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image,
                                                size: 45),
                                  ),
                                )
                              : const Icon(Icons.video_library, size: 45),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.title ?? 'Untitled',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDuration(video.duration ?? 0),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(video.url!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _selectedUrls.isEmpty ? null : _submitSelection,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                'Submit (${_selectedUrls.length} selected)',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
