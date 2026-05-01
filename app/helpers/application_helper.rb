module ApplicationHelper
  # Génère un QR code SVG inline pour un texte donné (code de carte cadeau, URL…)
  # Utilisable dans les vues ET les emails (SVG inline, pas besoin d'image externe)
  def qr_code_svg(texte, taille: 3)
    qr = RQRCode::QRCode.new(texte)
    # as_svg retourne un SVG inline — couleur noire sur fond transparent
    qr.as_svg(
      offset:          0,
      color:           '2e2926',   # Brun foncé de la charte Biche.
      shape_rendering: 'crispEdges',
      module_size:     taille,
      standalone:      true
    ).html_safe
  end
end
