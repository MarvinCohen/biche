// Stimulus controller — galerie-sort
// Gère le drag-and-drop pour réordonner les photos de la galerie admin.
// Utilise l'API HTML5 native (draggable) sans dépendance externe.
// Quand l'ordre change, envoie les IDs dans le nouvel ordre au serveur via PATCH AJAX.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Valeur stockée dans data-galerie-sort-url-value — URL de l'endpoint PATCH
  static values = { url: String }

  connect() {
    // Activer le drag-and-drop sur chaque item de la liste au montage du controller
    this._activerDrag()
  }

  _activerDrag() {
    const items = this.element.querySelectorAll('.admin-galerie-item')

    items.forEach(item => {
      // Rendre l'élément draggable
      item.setAttribute('draggable', 'true')

      // Quand on commence à glisser : mémoriser quel item est déplacé
      item.addEventListener('dragstart', e => {
        e.dataTransfer.setData('text/plain', item.dataset.id)
        item.classList.add('dragging')
      })

      // Nettoyage visuel quand on relâche
      item.addEventListener('dragend', () => {
        item.classList.remove('dragging')
      })

      // Quand un item passe au-dessus d'un autre : réorganiser visuellement la liste
      item.addEventListener('dragover', e => {
        e.preventDefault()
        const dragging = this.element.querySelector('.dragging')
        if (dragging && dragging !== item) {
          // Insérer l'élément en cours de déplacement avant ou après la cible
          const rect = item.getBoundingClientRect()
          const mid  = rect.top + rect.height / 2
          if (e.clientY < mid) {
            this.element.insertBefore(dragging, item)
          } else {
            this.element.insertBefore(dragging, item.nextSibling)
          }
        }
      })

      // Quand on relâche sur un item : sauvegarder le nouvel ordre
      item.addEventListener('drop', e => {
        e.preventDefault()
        this._sauvegarderOrdre()
      })
    })
  }

  // Envoyer le nouvel ordre au serveur via PATCH AJAX
  _sauvegarderOrdre() {
    // Récupérer les IDs dans leur ordre actuel dans le DOM
    const ids = Array.from(
      this.element.querySelectorAll('.admin-galerie-item')
    ).map(el => el.dataset.id)

    // Construire les données du formulaire avec le CSRF token Rails
    const body = new URLSearchParams()
    ids.forEach(id => body.append('ordre[]', id))

    fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: body.toString()
    })
    // Si succès silencieux : pas de rechargement, l'ordre est visuellement déjà correct
    // En cas d'erreur réseau on log dans la console pour debug
    .catch(err => console.error('Erreur réordonnancement galerie:', err))
  }
}
