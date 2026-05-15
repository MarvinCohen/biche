source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Authentification utilisateur
gem "devise"

# Paiement en ligne via Stripe
gem "stripe"

# Génération de QR codes (cartes cadeaux)
gem "rqrcode"

# Pagination des listes
gem "kaminari"

# Traductions françaises pour Rails (dates, ActiveRecord…)
gem "rails-i18n"

# Traductions françaises pour Devise (messages d'erreur connexion/inscription, etc.)
# Fournit automatiquement le fichier devise.fr.yml — pas besoin de le créer à la main.
gem "devise-i18n"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# NOTE : les gems Solid (cache/queue/cable) ont été retirées car
# elles nécessitent chacune une DB séparée + des migrations dédiées
# (db/cache_migrate, db/queue_migrate, db/cable_migrate) absentes du
# projet. Pour notre trafic actuel, on utilise des adapters in-process :
#   - Rails.cache  → :memory_store     (production.rb)
#   - Active Job   → :async            (production.rb)
#   - Action Cable → :async            (cable.yml)
# Si un jour on a besoin de queues persistantes ou de cache partagé
# entre plusieurs serveurs, on remettra solid_queue + une vraie config DB.

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
  # Charge les variables d'environnement depuis .env (clés Stripe, etc.)
  gem "dotenv-rails"
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Ouvre les emails dans le navigateur en dev plutôt que de les envoyer vraiment
  gem "letter_opener"
end
