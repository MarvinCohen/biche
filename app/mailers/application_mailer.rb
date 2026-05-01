class ApplicationMailer < ActionMailer::Base
  # Adresse expéditrice — domaine de test Resend (onboarding@resend.dev)
  # À remplacer par l'adresse réelle une fois le domaine biche-bordeaux.fr vérifié dans Resend
  default from: "Biche. <onboarding@resend.dev>"

  # Layout HTML commun à tous les emails (app/views/layouts/mailer.html.erb)
  layout "mailer"

  # Rend disponible les helpers de l'application dans les vues des mailers
  # Nécessaire pour qr_code_svg (défini dans ApplicationHelper)
  helper :application
end
