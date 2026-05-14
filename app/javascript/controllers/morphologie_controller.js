// ============================================================
// Controller Stimulus — Page morphologie (guide en 4 étapes)
//
// Gère l'état du parcours guidé :
//   1. Technique (cil à cil / volume)
//   2. Effet (uniquement si volume)
//   3. Morphologie (8 types d'yeux)
//   4. Recommandation (carte récap dynamique)
//
// Quand la cliente sélectionne une option à une étape, on met à jour :
//   - la classe .active sur la carte cliquée (et on retire des autres)
//   - le state interne (techniqueValue, effetValue, morphoValue)
//   - la section "Effet" est affichée seulement si volume est sélectionné
//   - la carte récap (étape 4) avec technique + effet + forme conseillée
//   - les pastilles d'étape (step-circle) en haut de la page
// ============================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Valeurs persistées dans le DOM via data-morphologie-*-value
  // Stimulus appelle automatiquement {nom}ValueChanged() quand elles changent.
  static values = {
    technique:  { type: String, default: "" }, // "cil_a_cil" | "volume"
    effet:      { type: String, default: "" }, // "mouille" | "wispy" | "manga" | "3d" | "5d"
    morpho:     { type: String, default: "" }, // "amande" | "ronds" | ... | "petit_oeil" | "grand_oeil"
    // Table de correspondance (technique+effet) → prestation_id, fournie
    // par PagesController#morphologie en JSON. Sert à construire l'URL du
    // bouton "Je réserve cette pose →" avec la bonne prestation pré-sélectionnée.
    prestaMap:  { type: Object, default: {} },
    // URL de base de /bookings/new — passée par la vue (évite de hardcoder une route côté JS).
    bookingUrl: { type: String, default: "/bookings/new" }
  }

  // Targets (= éléments DOM ciblés depuis le HTML via data-morphologie-target)
  static targets = [
    "techniqueCard",   // les 2 cartes Cil à cil / Volume
    "effetSection",    // <section> de l'étape 2 — cachée par défaut
    "effetCard",       // les 5 cartes d'effet
    "morphoCard",      // les 8 cartes type d'yeux
    "recapCard",       // la carte récap de l'étape 4
    "recapTechnique",  // <span> avec le nom de la technique choisie
    "recapEffet",      // <li> "effet" (caché si pas volume)
    "recapEffetName",  // <span> nom de l'effet choisi
    "recapForme",      // <span> forme conseillée (Cat Eyes / Doll Eyes)
    "recapMorpho",     // <span> nom de la morpho choisie
    "recapDescription",// <p> description courte de la reco
    "recapEmpty",      // <div> état vide tant que rien n'est sélectionné
    "stepCircle",      // les 4 cercles d'étape (data-step="1|2|3|4")
    "stepLabel",       // les 4 labels d'étape
    "reserveLink"      // <a> "Je réserve cette pose →" — son href est mis à jour dynamiquement
  ]

  // ============================================================
  // Tables de correspondance — données métier de la page
  // ============================================================

  // Libellés humains pour les techniques (utilisés dans la carte récap)
  techniqueLabels = {
    cil_a_cil: "Cil à cil",
    volume:    "Volume"
  }

  // Libellés humains pour les effets
  effetLabels = {
    mouille: "Effet mouillé",
    wispy:   "Wispy",
    manga:   "Manga",
    "3d":    "Volume 3D",
    "5d":    "Volume 5D"
  }

  // Mapping morphologie → forme conseillée + description courte
  // Validé avec Marvin dans tasks/todo.md
  morphoReco = {
    amande:     { nom: "Yeux en amande", forme: "Cat Eyes",       desc: "Forme polyvalente — un cat eye sublime la symétrie naturelle." },
    ronds:      { nom: "Yeux ronds",      forme: "Cat Eyes",       desc: "On allonge le regard pour briser la rondeur." },
    tombants:   { nom: "Yeux tombants",   forme: "Cat Eyes (fort)", desc: "Relevé externe prononcé pour redresser le coin tombant." },
    rapproches: { nom: "Yeux rapprochés", forme: "Cat Eyes",       desc: "Longueur concentrée à l'extérieur pour écarter visuellement." },
    ecartes:    { nom: "Yeux écartés",    forme: "Doll Eyes",      desc: "Longueur au centre pour rapprocher visuellement le regard." },
    brides:     { nom: "Yeux bridés",     forme: "Doll Eyes",      desc: "Ouverture au centre pour révéler la paupière." },
    petit_oeil: { nom: "Petit œil",       forme: "Doll Eyes",      desc: "Longueur au centre pour agrandir l'œil." },
    grand_oeil: { nom: "Grand œil",       forme: "Cat Eyes",       desc: "Cat eye pour allonger et éviter d'accentuer la rondeur." }
  }

  // ============================================================
  // Cycle de vie Stimulus
  // ============================================================

  // Appelé automatiquement quand le controller s'attache au DOM
  connect() {
    // Au chargement, on affiche/cache la section Effet selon la technique
    // (utile si on recharge la page avec un state déjà rempli)
    this.toggleEffetSection()
    this.refreshRecap()
    this.refreshSteps()
  }

  // ============================================================
  // Actions — déclenchées par les clics dans la vue
  // ============================================================

  // Étape 1 — Sélection d'une technique (cil à cil / volume)
  // Le bouton a data-action="click->morphologie#selectTechnique"
  //          et data-morphologie-value-param="cil_a_cil" (ou "volume")
  selectTechnique(event) {
    // event.params.value = valeur passée via data-morphologie-value-param
    const value = event.params.value

    // Si on change de technique, on réinitialise l'effet
    // (un effet n'a de sens que si on est sur "volume")
    if (this.techniqueValue !== value) {
      this.effetValue = ""
    }

    // On stocke la valeur — déclenche techniqueValueChanged() en cascade
    this.techniqueValue = value
  }

  // Étape 2 — Sélection d'un effet (uniquement pour volume)
  selectEffet(event) {
    this.effetValue = event.params.value
  }

  // Étape 3 — Sélection d'une morphologie d'œil
  selectMorpho(event) {
    this.morphoValue = event.params.value

    // Petit confort UX : scroll vers la carte récap après sélection morpho
    // (équivalent à l'ancien scrollIntoView du <script> inline)
    this.scrollToRecap()
  }

  // ============================================================
  // Callbacks Stimulus — appelés auto quand une value change
  // ============================================================

  // Quand la technique change → mise à jour des cartes, section effet, récap, étapes
  techniqueValueChanged() {
    this.highlightTechniqueCards()
    this.toggleEffetSection()
    this.refreshRecap()
    this.refreshSteps()
  }

  // Quand l'effet change → mise à jour des cartes effet + récap + étapes
  effetValueChanged() {
    this.highlightEffetCards()
    this.refreshRecap()
    this.refreshSteps()
  }

  // Quand la morpho change → mise à jour des cartes morpho + récap + étapes
  morphoValueChanged() {
    this.highlightMorphoCards()
    this.refreshRecap()
    this.refreshSteps()
  }

  // ============================================================
  // Méthodes privées — mise à jour de l'UI
  // ============================================================

  // Active la carte technique sélectionnée et désactive les autres
  highlightTechniqueCards() {
    this.techniqueCardTargets.forEach((card) => {
      // data-morphologie-value-param contient la valeur de la carte
      const cardValue = card.dataset.morphologieValueParam
      card.classList.toggle("selected", cardValue === this.techniqueValue)
    })
  }

  // Idem pour les cartes d'effet
  highlightEffetCards() {
    this.effetCardTargets.forEach((card) => {
      const cardValue = card.dataset.morphologieValueParam
      card.classList.toggle("selected", cardValue === this.effetValue)
    })
  }

  // Idem pour les cartes de morphologie
  highlightMorphoCards() {
    this.morphoCardTargets.forEach((card) => {
      const cardValue = card.dataset.morphologieValueParam
      card.classList.toggle("active", cardValue === this.morphoValue)
    })
  }

  // Affiche/masque la section "Effet" selon la technique choisie.
  // Si "volume" → on montre la section. Sinon (cil_a_cil ou rien) → on cache.
  toggleEffetSection() {
    if (!this.hasEffetSectionTarget) return
    // .hidden est l'attribut HTML standard — propre, accessible, pas besoin de CSS
    this.effetSectionTarget.hidden = this.techniqueValue !== "volume"
  }

  // Met à jour la carte récap (étape 4) en fonction du state actuel
  refreshRecap() {
    // Tant que rien n'est sélectionné, on affiche l'état vide
    const rienSelectionne = !this.techniqueValue && !this.morphoValue

    if (this.hasRecapEmptyTarget) {
      this.recapEmptyTarget.hidden = !rienSelectionne
    }
    if (this.hasRecapCardTarget) {
      this.recapCardTarget.hidden = rienSelectionne
    }

    // Si tout est vide, inutile d'aller plus loin
    if (rienSelectionne) return

    // --- Technique ---
    if (this.hasRecapTechniqueTarget) {
      this.recapTechniqueTarget.textContent =
        this.techniqueLabels[this.techniqueValue] || "—"
    }

    // --- Effet (visible uniquement si technique = volume) ---
    if (this.hasRecapEffetTarget) {
      const afficheEffet = this.techniqueValue === "volume"
      this.recapEffetTarget.hidden = !afficheEffet
      if (afficheEffet && this.hasRecapEffetNameTarget) {
        this.recapEffetNameTarget.textContent =
          this.effetLabels[this.effetValue] || "À définir"
      }
    }

    // --- CTA "Je réserve cette pose →" : on ajoute ?prestation_id=X pour
    //     pré-sélectionner le bon soin sur /bookings/new (cf. updateReserveLink). ---
    this.updateReserveLink()

    // --- Morpho + Forme conseillée + description ---
    const reco = this.morphoReco[this.morphoValue]
    if (reco) {
      if (this.hasRecapMorphoTarget)      this.recapMorphoTarget.textContent      = reco.nom
      if (this.hasRecapFormeTarget)       this.recapFormeTarget.textContent       = reco.forme
      if (this.hasRecapDescriptionTarget) this.recapDescriptionTarget.textContent = reco.desc
    } else {
      // Morpho pas encore choisie — placeholder
      if (this.hasRecapMorphoTarget)      this.recapMorphoTarget.textContent      = "À sélectionner"
      if (this.hasRecapFormeTarget)       this.recapFormeTarget.textContent       = "—"
      if (this.hasRecapDescriptionTarget) this.recapDescriptionTarget.textContent = "Sélectionnez votre morphologie pour obtenir la forme conseillée."
    }
  }

  // Met à jour les pastilles d'étape (1, 2, 3, 4) en haut de la page
  // - active : étape en cours (la prochaine à compléter)
  // - done   : étape déjà complétée
  // - todo   : étape à venir
  refreshSteps() {
    // Détermine quelles étapes sont complétées
    const done1 = !!this.techniqueValue
    // L'étape "effet" ne s'applique que si volume → on la considère "done"
    // soit si pas concernée (cil à cil), soit si un effet est choisi
    const done2 = this.techniqueValue === "cil_a_cil" || !!this.effetValue
    const done3 = !!this.morphoValue
    const done4 = done1 && done2 && done3

    // Tableau ordonné [step1, step2, step3, step4] pour itérer
    const etats = [done1, done2, done3, done4]

    this.stepCircleTargets.forEach((circle) => {
      // data-step="1" → indice 0 ; data-step="2" → indice 1 ; etc.
      const idx = parseInt(circle.dataset.step, 10) - 1
      const fait = etats[idx]
      // Le 1er non-fait est "active" ; ceux faits sont "done" ; reste = "todo"
      const premierNonFait = etats.findIndex((e) => !e)
      const estActive = idx === premierNonFait
      circle.classList.toggle("done", fait)
      circle.classList.toggle("active", !fait && estActive)
      circle.classList.toggle("todo", !fait && !estActive)
    })

    // Les labels d'étape suivent le même état "active"
    this.stepLabelTargets.forEach((label) => {
      const idx = parseInt(label.dataset.step, 10) - 1
      const fait = etats[idx]
      const premierNonFait = etats.findIndex((e) => !e)
      label.classList.toggle("active", fait || idx === premierNonFait)
    })
  }

  // Met à jour le href du bouton "Je réserve cette pose →" en y ajoutant
  // ?prestation_id=X — calculé d'après (technique, effet) via this.prestaMapValue.
  // Si aucune technique choisie ou pas de correspondance, on garde l'URL nue.
  updateReserveLink() {
    if (!this.hasReserveLinkTarget) return

    // Clé de lookup dans la table fournie par le serveur :
    //  - "cil_a_cil" si technique = cil à cil
    //  - "volume_<effet>" si technique = volume ET effet renseigné
    //  - "volume_default" si volume sans effet encore choisi
    let key = null
    if (this.techniqueValue === "cil_a_cil") {
      key = "cil_a_cil"
    } else if (this.techniqueValue === "volume") {
      key = this.effetValue ? `volume_${this.effetValue}` : "volume_default"
    }

    // Récupère l'id correspondant (peut être null si la prestation n'existe pas en base)
    const prestaId = key ? this.prestaMapValue[key] : null

    // Construit l'URL finale — avec ou sans le query param
    const baseUrl = this.bookingUrlValue || "/bookings/new"
    this.reserveLinkTarget.href = prestaId
      ? `${baseUrl}?prestation_id=${prestaId}`
      : baseUrl
  }

  // Scroll fluide jusqu'à la carte récap (étape 4)
  scrollToRecap() {
    if (!this.hasRecapCardTarget) return
    this.recapCardTarget.scrollIntoView({ behavior: "smooth", block: "start" })
  }
}
