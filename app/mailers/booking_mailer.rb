class BookingMailer < ApplicationMailer
  # ============================================================
  # Emails liés aux réservations
  # Chaque méthode prend un booking en paramètre et envoie
  # un email à la cliente associée.
  # ============================================================

  # Email 1 — Confirmation de réservation (envoyé juste après la création)
  # Déclenché par : BookingsController#create
  def confirmation_reservation(booking)
    # On stocke le booking dans une variable d'instance pour la vue
    @booking = booking
    @user    = booking.user

    # URL vers l'espace cliente (disponible grâce à default_url_options en config)
    @espace_url = espace_cliente_root_url

    mail(
      to:      @user.email,
      subject: "Votre réservation est enregistrée — Biche."
    )
  end

  # Email 2 — RDV confirmé par Syam (envoyé quand Syam clique "Confirmer")
  # Déclenché par : Admin::BookingsController#confirmer
  def rdv_confirme(booking)
    @booking = booking
    @user    = booking.user
    @espace_url = espace_cliente_root_url

    mail(
      to:      @user.email,
      subject: "Votre rendez-vous est confirmé ! — Biche."
    )
  end

  # Email 3 — Annulation par Syam (envoyé quand Syam annule un RDV)
  # Déclenché par : Admin::BookingsController#annuler
  def rdv_annule(booking)
    @booking = booking
    @user    = booking.user
    @espace_url = espace_cliente_root_url

    mail(
      to:      @user.email,
      subject: "Votre rendez-vous a été annulé — Biche."
    )
  end

  # Email 4 — Rappel 24h avant le rendez-vous
  # Déclenché par : Rake task (lib/tasks/emails.rake) via cron quotidien
  def rappel_rdv(booking)
    @booking = booking
    @user    = booking.user
    @espace_url = espace_cliente_root_url

    mail(
      to:      @user.email,
      subject: "Rappel — Votre rendez-vous est demain · Biche."
    )
  end
end
