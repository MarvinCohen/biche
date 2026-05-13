# ============================================================
# Script de création des packs de remplissage
#
# Idempotent : utilise `find_or_create_by!` sur (prestation_id, nb_remplissages)
# → on peut le relancer sans dupliquer ni écraser les modifications de Syam.
#
# Lancement :
#   rails runner db/setup_packs_remplissage.rb
#
# Création des packs :
# - 6 types de pose × 3 quantités (3, 6, 9) = 18 packs
# - Prix = moyenne des retouches 2 sem / 3 sem de cette pose
#   × nombre de remplissages × (1 - remise)
# - Remises : 0% pour pack 3, 10% pour pack 6, 15% pour pack 9
# ============================================================

puts "Création des packs de remplissage..."

# Configuration des packs : pour chaque pose, le prix moyen unitaire.
# La pose Manga n'a pas de retouche 3 sem → on utilise uniquement le prix 2 sem.
# (Données extraites du tableau de retouches dans seeds.rb.)
POSES_CONFIG = [
  { nom_prestation: "Demi-pose",         prix_moyen_euros: 35 },
  { nom_prestation: "Cil à cil",         prix_moyen_euros: 35 },
  { nom_prestation: "Pose effet mouillé", prix_moyen_euros: 40 },
  { nom_prestation: "Volume léger",      prix_moyen_euros: 40 },
  { nom_prestation: "Volume intense",    prix_moyen_euros: 45 },
  { nom_prestation: "Pose Manga",        prix_moyen_euros: 45 }
].freeze

# Quantités proposées avec la remise associée (en % d'éco).
# Centralisé ici pour pouvoir l'ajuster facilement.
QUANTITES = [
  { nb: 3, remise: 0.00 },   # Pas de remise sur le petit pack
  { nb: 6, remise: 0.10 },   # -10% sur le pack moyen
  { nb: 9, remise: 0.15 }    # -15% sur le grand pack
].freeze

# Compteurs pour le récap de fin
crees = 0
existants = 0

POSES_CONFIG.each do |pose|
  # Cherche la prestation de pose complète (catégorie 'extensions')
  # par son nom. Si elle n'existe pas, on log et on passe — évite un
  # crash en cas de seed partielle ou de renommage non répercuté.
  prestation = Prestation.find_by(nom: pose[:nom_prestation], categorie: 'extensions')

  unless prestation
    puts "  ⚠ Prestation \"#{pose[:nom_prestation]}\" introuvable — packs ignorés."
    next
  end

  QUANTITES.each do |q|
    # Calcul du prix final : moyenne × quantité × (1 - remise), arrondi à l'euro.
    prix_brut    = pose[:prix_moyen_euros] * q[:nb]
    prix_remise  = (prix_brut * (1 - q[:remise])).round
    prix_cents   = prix_remise * 100

    # find_or_create_by! : on identifie un pack par (prestation_id, nb_remplissages).
    # Si Syam a déjà modifié le prix ou la description d'un pack existant,
    # ses modifications sont préservées (le bloc n'est exécuté qu'à la création).
    pack = Product.find_or_create_by!(
      prestation_id: prestation.id,
      nb_remplissages: q[:nb],
      type_produit: 'pack'
    ) do |p|
      p.nom         = "Pack #{q[:nb]} remplissages — #{pose[:nom_prestation]}"
      p.description = "#{q[:nb]} remplissages de #{pose[:nom_prestation].downcase} à utiliser " \
                      "dans les #{q[:nb]} mois suivant l'achat." +
                      (q[:remise].positive? ? " Économie de #{(q[:remise] * 100).to_i}%." : "")
      p.prix_cents  = prix_cents
      p.actif       = true
    end

    # On distingue création réelle vs ligne déjà présente (logs lisibles)
    if pack.previously_new_record?
      crees += 1
      puts "  ✓ #{pack.nom} → #{prix_remise}€"
    else
      existants += 1
    end
  end
end

puts "  → #{crees} pack(s) créé(s), #{existants} déjà existant(s)."
