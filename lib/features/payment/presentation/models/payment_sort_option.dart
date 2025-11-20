class PaymentSortOption {
  const PaymentSortOption({
    required this.title,
    required this.sortBy,
    required this.sortDirection,
  });

  final String title;
  final String sortBy;
  final String sortDirection;
}

const List<PaymentSortOption> paymentSortOptions = [
  PaymentSortOption(
    title: 'По дате — сначала новые',
    sortBy: 'date',
    sortDirection: 'desc',
  ),
  PaymentSortOption(
    title: 'По дате — сначала старые',
    sortBy: 'date',
    sortDirection: 'asc',
  ),
  PaymentSortOption(
    title: 'По сумме — от большего к меньшему',
    sortBy: 'paymentAmount',
    sortDirection: 'desc',
  ),
  PaymentSortOption(
    title: 'По сумме — от меньшего к большему',
    sortBy: 'paymentAmount',
    sortDirection: 'asc',
  ),
  PaymentSortOption(
    title: 'По клиенту — А–Я',
    sortBy: 'clientName',
    sortDirection: 'asc',
  ),
  PaymentSortOption(
    title: 'По клиенту — Я–А',
    sortBy: 'clientName',
    sortDirection: 'desc',
  ),
  PaymentSortOption(
    title: 'По договору — по возрастанию',
    sortBy: 'creditId',
    sortDirection: 'asc',
  ),
  PaymentSortOption(
    title: 'По договору — по убыванию',
    sortBy: 'creditId',
    sortDirection: 'desc',
  ),
];
