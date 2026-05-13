# ============================================================
# SCRIPT ONE-SHOT — Initialise les 7 horaires d'ouverture
#
# À lancer UNE FOIS après la migration `create_business_hours` :
#   bundle exec rails runner db/setup_business_hours.rb
#
# Idempotent : `find_or_create_by!` ne crée pas de doublon si on
# relance le script (les jours déjà créés ne sont pas modifiés).
#
# Différent du seed principal (db/seeds.rb) car celui-ci ne touche
# QUE la table business_hours — pas de destroy_all sur les autres
# modèles. Safe à lancer en présence de données existantes.
# ============================================================

puts "Initialisation des horaires d'ouverture..."

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

# Convention Ruby pour `day_of_week` : 0 = dimanche … 6 = samedi
# Dimanche et lundi : fermés (mais ligne créée pour que Syam puisse rouvrir)
[
  [0, { ouvert: false }],  # Dimanche fermé
  [1, { ouvert: false }],  # Lundi fermé
  [2, {}],                 # Mardi → Samedi : valeurs par défaut
  [3, {}],
  [4, {}],
  [5, {}],
  [6, {}]
].each do |day, overrides|
  # find_or_create_by! → ne crée pas si la ligne existe déjà
  BusinessHour.find_or_create_by!(day_of_week: day) do |bh|
    attrs = horaires_ouvres.merge(overrides)
    bh.assign_attributes(attrs)
  end
  bh = BusinessHour.find_by(day_of_week: day)
  puts "  → #{bh.nom_jour} : #{bh.horaires_affichage} (pas: #{bh.pas_minutes}min)"
end

puts "\n✅ #{BusinessHour.count} jours configurés."
