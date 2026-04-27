class UserMailer < ApplicationMailer
  # ============================================================
  # Emails liés aux utilisatrices (hors réservations)
  # ============================================================

  # Email — Offre anniversaire (envoyé le jour de l'anniversaire de la cliente)
  # Déclenché par : Rake task (lib/tasks/emails.rake) via cron quotidien
  def offre_anniversaire(user)
    @user       = user
    @espace_url = espace_cliente_root_url
    @booking_url = new_booking_url

    mail(
      to:      @user.email,
      subject: "Joyeux anniversaire #{@user.first_name} 🎂 — Biche."
    )
  end
end
