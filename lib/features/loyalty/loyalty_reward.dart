/// A reward the customer chose in the Kahwti app, as the backend describes its code.
class LoyaltyReward {
  final String id, rewardName, kind, customerName;
  final int points;

  /// free_product: the product offered. amount_off: millimes off the ticket.
  final String? productId;
  final int? amount;

  /// A gift the café sent to this customer (no points spent).
  final bool gift;

  const LoyaltyReward({
    required this.id,
    required this.rewardName,
    required this.kind,
    required this.customerName,
    required this.points,
    this.productId,
    this.amount,
    this.gift = false,
  });

  factory LoyaltyReward.fromJson(Map<String, dynamic> j) => LoyaltyReward(
    id: j['id'] as String,
    rewardName: j['rewardName'] as String,
    kind: j['kind'] as String,
    customerName: (j['customerName'] as String?) ?? '',
    points: j['points'] as int,
    productId: j['productId'] as String?,
    amount: j['amount'] as int?,
    gift: j['gift'] == true,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'rewardName': rewardName,
    'kind': kind,
    'customerName': customerName,
    'points': points,
    'productId': productId,
    'amount': amount,
    'gift': gift,
  };
}

/// How a reward goes on the ticket (decided before any point is spent).
class RewardPlan {
  final List<String> lineIds;

  /// DiscountType.free or DiscountType.amount.
  final String type;
  final int value;

  /// "1 × Express offert", "Remise de 5.000 DT sur le ticket".
  final String description;

  const RewardPlan({required this.lineIds, required this.type, required this.value, required this.description});
}

/// What the cashier sees: the reward, who it is for, what it will do on this ticket.
class RewardCheck {
  final LoyaltyReward reward;
  final String description;
  const RewardCheck(this.reward, this.description);

  Map<String, Object?> toJson() => {'reward': reward.toJson(), 'description': description};
  factory RewardCheck.fromJson(Map<String, dynamic> j) =>
      RewardCheck(LoyaltyReward.fromJson((j['reward'] as Map).cast<String, dynamic>()), j['description'] as String);
}
