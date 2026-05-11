# ============================================================
# SEEDS — Données réelles de l'Atelier Biche.
# Tarifs transmis par Syam (image tarifaire officielle + compléments)
# Lancer avec : rails db:seed
# ============================================================

puts "Suppression des anciennes prestations..."
Prestation.destroy_all
Product.destroy_all

puts "Création des prestations..."

prestations = [

  # ============================================================
  # EXTENSIONS — POSES COMPLÈTES
  # ============================================================
  {
    nom: "Demi-pose",
    description: "Extension sur la moitié des cils pour un effet naturel et léger.",
    duree_minutes: 90,
    prix_cents: 5000,          # 50€
    categorie: "extensions",
    disponible: true
  },
  {
    nom: "Cil à cil",
    description: "Une extension posée sur chaque cil naturel. Effet naturel et élégant.",
    duree_minutes: 120,        # 2h
    prix_cents: 6000,          # 60€
    categorie: "extensions",
    disponible: true
  },
  {
    nom: "Pose effet mouillé",
    description: "Technique wet look pour un regard intense et graphique.",
    duree_minutes: 120,
    prix_cents: 7000,          # 70€
    categorie: "extensions",
    disponible: true
  },
  {
    nom: "Volume léger",
    description: "2 à 3 extensions par cil pour un regard densifié et élégant.",
    duree_minutes: 150,        # 2h30
    prix_cents: 7000,          # 70€
    categorie: "extensions",
    disponible: true
  },
  {
    nom: "Volume intense",
    description: "Volume prononcé pour un regard dramatique et envoûtant.",
    duree_minutes: 150,
    prix_cents: 8000,          # 80€
    categorie: "extensions",
    disponible: true
  },
  {
    nom: "Pose Manga",
    description: "Effet manga XXL pour un regard ultra-expressif et théâtral.",
    duree_minutes: 180,        # 3h
    prix_cents: 8000,          # 80€
    categorie: "extensions",
    disponible: true
  },

  # ============================================================
  # RETOUCHES 2 SEMAINES (remplissages)
  # ============================================================
  {
    nom: "Remplissage Demi-pose — 2 semaines",
    description: "Remplissage de la demi-pose à 2 semaines.",
    duree_minutes: 45,
    prix_cents: 3000,          # 30€
    categorie: "retouche",
    disponible: true
  },
  {
    nom: "Remplissage Cil à cil — 2 semaines",
    description: "Remplissage cil à cil à 2 semaines.",
    duree_minutes: 60,
    prix_cents: 3000,          # 30€
    categorie: "retouche",
    disponible: true
  },
  {
    nom: "Remplissage Effet mouillé — 2 semaines",
    description: "Remplissage effet mouillé à 2 semaines.",
    duree_minutes: 60,
    prix_cents: 3500,          # 35€
    categorie: "retouche",
    disponible: true
  },
  {
    nom: "Remplissage Volume léger — 2 semaines",
    description: "Remplissage volume léger à 2 semaines.",
    duree_minutes: 60,
    prix_cents: 3500,          # 35€
    categorie: "retouche",
    disponible: true
  },
  {
    nom: "Remplissage Volume intense — 2 semaines",
    description: "Remplissage volume intense à 2 semaines.",
    duree_minutes: 75,
    prix_cents: 4000,          # 40€
    categorie: "retouche",
    disponible: true
  },
  {
    nom: "Remplissage Manga — 2 semaines",
    description: "Remplissage pose manga à 2 semaines.",
    duree_minutes: 75,
    prix_cents: 4500,          # 45€
    categorie: "retouche",
    disponible: true
  },

  # ============================================================
  # RETOUCHES 3 SEMAINES (remplissages)
  # Note : pas de retouche 3 semaines pour la Pose Manga
  # ============================================================
  {
    nom: "Remplissage Demi-pose — 3 semaines",
    description: "Remplissage de la demi-pose à 3 semaines.",
    duree_minutes: 60,
    prix_cents: 4000,          # 40€
    categorie: "retouche",
    disponible: true
  },
  {
    nom: "Remplissage Cil à cil — 3 semaines",
    description: "Remplissage cil à cil à 3 semaines.",
    duree_minutes: 75,
    prix_cents: 4000,          # 40€
    categorie: "retouche",
    disponible: true
  },
  {
    nom: "Remplissage Effet mouillé — 3 semaines",
    description: "Remplissage effet mouillé à 3 semaines.",
    duree_minutes: 75,
    prix_cents: 4500,          # 45€
    categorie: "retouche",
    disponible: true
  },
  {
    nom: "Remplissage Volume léger — 3 semaines",
    description: "Remplissage volume léger à 3 semaines.",
    duree_minutes: 75,
    prix_cents: 4500,          # 45€
    categorie: "retouche",
    disponible: true
  },
  {
    nom: "Remplissage Volume intense — 3 semaines",
    description: "Remplissage volume intense à 3 semaines.",
    duree_minutes: 90,
    prix_cents: 5000,          # 50€
    categorie: "retouche",
    disponible: true
  },

  # ============================================================
  # REHAUSSEMENT
  # ============================================================
  {
    nom: "Rehaussement de cils",
    description: "Courbure naturelle de vos cils sans extension. Regard ouvert et lumineux.",
    duree_minutes: 60,
    prix_cents: 4000,          # 40€
    categorie: "rehaussement",
    disponible: true
  },
  {
    nom: "Teinture + rehaussement",
    description: "Rehaussement de cils avec teinture incluse pour un regard plus intense.",
    duree_minutes: 75,
    prix_cents: 5000,          # 50€
    categorie: "rehaussement",
    disponible: true
  },

  # ============================================================
  # DÉPOSE
  # ============================================================
  {
    nom: "Dépose",
    description: "Retrait soigneux des extensions posées à l'atelier Biche.",
    duree_minutes: 30,
    prix_cents: 1000,          # 10€
    categorie: "depose",
    disponible: true
  },
  {
    nom: "Dépose extérieure",
    description: "Retrait d'extensions posées dans un autre salon.",
    duree_minutes: 45,
    prix_cents: 1500,          # 15€
    categorie: "depose",
    disponible: true
  }

]

prestations.each do |attrs|
  Prestation.create!(attrs)
end

puts "  → #{Prestation.count} prestations créées"

# --- PRODUITS SHOP ---
puts "Création des produits shop..."

produits = [
  { nom: "Carte cadeau",        description: "Valable sur toutes les prestations. La destinataire choisit sa date.", prix_cents: 6000, type_produit: "carte_cadeau", actif: true },
  { nom: "Pack 3 remplissages", description: "3 remplissages à utiliser en 3 mois. Économie de 15€.",              prix_cents: 12000, type_produit: "pack",         actif: true },
  { nom: "Pack 5 remplissages", description: "5 remplissages sur 5 mois. Brossette offerte. Économie de 30€.",     prix_cents: 19500, type_produit: "pack",         actif: true },
  { nom: "Pack 10 remplissages",description: "Un an de regard parfait. 1 pose offerte. Économie de 70€.",          prix_cents: 38000, type_produit: "pack",         actif: true },
  { nom: "Nettoyant cils",      description: "Mousse douce sans huile ni alcool.",                                  prix_cents: 1800,  type_produit: "routine",      actif: true },
  { nom: "Brossette cils",      description: "Pack de 10 brossettes jetables.",                                     prix_cents: 800,   type_produit: "routine",      actif: true },
  { nom: "Sérum cils",          description: "Sérum fortifiant pour cils naturels.",                                prix_cents: 3200,  type_produit: "routine",      actif: true },
  { nom: "Kit entretien",       description: "Nettoyant + brossettes + sérum.",                                     prix_cents: 5200,  type_produit: "routine",      actif: true }
]

produits.each { |attrs| Product.create!(attrs) }
puts "  → #{Product.count} produits créés"

# --- CLIENTE DE TEST ---
puts "Création de la cliente de test..."
user = User.find_or_create_by!(email: "marie@test.com") do |u|
  u.first_name = "Marie"
  u.last_name  = "Lefèvre"
  u.phone      = "06 12 34 56 78"
  u.birth_date = Date.new(1995, 4, 15)
  u.password   = "password123"
end

puts "  → marie@test.com / password123"

# ============================================================
# RÉGLAGES DU SITE — clés/valeurs éditables depuis l'admin
# On pré-crée les clés attendues avec une valeur vide pour que
# Syam les voie tout de suite dans le formulaire admin.
# `find_or_create_by!` → idempotent : ne crée pas de doublon si
# on relance les seeds plusieurs fois.
# ============================================================
puts "\nCréation des réglages du site..."
SiteSetting.find_or_create_by!(key: "tiktok_latest_url") do |s|
  s.value = ""  # Vide au départ → section TikTok masquée sur le site public
end
puts "  → tiktok_latest_url (vide)"

puts "\n✅ Seeds terminés ! #{Prestation.count} prestations, #{Product.count} produits."
