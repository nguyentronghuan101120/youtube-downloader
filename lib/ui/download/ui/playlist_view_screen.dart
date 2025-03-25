import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_flutter/ui/common/app_button.dart';
import 'package:youtube_downloader_flutter/ui/download/controller/download_controller.dart';
import 'package:youtube_downloader_flutter/ui/download/ui/video_card.dart';
import 'package:youtube_downloader_flutter/utils/enums/select_status.dart';
import 'package:youtube_downloader_flutter/utils/models/video_info_model.dart';
import 'package:youtube_downloader_flutter/utils/services/show_log_service.dart';

class PlaylistViewScreen extends StatefulWidget {
  final bool isHistoryView;

  const PlaylistViewScreen({
    super.key,
    this.isHistoryView = false,
  });

  @override
  State<PlaylistViewScreen> createState() => _PlaylistViewScreenState();
}

class _PlaylistViewScreenState extends State<PlaylistViewScreen> {
  List<VideoInfoModel> _filteredVideos = [];
  final TextEditingController _searchController = TextEditingController();
  final Set<VideoInfoModel> _selectedVideos = {};
  SelectStatus _selectStatus = SelectStatus.none;
  Timer? _debounce;

  late DownloadController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<DownloadController>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.isHistoryView) {
        await _controller.getHistory();
      }

      _filteredVideos = _controller.playlistVideos;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _filterVideos() {
    final query = _searchController.text.toLowerCase();
    final controller = Provider.of<DownloadController>(context, listen: false);
    setState(() {
      _filteredVideos = controller.playlistVideos
          .where((video) =>
              (video.title?.toLowerCase().contains(query) ?? false) ||
              (video.id?.toLowerCase().contains(query) ?? false))
          .toList();
      _updateSelectionState();
    });
  }

  void _toggleSelection(VideoInfoModel video) {
    setState(() {
      _selectedVideos.contains(video)
          ? _selectedVideos.remove(video)
          : _selectedVideos.add(video);
      _updateSelectionState();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectStatus == SelectStatus.all) {
        _selectedVideos.clear();
      } else {
        _selectedVideos.clear();
        _selectedVideos.addAll(_filteredVideos);
      }
      _updateSelectionState();
    });
  }

  void _updateSelectionState({bool clear = false}) {
    if (clear) {
      _selectedVideos.clear();
    }
    _selectStatus = _selectedVideos.isEmpty
        ? SelectStatus.none
        : _selectedVideos.length == _filteredVideos.length
            ? SelectStatus.all
            : SelectStatus.some;
  }

  void _showConfirmationDialog(String action, Function onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm $action'),
          content:
              Text('Are you sure you want to $action the selected videos?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshVideos() async {
    final controller = Provider.of<DownloadController>(context, listen: false);
    if (widget.isHistoryView) {
      await controller.getHistory();
    }
    setState(() {
      _filteredVideos = controller.playlistVideos;
      _updateSelectionState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.isHistoryView
                ? 'Select Videos from History'
                : 'Select Videos from Playlist'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              if (widget.isHistoryView)
                IconButton(
                  onPressed: () {
                    if (_selectedVideos.isEmpty) {
                      ShowLogService.showLog(
                          context, 'Please select videos to remove');
                      return;
                    }
                    _showConfirmationDialog('remove', () {
                      controller.removeHistory(_selectedVideos.toList());
                      _updateSelectionState(clear: true);
                    });
                  },
                  icon: const Icon(Icons.delete),
                ),
            ],
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
                    suffixIcon: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _filterVideos();
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                  onChanged: (value) {
                    _filterVideos();
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _selectStatus.value,
                      tristate: true,
                      onChanged: (_) => _toggleSelectAll(),
                    ),
                    Text('${_selectedVideos.length} selected'),
                    const Spacer(),
                    Text('${_filteredVideos.length} videos found'),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshVideos,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredVideos.length,
                      itemBuilder: (context, index) {
                        final video = _filteredVideos[index];
                        return VideoCard(
                          video: video,
                          isSelected: _selectedVideos.contains(video),
                          onToggle: () => _toggleSelection(video),
                        );
                      },
                    ),
                  ),
                ),
                AppButton(
                  onPressed: () => _showConfirmationDialog('download', () {
                    controller.youtubeDownloader(
                        playlistVideos: _selectedVideos.toList());
                    Navigator.pop(context);
                  }),
                  label: 'Submit (${_selectedVideos.length} selected)',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
