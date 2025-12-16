import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _isProcessing = false;

  // Controller điều khiển camera
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Hàm xử lý khi quét được mã
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isProcessing = true;
        });

        final String code = barcode.rawValue!;

        // Gọi Provider login
        final success = await context.read<UserProvider>().loginWithQrCode(
          code,
        );

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Đăng nhập thành công!"),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/home'); // Chuyển về trang chủ
          }
        } else {
          if (mounted) {
            final error =
                context.read<UserProvider>().errorMessage ??
                "Mã QR không hợp lệ hoặc đã hết hạn";
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red),
            );

            // Delay 2 giây rồi cho phép quét lại
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _isProcessing = false);
            });
          }
        }
        break; // Chỉ xử lý mã đầu tiên tìm thấy
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Quét mã đăng nhập"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // --- [SỬA LỖI 1 & 2] Nút bật/tắt đèn Flash ---
          IconButton(
            // Thay vì lắng nghe torchState, ta lắng nghe chính controller
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                // state ở đây là MobileScannerState
                switch (state.torchState) {
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  // Thêm default để sửa lỗi "body might complete normally"
                  default:
                    return const Icon(Icons.no_flash, color: Colors.grey);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),

          // Nút xoay Camera trước/sau
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Overlay làm tối xung quanh (Custom Shape)
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: const Color(0xFF3366FF),
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          // Text hướng dẫn
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _isProcessing
                      ? "Đang xử lý..."
                      : "Di chuyển camera đến mã QR trên website",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                  ),
                ),
                if (_isProcessing)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Class Custom Overlay (Đã sửa lỗi tên biến) ---
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.blue,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero)
      ..addRect(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutSize,
          height: cutOutSize,
        ),
      );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final borderOffset = borderWidth / 2;
    final double mCutOutSize = cutOutSize + borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: mCutOutSize,
      height: mCutOutSize,
    );

    // Vẽ phần nền tối (trừ phần cắt ở giữa)
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRect(cutOutRect),
      ),
      backgroundPaint,
    );

    // Vẽ 4 góc
    final r = cutOutRect.deflate(borderWidth / 2);

    // Top Left
    canvas.drawLine(
      r.topLeft,
      r.topLeft + Offset(0, borderLength),
      borderPaint,
    );
    canvas.drawLine(
      r.topLeft,
      r.topLeft + Offset(borderLength, 0),
      borderPaint,
    );

    // Top Right
    canvas.drawLine(
      r.topRight,
      r.topRight + Offset(0, borderLength),
      borderPaint,
    );
    canvas.drawLine(
      r.topRight,
      r.topRight - Offset(borderLength, 0),
      borderPaint,
    );

    // Bottom Left
    canvas.drawLine(
      r.bottomLeft,
      r.bottomLeft - Offset(0, borderLength),
      borderPaint,
    );
    canvas.drawLine(
      r.bottomLeft,
      r.bottomLeft + Offset(borderLength, 0),
      borderPaint,
    );

    // Bottom Right
    canvas.drawLine(
      r.bottomRight,
      r.bottomRight - Offset(0, borderLength),
      borderPaint,
    );
    canvas.drawLine(
      r.bottomRight,
      r.bottomRight - Offset(borderLength, 0),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
