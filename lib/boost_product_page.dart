import 'package:flutter/material.dart';
import 'package:teftef/core/config.dart';
import 'package:teftef/services/api_service.dart';

class BoostProductPage extends StatefulWidget {
  final dynamic product;
  const BoostProductPage({super.key, required this.product});

  @override
  State<BoostProductPage> createState() => _BoostProductPageState();
}

class _BoostProductPageState extends State<BoostProductPage> {
  int? _selectedPackageId;
  dynamic _primaryAgent;
  bool _isAlreadyPending = false;
  int _currentStep = 0; // 0: Selection, 1: Payment
  bool _isLoading = true;
  bool _isActivating = false;
  List<dynamic> _packages = [];
  String? _errorMessage;

  final TextEditingController _transactionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkPendingStatus();
    _fetchData();
  }

  void _checkPendingStatus() {
    final boostRequest = widget.product['boostRequest'];
    if (boostRequest != null && boostRequest['status'] == 'pending') {
      setState(() {
        _isAlreadyPending = true;
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final packageRes = await ApiService.fetchBoostPackages();
    final agentRes = await ApiService.fetchPaymentAgents();
    
    if (mounted) {
      if (packageRes['success'] && agentRes['success']) {
        final agents = agentRes['agents'] as List<dynamic>;
        setState(() {
          _packages = packageRes['packages'];
          _primaryAgent = agents.isNotEmpty ? agents.first : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = !packageRes['success'] ? packageRes['message'] : agentRes['message'];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleActivateBoost() async {
    if (_selectedPackageId == null || _primaryAgent == null || !_formKey.currentState!.validate()) return;

    setState(() => _isActivating = true);

    final res = await ApiService.activateBoost(
      widget.product['id'], 
      _selectedPackageId!, 
      int.tryParse(_primaryAgent['id'].toString()) ?? 0,
      _transactionController.text.trim(),
    );

    if (mounted) {
      setState(() => _isActivating = false);
      if (res['success']) {
        _showSuccessDialog();
      } else {
        // Specifically check for "Already have a pending request" (usually 400 or identified by message)
        if (res['message']?.toString().toLowerCase().contains('pending') == true) {
          _showErrorDialog("Request Already Pending", res['message'] ?? "You already have a boost request waiting for verification.");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Failed to submit boost request'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              "Request Submitted",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your boost request is now Pending Admin Verification. We'll verify your transaction ID shortly.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Return to products list with refresh
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Got it", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product['images'] as List<dynamic>?;
    String? imageUrl = images != null && images.isNotEmpty 
        ? AppConfig.getImageUrl(images[0].toString()) 
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Boost Product", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
                    TextButton(onPressed: _fetchData, child: const Text("Retry")),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductPreview(imageUrl),
                    if (_isAlreadyPending) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.amber[900]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Verification in progress. Please wait for approval before submitting a new request.",
                                style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    if (_currentStep == 0) ...[
                      const Text(
                        "Choose a Boost Plan",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Select a plan to increase your product's visibility and reach more potential buyers.",
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                      const SizedBox(height: 24),
                      ..._packages.map((package) => _buildPackageCard(package)),
                    ] else ...[
                      _buildPaymentStep(),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProductPreview(String? imageUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(color: Colors.grey[100], child: const Icon(Icons.image)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product['name'] ?? 'Unnamed Product',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "ETB ${widget.product['price']}",
                  style: const TextStyle(color: Color(0xFF1B4D3E), fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(dynamic package) {
    final int id = int.tryParse(package['id'].toString()) ?? 0;
    final String name = package['name']?.toString() ?? 'Unnamed Plan';
    final double price = double.tryParse(package['price'].toString()) ?? 0.0;
    final int durationHours = int.tryParse(package['durationHours'].toString()) ?? 0;
    
    bool isSelected = _selectedPackageId == id;
    bool isPopular = durationHours == 168; // 7 days is popular

    Color color;
    IconData icon;
    String description;

    if (durationHours <= 24) {
      color = Colors.blue;
      icon = Icons.timer_outlined;
      description = "Perfect for a quick sale. High visibility for a full day.";
    } else if (durationHours <= 168) {
      color = Colors.orange;
      icon = Icons.calendar_today_outlined;
      description = "Best value for most sellers. Stay on top for a whole week.";
    } else {
      color = Colors.purple;
      icon = Icons.star_outline_rounded;
      description = "Maximum exposure. Keep your product in the spotlight.";
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedPackageId = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? Colors.black.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                            const Spacer(),
                            Text(
                              "ETB $price",
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isPopular)
              Positioned(
                top: 0,
                right: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                  ),
                  child: const Text(
                    "BEST VALUE",
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    if (_primaryAgent == null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange[300]),
            const SizedBox(height: 16),
            const Text(
              "Payment System Unavailable",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "No official bank account is currently configured. Please try again later.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextButton(onPressed: _fetchData, child: const Text("Retry")),
          ],
        ),
      );
    }

    final selectedPackage = _packages.firstWhere(
      (p) => int.tryParse(p['id'].toString()) == _selectedPackageId,
      orElse: () => null,
    );
    
    if (selectedPackage == null) return const SizedBox();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentStep = 0),
                icon: const Icon(Icons.arrow_back_rounded),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Text(
                "Payment Instructions",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "Please transfer the package price to the following official bank account.",
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Transfer via ${_primaryAgent['bankName']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildInstructionRow("Account Number", _primaryAgent['accountNumber']?.toString() ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInstructionRow("Account Name", _primaryAgent['name']?.toString() ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInstructionRow("Amount", "ETB ${double.tryParse(selectedPackage['price'].toString())}"),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "Verify Transaction",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please paste your Transaction ID below for manual verification.",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _transactionController,
            decoration: InputDecoration(
              hintText: "Enter Transaction ID (e.g. AB12CD...)",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
              prefixIcon: const Icon(Icons.receipt_long_rounded, color: Colors.grey),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter your Transaction ID";
              }
              if (value.trim().length < 5) {
                return "Transaction ID is too short";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_selectedPackageId == null || _isActivating || _isAlreadyPending) 
            ? null 
            : (_currentStep == 0 
                ? () => setState(() => _currentStep = 1) 
                : _handleActivateBoost),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isActivating 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                _currentStep == 0 ? "Continue to Payment" : "Submit Request", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }
}
