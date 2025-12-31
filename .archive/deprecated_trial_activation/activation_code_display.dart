import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget to display activation code with copy button
/// Used on payment success screens and in subscription settings
class ActivationCodeDisplay extends StatefulWidget {
  final String code;
  final bool showInstructions;
  final VoidCallback? onCodeCopied;

  const ActivationCodeDisplay({
    Key? key,
    required this.code,
    this.showInstructions = true,
    this.onCodeCopied,
  }) : super(key: key);

  @override
  State<ActivationCodeDisplay> createState() => _ActivationCodeDisplayState();
}

class _ActivationCodeDisplayState extends State<ActivationCodeDisplay> {
  bool _copied = false;

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.code));

    setState(() {
      _copied = true;
    });

    // Reset after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Code copied to clipboard!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Callback
    widget.onCodeCopied?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          'Your Activation Code:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),

        const SizedBox(height: 12),

        // Code display box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Code text
              SelectableText(
                widget.code,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  fontFamily: 'monospace',
                  color: Theme.of(context).primaryColor,
                ),
              ),

              const SizedBox(width: 16),

              // Copy button
              Material(
                color: _copied ? Colors.green : Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _copyCode,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check : Icons.copy,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _copied ? 'Copied!' : 'Copy',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (widget.showInstructions) ...[
          const SizedBox(height: 16),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Save this code!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '💡 Copy and paste this code into your notes app.\n'
                  '📧 Also check your email receipt for a backup.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact version for settings screen (obfuscated code display)
class ActivationCodeCompact extends StatelessWidget {
  final String code;

  const ActivationCodeCompact({
    Key? key,
    required this.code,
  }) : super(key: key);

  String get obfuscatedCode {
    // Show first 2 and last 3 characters: M-***-123
    if (code.length < 9) return code;
    return '${code.substring(0, 2)}***-***${code.substring(8)}';
  }

  void _copyFullCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Full code copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.vpn_key, color: Theme.of(context).primaryColor),
      title: const Text('Activation Code'),
      subtitle: Text(
        obfuscatedCode,
        style: const TextStyle(
          fontFamily: 'monospace',
          letterSpacing: 2,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy),
        onPressed: () => _copyFullCode(context),
        tooltip: 'Copy full code',
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Your Activation Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ActivationCodeDisplay(
                  code: code,
                  showInstructions: false,
                ),
                const SizedBox(height: 16),
                Text(
                  'Keep this code safe. You\'ll need it to reinstall the app.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
