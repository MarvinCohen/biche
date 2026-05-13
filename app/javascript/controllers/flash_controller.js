// ============================================================
// Stimulus controller : auto-dismiss des messages flash
//
// Branché automatiquement sur chaque .flash dans le layout via
// `data-controller="flash"`. Après un délai (configurable via la
// valeur `delay`, défaut 4000ms), la pastille s'efface en fondu
// puis est retirée du DOM.
//
// Pourquoi un controller ? Pour rester cohérent avec le reste du
// projet (Stimulus), garder le JS testable et permettre d'ajuster
// la durée par flash si besoin via `data-flash-delay-value`.
// ============================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Valeur exposée : durée en ms avant disparition (par défaut 4s)
  static values = { delay: { type: Number, default: 4000 } }

  // Hook Stimulus : appelé dès que l'élément est connecté au DOM
  connect() {
    // On planifie la disparition après `delayValue` ms
    this.timeout = setTimeout(() => this.dismiss(), this.delayValue)
  }

  // Au cas où l'élément est retiré avant la fin du timer (ex: turbo nav),
  // on nettoie pour ne pas laisser un setTimeout orphelin tourner.
  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  // Lance l'animation de sortie : fondu + glissement vers le haut
  // puis retire l'élément du DOM une fois la transition terminée.
  dismiss() {
    // On applique une transition CSS douce (300ms)
    this.element.style.transition = "opacity 0.3s ease, transform 0.3s ease"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(-10px)"

    // Une fois la transition finie, on supprime carrément l'élément
    // (sinon il occuperait encore de la place visuellement à 0% d'opacité)
    setTimeout(() => this.element.remove(), 300)
  }
}
