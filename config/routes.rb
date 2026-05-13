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

    # Crédits de remplissage (issus des packs achetés en boutique)
    # Page dédiée : la cliente consulte ses crédits actifs et l'historique.
    resources :credits, only: [:index]
  end

  # ============================================================
  # ADMIN — interface de gestion pour Syam (accès restreint admin: true)
  # ============================================================
  namespace :admin do
    # Tableau de bord : planning du jour + stats
    root to: "dashboard#index"

    # Réservations : détail, changement de statut, création manuelle.
    # Plus d'action `index` : la liste du jour est intégrée au dashboard
    # (admin/dashboard#index sert de planning du jour avec navigation par date).
    resources :bookings, only: [:show, :new, :create] do
      collection do
        get :creneaux  # Créneaux disponibles toutes les 15 min (AJAX pour le formulaire admin)
      end
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

    # Prestations : CRUD complet — Syam peut créer, modifier et supprimer des prestations
    resources :prestations, only: [:index, :new, :create, :edit, :update, :destroy]

    # Messages : envoi de newsletters / notifications aux clientes
    resources :messages, only: [:new, :create]

    # Produits boutique : CRUD complet
    resources :products, only: [:index, :new, :create, :edit, :update, :destroy]

    # Indisponibilités : Syam peut bloquer des créneaux (pause, congé, etc.)
    # `index` et `new` ne sont plus exposés : la gestion est centralisée dans la page
    # `admin/disponibilites` (qui inclut un form de création et la liste).
    resources :indisponibilites, only: [:create, :destroy]

    # Cartes cadeaux : Syam peut consulter les cartes, voir le solde et déduire un montant
    resources :cartes_cadeaux, only: [:index, :show] do
      member do
        post :deduire  # Déduire un montant du solde de la carte
      end
      collection do
        get :scanner   # Page de scan / recherche par code
      end
    end

    # Galerie photos : Syam peut ajouter, supprimer et réordonner les photos de la galerie
    resources :galerie_photos, only: [:index, :new, :create, :destroy] do
      collection do
        # Endpoint AJAX pour sauvegarder le nouvel ordre après drag-and-drop
        patch :reordonner
      end
    end

    # Vidéos Instagram : Syam peut ajouter, modifier, supprimer et réordonner
    resources :videos, only: [:index, :new, :create, :edit, :update, :destroy] do
      collection do
        # Endpoint AJAX pour sauvegarder le nouvel ordre après drag-and-drop
        patch :reordonner
      end
    end

    # Agenda semaine : vue sur 7 jours
    get 'agenda', to: 'dashboard#agenda', as: :agenda

    # Réglages du site : édition de réglages globaux clé/valeur
    # (ex : URL de la dernière vidéo TikTok à afficher sur home + galerie)
    # `resource` (singulier) car il n'y a qu'une seule page de réglages,
    # pas une liste de réglages à parcourir.
    resource :site_settings, only: %i[edit update]

    # Horaires d'ouverture hebdomadaires : Syam édite ses 7 jours depuis la page Disponibilités.
    # On expose uniquement `update` — la liste est servie par `admin/disponibilites#index`.
    resources :business_hours, only: %i[update]

    # Page centralisée de gestion des disponibilités (horaires hebdo + fermetures exceptionnelles).
    # Une seule action `index` car c'est une vue composite (pas un CRUD).
    get 'disponibilites', to: 'disponibilites#index', as: :disponibilites
  end

  # ============================================================
  # SHOP — boutique en ligne (à connecter aux paiements Stripe plus tard)
  # ============================================================
  resources :orders, only: [:new, :create, :show] do
    collection do
      # Page de confirmation après paiement Stripe réussi
      get :success

      # ----- Achat d'un pack de remplissages -----
      # Flux séparé du flux carte cadeau (qui passe par Stripe).
      # Pour la démo, l'achat est confirmé immédiatement (statut paye direct)
      # et un Credit est créé pour la cliente. TODO : brancher Stripe plus tard.
      get  :new_pack    # GET  /orders/new_pack?product_id=X — page de récap
      post :create_pack # POST /orders/create_pack          — finalise l'achat
    end
  end

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
