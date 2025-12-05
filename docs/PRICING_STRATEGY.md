# 💰 FitGenius - Pricing Strategy Alternatives
## Analisi Modelli di Pricing e Raccomandazioni

---

# 📊 ANALISI MODELLO ATTUALE

## Pricing Corrente

| Tier | Prezzo | Features Chiave | % Target |
|------|--------|-----------------|----------|
| **Free** | €0 | 3 trial workout, 1 piano/2 mesi, libreria esercizi | 70% |
| **Premium** | €9.99/m | Piani illimitati, statistiche, progress tracking | 20% |
| **Gold** | €19.99/m | + Voice coach, pose detection | 8% |
| **Platinum** | €29.99/m | + Advanced pose, weekly reports, priority support | 2% |

### Revenue Projection Corrente
```
Scenario: 10.000 MAU

Free:      7.000 × €0     = €0
Premium:   2.000 × €9.99  = €19.980
Gold:        800 × €19.99 = €15.992
Platinum:    200 × €29.99 = €5.998

MRR Totale: €41.970
ARPU: €4.20
```

---

# 🔄 ALTERNATIVE PRICING STRATEGIES

## STRATEGIA A: Simplified Freemium (2 Tier)

### Struttura
| Tier | Prezzo | Features |
|------|--------|----------|
| **Free** | €0 | 3 workout/mese, ads, no voice coach |
| **Pro** | €14.99/m | Tutto illimitato |

### Vantaggi
✅ Decisione semplice per utente
✅ Meno friction nel funnel
✅ Comunicazione marketing più chiara
✅ Meno segmentazione da gestire

### Svantaggi
❌ Perdi utenti "in mezzo" che pagherebbero €9.99 ma non €14.99
❌ Revenue potenzialmente inferiore da high-value users
❌ Meno upsell opportunities

### Revenue Projection
```
Scenario: 10.000 MAU (con conversion rate migliore)

Free: 7.500 × €0     = €0
Pro:  2.500 × €14.99 = €37.475

MRR: €37.475
ARPU: €3.75

vs Attuale: -€4.495/mese (-11%)
MA: acquisition più semplice, possibile MAU higher
```

### Quando usare
- **Early stage** quando devi validare product-market fit
- Se analytics mostrano che 4 tier confonde gli utenti
- Se il tier Gold ha pochi subscriber

---

## STRATEGIA B: Usage-Based (Pay-per-Use)

### Struttura
| Feature | Prezzo |
|---------|--------|
| Base app | €0 |
| AI Workout Plan | €2.99 ciascuno |
| Voice Coach Session | €0.99 ciascuna |
| Form Analysis | €1.99 ciascuna |
| Pack 10 sessioni | €7.99 (-20%) |
| Pack 30 sessioni | €19.99 (-33%) |

### Vantaggi
✅ Bassa barriera all'ingresso
✅ Paga solo quello che usi
✅ Attraente per utenti occasionali
✅ Revenue correlata direttamente al valore

### Svantaggi
❌ Revenue imprevedibile
❌ Può scoraggiare uso frequente
❌ Utenti power-user pagano troppo
❌ Complexity tecnica (billing)

### Revenue Projection
```
Scenario: 10.000 MAU

Acquisti medi/utente: €3.50/mese
Active purchasers: 40%

= 4.000 × €3.50 = €14.000/mese

MRR: €14.000
ARPU: €1.40

vs Attuale: -67% (NON raccomandato come unico modello)
```

### Quando usare
- Come **addon al subscription** (feature premium)
- Per mercati price-sensitive
- Hybrid: subscription base + pay-per-use per AI avanzata

---

## STRATEGIA C: Annual Focus (Discount Push)

### Struttura
| Tier | Mensile | Annuale | Savings |
|------|---------|---------|---------|
| Premium | €9.99 | €79.99/anno | 33% |
| Gold | €19.99 | €159.99/anno | 33% |
| Platinum | €29.99 | €239.99/anno | 33% |

### Vantaggi
✅ LTV garantita upfront
✅ Riduzione churn (commitment psicologico)
✅ Cash flow migliore
✅ Lower payment processing costs

### Svantaggi
❌ Ticket più alto = più friction
❌ Refund risk se utente abbandona
❌ Revenue recognition più complessa

### Revenue Projection
```
Scenario: 10.000 MAU
Split: 60% monthly, 40% annual

Monthly:
- Premium: 1.200 × €9.99 = €11.988
- Gold: 480 × €19.99 = €9.595
- Platinum: 120 × €29.99 = €3.599

Annual (converted to MRR):
- Premium: 800 × €6.67 = €5.336
- Gold: 320 × €13.33 = €4.266
- Platinum: 80 × €20.00 = €1.600

MRR: €36.384
MA: Upfront cash = €37.597 (boost)
```

### 🎯 Raccomandazione
**Implementare immediatamente** come opzione aggiuntiva, non sostitutiva

---

## STRATEGIA D: Lifetime Deal (LTD)

### Struttura
| Offerta | Prezzo | Quando |
|---------|--------|--------|
| Lifetime Premium | €199 | Launch limited |
| Lifetime Gold | €299 | Launch limited |
| Lifetime Platinum | €399 | Launch limited |

### Vantaggi
✅ Cash injection immediata (per marketing)
✅ Early adopters = brand ambassadors
✅ Product Hunt e community love LTD
✅ Riduce CAC a 0 per questi utenti

### Svantaggi
❌ Perdi revenue ricorrente forever
❌ Può cannibalizzare subscription
❌ Unsustainable long-term
❌ Support burden permanente

### Revenue Projection
```
Scenario: 500 LTD venduti al launch

Premium LTD: 300 × €199 = €59.700
Gold LTD: 150 × €299 = €44.850
Platinum LTD: 50 × €399 = €19.950

Totale cash: €124.500

"Lost MRR" (se fossero subscription):
300 × €9.99 + 150 × €19.99 + 50 × €29.99 = €6.495/mese

Breakeven: 19 mesi
```

### 🎯 Raccomandazione
**Solo al launch**, massimo 500 posti, mai più ripetere

---

## STRATEGIA E: B2B / Team Pricing

### Struttura
| Piano | Prezzo | Include |
|-------|--------|---------|
| Team 5 | €39.99/m | 5 account, admin dashboard |
| Team 10 | €69.99/m | 10 account, analytics |
| Team 25 | €149.99/m | 25 account, priority support |
| Enterprise | Custom | 50+ account, API access, SSO |

### Vantaggi
✅ ARPU molto più alto
✅ Churn più basso (decision maker diverso)
✅ Expansion revenue (crescita team)
✅ Predictable revenue

### Svantaggi
❌ Sales cycle più lungo
❌ Richiede sales team
❌ Feature specifiche (admin panel)
❌ Support enterprise level

### Revenue Projection
```
Anno 1: 20 team medi

20 × €69.99 × 12 = €16.798/anno

Anno 2: 100 team

100 × €69.99 × 12 = €83.988/anno
+ 5 Enterprise × €5.000/anno = €25.000

Totale: €108.988
```

### 🎯 Raccomandazione
**Fase 2** (dopo product-market fit consumer)

---

## STRATEGIA F: Hybrid Gamified

### Struttura
| Tier | Prezzo | XP Bonus | Perks |
|------|--------|----------|-------|
| Free | €0 | 1x XP | Base features |
| Supporter | €4.99/m | 1.5x XP | No ads, badge |
| Champion | €14.99/m | 2x XP | All features, exclusive badge |
| Legend | €24.99/m | 3x XP | Early access, custom avatar |

### Focus
- Leva sulla **gamification esistente**
- Gli utenti pagano per **status** oltre che features
- Comunità più engaged

### Vantaggi
✅ Allineato con feature esistente
✅ FOMO per badge esclusivi
✅ Aumenta engagement
✅ Differenziazione dalla competizione

### Svantaggi
❌ Può sembrare "pay to win"
❌ Complica leaderboard (unfair advantage?)
❌ Alcuni utenti non interessati a gamification

---

# 🧪 ESPERIMENTI DI PRICING

## Test 1: Price Point Sensitivity

### Setup
- A/B test su nuovi utenti
- Variante A: €9.99 Premium
- Variante B: €7.99 Premium  
- Variante C: €12.99 Premium

### Metriche
- Conversion rate trial → paid
- Churn dopo primo mese
- Revenue per user

### Durata
4 settimane, minimo 1.000 utenti per variante

---

## Test 2: Trial Length

### Setup
- A: 7 giorni trial gratuito
- B: 14 giorni trial gratuito
- C: 3 giorni trial + 50% off primo mese

### Ipotesi
Trial più lungo = più engagement ma anche più "freeloader"

---

## Test 3: Feature Gating

### Setup
Cosa mettere dietro paywall?

| Feature | Attuale | Test A | Test B |
|---------|---------|--------|--------|
| Custom workout | Premium | Free (limite 1) | Free |
| Voice coach | Gold | Premium | Gold |
| Form analysis | Gold | Premium (3/mese) | Gold |

### Obiettivo
Trovare il balance tra valore gratuito (acquisition) e incentivo a pagare (monetization)

---

# 💡 RACCOMANDAZIONE FINALE

## Pricing Strategy Consigliata: "Core + Premium + Pro"

### Nuova Struttura Proposta

| Tier | Prezzo | Nuovo Nome | Posizionamento |
|------|--------|------------|----------------|
| Free | €0 | **FitGenius Lite** | Discovery |
| €9.99/m | **FitGenius Core** | Best value |
| €19.99/m | **FitGenius Pro** | Power users |

### Cambiamenti Chiave

1. **Eliminare Platinum** 
   - Troppo pochi subscriber (2%)
   - Complessità non giustificata
   - Features Platinum → incluse in Pro

2. **Rinominare i tier**
   - "Premium/Gold/Platinum" = commoditized
   - "Lite/Core/Pro" = più moderno

3. **Aggiungere Annual**
   - -33% per pagamento annuale
   - Default selection = annual (più revenue)

4. **Lifetime al Launch**
   - 500 posti massimo
   - Early bird esclusivo
   - Never again after launch

### Nuova Revenue Projection

```
Scenario: 10.000 MAU

Lite:    7.000 × €0     = €0
Core:    2.400 × €9.99  = €23.976 (+20%)
Pro:       600 × €19.99 = €11.994 (+50%)

MRR: €35.970
ARPU: €3.60

Con Annual (40% adoption, 33% discount):
Effective MRR: €32.770

MA: Cash flow migliore + lower churn
```

---

# 📋 IMPLEMENTATION CHECKLIST

## Settimana 1-2: Preparation
- [ ] Documentare pricing attuale in analytics
- [ ] Setup A/B testing framework
- [ ] Preparare nuove grafiche paywall
- [ ] Legal review nuovi T&C

## Settimana 3-4: Soft Launch
- [ ] Roll out a 10% nuovi utenti
- [ ] Monitor conversion rates
- [ ] Collect feedback
- [ ] Adjust if needed

## Settimana 5-6: Full Rollout
- [ ] Comunicazione agli utenti esistenti
- [ ] Grandfather clause (esistenti keep price)
- [ ] Update marketing materials
- [ ] Update App Store description

## Ongoing
- [ ] Monthly pricing review
- [ ] Quarterly A/B tests
- [ ] Competitor pricing monitoring
- [ ] Customer feedback integration

---

# 📚 APPENDICE: PSYCHOLOGY OF PRICING

## Principi Utilizzati

### 1. Anchoring
- Mostra Platinum/Pro come prima opzione
- Fa sembrare Core un "affare"

### 2. Decoy Effect
- Il tier "medio" esiste per far sembrare il tier "alto" ragionevole

### 3. Price Ending
- €9.99 vs €10 = percezione diversa
- Funziona ancora, usarlo

### 4. Scarcity
- "Early bird pricing" crea urgenza
- "500 lifetime deals" = FOMO

### 5. Social Proof
- "87% degli utenti sceglie Core"
- "La scelta più popolare" badge

### 6. Free Trial
- Riduce rischio percepito
- Permette di sperimentare valore
- 7 giorni = sweet spot

### 7. Annual vs Monthly
- Mostra savings in €/anno
- "Risparmia €XX" è più impattful
- Default su annual (pre-selezionato)

---

## Competitor Pricing Reference

| App | Base | Pro | Top |
|-----|------|-----|-----|
| Freeletics | Free | €12.99/m | - |
| SWEAT | - | €20/m | - |
| Fitbod | Free | €13/m | - |
| Nike TC | Free | - | - |
| MyFitnessPal | Free | €10/m | €20/m |
| **FitGenius** | Free | €9.99/m | €19.99/m |

### Posizionamento
- Più economico di SWEAT (premium brand positioning loro)
- In linea con Freeletics e Fitbod
- Value proposition AI giustifica premium

---

**Documento creato:** 5 Dicembre 2024
**Prossima review:** Dopo primi 30 giorni dati
