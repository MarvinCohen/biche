class PagesController < ApplicationController
  # ============================================================
  # Pages informatives — accessibles sans authentification
  # ============================================================

  # GET / — Page d'accueil avec carrousel prestations
  def home
    # On charge les 4 premières prestations dispo pour le carrousel
    @prestations = Prestation.disponibles.par_nom.limit(4)
  end

  # GET /a-propos
  def about
  end

  # GET /faq
  def faq
  end

  # GET /galerie
  def galerie
  end

  # GET /morphologie
  def morphologie
  end

  # GET /avis
  def avis
  end

  # GET /contact
  def contact
  end
end
