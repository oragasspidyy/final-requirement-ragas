import '../models/models.dart';

/// Service categories shown as filter chips.
const List<String> serviceCategories = [
  'All',
  'Veterinary',
  'Grooming',
  'Vaccination',
  'Dental',
  'Wellness',
];

/// Time slots offered by providers (Mon–Sat).
const List<String> timeSlots = [
  '9:00 AM',
  '10:00 AM',
  '11:30 AM',
  '1:00 PM',
  '2:30 PM',
  '4:00 PM',
];

const List<String> speciesOptions = ['Dog', 'Cat', 'Rabbit', 'Bird', 'Other'];

const Map<String, List<String>> breedOptions = {
  'Dog': [
    'Aspin',
    'Shih Tzu',
    'Labrador Retriever',
    'Golden Retriever',
    'Poodle',
    'Pomeranian',
    'Chihuahua',
    'Siberian Husky',
    'Beagle',
    'Dachshund',
    'Mixed',
    'Other',
  ],
  'Cat': [
    'Puspin',
    'Persian',
    'Siamese',
    'British Shorthair',
    'Maine Coon',
    'Ragdoll',
    'Mixed',
    'Other',
  ],
  'Rabbit': ['Holland Lop', 'Netherland Dwarf', 'Lionhead', 'Mixed', 'Other'],
  'Bird': ['Lovebird', 'Parakeet', 'Cockatiel', 'Parrot', 'Other'],
  'Other': ['Other'],
};

const List<String> vaccineOptions = [
  'Anti-Rabies',
  '5-in-1 (DHPPL)',
  '6-in-1 (DHPPiL+CV)',
  '4-in-1 (FVRCP)',
  'Kennel Cough (Bordetella)',
  'Leptospirosis',
  'Feline Leukemia (FeLV)',
  'Deworming',
  'Other',
];

const List<PetService> serviceCatalog = [
  PetService(
    id: 'vet-consultation',
    name: 'Vet Consultation',
    category: 'Veterinary',
    provider: 'Davao Vet Clinic',
    location: 'Bajada, Davao City',
    price: 500,
    priceLabel: '₱500',
    duration: '30 min',
    rating: 4.8,
    reviews: 98,
    image: 'assets/images/service_vet.jpg',
    description:
        'A complete check-up with a licensed veterinarian. Bring your pet in for '
        'any health concern — from skin problems and loss of appetite to '
        'follow-up visits after treatment. The vet will examine your pet and '
        'recommend the next steps.',
    includes: [
      'Physical examination',
      'Weight & temperature check',
      'Health advice',
      'Prescription if needed',
    ],
    hours: 'Mon–Sat · 8:00 AM – 5:00 PM',
    phone: '(082) 234 5678',
  ),
  PetService(
    id: 'full-grooming',
    name: 'Full Grooming',
    category: 'Grooming',
    provider: 'Happy Paws Grooming',
    location: 'Matina, Davao City',
    price: 650,
    priceLabel: '₱650',
    duration: '1.5 hrs',
    rating: 4.7,
    reviews: 120,
    image: 'assets/images/service_grooming.jpg',
    description:
        'Head-to-tail pampering for your pet. Our groomers use gentle, '
        'pet-safe shampoos and take extra care with nervous pets. Perfect '
        'for keeping your pet clean, comfortable and looking their best.',
    includes: ['Bath and blow-dry', 'Haircut', 'Nail trim', 'Ear cleaning'],
    hours: 'Mon–Sat · 9:00 AM – 6:00 PM',
    phone: '(082) 123 4567',
  ),
  PetService(
    id: 'vaccination',
    name: 'Vaccination',
    category: 'Vaccination',
    provider: 'Davao Vet Clinic',
    location: 'Bajada, Davao City',
    price: 350,
    priceLabel: '₱350+',
    duration: '15 min',
    rating: 4.9,
    reviews: 143,
    image: 'assets/images/service_vaccination.jpg',
    description:
        'Keep your pet protected with core and non-core vaccines such as '
        'Anti-Rabies, 5-in-1 and 4-in-1. Price depends on the vaccine. '
        'Your vaccination card will be updated during the visit.',
    includes: [
      'Pre-vaccination check',
      'Vaccine administration',
      'Vaccination card update',
      'Next-dose schedule',
    ],
    hours: 'Mon–Sat · 8:00 AM – 5:00 PM',
    phone: '(082) 234 5678',
  ),
  PetService(
    id: 'dental-cleaning',
    name: 'Dental Cleaning',
    category: 'Dental',
    provider: 'PetSmile Dental Care',
    location: 'Lanang, Davao City',
    price: 1200,
    priceLabel: '₱1,200',
    duration: '1 hr',
    rating: 4.6,
    reviews: 57,
    image: 'assets/images/service_dental.jpg',
    description:
        'Professional teeth cleaning to remove plaque and tartar, prevent gum '
        'disease and freshen your pet\'s breath. Recommended once a year for '
        'most dogs and cats.',
    includes: [
      'Oral examination',
      'Scaling & polishing',
      'Gum health check',
      'Home-care tips',
    ],
    hours: 'Mon–Sat · 9:00 AM – 5:00 PM',
    phone: '(082) 345 6789',
  ),
  PetService(
    id: 'wellness-checkup',
    name: 'Wellness Check-up',
    category: 'Wellness',
    provider: 'Davao Vet Clinic',
    location: 'Bajada, Davao City',
    price: 800,
    priceLabel: '₱800',
    duration: '45 min',
    rating: 4.8,
    reviews: 76,
    image: 'assets/images/service_wellness.jpg',
    description:
        'A preventive health package for healthy pets. Catch problems early '
        'with a thorough check of your pet\'s heart, lungs, skin, eyes and ears, '
        'plus nutrition and weight advice.',
    includes: [
      'Full body exam',
      'Heart & lung check',
      'Nutrition advice',
      'Parasite check',
    ],
    hours: 'Mon–Sat · 8:00 AM – 5:00 PM',
    phone: '(082) 234 5678',
  ),
  PetService(
    id: 'nail-trim-bath',
    name: 'Nail Trim & Bath',
    category: 'Grooming',
    provider: 'Happy Paws Grooming',
    location: 'Matina, Davao City',
    price: 300,
    priceLabel: '₱300',
    duration: '40 min',
    rating: 4.5,
    reviews: 88,
    image: 'assets/images/service_bath.jpg',
    description:
        'A quick refresh between full grooming sessions: a relaxing bath with '
        'pet-safe shampoo and a careful nail trim.',
    includes: ['Bath and towel-dry', 'Nail trim', 'Paw cleaning'],
    hours: 'Mon–Sat · 9:00 AM – 6:00 PM',
    phone: '(082) 123 4567',
  ),
];

PetService? serviceById(String id) {
  for (final s in serviceCatalog) {
    if (s.id == id) return s;
  }
  return null;
}
