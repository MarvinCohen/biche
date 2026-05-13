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

# Cartes cadeaux + produits routine — créés ici car simples et génériques.
# Les PACKS de remplissage sont créés par un script dédié (db/setup_packs_remplissage.rb)
# car ils sont déclinés par pose × nb_remplissages = 18 produits.
produits = [
  { nom: "Carte cadeau",   description: "Valable sur toutes les prestations. La destinataire choisit sa date.", prix_cents: 6000, type_produit: "carte_cadeau", actif: true },
  { nom: "Nettoyant cils", description: "Mousse douce sans huile ni alcool.",                                   prix_cents: 1800, type_produit: "routine",      actif: true },
  { nom: "Brossette cils", description: "Pack de 10 brossettes jetables.",                                      prix_cents: 800,  type_produit: "routine",      actif: true },
  { nom: "Sérum cils",     description: "Sérum fortifiant pour cils naturels.",                                 prix_cents: 3200, type_produit: "routine",      actif: true },
  { nom: "Kit entretien",  description: "Nettoyant + brossettes + sérum.",                                      prix_cents: 5200, type_produit: "routine",      actif: true }
]

produits.each { |attrs| Product.create!(attrs) }

# Chargement des packs de remplissage (idempotent : utilise find_or_create_by!).
# Charge le script qui crée les 18 packs (6 poses × 3 quantités).
load Rails.root.join('db', 'setup_packs_remplissage.rb')

puts "  → #{Product.count} produits créés au total"

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

# ============================================================
# HORAIRES D'OUVERTURE — une ligne par jour de la semaine
# Convention Ruby pour `day_of_week` : 0 = dimanche … 6 = samedi
#
# Défaut : Calao Studio mardi → samedi, 9h → 18h, pause 12h30-13h30
# Dimanche et lundi : fermés (mais on crée quand même la ligne
# avec ouvert: false pour que Syam puisse rouvrir depuis l'admin).
#
# `find_or_create_by!` → idempotent : si la ligne existe déjà
# pour ce jour, on ne touche pas (Syam pourrait avoir modifié ses
# horaires entre temps).
# ============================================================
puts "\nCréation des horaires d'ouverture (par défaut)..."

# Horaires par défaut pour les jours ouvrés
# Pas de pause déjeuner par défaut — Syam peut en ajouter une plus tard via l'admin
horaires_ouvres = {
  heure_debut: "09:00",
  heure_fin:   "18:00",
  pause_debut: nil,
  pause_fin:   nil,
  pas_minutes: 90,
  ouvert:      true
}

# Définition des 7 jours
# day_of_week => attributs (on override `ouvert` pour dim et lun)
[
  [0, { ouvert: false }],  # Dimanche fermé
  [1, { ouvert: false }],  # Lundi fermé
  [2, {}],                 # Mardi → Samedi : valeurs par défaut
  [3, {}],
  [4, {}],
  [5, {}],
  [6, {}]
].each do |day, overrides|
  BusinessHour.find_or_create_by!(day_of_week: day) do |bh|
    # On part des valeurs ouvrées par défaut, et on applique les overrides
    attrs = horaires_ouvres.merge(overrides)
    bh.assign_attributes(attrs)
  end
  bh = BusinessHour.find_by(day_of_week: day)
  puts "  → #{bh.nom_jour} : #{bh.horaires_affichage}"
end

puts "\n✅ Seeds terminés ! #{Prestation.count} prestations, #{Product.count} produits, #{BusinessHour.count} jours configurés."
