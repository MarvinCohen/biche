# ============================================================
# SEEDS — Données de départ pour l'application Biche.
# Utilise find_or_create_by! pour éviter les doublons si on relance les seeds.
# Lancer avec : rails db:seed
# ============================================================

puts "Création des prestations..."

# --- PRESTATIONS (soins proposés par Syam) ---
prestations = [
  {
    nom: "Cil à cil",
    description: "Effet naturel, une extension posée sur chaque cil naturel pour un résultat élégant et discret.",
    duree_minutes: 120,       # 2h
    prix_cents: 6500,         # 65€ (on stocke en centimes pour éviter les problèmes d'arrondi)
    categorie: "extensions",
    disponible: true
  },
  {
    nom: "Volume léger",
    description: "Effet densifié avec 2 à 3 extensions par cil pour un regard intensifié et élégant.",
    duree_minutes: 150,       # 2h30
    prix_cents: 8000,         # 80€
    categorie: "extensions",
    disponible: true
  },
  {
    nom: "Volume russe",
    description: "Technique avancée pour un regard dramatique et ultra-volumineux.",
    duree_minutes: 180,       # 3h
    prix_cents: 9500,         # 95€
    categorie: "extensions",
    disponible: true
  },
  {
    nom: "Rehaussement de cils",
    description: "Courbure naturelle de vos cils, sans extension. Un regard ouvert et doux.",
    duree_minutes: 60,        # 1h
    prix_cents: 5500,         # 55€
    categorie: "rehaussement",
    disponible: true
  },
  {
    nom: "Retouche 2 semaines",
    description: "Entretien cil à cil pour maintenir un résultat parfait.",
    duree_minutes: 60,        # 1h
    prix_cents: 3500,         # 35€
    categorie: "retouche",
    disponible: true
  },
  {
    nom: "Retouche 3 semaines",
    description: "Entretien volume pour maintenir la densité entre les poses.",
    duree_minutes: 75,        # 1h15
    prix_cents: 4500,         # 45€
    categorie: "retouche",
    disponible: true
  },
  {
    nom: "Dépose",
    description: "Retrait soigneux des extensions sans abîmer les cils naturels.",
    duree_minutes: 30,
    prix_cents: 2000,         # 20€
    categorie: "retouche",
    disponible: true
  }
]

prestations.each do |attrs|
  Prestation.find_or_create_by!(nom: attrs[:nom]) do |p|
    p.description   = attrs[:description]
    p.duree_minutes = attrs[:duree_minutes]
    p.prix_cents    = attrs[:prix_cents]
    p.categorie     = attrs[:categorie]
    p.disponible    = attrs[:disponible]
  end
end

puts "  → #{Prestation.count} prestations créées"

# --- PRODUITS SHOP ---
puts "Création des produits shop..."

produits = [
  # Cartes cadeaux
  {
    nom: "Carte cadeau",
    description: "Valable sur toutes les prestations de l'atelier. La destinataire choisit sa date.",
    prix_cents: 6500,         # Prix de base, montant ajustable à la commande
    type_produit: "carte_cadeau",
    actif: true
  },
  # Packs multi-visites
  {
    nom: "Pack 3 retouches",
    description: "3 retouches 3 semaines à utiliser dans les 3 mois. Économie de 15€.",
    prix_cents: 12000,        # 120€ au lieu de 135€
    type_produit: "pack",
    actif: true
  },
  {
    nom: "Pack 5 retouches",
    description: "5 retouches sur 5 mois. Le plus choisi. Brossette offerte. Économie de 30€.",
    prix_cents: 19500,        # 195€ au lieu de 225€
    type_produit: "pack",
    actif: true
  },
  {
    nom: "Pack 10 retouches",
    description: "Un an de regard parfait. 1 pose offerte + produits entretien. Économie de 70€.",
    prix_cents: 38000,        # 380€ au lieu de 450€
    type_produit: "pack",
    actif: true
  },
  # Produits routine
  {
    nom: "Nettoyant cils",
    description: "Mousse douce sans huile ni alcool pour nettoyer vos extensions.",
    prix_cents: 1800,         # 18€
    type_produit: "routine",
    actif: true
  },
  {
    nom: "Brossette cils",
    description: "Pack de 10 brossettes jetables pour démêler vos extensions au quotidien.",
    prix_cents: 800,          # 8€
    type_produit: "routine",
    actif: true
  },
  {
    nom: "Sérum cils",
    description: "Sérum fortifiant pour renforcer vos cils naturels et prolonger la durée des extensions.",
    prix_cents: 3200,         # 32€
    type_produit: "routine",
    actif: true
  },
  {
    nom: "Kit entretien",
    description: "L'essentiel réuni : nettoyant + brossettes + sérum cils.",
    prix_cents: 5200,         # 52€
    type_produit: "routine",
    actif: true
  }
]

produits.each do |attrs|
  Product.find_or_create_by!(nom: attrs[:nom]) do |p|
    p.description  = attrs[:description]
    p.prix_cents   = attrs[:prix_cents]
    p.type_produit = attrs[:type_produit]
    p.actif        = attrs[:actif]
  end
end

puts "  → #{Product.count} produits créés"

# --- CLIENTE DE TEST (pour tester l'espace cliente) ---
puts "Création de la cliente de test..."

user = User.find_or_create_by!(email: "marie@test.com") do |u|
  u.first_name = "Marie"
  u.last_name  = "Lefèvre"
  u.phone      = "06 12 34 56 78"
  u.birth_date = Date.new(1995, 4, 15)
  u.password   = "password123"
end

puts "  → Cliente de test créée : marie@test.com / password123"
puts "\n✅ Seeds terminés !"
