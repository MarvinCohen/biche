# Initializer Stripe — configure la clé secrète au démarrage de l'application
# La clé est lue depuis la variable d'environnement (fichier .env en dev, variable système en prod)
Stripe.api_key = ENV['STRIPE_SECRET_KEY']
