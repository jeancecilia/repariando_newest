import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final String pdfUrl;
  final String fileName;

  const PdfViewerScreen({
    Key? key,
    required this.pdfUrl,
    required this.fileName,
  }) : super(key: key);

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _currentViewerIndex = 0;
  
  // Different PDF viewer services to try
  final List<String Function(String)> _pdfViewers = [
    // Google Docs viewer
    (String url) => 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(url)}',
    // Mozilla PDF.js viewer
    (String url) => 'https://mozilla.github.io/pdf.js/web/viewer.html?file=${Uri.encodeComponent(url)}',
    // Direct URL (fallback)
    (String url) => url,
  ];

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    print('🔍 PDF Viewer Debug - Initializing WebView');
    print('📄 PDF URL: ${widget.pdfUrl}');
    print('📄 File Name: ${widget.fileName}');
    
    _loadWithCurrentViewer();
  }
  
  void _loadWithCurrentViewer() {
    if (_currentViewerIndex >= _pdfViewers.length) {
      print('❌ All PDF viewers failed');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Unable to load PDF with any viewer service';
      });
      return;
    }
    
    final String pdfViewerUrl = _pdfViewers[_currentViewerIndex](widget.pdfUrl);
    print('🌐 Trying viewer ${_currentViewerIndex + 1}/${_pdfViewers.length}: $pdfViewerUrl');
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('📱 Page started loading: $url');
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            print('✅ Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error with viewer ${_currentViewerIndex + 1}: ${error.description}');
            print('❌ Error code: ${error.errorCode}');
            print('❌ Error type: ${error.errorType}');
            
            // Try next viewer
            _currentViewerIndex++;
            if (_currentViewerIndex < _pdfViewers.length) {
              print('🔄 Trying next viewer...');
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _loadWithCurrentViewer();
                }
              });
            } else {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = 'Unable to load PDF: ${error.description}';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(pdfViewerUrl));
  }

  Future<void> _openInExternalApp() async {
    try {
      final url = Uri.parse(widget.pdfUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('cannot_open_pdf'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_opening_pdf'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.fileName,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openInExternalApp,
            tooltip: 'Open in external app',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading PDF',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _currentViewerIndex = 0;
                  _initializeWebView();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openInExternalApp,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in External App'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading PDF...'),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
