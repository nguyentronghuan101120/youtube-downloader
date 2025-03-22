import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_downloader_flutter/log_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Downloader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _urlController = TextEditingController();
  final List<LogModel> _processLogs = [];
  bool _isDownloading = false;
  String? _downloadedFilePath;
  Process? process;
  final ScrollController _scrollController = ScrollController();

  String _downloadType = 'audio';
  String _audioFormat = 'mp3';
  String _videoQuality = '1080p';

  Future<void> runYouTubeDownloader(String youtubeUrl) async {
    _initializeDownloadState();

    try {
      _logMessage("Preparing to download...");

      final downloaderPath = await _getDownloaderPath();
      await _makeFileExecutable(downloaderPath);

      final processArgs = _buildProcessArgs(youtubeUrl);
      process = await _startDownloadProcess(downloaderPath, processArgs);

      if (process != null) {
        _listenToProcessOutput(process!);
        await _handleProcessExit(process!);
      }
    } catch (e) {
      _logMessage('Error: $e');
    } finally {
      _finalizeDownloadState();
    }
  }

  void _initializeDownloadState() {
    setState(() {
      _isDownloading = true;
      _processLogs.clear();
      _downloadedFilePath = null;
      process = null;
    });
  }

  Future<void> _makeFileExecutable(String path) async {
    await Process.run('chmod', ['+x', path]);
  }

  List<String> _buildProcessArgs(String youtubeUrl) {
    return [
      youtubeUrl,
      '--format=$_downloadType',
      if (_downloadType == 'audio') '--audio-format=$_audioFormat',
      if (_downloadType == 'video') '--quality=$_videoQuality',
    ];
  }

  Future<Process> _startDownloadProcess(String path, List<String> args) {
    return Process.start('python', [path, ...args]);
  }

  void _listenToProcessOutput(Process process) {
    process.stdout.transform(utf8.decoder).listen(_logMessage);
    process.stderr.transform(utf8.decoder).listen((data) {
      _logMessage(data);
    });
  }

  Future<void> _handleProcessExit(Process process) async {
    final exitCode = await process.exitCode.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        process.kill();
        throw TimeoutException("Process took too long to complete.");
      },
    );

    if (exitCode == 0) {
      _logMessage("Download completed successfully!");
    } else {
      _logMessage("Download failed with exit code $exitCode.");
      final errorMessage = await process.stderr.transform(utf8.decoder).join();
      throw Exception("Python Script Error: $errorMessage");
    }
  }

  void _finalizeDownloadState() {
    setState(() {
      _isDownloading = false;
    });
  }

  Future<String> _getDownloaderPath() async {
    // Load the asset
    final byteData = await rootBundle.load('assets/excutable_for_app.py');

    // Get the temporary directory
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/excutable_for_app.py';

    // Write the asset to a file in the temporary directory
    final file = File(tempFilePath);
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return tempFilePath;
  }

  void _logMessage(String message) {
    final logMessage = message.trim();
    final logType = logMessage.toLowerCase().contains('error') ||
            logMessage.toLowerCase().contains('failed')
        ? LogType.error
        : logMessage.toLowerCase().contains('warning')
            ? LogType.warning
            : LogType.info;
    setState(() {
      _processLogs.add(LogModel(logMessage, logType));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Downloader'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputRow(),
            const SizedBox(height: 16),
            _buildDownloadButton(),
            const SizedBox(height: 16),
            _buildLogList(),
            if (_downloadedFilePath != null)
              Text("Download completed: $_downloadedFilePath"),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'YouTube URL',
              hintText: 'Enter the YouTube video URL',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: _downloadType,
          items: const [
            DropdownMenuItem(value: 'video', child: Text('Video')),
            DropdownMenuItem(value: 'audio', child: Text('Audio')),
          ],
          onChanged: (value) {
            setState(() {
              _downloadType = value!;
            });
          },
        ),
        const SizedBox(width: 8),
        if (_downloadType == 'video') _buildVideoQualityDropdown(),
        if (_downloadType == 'audio') _buildAudioFormatDropdown(),
      ],
    );
  }

  Widget _buildVideoQualityDropdown() {
    return DropdownButton<String>(
      value: _videoQuality,
      items: const [
        DropdownMenuItem(value: '360p', child: Text('360p')),
        DropdownMenuItem(value: '480p', child: Text('480p')),
        DropdownMenuItem(value: '720p', child: Text('720p')),
        DropdownMenuItem(value: '1080p', child: Text('1080p')),
      ],
      onChanged: (value) {
        setState(() {
          _videoQuality = value!;
        });
      },
    );
  }

  Widget _buildAudioFormatDropdown() {
    return DropdownButton<String>(
      value: _audioFormat,
      items: const [
        DropdownMenuItem(value: 'mp3', child: Text('MP3')),
        DropdownMenuItem(value: 'flac', child: Text('FLAC')),
        DropdownMenuItem(value: 'aac', child: Text('AAC')),
        DropdownMenuItem(value: 'wav', child: Text('WAV')),
      ],
      onChanged: (value) {
        setState(() {
          _audioFormat = value!;
        });
      },
    );
  }

  Widget _buildDownloadButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isDownloading
                ? null
                : () {
                    runYouTubeDownloader(_urlController.text);
                  },
            child: _isDownloading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Start Download'),
          ),
        ),
        if (_isDownloading) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              process?.kill();
              setState(() {
                _isDownloading = false;
              });
            },
            child: const Icon(Icons.cancel),
          ),
        ]
      ],
    );
  }

  Widget _buildLogList() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Expanded(
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        controller: _scrollController,
        itemCount: _processLogs.length,
        itemBuilder: (context, index) {
          return SelectableText(
            _processLogs[index].message,
            style: TextStyle(color: _processLogs[index].type.color),
          );
        },
      ),
    );
  }
}
