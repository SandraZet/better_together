import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SharePreviewSheet extends StatefulWidget {
  final String nickname;
  final String location;
  final String headline;
  final String text;
  final String slot;
  final int counter;
  final List<Color> gradientColors;
  final VoidCallback onSubmitted;

  const SharePreviewSheet({
    super.key,
    required this.nickname,
    required this.location,
    required this.headline,
    required this.text,
    required this.slot,
    required this.counter,
    required this.gradientColors,
    required this.onSubmitted,
  });

  @override
  State<SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends State<SharePreviewSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isGenerating = false;

  Future<void> _captureAndShare() async {
    if (!mounted) return;
    setState(() => _isGenerating = true);

    try {
      // Small delay to ensure UI is fully rendered
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      final context = _cardKey.currentContext;
      if (context == null) {
        throw Exception('Card context is null');
      }

      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('RenderRepaintBoundary not found');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to temp file with timestamp to force refresh
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/now_share_$timestamp.png');

      await file.writeAsBytes(pngBytes);

      // Share the image
      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Micro-Actions together: \n"${widget.text}" \n NOW. 🚀\n\nBe part. Or not. ✨',
      );

      // Clean up temporary file after sharing
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Failed to delete temp file: $e');
      }

      // Don't auto-close or trigger callbacks - let user dismiss manually
      // This prevents black screen issues when switching apps
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Text(
                'Your Moment',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              /* Text(
                'This image will be shared',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ), */
              const SizedBox(height: 24),
              // Preview Card
              RepaintBoundary(
                key: _cardKey,
                child: _ShareCard(
                  location: widget.location,
                  nickname: widget.nickname,
                  headline: widget.headline,
                  text: widget.text,
                  slot: widget.slot,
                  counter: widget.counter,
                  gradientColors: widget.gradientColors,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _captureAndShare,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(double.infinity, 0),
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(""),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Share it',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareCard extends StatefulWidget {
  final String nickname;
  final String location;
  final String text;
  final String headline;
  final String slot;
  final int counter;
  final List<Color> gradientColors;

  const _ShareCard({
    required this.location,
    required this.text,
    required this.nickname,
    required this.headline,
    required this.slot,
    required this.counter,
    required this.gradientColors,
  });

  @override
  State<_ShareCard> createState() => _ShareCardState();
}

class _ShareCardState extends State<_ShareCard> {
  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white;

    return Container(
      width: 420,
      height: 540,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.gradientColors,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ⭐ Blitz – oversized + abgeschnitten
            Positioned(
              top: -130,
              left: -180,
              child: Image.asset(
                'lib/assets/nowblitznobg.png',
                width: 600,
                fit: BoxFit.cover,
              ),
            ),

            // ⭐ Top gradient overlay for text contrast
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.white.withOpacity(0.6), Colors.transparent],
                  ),
                ),
              ),
            ),

            // ⭐ Inhalte
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // TOP LEFT COUNTER
                  Align(
                    alignment: Alignment.center,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: ' Now.  ',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: '${widget.counter} ',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: ' around the world.',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  const SizedBox(height: 1),
                  // HEADLINE
                  AutoSizeText(
                    widget.headline,
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    minFontSize: 32,
                    wrapWords: false,
                    style: GoogleFonts.poppins(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: Offset(1, 6),
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 40,
                          offset: Offset(1, -1),
                        ),

                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 40,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // BOTTOM TAG
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.nickname.isEmpty ? "tom" : widget.nickname}  |  ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} | ${widget.location.isEmpty ? "now.space" : widget.location}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                        letterSpacing: 0.5,
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
