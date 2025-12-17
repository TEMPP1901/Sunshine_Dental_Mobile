import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Màn hình chụp ảnh khuôn mặt với giao diện Premium (Scanning Effect)
class FaceCameraScreen extends StatefulWidget {
  const FaceCameraScreen({super.key});

  @override
  State<FaceCameraScreen> createState() => _FaceCameraScreenState();
}

class _FaceCameraScreenState extends State<FaceCameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  int _selectedCameraIndex = 0;
  
  // Animation cho hiệu ứng quét (Scanning)
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  
  bool _showFlash = false;

  @override
  void initState() {
    super.initState();
    // Scanning animation: chạy lên xuống
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: false);
    
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
    
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      int frontCameraIndex = _cameras!.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      if (frontCameraIndex == -1) frontCameraIndex = 0;
      _selectedCameraIndex = frontCameraIndex;

      _controller = CameraController(
        _cameras![_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.jpeg
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      // Flash effect
      setState(() => _showFlash = true);
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() => _showFlash = false);

      final XFile imageFile = await _controller!.takePicture();
      if (mounted) context.pop(XFile(imageFile.path));
    } catch (e) {
      setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview (Full Screen)
          Transform.scale(
            scale: scale,
            child: Center(child: CameraPreview(_controller!)),
          ),

          // 2. Dark Overlay with Cutout & Scanning Effect
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: FaceScanningOverlayPainter(
                    scanValue: _scanAnimation.value,
                  ),
                );
              },
            ),
          ),

          // 3. Top Bar (Minimalist)
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Back Button (Glass)
                    ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.black.withOpacity(0.2),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => context.pop(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Instruction Text
          Positioned(
            top: size.height * 0.15,
            left: 0, right: 0,
            child: Column(
              children: [
                Text(
                  "Xác thực khuôn mặt",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Giữ khuôn mặt trong khung hình",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // 5. Bottom Controls (Shutter Button)
          Positioned(
            bottom: 50, left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isCapturing ? null : _captureImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                    color: Colors.transparent,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCapturing ? Colors.white.withOpacity(0.5) : Colors.white,
                    ),
                    child: _isCapturing
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),

          // 6. Flash Overlay
          if (_showFlash)
            Positioned.fill(child: Container(color: Colors.white)),
        ],
      ),
    );
  }
}

class FaceScanningOverlayPainter extends CustomPainter {
  final double scanValue; // 0.0 to 1.0

  FaceScanningOverlayPainter({required this.scanValue});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.45;
    final ovalWidth = size.width * 0.7;
    final ovalHeight = size.height * 0.45;

    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: ovalWidth,
      height: ovalHeight,
    );

    // 1. Draw Dark Overlay with Cutout
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(rect);
    
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.8) // Darker for focus
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, overlayPaint);

    // 2. Draw Thin White Border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(rect, borderPaint);

    // 3. Draw Scanning Line (Gradient)
    // Line moves from top of oval to bottom of oval
    final scanY = rect.top + (rect.height * scanValue);
    
    // Only draw scan line if it's within the oval (it always is by math, but visual clipping helps)
    canvas.save();
    canvas.clipPath(Path()..addOval(rect)); // Clip to oval

    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blueAccent.withOpacity(0.0),
          Colors.blueAccent.withOpacity(0.5),
          Colors.blueAccent.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(rect.left, scanY - 20, rect.width, 40));

    // Draw a wide rect for the scan "beam"
    canvas.drawRect(
      Rect.fromLTWH(rect.left, scanY - 20, rect.width, 40),
      scanPaint,
    );
    
    // Draw the sharp line in the middle of the beam
    final linePaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    canvas.drawLine(
      Offset(rect.left + 20, scanY), 
      Offset(rect.right - 20, scanY), 
      linePaint
    );

    canvas.restore();

    // 4. Draw Corner Brackets (Minimalist)
    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
      
    final cornerSize = 30.0;
    final gap = 20.0; // Gap from the oval
    final bracketRect = rect.inflate(gap);

    // TL
    canvas.drawPath(
      Path()..moveTo(bracketRect.left, bracketRect.top + cornerSize)..lineTo(bracketRect.left, bracketRect.top)..lineTo(bracketRect.left + cornerSize, bracketRect.top),
      bracketPaint
    );
    // TR
    canvas.drawPath(
      Path()..moveTo(bracketRect.right - cornerSize, bracketRect.top)..lineTo(bracketRect.right, bracketRect.top)..lineTo(bracketRect.right, bracketRect.top + cornerSize),
      bracketPaint
    );
    // BL
    canvas.drawPath(
      Path()..moveTo(bracketRect.left, bracketRect.bottom - cornerSize)..lineTo(bracketRect.left, bracketRect.bottom)..lineTo(bracketRect.left + cornerSize, bracketRect.bottom),
      bracketPaint
    );
    // BR
    canvas.drawPath(
      Path()..moveTo(bracketRect.right - cornerSize, bracketRect.bottom)..lineTo(bracketRect.right, bracketRect.bottom)..lineTo(bracketRect.right, bracketRect.bottom - cornerSize),
      bracketPaint
    );
  }

  @override
  bool shouldRepaint(covariant FaceScanningOverlayPainter oldDelegate) {
    return oldDelegate.scanValue != scanValue;
  }
}
