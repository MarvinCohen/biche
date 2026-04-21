class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # ============================================================
  # DEVISE — Autoriser les champs supplémentaires du formulaire
  # Par défaut, Devise n'accepte que email + password.
  # On doit explicitement autoriser nos champs custom (first_name, last_name, phone).
  # ============================================================
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # Devise appelle cette méthode avant les actions d'inscription et de mise à jour du profil.
  # On "permet" nos champs custom pour qu'ils passent le filtre strong params.
  def configure_permitted_parameters
    # À l'inscription (sign_up) : on accepte prénom, nom, téléphone et date de naissance
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone, :birth_date])

    # À la modification du compte (account_update) : idem
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone, :birth_date])
  end
end
