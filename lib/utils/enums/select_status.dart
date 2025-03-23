enum SelectStatus {
  none,
  all,
  some,
}

extension SelectStatusExtension on SelectStatus {
  bool? get value => switch (this) {
        SelectStatus.all => true,
        SelectStatus.none => false,
        SelectStatus.some => null,
      };
}
