import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/finance_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import '../wallets/add_wallet_screen.dart';
import '../../domain/models/finance_summary.dart';

import '../../../../core/localization/app_localizations.dart';

import '../../../../core/services/security_service.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const _WalletsAppBar(),
          
          walletsAsync.when(
            data: (wallets) => wallets.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyWalletsView(context))
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _WalletCardItem(wallet: wallets[index]),
                        childCount: wallets.length,
                      ),
                    ),
                  ),
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text('${context.tr('error')}: $err'))),
          ),
        ],
      ),
      floatingActionButton: _AddWalletFAB(),
    );
  }

  Widget _buildEmptyWalletsView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, 
              size: 64, color: AppColors.indigo),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('no_wallets_title'),
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('no_wallets_desc'),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 14),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _WalletsAppBar extends StatelessWidget {
  const _WalletsAppBar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => context.push('/transfer'),
          icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
          label: const Text('TRANSFER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 20),
        title: Text(
          context.tr('my_wallets'),
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Opacity(
                opacity: 0.1,
                child: Transform.rotate(
                  angle: -0.2,
                  child: const Icon(Icons.account_balance_wallet_rounded, size: 200, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Opacity(
                opacity: 0.15,
                child: const Icon(Icons.credit_card_rounded, size: 80, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCardItem extends StatefulWidget {
  final Wallet wallet;
  const _WalletCardItem({required this.wallet});

  @override
  State<_WalletCardItem> createState() => _WalletCardItemState();
}

class _WalletCardItemState extends State<_WalletCardItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  Color _getProviderColor() {
    if (widget.wallet.provider == null) return Color(widget.wallet.color);
    
    switch (widget.wallet.provider) {
      case 'CRDB': return const Color(0xFF006838);
      case 'NMB': return const Color(0xFF005AAB);
      case 'NBC': return const Color(0xFFE31E24);
      case 'Equity': return const Color(0xFF8B2332);
      case 'M-Pesa': return const Color(0xFFE31E24);
      case 'Airtel Money': return const Color(0xFFFF0000);
      case 'Tigo Pesa': return const Color(0xFF003399);
      case 'Halopesa': return const Color(0xFFFF6600);
      case 'Azam Pesa': return const Color(0xFF00ADEF);
      default: return Color(widget.wallet.color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _getProviderColor();
    
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: angle <= math.pi / 2
                ? _buildFront(cardColor)
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBack(cardColor),
                  ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildFront(Color cardColor) {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.wallet.provider?.toUpperCase() ?? widget.wallet.type.toUpperCase(),
                          style: AppTextStyles.semiBold.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            letterSpacing: 1.2,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          widget.wallet.type.toUpperCase(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.contactless_outlined, color: Colors.white70, size: 24),
                  ],
                ),
                const Spacer(),
                Text(
                  _formatAccountNumber(widget.wallet.accountNumber ?? ''),
                  style: AppTextStyles.semiBold.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<bool>(
                  future: SecurityService.instance.isHideBalancesEnabled,
                  builder: (context, snapshot) {
                    final isHidden = snapshot.data ?? false;
                    return Text(
                      isHidden ? 'TSh ••••••' : CurrencyFormatter.formatScaled(widget.wallet.balance, symbol: 'TSh '),
                      style: AppTextStyles.h2.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  }
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.wallet.name,
                      style: AppTextStyles.h4.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const Icon(Icons.info_outline, color: Colors.white54, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(Color cardColor) {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Stack(
        children: [
          // Magnetic stripe simulation
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              color: Colors.black87,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  context.tr('current_balance'),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<bool>(
                  future: SecurityService.instance.isHideBalancesEnabled,
                  builder: (context, snapshot) {
                    final isHidden = snapshot.data ?? false;
                    return Text(
                      isHidden ? 'TSh ••••••' : CurrencyFormatter.formatScaled(widget.wallet.balance, symbol: 'TSh '),
                      style: AppTextStyles.display.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                Consumer(
                  builder: (context, ref, child) => IconButton(
                    onPressed: () => context.push('/add-transaction', extra: widget.wallet.id),
                    icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                    tooltip: context.tr('add_income'),
                    style: IconButton.styleFrom(backgroundColor: Colors.white10),
                  ),
                ),
                const SizedBox(width: 8),
                Consumer(
                  builder: (context, ref, child) => IconButton(
                    onPressed: () => _showDeleteConfirmation(context, ref),
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
                    style: IconButton.styleFrom(backgroundColor: Colors.white10),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: Text(
              context.tr('tap_to_flip'),
              style: AppTextStyles.labelSmall.copyWith(color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${context.tr('delete')} ${widget.wallet.name}?'),
        content: Text(context.tr('delete_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(walletRepositoryProvider).deleteWallet(widget.wallet.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  String _formatAccountNumber(String number) {
    if (number.isEmpty) return '**** **** **** ****';
    if (number.length <= 4) return '**** **** **** $number';
    return '**** **** **** ${number.substring(number.length - 4)}';
  }
}

class _AddWalletFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: FloatingActionButton.extended(
        onPressed: () => context.push('/add-wallet'),
        backgroundColor: AppColors.indigo,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        label: Text(
          context.tr('add_wallet_btn'),
          style: AppTextStyles.semiBold.copyWith(
            color: Colors.white,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
