import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final List<File> _capturedPhotos = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isCapturing = false;
  bool _isInitialized = false;
  bool _showFallbackMode = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _error = 'No cameras available';
          _showFallbackMode = true;
        });
        return;
      }

      // Use the first rear camera
      final camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _error = null;
          _showFallbackMode = false;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _error = 'Camera initialization failed. Please check permissions.';
          _showFallbackMode = true;
        });
      }
    }
  }

  /// Fallback method to take photo using ImagePicker
  Future<void> _takePhotoWithImagePicker() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        // Copy to our temporary directory
        final Directory tempDir = await getTemporaryDirectory();
        final String dirPath = '${tempDir.path}/rufko_photos';
        await Directory(dirPath).create(recursive: true);

        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String filePath = path.join(dirPath, 'IMG_$timestamp.jpg');
        
        final File photoFile = File(photo.path);
        final File savedPhoto = await photoFile.copy(filePath);

        setState(() {
          _capturedPhotos.add(savedPhoto);
          _isCapturing = false;
        });
      } else {
        setState(() {
          _isCapturing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String dirPath = '${tempDir.path}/rufko_photos';
      await Directory(dirPath).create(recursive: true);

      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = path.join(dirPath, 'IMG_$timestamp.jpg');

      // Take picture
      final XFile photo = await _controller!.takePicture();
      
      // Copy to our directory
      final File photoFile = File(photo.path);
      final File savedPhoto = await photoFile.copy(filePath);

      if (mounted) {
        setState(() {
          _capturedPhotos.add(savedPhoto);
          _isCapturing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing photo: $e')),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _capturedPhotos.removeAt(index);
    });
  }

  void _done() {
    Navigator.pop(context, _capturedPhotos);
  }

  Widget _buildCameraPreview() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white70),
              const SizedBox(height: 24),
              Text(
                'Camera Not Available',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (_showFallbackMode) ...[
                ElevatedButton.icon(
                  onPressed: _takePhotoWithImagePicker,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Use System Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                onPressed: _initializeCamera,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera preview
        CameraPreview(_controller!),
        
        // Viewfinder overlay
        CustomPaint(
          size: Size.infinite,
          painter: ViewfinderPainter(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview (full screen)
          Positioned.fill(
            child: _buildCameraPreview(),
          ),

          // Top bar with close button and photo count
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          if (_capturedPhotos.isEmpty) {
                            Navigator.pop(context);
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Discard photos?'),
                                content: Text(
                                  'You have ${_capturedPhotos.length} photo${_capturedPhotos.length == 1 ? '' : 's'}. '
                                  'Do you want to discard them?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Keep Taking'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pop(this.context);
                                    },
                                    child: const Text('Discard'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_capturedPhotos.length} photo${_capturedPhotos.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Photo thumbnails
                    if (_capturedPhotos.isNotEmpty)
                      Container(
                        height: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _capturedPhotos.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _capturedPhotos[index],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => _removePhoto(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 16),

                    // Camera controls
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Gallery button (placeholder)
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white30),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.photo_library, color: Colors.white),
                              onPressed: () async {
                                // Add gallery access as fallback
                                if (_isCapturing) return;
                                
                                setState(() {
                                  _isCapturing = true;
                                });

                                try {
                                  final XFile? photo = await _imagePicker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1920,
                                    maxHeight: 1080,
                                    imageQuality: 85,
                                  );

                                  if (photo != null) {
                                    final Directory tempDir = await getTemporaryDirectory();
                                    final String dirPath = '${tempDir.path}/rufko_photos';
                                    await Directory(dirPath).create(recursive: true);

                                    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
                                    final String filePath = path.join(dirPath, 'IMG_$timestamp.jpg');
                                    
                                    final File photoFile = File(photo.path);
                                    final File savedPhoto = await photoFile.copy(filePath);

                                    if (mounted) {
                                      setState(() {
                                        _capturedPhotos.add(savedPhoto);
                                        _isCapturing = false;
                                      });
                                    }
                                  } else {
                                    if (mounted) {
                                      setState(() {
                                        _isCapturing = false;
                                      });
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setState(() {
                                      _isCapturing = false;
                                    });
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error selecting photo: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ),

                          // Capture button
                          GestureDetector(
                            onTap: _isCapturing 
                                ? null 
                                : _showFallbackMode 
                                    ? _takePhotoWithImagePicker 
                                    : (!_isInitialized ? null : _capturePhoto),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isCapturing
                                        ? Colors.grey
                                        : _showFallbackMode
                                            ? Colors.blue
                                            : Colors.white,
                                  ),
                                  child: _showFallbackMode 
                                      ? const Icon(Icons.camera_alt, color: Colors.white, size: 24)
                                      : null,
                                ),
                              ],
                            ),
                          ),

                          // Done button
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _capturedPhotos.isNotEmpty
                                  ? Colors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.check,
                                color: _capturedPhotos.isNotEmpty
                                    ? Colors.white
                                    : Colors.white30,
                              ),
                              onPressed:
                                  _capturedPhotos.isNotEmpty ? _done : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for viewfinder overlay
class ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = 30;

    // Draw center crosshair
    canvas.drawLine(
      Offset(centerX - radius, centerY),
      Offset(centerX - radius / 2, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + radius / 2, centerY),
      Offset(centerX + radius, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - radius),
      Offset(centerX, centerY - radius / 2),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY + radius / 2),
      Offset(centerX, centerY + radius),
      paint,
    );

    // Draw corner brackets
    final double bracketSize = 20;
    final double margin = 40;

    // Top-left
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin + bracketSize, margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin, margin + bracketSize),
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - margin - bracketSize, margin),
      Offset(size.width - margin, margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + bracketSize),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(margin, size.height - margin - bracketSize),
      Offset(margin, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + bracketSize, size.height - margin),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - margin - bracketSize, size.height - margin),
      Offset(size.width - margin, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin - bracketSize),
      Offset(size.width - margin, size.height - margin),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}