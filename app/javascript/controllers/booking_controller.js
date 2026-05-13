// Stimulus controller — Formulaire de réservation en 4 étapes
// Gère : navigation entre étapes, sélection prestation, calendrier, créneaux, récap

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  // ============================================================
  // TARGETS — éléments HTML reliés au controller
  // ============================================================
  static targets = [
    // Étapes (sections affichées/cachées)
    "step",
    "stepIndicator",

    // Étape 1 — choix du soin
    "prestationOption",
    "prestationId",      // input hidden
    "prestationNom",     // pour le récap
    "prestationPrix",    // pour le récap
    "prestationDuree",   // pour le récap

    // Étape 2 — calendrier
    "calMonth",          // libellé "Avril 2026"
    "calDays",           // grille des jours
    "dateInput",         // input hidden
    "dateLabel",         // "Créneaux disponibles — Samedi 18 avril"
    "slotsGrid",         // grille des créneaux horaires
    "heureInput",        // input hidden

    // Étape 3 — paiement
    "paymentOpt",
    "paymentInput",      // input hidden
    "creditOption",      // 3e option de paiement — affichée si un crédit est applicable
    "creditCount",       // span "(X restants)" dans le libellé de l'option crédit
    "creditIdInput",     // input hidden pour le credit_id sélectionné

    // Étape 4 — récap
    "recapPrestation",
    "recapDate",
    "recapHeure",
    "recapHeureFin",
    "recapPrix",
    "recapAcompte",
    "recapAcompteRow",   // ligne entière "Acompte dû" — cachée si paiement par crédit
    "recapGarantie",
    "submitBtn",         // bouton de soumission — libellé adapté selon mode paiement
    "confirmNote"        // note explicative sous le bouton — adaptée aussi
  ]

  // ============================================================
  // VALEURS passées depuis le HTML (data attributes)
  // ============================================================
  static values = {
    creneauxUrl: String,   // URL de l'endpoint AJAX créneaux
    prestationId: Number,  // Prestation pré-sélectionnée (depuis le lien "Je réserve")
    // Jours de la semaine fermés (0=dim … 6=sam) — vient de BusinessHour côté serveur
    // Default vide : si la table n'est pas configurée, tous les jours sont ouverts.
    joursFermes: { type: Array, default: [] },
    // Dates spécifiques bloquées « jour entier » (format "YYYY-MM-DD") — vient d'Indisponibilite
    // Permet de griser un lundi ponctuel sans toucher à la semaine type.
    joursBloques: { type: Array, default: [] },
    // Crédits actifs de la cliente — utilisés pour afficher dynamiquement
    // l'option "Utiliser un crédit" si une retouche applicable est choisie.
    // Format : [{ id, prestation_id, prestation_nom, nb_restant }, ...]
    creditsActifs: { type: Array, default: [] }
  }

  // ============================================================
  // ÉTAT INTERNE du formulaire
  // ============================================================
  connect() {
    // Étape courante (0 = soin, 1 = date, 2 = paiement, 3 = récap)
    this.currentStep = 0

    // Date affichée dans le calendrier (mois courant par défaut)
    this.calYear  = new Date().getFullYear()
    this.calMonth = new Date().getMonth()  // 0-indexé

    // Sélections de l'utilisatrice
    this.selectedPrestationId    = null
    this.selectedPrestationNom   = null
    this.selectedPrestationPrix  = null
    this.selectedPrestationDuree = null
    this.selectedDate            = null
    this.selectedDateLabel       = null
    this.selectedHeure           = null
    this.selectedPayment         = null

    // Afficher la première étape
    this.showStep(0)

    // Pré-sélectionner une prestation si l'URL contient ?prestation_id=X
    if (this.prestationIdValue > 0) {
      const option = this.prestationOptionTargets.find(
        el => el.dataset.prestationId == this.prestationIdValue
      )
      if (option) this.doSelectPrestation(option)
    }

    // Générer le calendrier du mois en cours
    this.renderCalendar()
  }

  // ============================================================
  // NAVIGATION ENTRE ÉTAPES
  // ============================================================

  // Avancer à l'étape suivante (avec validation minimale)
  nextStep(event) {
    event.preventDefault()

    if (this.currentStep === 0 && !this.selectedPrestationId) {
      alert("Veuillez choisir une prestation.")
      return
    }
    if (this.currentStep === 1 && !this.selectedDate) {
      alert("Veuillez choisir une date.")
      return
    }
    if (this.currentStep === 1 && !this.selectedHeure) {
      alert("Veuillez choisir un créneau horaire.")
      return
    }
    if (this.currentStep === 2 && !this.selectedPayment) {
      alert("Veuillez choisir un mode de garantie.")
      return
    }

    this.currentStep++
    this.showStep(this.currentStep)

    // Mettre à jour le récap à l'étape 3
    if (this.currentStep === 3) this.updateRecap()
  }

  // Revenir à l'étape précédente
  prevStep(event) {
    event.preventDefault()
    if (this.currentStep > 0) {
      this.currentStep--
      this.showStep(this.currentStep)
    }
  }

  // Afficher uniquement l'étape courante et mettre à jour les indicateurs
  showStep(index) {
    // Afficher/cacher les sections d'étape
    this.stepTargets.forEach((step, i) => {
      step.style.display = i === index ? "block" : "none"
    })

    // Mettre à jour les cercles d'indicateur en haut
    this.stepIndicatorTargets.forEach((indicator, i) => {
      indicator.classList.remove("done", "active", "todo")
      if (i < index)      indicator.classList.add("done")
      else if (i === index) indicator.classList.add("active")
      else                  indicator.classList.add("todo")

      // Le texte intérieur : ✓ si terminé, numéro si pas encore
      indicator.textContent = i < index ? "✓" : i + 1
    })
  }

  // ============================================================
  // ÉTAPE 1 — SÉLECTION DE LA PRESTATION
  // ============================================================

  // Appelé au clic sur une option de prestation
  selectPrestation(event) {
    this.doSelectPrestation(event.currentTarget)
  }

  doSelectPrestation(el) {
    // Enlever la sélection de toutes les options
    this.prestationOptionTargets.forEach(opt => opt.classList.remove("selected"))

    // Marquer l'option cliquée comme sélectionnée
    el.classList.add("selected")

    // Lire les données depuis les data attributes de l'élément
    this.selectedPrestationId    = el.dataset.prestationId
    this.selectedPrestationNom   = el.dataset.prestationNom
    this.selectedPrestationPrix  = el.dataset.prestationPrix
    this.selectedPrestationDuree = parseInt(el.dataset.prestationDuree)

    // Mettre à jour l'input hidden du formulaire
    this.prestationIdTarget.value = this.selectedPrestationId

    // Mettre à jour le radio circle visuel
    this.prestationOptionTargets.forEach(opt => {
      const circle = opt.querySelector(".radio-circle")
      if (circle) circle.classList.toggle("checked", opt === el)
    })

    // Actualiser l'option "Utiliser un crédit" en fonction de la prestation choisie
    // (l'affiche si un crédit applicable existe, la cache sinon).
    this.refreshCreditOption()
  }

  // Affiche ou masque l'option "Utiliser un crédit" à l'étape 3 en fonction
  // de la prestation sélectionnée. Reprend la logique côté serveur de
  // Credit#applicable_a? : matching insensible à la casse sur le nom de la pose.
  // Stocke aussi l'id du crédit applicable dans `_applicableCreditId` pour le
  // remplir dans le hidden field si la cliente choisit cette option.
  refreshCreditOption() {
    // Si le formulaire n'expose pas l'option (jamais de crédits actifs côté serveur)
    // → rien à faire. hasCreditOptionTarget est un helper Stimulus.
    if (!this.hasCreditOptionTarget) return

    // Pas de prestation choisie : on cache l'option par sécurité
    if (!this.selectedPrestationNom) {
      this.creditOptionTarget.style.display = "none"
      this._applicableCreditId = null
      return
    }

    // Recherche FIFO : on prend le 1er crédit dont le nom de la pose est
    // inclus dans le nom de la prestation choisie. creditsActifsValue est
    // déjà trié par expiration la plus proche côté serveur.
    const presta = this.selectedPrestationNom.toLowerCase()
    const credit = this.creditsActifsValue.find(c =>
      presta.includes(c.prestation_nom.toLowerCase())
    )

    if (credit) {
      // Texte "(X restant·s)" — accord du pluriel à la française
      const pluriel = credit.nb_restant > 1 ? "s" : ""
      this.creditCountTarget.textContent = `(${credit.nb_restant} restant${pluriel})`
      this.creditOptionTarget.style.display = "block"
      this._applicableCreditId = credit.id
    } else {
      this.creditOptionTarget.style.display = "none"
      this._applicableCreditId = null
    }
  }

  // ============================================================
  // ÉTAPE 2 — CALENDRIER
  // ============================================================

  // Mois précédent
  prevMonth(event) {
    event.preventDefault()
    if (this.calMonth === 0) {
      this.calMonth = 11
      this.calYear--
    } else {
      this.calMonth--
    }
    this.renderCalendar()
  }

  // Mois suivant
  nextMonth(event) {
    event.preventDefault()
    if (this.calMonth === 11) {
      this.calMonth = 0
      this.calYear++
    } else {
      this.calMonth++
    }
    this.renderCalendar()
  }

  // Génère dynamiquement la grille du calendrier
  renderCalendar() {
    const moisNoms = ["Janvier","Février","Mars","Avril","Mai","Juin","Juillet","Août","Septembre","Octobre","Novembre","Décembre"]

    // Mettre à jour le libellé du mois
    this.calMonthTarget.textContent = `${moisNoms[this.calMonth]} ${this.calYear}`

    const today     = new Date()
    const firstDay  = new Date(this.calYear, this.calMonth, 1)
    const lastDay   = new Date(this.calYear, this.calMonth + 1, 0)

    // Lundi = 0 en France (le calendrier commence le lundi)
    let startDow = firstDay.getDay() - 1
    if (startDow < 0) startDow = 6

    let html = ""

    // Cases vides avant le 1er du mois
    for (let i = 0; i < startDow; i++) {
      const prevDate = new Date(this.calYear, this.calMonth, -startDow + i + 1)
      html += `<div class="cal-day other">${prevDate.getDate()}</div>`
    }

    // Jours du mois
    for (let d = 1; d <= lastDay.getDate(); d++) {
      const date     = new Date(this.calYear, this.calMonth, d)
      const dow      = date.getDay()  // 0=dim, 6=sam
      const dateStr  = `${this.calYear}-${String(this.calMonth + 1).padStart(2,'0')}-${String(d).padStart(2,'0')}`
      const isPast   = date < new Date(today.getFullYear(), today.getMonth(), today.getDate())
      const isToday  = date.toDateString() === today.toDateString()
      // Jours fermés (semaine type) : lus depuis BusinessHour côté serveur
      const isClosed = this.joursFermesValue.includes(dow)
      // Date bloquée ponctuellement (indispo jour entier) : ex. "ce lundi je ne travaille pas"
      // On compare via le format "YYYY-MM-DD" (date locale, pas Date.toISOString qui décale en UTC).
      const isBlocked = this.joursBloquesValue.includes(dateStr)

      let classes = "cal-day"
      if (isToday)                          classes += " today"
      if (isPast || isClosed || isBlocked)  classes += " unavailable"

      if (isPast || isClosed || isBlocked) {
        html += `<div class="${classes}">${d}</div>`
      } else {
        html += `<div class="${classes}" data-date="${dateStr}" data-action="click->booking#selectDate">${d}</div>`
      }
    }

    // Cases vides après le dernier jour
    const totalCells = startDow + lastDay.getDate()
    const remaining  = totalCells % 7 === 0 ? 0 : 7 - (totalCells % 7)
    for (let i = 1; i <= remaining; i++) {
      html += `<div class="cal-day other">${i}</div>`
    }

    this.calDaysTarget.innerHTML = html
  }

  // Sélectionner un jour dans le calendrier
  selectDate(event) {
    const el      = event.currentTarget
    const dateStr = el.dataset.date  // "2026-04-18"

    // Désélectionner tous les jours
    this.calDaysTarget.querySelectorAll(".cal-day").forEach(d => d.classList.remove("selected"))

    // Sélectionner le jour cliqué
    el.classList.add("selected")

    // Stocker la date et mettre à jour l'input hidden
    this.selectedDate    = dateStr
    this.dateInputTarget.value = dateStr

    // Formater le label lisible (ex: "Samedi 18 avril 2026")
    const date      = new Date(dateStr + "T12:00:00")
    const joursNoms = ["Dimanche","Lundi","Mardi","Mercredi","Jeudi","Vendredi","Samedi"]
    const moisNoms  = ["janvier","février","mars","avril","mai","juin","juillet","août","septembre","octobre","novembre","décembre"]
    this.selectedDateLabel = `${joursNoms[date.getDay()]} ${date.getDate()} ${moisNoms[date.getMonth()]} ${date.getFullYear()}`

    // Réinitialiser la sélection de créneau
    this.selectedHeure = null
    this.heureInputTarget.value = ""

    // Charger les créneaux disponibles via AJAX
    this.loadCreneaux(dateStr)
  }

  // Charge les créneaux disponibles pour une date via l'endpoint AJAX
  async loadCreneaux(dateStr) {
    // Afficher un loader dans la grille
    this.slotsGridTarget.innerHTML = '<div style="font-size:12px;color:#8e8480;padding:8px 0">Chargement...</div>'
    this.dateLabelTarget.textContent = `Créneaux disponibles — ${this.selectedDateLabel}`

    const url = `${this.creneauxUrlValue}?date=${dateStr}&prestation_id=${this.selectedPrestationId}`

    try {
      const response = await fetch(url, {
        headers: { "Accept": "application/json" }
      })
      const creneaux = await response.json()
      this.renderCreneaux(creneaux)
    } catch (e) {
      this.slotsGridTarget.innerHTML = '<div style="font-size:12px;color:#c47a7a">Erreur de chargement.</div>'
    }
  }

  // Affiche les boutons de créneaux dans la grille
  renderCreneaux(creneaux) {
    if (creneaux.length === 0) {
      this.slotsGridTarget.innerHTML = '<div style="font-size:12px;color:#8e8480;padding:8px 0">Aucun créneau disponible ce jour.</div>'
      return
    }

    const html = creneaux.map(h =>
      `<div class="slot" data-heure="${h}" data-action="click->booking#selectSlot">${h}</div>`
    ).join("")

    this.slotsGridTarget.innerHTML = html
  }

  // Sélectionner un créneau horaire
  selectSlot(event) {
    const el = event.currentTarget

    // Désélectionner tous les créneaux
    this.slotsGridTarget.querySelectorAll(".slot").forEach(s => s.classList.remove("selected"))

    // Sélectionner le créneau cliqué
    el.classList.add("selected")

    // ex: "09h30" pour l'affichage dans le récap
    this.selectedHeure = el.dataset.heure

    // Conversion "09h30" → "09:30:00" pour le champ time de PostgreSQL
    // Time.parse() côté Rails attend ce format standard, pas "9h30"
    const heureRails = this.selectedHeure.replace("h", ":") + ":00"
    this.heureInputTarget.value = heureRails
  }

  // ============================================================
  // ÉTAPE 3 — MODE DE PAIEMENT
  // ============================================================

  selectPayment(event) {
    const el = event.currentTarget

    // Désélectionner toutes les options
    this.paymentOptTargets.forEach(opt => opt.classList.remove("selected"))

    // Sélectionner l'option cliquée
    el.classList.add("selected")

    this.selectedPayment = el.dataset.payment
    this.paymentInputTarget.value = this.selectedPayment

    // Si la cliente choisit "crédit" → on remplit le hidden credit_id avec
    // l'id du crédit applicable trouvé par refreshCreditOption(). Sinon on vide
    // (au cas où elle aurait basculé crédit → acompte par exemple).
    if (this.hasCreditIdInputTarget) {
      this.creditIdInputTarget.value =
        (this.selectedPayment === "credit" ? (this._applicableCreditId || "") : "")
    }
  }

  // ============================================================
  // ÉTAPE 4 — RÉCAPITULATIF
  // ============================================================

  updateRecap() {
    // Prestation
    if (this.hasRecapPrestationTarget) {
      this.recapPrestationTarget.textContent = this.selectedPrestationNom
    }

    // Date
    if (this.hasRecapDateTarget) {
      this.recapDateTarget.textContent = this.selectedDateLabel
    }

    // Heure de début et de fin (début + durée en minutes)
    if (this.hasRecapHeureTarget) {
      this.recapHeureTarget.textContent = this.selectedHeure
    }
    if (this.hasRecapHeureFinTarget && this.selectedHeure && this.selectedPrestationDuree) {
      const [hh, mm]  = this.selectedHeure.replace("h", ":").split(":").map(Number)
      const totalMin  = hh * 60 + mm + this.selectedPrestationDuree
      const finH      = Math.floor(totalMin / 60)
      const finM      = totalMin % 60
      this.recapHeureFinTarget.textContent = `${finH}h${String(finM).padStart(2,'0')}`
    }

    // Prix total
    if (this.hasRecapPrixTarget) {
      this.recapPrixTarget.textContent = `${this.selectedPrestationPrix}€`
    }

    // Acompte (30% du prix)
    if (this.hasRecapAcompteTarget) {
      const acompte = Math.round(parseFloat(this.selectedPrestationPrix) * 0.30)
      this.recapAcompteTarget.textContent = `${acompte}€`
    }

    // Si paiement par crédit : on cache la ligne "Acompte dû" (rien à payer).
    // Sinon on s'assure qu'elle reste visible.
    if (this.hasRecapAcompteRowTarget) {
      this.recapAcompteRowTarget.style.display =
        (this.selectedPayment === "credit" ? "none" : "flex")
    }

    // Mode de garantie — 3 libellés selon le mode choisi
    if (this.hasRecapGarantieTarget) {
      let label = "Empreinte CB"
      if (this.selectedPayment === "acompte") label = "Acompte 30%"
      else if (this.selectedPayment === "credit") label = "Crédit de pack"
      this.recapGarantieTarget.textContent = label
    }

    // Adapter le libellé du bouton submit + la note explicative selon le mode.
    // Pour un submit type="submit", on modifie `value` (input) ou `textContent` (button).
    // En Rails, f.submit génère un <input type="submit"> → on utilise `value`.
    if (this.hasSubmitBtnTarget) {
      const btn = this.submitBtnTarget
      if (this.selectedPayment === "credit") {
        btn.value = "Confirmer avec mon crédit"
      } else if (this.selectedPayment === "empreinte") {
        btn.value = "Confirmer la réservation"
      } else {
        btn.value = "Confirmer et payer l'acompte"
      }
    }
    if (this.hasConfirmNoteTarget) {
      if (this.selectedPayment === "credit") {
        this.confirmNoteTarget.innerHTML =
          "Aucun paiement requis — votre crédit sera consommé après le rendez-vous.<br>" +
          "Un email de confirmation vous sera envoyé."
      } else {
        this.confirmNoteTarget.innerHTML =
          "Un email de confirmation + rappel 24h avant vous seront envoyés automatiquement.<br>" +
          "Paiement sécurisé via Stripe."
      }
    }
  }
}
