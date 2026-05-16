enum PaymentMethod {
  efectivo,
  tarjeta,
  transferencia,
}

extension PaymentMethodExtension on PaymentMethod {
  String get name {
    switch (this) {
      case PaymentMethod.efectivo:
        return 'Efectivo';
      case PaymentMethod.tarjeta:
        return 'Tarjeta';
      case PaymentMethod.transferencia:
        return 'Transferencia';
    }
  }
}
