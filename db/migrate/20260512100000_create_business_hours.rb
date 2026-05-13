# ============================================================
# Migration — Horaires d'ouverture hebdomadaires
#
# Une ligne par jour de la semaine (7 lignes max).
# Syam édite ses horaires depuis l'admin (jour ouvert / fermé,
# heures d'ouverture, pause déjeuner, pas entre créneaux).
#
# Distinct de `indisponibilites` qui couvre l'ad-hoc (congé,
# fermeture exceptionnelle, etc.).
# ============================================================
class CreateBusinessHours < ActiveRecord::Migration[8.1]
  def change
    create_table :business_hours do |t|
      # Jour de la semaine selon la convention Ruby : 0 = dimanche … 6 = samedi
      # (correspond à `Date#wday`, ce qui simplifie la comparaison avec une date donnée)
      t.integer :day_of_week, null: false

      # Le jour est-il ouvré ? (false = fermé, aucun créneau proposé)
      t.boolean :ouvert, null: false, default: true

      # Heures d'ouverture du jour (ex : 09:00 → 18:00)
      t.time :heure_debut, null: false
      t.time :heure_fin,   null: false

      # Pause déjeuner — optionnelle, si renseignée bloque les créneaux qui la chevauchent
      t.time :pause_debut
      t.time :pause_fin

      # Intervalle (en minutes) entre deux débuts de créneau (ex : 90 = créneaux toutes les 1h30)
      t.integer :pas_minutes, null: false, default: 90

      t.timestamps
    end

    # Index unique : un seul enregistrement par jour de la semaine
    # (évite les doublons accidentels et accélère la lecture par jour)
    add_index :business_hours, :day_of_week, unique: true
  end
end
