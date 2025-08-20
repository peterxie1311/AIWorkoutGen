# AiWorkoutGen (iOS)

AiWorkoutGen is an iOS app that generates **personalised strength workouts** using the OpenAI API, tracks sessions/sets/reps, and helps you stay consistent week to week. It remembers your recent history to avoid redundancy and progressively vary stimuli.

---

## ✨ Features
- **AI workout generation** – Builds workouts based on recent training history and preferences.
- **Workout logging** – Track sessions, exercises, sets, reps, and weights.
- **History-aware plans** – Sends a rolling window of previous workouts to the AI to diversify recommendations.
- **Saved sessions** – Browse previous workouts and repeat/modify them.
- **Settings** – Configure preferences (e.g., focus, exclusions).
- **Local persistence** – Uses Core Data for offline-first storage.

---

## 🧱 Tech Stack
- **Language:** Swift 5, UIKit (Storyboards)
- **Persistence:** Core Data (`Workout.xcdatamodeld`)
- **AI Integration:** OpenAI Chat Completions (through `workoutAIService.swift`)
- **Architecture:** MVC with manager/services; easy path to MVVM
- **Testing:** Unit/UI test targets scaffolded (`WorkoutTests`, `WorkoutUITests`)

---

## 📂 Project Structure (high level)
```
AIWorkoutGen/
├─ Workout.xcodeproj/
├─ Workout/
│  ├─ AppDelegate.swift, SceneDelegate.swift
│  ├─ Main.storyboard, LaunchScreen.storyboard
│  ├─ Models & Managers/
│  │   ├─ WorkoutManager.swift
│  │   ├─ WorkoutSessionsManager.swift
│  │   ├─ SetrepManager.swift
│  │   ├─ workouttree.swift, Tree.swift
│  ├─ Views & Controllers/
│  │   ├─ WorkoutViewController.swift
│  │   ├─ WorkoutsListViewController.swift
│  │   ├─ AddSetViewController.swift
│  │   ├─ RepViewController.swift
│  ├─ Services/
│  │   └─ workoutAIService.swift   # OpenAI integration
│  ├─ Data/
│  │   └─ Workout.xcdatamodeld/    # Core Data model
│  ├─ Utilities/
│  │   ├─ Constants.swift
│  │   └─ HelperFunctions.swift
│  └─ Assets.xcassets/ (App icon etc.)
```

> Filenames may vary slightly depending on the branch you shared; this outline reflects the uploaded project.

---

## ⚙️ Setup & Build

### 1) Clone and open
```bash
git clone https://github.com/<your-user>/AIWorkoutGen.git
cd AIWorkoutGen
open AIWorkoutGen/Workout.xcodeproj
```
- Target: **iOS 15+** (adjust to your project settings)
- Tooling: **Xcode 15+** recommended

### 2) Configure the OpenAI API key (no key is committed ✅)
Choose one of these safe approaches:

**Option A — Xcode `.xcconfig` (recommended)**
1. Create a file `Config.xcconfig` (do not commit) and add:
   ```
   OPENAI_API_KEY = sk-your-key
   ```
2. In your target **Build Settings** → **Other Swift Flags** (or a dedicated build setting), expose it at runtime or read via `Bundle.main.object(forInfoDictionaryKey:)` by also adding a `User-Defined` setting and referencing it in `Info.plist` as `OPENAI_API_KEY`.
3. In `workoutAIService.swift`, load it from `Info.plist`:
   ```swift
   let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
   ```

**Option B — Keychain / Secure storage**
- Store the key once after first launch, then read it for API calls.
- Useful if you plan to add an in‑app settings screen to paste the key.

**Option C — Environment file (local only)**
- Use a local plist (`Secrets.plist`) that is **gitignored**, then load it at runtime.

> Never hard‑code the API key in source or Storyboards. Add your secrets file to `.gitignore`.

### 3) Run
- Select a simulator → **Run (⌘R)**.
- First run will initialise Core Data stores.
- Generate a plan via the AI button and start logging sets/reps.

---

## 🔌 OpenAI Integration (overview)
- All API calls are centralised in **`workoutAIService.swift`**.
- The service composes a prompt using your **recent 100 workouts** (or similar window) and your **preferences**.
- Responses are parsed into the app’s workout model (exercise list, sets/reps, notes).

Example call (pseudocode):
```swift
struct WorkoutRequest: Codable { let recentWorkouts: [WorkoutSummary], let goal: String }
struct WorkoutPlan: Codable { let sessions: [Session] }

let plan = try await aiClient.generatePlan(from: request)
```

---

## 🧪 Testing
- `WorkoutTests` for unit tests (e.g., parsing AI responses, set/rep math).
- `WorkoutUITests` for basic flows (create workout → add set → complete).

---

## 🔒 Privacy & Security
- **No API keys** are shipped with the app.
- Workout history is stored locally via **Core Data**.
- If you later add analytics/cloud sync, document it here.

---

## 🗺 Roadmap / Future Work
- Move to **MVVM** with view models for testability.
- Replace storyboard navigation with **Coordinators**.
- Add export/import (JSON/CSV) for workouts.
- Offline queueing & retry for AI calls.
- Theming and accessibility polish.
- SwiftUI rewrite (optional path) for modern UI.

---

## 📸 Screenshots
_Add screenshots or screen recordings here (e.g., Generator, Session Log, History)._

---

## 📄 License
MIT (or your choice). Add a `LICENSE` file if you want others to reuse the project.

---

## 👤 Author
**Peter Xie**  
- Email: peterxie2000@gmail.com  
- LinkedIn: https://www.linkedin.com/in/peterxie1311  
- GitHub: https://github.com/peterxie1311
