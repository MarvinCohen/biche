// ============================================================
// Stimulus controller : œil pour afficher/masquer un mot de passe
//
// Usage : envelopper l'input dans un <div data-controller="password-toggle">
// et ajouter `data-password-toggle-target="input"` sur l'input, puis un
// bouton avec `data-action="click->password-toggle#toggle"` et deux <svg>
// ciblés par `data-password-toggle-target="iconShow"` / `iconHide"`.
//
// Le controller bascule simplement entre type="password" et type="text",
// et permute les deux icônes (œil ouvert / œil barré).
// ============================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Cibles dans le DOM : l'input + les deux icônes œil
  static targets = ["input", "iconShow", "iconHide"]

  // Hook Stimulus : au montage, on garantit l'état initial cohérent
  // (input masqué, icône "show" visible, icône "hide" cachée)
  connect() {
    this.inputTarget.type = "password"
    if (this.hasIconHideTarget) this.iconHideTarget.style.display = "none"
  }

  // Inverse l'état affiché/masqué + swap les icônes
  toggle(event) {
    // empêche le submit si jamais le bouton est dans un <form>
    event.preventDefault()

    // Si le champ est actuellement masqué → on l'affiche, sinon l'inverse
    const estMasque = this.inputTarget.type === "password"
    this.inputTarget.type = estMasque ? "text" : "password"

    // Swap des icônes : œil normal vs œil barré
    if (this.hasIconShowTarget && this.hasIconHideTarget) {
      this.iconShowTarget.style.display = estMasque ? "none" : ""
      this.iconHideTarget.style.display = estMasque ? "" : "none"
    }
  }
}
