require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Stockage des fichiers uploadés via Cloudinary (cloud).
  # On NE peut PAS utiliser :local sur Railway : le filesystem du
  # container est éphémère, donc à chaque redéploiement, tous les
  # uploads disparaitraient (photos galerie, vidéos admin, etc.).
  # La conf du service est dans config/storage.yml (clé `cloudinary`)
  # et les credentials sont injectés via variables d'env Railway :
  # CLOUDINARY_CLOUD_NAME / CLOUDINARY_API_KEY / CLOUDINARY_API_SECRET.
  config.active_storage.service = :cloudinary

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Cache en mémoire (in-process).
  # On évite :solid_cache_store qui nécessite une DB séparée + migrations
  # (db/cache_migrate). Pour le trafic actuel (admin Syam + quelques clientes),
  # le cache en mémoire est largement suffisant. Inconvénient : le cache
  # est perdu à chaque redéploiement Railway, mais ce n'est pas critique
  # (rien de couteux à recalculer ici).
  config.cache_store = :memory_store

  # Active Job en mode async : les jobs tournent dans un thread pool
  # in-process (pas de DB queue à gérer). Suffisant pour notre cas
  # d'usage (Active Storage AnalyzeJob après upload vidéo, etc.).
  # Limite : si Railway redémarre pendant un job, il est perdu — anodin
  # ici (juste de l'analyse de métadonnées). Si on ajoute des emails
  # critiques async plus tard, il faudra repasser sur Solid Queue ou
  # un service type Sidekiq + Redis.
  config.active_job.queue_adapter = :async

  # Remonte les erreurs d'envoi pour les détecter rapidement en prod
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true

  # URL de base pour les liens dans les emails (à mettre à jour avec le vrai domaine en prod)
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "example.com") }

  # Envoi via Resend SMTP
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              "smtp.resend.com",
    port:                 587,
    user_name:            "resend",
    password:             ENV["RESEND_API_KEY"],
    authentication:       :plain,
    enable_starttls_auto: true
  }

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via bin/rails credentials:edit.
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # ============================================================
  # Hôtes autorisés en production (anti DNS rebinding)
  # Rails 8 bloque par défaut toute requête venant d'un hôte non listé.
  # On autorise :
  #   - Tous les sous-domaines *.up.railway.app (URL générée par Railway)
  #   - Tous les sous-domaines *.railway.app (au cas où)
  #   - Le domaine custom si la variable APP_HOST est définie (ex: biche.fr)
  # ============================================================
  config.hosts << /.*\.up\.railway\.app/
  config.hosts << /.*\.railway\.app/
  config.hosts << ENV["APP_HOST"] if ENV["APP_HOST"].present?

  # Le endpoint /up (healthcheck Rails) doit rester accessible
  # même si l'hôte n'est pas dans la liste (utile pour Railway).
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
