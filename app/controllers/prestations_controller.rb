class PrestationsController < ApplicationController
  # ============================================================
  # Catalogue des soins — lecture seule, accessible à toutes
  # ============================================================

  # GET /prestations — liste complète des soins avec tarifs
  def index
    # Toutes les prestations disponibles, triées alphabétiquement
    @prestations = Prestation.disponibles.par_nom

    # Filtre par catégorie si un paramètre est passé (via les onglets de la maquette)
    @prestations = @prestations.where(categorie: params[:categorie]) if params[:categorie].present?
  end

  # GET /prestations/:id — détail d'un soin
  def show
    @prestation = Prestation.find(params[:id])
  end
end
