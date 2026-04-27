# ============================================================
# Preview des emails UserMailer
# Accessible sur : http://localhost:3000/rails/mailers/user_mailer
# ============================================================
class UserMailerPreview < ActionMailer::Preview

  # Preview : offre anniversaire
  # URL : /rails/mailers/user_mailer/offre_anniversaire
  def offre_anniversaire
    user = User.where(admin: false).first
    UserMailer.offre_anniversaire(user)
  end

end
