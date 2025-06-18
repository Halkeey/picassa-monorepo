# Picassa - Design Principles & Architecture

## Project Structure 

## Architectural Overview

Projekt používa The Composable Architecture (TCA) ako hlavný architektonický vzor, ktorý poskytuje predvídateľný jednosmerný tok dát a stavu.

### Key Components

#### Features/
Obsahuje hlavné funkčné moduly aplikácie, každý s vlastnou logikou a UI:

- **Calendar/**
  - `CalendarView.swift` - UI komponenty pre kalendár
  - `CalendarFeature.swift` - Business logika a state management pre kalendár
- **Social/**
  - `SocialView.swift` - UI komponenty pre sociálne funkcie
  - `SocialFeature.swift` - Business logika pre sociálne funkcie
- **AppFeature.swift**
  - Hlavný koordinátor aplikácie
  - Spája všetky features do jedného celku

#### Models/
Obsahuje doménové modely aplikácie:

- **Event.swift**
  - Definuje štruktúru udalostí
  - Obsahuje všetky potrebné typy a stavy pre udalosti

#### Utilities/
Pomocné nástroje a utility:

- **Localization.swift**
  - Systém pre lokalizáciu textov
  - Podporuje EN, SK a CZ jazyky

#### PicassaApp.swift
Vstupný bod aplikácie, kde sa inicializuje hlavný store a routing.

## Design Patterns

### The Composable Architecture (TCA)
- **State** - Reprezentuje celý stav feature
- **Action** - Všetky možné akcie, ktoré môžu zmeniť stav
- **Reducer** - Spracováva akcie a aktualizuje stav
- **Store** - Drží stav a sprostredkováva akcie

### View Architecture
- Používa SwiftUI
- Modulárny prístup s možnosťou znovupoužitia komponentov
- Jasné oddelenie UI od business logiky

### Localization
- Centralizovaný systém pre správu textov
- Podporuje viacjazyčnosť (EN, SK, CZ)
- Používa enum-based prístup pre type-safe prístup k textom

## Best Practices

1. **Single Responsibility**
   - Každý komponent má jednu hlavnú zodpovednosť
   - Logicky oddelené súbory podľa funkcionality

2. **Dependency Injection**
   - Používa sa cez TCA Store
   - Umožňuje lepšie testovanie a modularitu

3. **State Management**
   - Centralizovaný cez TCA
   - Predvídateľný tok dát
   - Jednoduchá debugovateľnosť

4. **UI Components**
   - Znovupoužiteľné komponenty
   - Konzistentný dizajn
   - Responzívne správanie

5. **Code Organization**
   - Logické členenie do priečinkov
   - Jasná hierarchia komponentov
   - Prehľadná štruktúra projektu

## Future Considerations

1. **Networking Layer**
   - Pridať abstrakciu pre sieťovú komunikáciu
   - Implementovať caching mechanizmus

2. **Persistence**
   - Pridať lokálne úložisko pre offline podporu
   - Synchronizácia s backend službami

3. **Testing**
   - Unit testy pre business logiku
   - UI testy pre kritické user flows
   - Snapshot testy pre UI komponenty 