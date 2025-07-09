class Address {
  final String id;
  final double? latitude;
  final double? longitude;
  final String shortText;
  final String longText;
  final String? street;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  Address({
    this.id = '',
    this.latitude,
    this.longitude,
    this.shortText = '',
    this.longText = '',
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['Id'] ?? '',
      latitude: (json['Latitute'] as num?)?.toDouble(),
      longitude: (json['Longtitute'] as num?)?.toDouble(),
      shortText: json['ShortText'] ?? '',
      longText: json['LongText'] ?? '',
      street: json['Street'],
      city: json['City'],
      state: json['State'],
      postalCode: json['PostalCode'],
      country: json['Country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Latitute': latitude,
      'Longtitute': longitude,
      'ShortText': shortText,
      'LongText': longText,
      // Remove null address fields as per requirements
    };
  }

  String getFormattedAddress() {
    if (longText.isNotEmpty) return longText;
    if (shortText.isNotEmpty) return shortText;

    List<String> parts = [];
    if (street?.isNotEmpty == true) parts.add(street!);
    if (city?.isNotEmpty == true) parts.add(city!);
    if (state?.isNotEmpty == true) parts.add(state!);
    if (postalCode?.isNotEmpty == true) parts.add(postalCode!);
    if (country?.isNotEmpty == true) parts.add(country!);

    return parts.join(', ');
  }

  Address copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? shortText,
    String? longText,
    String? street,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  }) {
    return Address(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      shortText: shortText ?? this.shortText,
      longText: longText ?? this.longText,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        other.id == id &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.shortText == shortText &&
        other.longText == longText &&
        other.street == street &&
        other.city == city &&
        other.state == state &&
        other.postalCode == postalCode &&
        other.country == country;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        shortText.hashCode ^
        longText.hashCode ^
        street.hashCode ^
        city.hashCode ^
        state.hashCode ^
        postalCode.hashCode ^
        country.hashCode;
  }

  @override
  String toString() {
    return 'Address(id: $id, latitude: $latitude, longitude: $longitude, shortText: $shortText, longText: $longText, street: $street, city: $city, state: $state, postalCode: $postalCode, country: $country)';
  }
}
