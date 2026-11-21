import '../../core/api/pos_api.dart';
import '../../core/lan/hub_client.dart';
import '../order/data/order_repository.dart';
import 'loyalty_reward.dart';

/// "Fidélité" on the ticket: the customer's 6-digit code from the Kahwti app.
/// Needs internet: the backend holds the points.
abstract class RewardActions {
  /// What the code is and how it would go on the ticket. Nothing is spent.
  Future<RewardCheck> check(String orderId, String code);

  /// Spends the points (once) and puts the reward on the ticket.
  Future<RewardCheck> redeem(String orderId, String code);
}

/// On the POS that has the ticket (the main POS, or a POS without a hub).
class LocalRewardActions implements RewardActions {
  LocalRewardActions(this._api, this._orders);
  final PosApi _api;
  final OrderRepository _orders;

  @override
  Future<RewardCheck> check(String orderId, String code) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) throw const OrderException('Le code fidélité a 6 chiffres.');
    final reward = await _call(() => _api.checkReward(code));
    final plan = await _orders.planReward(orderId, reward);
    return RewardCheck(reward, plan.description);
  }

  @override
  Future<RewardCheck> redeem(String orderId, String code) async {
    // It must fit the ticket BEFORE the points are spent.
    await check(orderId, code);
    final reward = await _call(() => _api.redeemReward(code, orderId: orderId));
    final plan = await _orders.applyReward(orderId, reward);
    return RewardCheck(reward, plan.description);
  }

  static Future<LoyaltyReward> _call(Future<Map<String, dynamic>> Function() f) async {
    try {
      return LoyaltyReward.fromJson(await f());
    } on ApiException catch (e) {
      throw OrderException(switch (e.code) {
        _ when e.isNetwork => 'Pas de connexion internet : impossible de vérifier le code fidélité.',
        'REDEMPTION_NOT_FOUND' => 'Code inconnu ou expiré. Le client peut en créer un nouveau dans l’application.',
        'REDEMPTION_USED' => 'Ce code a déjà été utilisé.',
        'NOT_ENOUGH_POINTS' => 'Le client n’a plus assez de points pour cette récompense.',
        'VALIDATION_ERROR' => 'Le code fidélité a 6 chiffres.',
        'TOO_MANY_REQUESTS' => 'Trop d’essais. Patientez une minute.',
        _ => e.message,
      });
    }
  }
}

/// On a server tablet: the main POS has the ticket, so it does it (with its own connection).
class HubRewardActions implements RewardActions {
  HubRewardActions(this._client, {required String? Function() staffId}) : _staffId = staffId;
  final HubClient _client;
  final String? Function() _staffId;

  Future<RewardCheck> _send(String action, String orderId, String code) async {
    final json = await _client.command(action, {'orderId': orderId, 'code': code}, staffId: _staffId());
    return RewardCheck.fromJson((json['result'] as Map).cast<String, dynamic>());
  }

  @override
  Future<RewardCheck> check(String orderId, String code) => _send('reward_check', orderId, code);

  @override
  Future<RewardCheck> redeem(String orderId, String code) => _send('reward_redeem', orderId, code);
}
