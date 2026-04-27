Rails.application.routes.draw do
  # ============================================================
  # DEVISE — authentification clientes
  # ============================================================
  devise_for :users

  # ============================================================
  # PAGES STATIQUES — informatives, accessibles à toutes
  # ============================================================
  get "a-propos",    to: "pages#about",      as: :about
  get "faq",         to: "pages#faq",         as: :faq
  get "galerie",     to: "pages#galerie",     as: :galerie
  get "morphologie", to: "pages#morphologie", as: :morphologie
  get "avis",        to: "pages#avis",        as: :avis
  get "contact",     to: "pages#contact",     as: :contact
  get "shop",        to: "pages#shop",        as: :shop

  # ============================================================
  # PRESTATIONS — catalogue des soins (lecture seule côté cliente)
  # ============================================================
  resources :prestations, only: [:index, :show]

  # ============================================================
  # RÉSERVATIONS — processus en 4 étapes
  # ============================================================
  resources :bookings, only: [:new, :create, :show, :destroy] do
    collection do
      # Créneaux disponibles pour une date donnée (appelé en AJAX)
      get :creneaux
      # Page de confirmation après paiement Stripe réussi
      get :success
    end
  end

  # ============================================================
  # ESPACE CLIENTE — zone privée (nécessite authentification)
  # ============================================================
  namespace :espace_cliente do
    # Tableau de bord principal
    root to: "dashboard#index"

    # Carte fidélité
    resource :fidelite, only: [:show], controller: "fidelite"

    # Rendez-vous à venir
    resources :rdvs, only: [:index]

    # Historique des soins passés
    resources :historique, only: [:index, :show]

    # Messages / newsletters reçus
    resources :messages, only: [:index, :show] do
      member do
        patch :marquer_lu  # Marquer un message comme lu
      end
    end

    # Profil et préférences
    resource :profil, only: [:show, :edit, :update], controller: "profil"
  end

  # ============================================================
  # ADMIN — interface de gestion pour Syam (accès restreint admin: true)
  # ============================================================
  namespace :admin do
    # Tableau de bord : planning du jour + stats
    root to: "dashboard#index"

    # Réservations : liste (avec filtre date), détail, changement de statut
    resources :bookings, only: [:index, :show] do
      member do
        patch :confirmer   # en_attente → confirme
        patch :terminer    # confirme  → termine
        patch :annuler     # * → annule
      end
    end

    # Fiches techniques post-soin (créées par Syam après chaque prestation)
    resources :soins_historiques, only: [:new, :create, :edit, :update]

    # Clientes : liste et profil complet
    resources :users, only: [:index, :show]

    # Messages : envoi de newsletters / notifications aux clientes
    resources :messages, only: [:new, :create]
  end

  # ============================================================
  # SHOP — boutique en ligne (à connecter aux paiements Stripe plus tard)
  # ============================================================
  resources :orders, only: [:new, :create, :show]

  # ============================================================
  # STRIPE — webhooks de paiement (appelé par Stripe directement)
  # ============================================================
  post "stripe/webhook", to: "stripe#webhook", as: :stripe_webhook

  # ============================================================
  # SANTÉ DE L'APPLICATION — pour les load balancers
  # ============================================================
  get "up" => "rails/health#show", as: :rails_health_check

  # ============================================================
  # PAGE D'ACCUEIL
  # ============================================================
  root to: "pages#home"
end
