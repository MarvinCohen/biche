# Refonte page /morphologie — Guide morpho en 4 étapes

## Objectif

Transformer la page `/morphologie` actuelle (3 étapes : techniques descriptives → type d'yeux → reco) en un **parcours guidé en 4 étapes** où la cliente compose son choix, et la carte de recommandation affiche un récapitulatif + la forme conseillée selon sa morphologie.

### Les 4 nouvelles étapes

1. **Technique** — Cil à cil OU Volume (2 grosses cartes, choix exclusif)
2. **Effet** — uniquement si **Volume** sélectionné à l'étape 1 → Effet mouillé / Wispy / Manga / 3D / 5D (la section est masquée si Cil à cil)
3. **Morphologie** — 8 types d'yeux : amande, ronds, tombants, rapprochés, écartés, bridés (photos) + petit œil, grand œil (SVG en attendant photos)
4. **Recommandation** — carte dynamique avec :
   - Récap des choix de la cliente (technique + effet)
   - Forme conseillée selon la morphologie sélectionnée (Cat Eyes / Doll Eyes)
   - CTA "Je réserve cette pose →"

### Mapping morpho → forme conseillée (validé)

| Morphologie    | Forme conseillée |
|----------------|------------------|
| Petit œil      | Doll Eyes        |
| Grand œil      | Cat Eyes         |
| En amande      | Cat Eyes         |
| Ronds          | Cat Eyes         |
| Tombants       | Cat Eyes (fort) |
| Rapprochés     | Cat Eyes         |
| Écartés        | Doll Eyes        |
| Bridés         | Doll Eyes        |

### Descriptions à reprendre (texte fourni par Syam)

- **Effet mouillé** : « Une pose effet mouillé est une technique d'extensions de cils qui reproduit l'apparence de cils légèrement mouillés, grâce à des bouquets fins et fermés. Le rendu est brillant, structuré et intense, tout en restant élégant. L'intensité peut être adaptée. »
- **Wispy** : « Mélange différentes longueurs pour créer un effet aérien, texturé et légèrement "ébouriffé", avec des pics plus longs qui donnent un regard intense et sophistiqué. »
- **Manga** : « Inspirée du regard des personnages de manga/anime, avec des pics bien définis et espacés qui agrandissent les yeux et donnent un effet poupée très marqué. »
- **3D** : « Bouquets de 3 extensions ultra fines sur chaque cil naturel pour un rendu fourni, léger et élégant. »
- **5D** : « Bouquets de 5 extensions ultra fines par cil naturel pour un effet plus dense, glamour et intense, tout en gardant de la légèreté. »

---

## Fichiers impactés

- `app/views/pages/morphologie.html.erb` — refonte complète (4 sections au lieu de 3)
- `app/assets/stylesheets/pages.css` — nouveaux styles : cartes Technique XL, cartes Effet, eye-card mix photo+picto
- `app/assets/images/morphologie/` — dossier à créer pour les 6 photos (action manuelle Marvin)
- `app/javascript/controllers/morphologie_controller.js` — nouveau Stimulus controller pour gérer le state (technique, effet, morpho) et la mise à jour de la carte récap
- Suppression du `<script>` inline `selectEye()` qui existe actuellement

---

## Étapes

- [ ] 1. Créer le dossier `app/assets/images/morphologie/` — **action manuelle Marvin** : découper le screenshot WhatsApp et y placer 6 fichiers : `amande.jpg`, `ronds.jpg`, `tombants.jpg`, `rapproches.jpg`, `ecartes.jpg`, `brides.jpg`
- [ ] 2. Créer `app/javascript/controllers/morphologie_controller.js` (Stimulus) :
  - values : `technique` (String), `effet` (String), `morpho` (String)
  - targets : `techniqueCard`, `effetSection`, `effetCard`, `morphoCard`, `recapTechnique`, `recapEffet`, `recapForme`, `recapDescription`
  - actions : `selectTechnique`, `selectEffet`, `selectMorpho`
  - méthode `updateRecap()` qui met à jour la carte récap + affiche/masque la section Effet selon technique
- [ ] 3. Refondre la barre `steps-indicator` : 3 étapes → 4 étapes (Technique / Effet / Morpho / Ma pose)
- [ ] 4. Refondre **Étape 1** — remplacer le carrousel des 5 techniques par 2 grosses cartes de choix : "Cil à cil" / "Volume" + court texte explicatif
- [ ] 5. Refondre **Étape 2** — nouvelle section "Effets" (cachée par défaut via `hidden`, affichée si Volume) avec 5 cartes : Effet mouillé, Wispy, Manga, 3D, 5D + descriptions Syam
- [ ] 6. Refondre **Étape 3** — passer de 6 à 8 cartes type yeux. Structure mix photo+picto : `<img>` + petit pictogramme SVG dans le coin (comme le screenshot). Pour petit/grand œil → SVG en plein cadre en attendant photos
- [ ] 7. Refondre **Étape 4** — carte récap dynamique : technique choisie, effet choisi (affiché si Volume), forme conseillée selon morpho (Doll/Cat Eyes), short description
- [ ] 8. Ajouter les styles CSS dans `pages.css` (cartes technique XL, cartes effet, eye-card avec photo + overlay picto)
- [ ] 9. Supprimer le `<script>` inline en bas de la vue (logique déplacée dans le Stimulus controller)
- [ ] 10. Tester le flow complet en dev (`rails server`)

---

## Notes

- **Style** : on garde le système de design existant (variables CSS, classes `.sec`, `.sec-alt`, `.sec-cream`, etc.)
- **Comportement Stimulus** : on respecte CLAUDE.md → un controller par comportement, pas de JS inline ni de `onclick=""`
- **Commentaires** : chaque méthode, chaque bloc logique commenté en français (règle absolue CLAUDE.md)
- **Fallback photos** : tant que les 6 photos ne sont pas dans `app/assets/images/morphologie/`, prévoir un fond CSS beige (`var(--color-nude)`) sur `.eye-img-wrap` pour éviter une icône cassée disgracieuse
