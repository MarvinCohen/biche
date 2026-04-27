# ============================================================
# Rake tasks — Emails planifiés (exécutés quotidiennement via cron)
#
# INSTALLATION DU CRON :
# Ajouter dans le crontab du serveur (`crontab -e`) :
#
#   # Rappels RDV : tous les jours à 10h
#   0 10 * * * cd /chemin/vers/biche && bundle exec rails emails:rappels_rdv RAILS_ENV=production
#
#   # Offres anniversaire : tous les jours à 9h
#   0 9 * * * cd /chemin/vers/biche && bundle exec rails emails:anniversaires RAILS_ENV=production
#
# EN DÉVELOPPEMENT, lancer manuellement :
#   rails emails:rappels_rdv
#   rails emails:anniversaires
# ============================================================

namespace :emails do

  # ---- RAPPELS RDV (24h avant) ----
  desc "Envoie un email de rappel à toutes les clientes avec un RDV confirmé demain"
  task rappels_rdv: :environment do
    # On cherche tous les RDV confirmés dont la date est demain
    demain = Date.today + 1

    bookings_demain = Booking
                        .where(date: demain, statut: 'confirme')
                        .includes(:user, :prestation)

    puts "[emails:rappels_rdv] #{bookings_demain.count} rappel(s) à envoyer pour le #{demain}"

    bookings_demain.each do |booking|
      BookingMailer.rappel_rdv(booking).deliver_later
      puts "  → Rappel envoyé à #{booking.user.email} (#{booking.prestation.nom} à #{booking.heure.strftime('%Hh%M')})"
    end

    puts "[emails:rappels_rdv] Terminé."
  end

  # ---- OFFRES ANNIVERSAIRE ----
  desc "Envoie une offre anniversaire aux clientes dont c'est l'anniversaire aujourd'hui"
  task anniversaires: :environment do
    aujourd_hui = Date.today

    # On cherche les clientes (non admin) dont le mois et le jour de naissance
    # correspondent à aujourd'hui.
    # On exclut les clientes sans date de naissance renseignée.
    clientes_anniversaire = User
                              .where(admin: false)
                              .where.not(birth_date: nil)
                              .where(
                                "EXTRACT(month FROM birth_date) = ? AND EXTRACT(day FROM birth_date) = ?",
                                aujourd_hui.month,
                                aujourd_hui.day
                              )

    puts "[emails:anniversaires] #{clientes_anniversaire.count} anniversaire(s) aujourd'hui"

    clientes_anniversaire.each do |user|
      UserMailer.offre_anniversaire(user).deliver_later
      puts "  → Offre envoyée à #{user.email} (#{user.full_name})"
    end

    puts "[emails:anniversaires] Terminé."
  end

end
