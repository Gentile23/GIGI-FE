# FitGenius - Guida Integrazione Backend

## 🚀 Setup Rapido

### 1. Avvia il Server Laravel
```bash
cd c:/Users/genti/Progetti/Gest_One
php artisan serve
```
Il server sarà disponibile su `http://localhost:8000`

### 2. Configura l'URL API (se necessario)
Modifica `lib/core/constants/api_config.dart`:
```dart
static const String baseUrl = 'http://localhost:8000/api';
```

**Note per diverse piattaforme:**
- **Web (Chrome/Edge)**: `http://localhost:8000/api` ✅
- **Android Emulator**: `http://10.0.2.2:8000/api`
- **iOS Simulator**: `http://localhost:8000/api`
- **Dispositivo fisico**: `http://TUO_IP:8000/api` (es. `http://192.168.1.100:8000/api`)

### 3. Configura CORS su Laravel
Il file `config/cors.php` dovrebbe già essere configurato. Verifica che includa:
```php
'paths' => ['api/*'],
'allowed_origins' => ['*'], // Per sviluppo
'allowed_methods' => ['*'],
'allowed_headers' => ['*'],
```

### 4. Testa l'Integrazione

#### Test Registrazione
1. Apri l'app Flutter
2. Vai alla schermata di registrazione
3. Inserisci:
   - Nome: Test User
   - Email: test@example.com
   - Password: password123
4. Clicca "Create Account"

#### Test Login
1. Usa le credenziali create
2. Email: test@example.com
3. Password: password123
4. Clicca "Sign In"

### 5. Verifica Backend
Controlla il database SQLite:
```bash
cd c:/Users/genti/Progetti/Gest_One
php artisan tinker
>>> User::all()
```

## 📡 Endpoint API Disponibili

### Autenticazione
- `POST /api/register` - Registrazione
- `POST /api/login` - Login
- `POST /api/logout` - Logout (richiede auth)

### Utente
- `GET /api/user` - Dati utente (richiede auth)
- `POST /api/user/profile` - Aggiorna profilo (richiede auth)

### Esercizi
- `GET /api/exercises` - Lista esercizi (richiede auth)
- `GET /api/exercises/{id}` - Dettaglio esercizio (richiede auth)

### Workout Plans
- `GET /api/workout-plans` - Lista piani (richiede auth)
- `GET /api/workout-plans/current` - Piano corrente (richiede auth)
- `POST /api/workout-plans/generate` - Genera piano (richiede auth)

## 🔧 Troubleshooting

### Errore CORS
Se vedi errori CORS nella console:
1. Verifica che Laravel sia in esecuzione
2. Controlla `config/cors.php`
3. Pulisci cache: `php artisan config:clear`

### Errore 401 Unauthorized
- Il token non è valido o è scaduto
- Fai logout e login di nuovo

### Errore di connessione
- Verifica che Laravel sia in esecuzione su `http://localhost:8000`
- Controlla che l'URL in `api_config.dart` sia corretto
- Per dispositivi fisici, usa l'IP della tua macchina

### Database vuoto
Popola il database con dati di test:
```bash
php artisan db:seed
```

## 📝 Prossimi Passi

1. ✅ Auth screen integrata
2. ⏳ Integrare questionnaire con backend
3. ⏳ Integrare home screen con dati reali
4. ⏳ Integrare workout screens
5. ⏳ Aggiungere gestione errori migliorata
6. ⏳ Aggiungere loading states
7. ⏳ Implementare refresh token

## 🎯 Test Completo

### Flusso Completo
1. Registrazione → ✅ Salva user nel DB
2. Login → ✅ Riceve token
3. Fetch user data → ⏳ Da testare
4. Update profile → ⏳ Da testare
5. Fetch workouts → ⏳ Da testare
6. Logout → ✅ Cancella token

## 📊 Stato Integrazione

- [x] API Client setup
- [x] Auth Service
- [x] User Service  
- [x] Workout Service
- [x] Exercise Service
- [x] Auth Provider
- [x] Auth Screen integrata
- [ ] Questionnaire integrato
- [ ] Home Screen integrata
- [ ] Workout Screens integrate
- [ ] Profile Screen integrato
