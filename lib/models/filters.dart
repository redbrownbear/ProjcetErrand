class Filters {
  int maxPrice;
  double maxDist;
  String gender;
  int ageMin, ageMax;
  Filters({this.maxPrice = 30000, this.maxDist = 2, this.gender = 'all', this.ageMin = 20, this.ageMax = 60});
  Filters copy() => Filters(maxPrice: maxPrice, maxDist: maxDist, gender: gender, ageMin: ageMin, ageMax: ageMax);
}
