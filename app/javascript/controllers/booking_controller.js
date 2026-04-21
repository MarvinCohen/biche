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

    // Étape 4 — récap
    "recapPrestation",
    "recapDate",
    "recapHeure",
    "recapHeureFin",
    "recapPrix",
    "recapAcompte",
    "recapGarantie"
  ]

  // ============================================================
  // VALEURS passées depuis le HTML (data attributes)
  // ============================================================
  static values = {
    creneauxUrl: String,   // URL de l'endpoint AJAX créneaux
    prestationId: Number   // Prestation pré-sélectionnée (depuis le lien "Je réserve")
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
      const isPast   = date < new Date(today.getFullYear(), today.getMonth(), today.getDate())
      const isToday  = date.toDateString() === today.toDateString()
      // Dimanches indisponibles (Syam ne travaille pas le dimanche)
      const isClosed = dow === 0

      let classes = "cal-day"
      if (isToday)               classes += " today"
      if (isPast || isClosed)    classes += " unavailable"

      const dateStr = `${this.calYear}-${String(this.calMonth + 1).padStart(2,'0')}-${String(d).padStart(2,'0')}`

      if (isPast || isClosed) {
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

    this.selectedHeure = el.dataset.heure
    this.heureInputTarget.value = this.selectedHeure
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

    // Mode de garantie
    if (this.hasRecapGarantieTarget) {
      this.recapGarantieTarget.textContent = this.selectedPayment === "acompte" ? "Acompte 30%" : "Empreinte CB"
    }
  }
}
