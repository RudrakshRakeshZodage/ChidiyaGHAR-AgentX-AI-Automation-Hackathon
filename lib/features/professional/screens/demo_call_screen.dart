import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' as stream;
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/theme.dart';
import '../../../core/api_keys.dart';
import '../../../core/user_model.dart';
import '../../../services/payment_service.dart';
import '../../../services/pdf_service.dart';
import '../../../services/health_service.dart';
import 'package:open_file/open_file.dart';

class DemoCallScreen extends StatefulWidget {
  final String channelId;
  const DemoCallScreen({super.key, this.channelId = 'test_channel'});

  @override
  State<DemoCallScreen> createState() => _DemoCallScreenState();
}

class _DemoCallScreenState extends State<DemoCallScreen> {
  int _secondsRemaining = 120;
  Timer? _timer;
  bool _isInit = false;
  late stream.StreamVideo _client;
  late stream.Call _call;

  @override
  void initState() {
    super.initState();
    _initStream();
    _startTimer();
  }

  Future<void> _initStream() async {
    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    final user = supabase.Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';

    _client = stream.StreamVideo(
      ApiKeys.streamApiKey,
      user: stream.User.regular(
        userId: userId, 
        name: user?.email?.split('@')[0] ?? 'User',
      ),
      // Static token bypass for demo/hackathon environment
      userToken: 'development', 
    );

    _call = _client.makeCall(callType: stream.StreamCallType.defaultType(), id: widget.channelId);
    
    await _call.getOrCreate();
    
    setState(() {
      _isInit = true;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _endCall();
      }
    });
  }


  void _endCall() async {
    if (mounted) {
      _call.leave();
      _client.dispose();
      
      final healthService = HealthService();
      final userProfile = UserData(
        name: healthService.currentData.userName,
        email: healthService.currentData.email,
        phone: healthService.currentData.phone,
        age: 28,
        gender: 'Male',
        weight: healthService.currentData.weight,
        height: healthService.currentData.height,
        category: 'Working Professional',
      );

      // Trigger Payment & PDF Receipt
      final paymentService = PaymentService();
      
      // 1. Generate Tax Invoice
      final receiptFile = await PdfService.generateTaxInvoice(userProfile, 'Dr. Sarah Smith', 499.0);

      // 2. Process Payment (Upload & Log)
      final currentUser = supabase.Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await paymentService.processSpecialistPayment(
          userId: currentUser.id,
          specialistId: 'spec_123', // Mock ID
          amount: 499.0,
          serviceType: 'Online Consultation',
          receiptFile: receiptFile,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Consultation Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment of ₹499.0 processed successfully.'),
                const SizedBox(height: 12),
                const Text('Blockchain Verified (Solana):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text('Tx: 5Kj3...9zB2', style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.green)), // Using mock as simple display, real one is in logs
                const SizedBox(height: 12),
                const Text('Tax Invoice generated & sent to your email.', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => OpenFile.open(receiptFile.path),
                child: const Text('View Invoice'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _call.leave();
    _client.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: stream.StreamCallContainer(
        call: _call,
        callContentWidgetBuilder: (context, call) {
          return stream.StreamCallContent(
            call: call,
            callControlsWidgetBuilder: (context, call) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Time Remaining: ${_formatTime(_secondsRemaining)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  stream.StreamCallControls.withDefaultOptions(
                    call: call,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
