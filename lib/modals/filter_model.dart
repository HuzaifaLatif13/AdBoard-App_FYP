class FilterModel {
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final String? category;
  final bool? isAvailable;
  final String? size;
  final DateTime? postedAfter;
  final DateTime? postedBefore;

  FilterModel({
    this.location,
    this.minPrice,
    this.maxPrice,
    this.category,
    this.isAvailable,
    this.size,
    this.postedAfter,
    this.postedBefore,
  });

  bool hasActiveFilters() {
    return location != null ||
        minPrice != null ||
        maxPrice != null ||
        category != null ||
        isAvailable != null ||
        size != null ||
        postedAfter != null ||
        postedBefore != null;
  }

  FilterModel copyWith({
    String? location,
    double? minPrice,
    double? maxPrice,
    String? category,
    bool? isAvailable,
    String? size,
    DateTime? postedAfter,
    DateTime? postedBefore,
  }) {
    return FilterModel(
      location: location ?? this.location,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      size: size ?? this.size,
      postedAfter: postedAfter ?? this.postedAfter,
      postedBefore: postedBefore ?? this.postedBefore,
    );
  }

  FilterModel clear() {
    return FilterModel();
  }
}
