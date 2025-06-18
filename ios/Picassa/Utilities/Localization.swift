import Foundation

enum Language: String {
    case en = "en"
    case sk = "sk"
    case cs = "cs"
}

enum LocalizedString {
    enum Calendar {
        static let noEvents = LocalizedText(
            en: "No events",
            sk: "Žiadne udalosti",
            cs: "Žádné události"
        )
        
        static let noEventsDescription = LocalizedText(
            en: "There are no events scheduled for this day",
            sk: "Pre tento deň nie sú naplánované žiadne udalosti",
            cs: "Pro tento den nejsou naplánovány žádné události"
        )
        
        static let close = LocalizedText(
            en: "Close",
            sk: "Zavrieť",
            cs: "Zavřít"
        )
        
        static let description = LocalizedText(
            en: "Description",
            sk: "Popis",
            cs: "Popis"
        )
        
        static let edit = LocalizedText(
            en: "Edit",
            sk: "Upraviť",
            cs: "Upravit"
        )
        
        static let delete = LocalizedText(
            en: "Delete",
            sk: "Vymazať",
            cs: "Smazat"
        )
        
        static let editEvent = LocalizedText(
            en: "Edit Event",
            sk: "Upraviť udalosť",
            cs: "Upravit událost"
        )
        
        static let title = LocalizedText(
            en: "Title",
            sk: "Názov",
            cs: "Název"
        )
        
        static let date = LocalizedText(
            en: "Date",
            sk: "Dátum",
            cs: "Datum"
        )
        
        static let duration = LocalizedText(
            en: "Duration",
            sk: "Trvanie",
            cs: "Trvání"
        )
        
        static let type = LocalizedText(
            en: "Type",
            sk: "Typ",
            cs: "Typ"
        )
        
        static let status = LocalizedText(
            en: "Status",
            sk: "Stav",
            cs: "Stav"
        )
        
        static let cancel = LocalizedText(
            en: "Cancel",
            sk: "Zrušiť",
            cs: "Zrušit"
        )
        
        static let save = LocalizedText(
            en: "Save",
            sk: "Uložiť",
            cs: "Uložit"
        )
        
        static let addEvent = LocalizedText(
            en: "Add Event",
            sk: "Pridať udalosť",
            cs: "Přidat událost"
        )
        
        enum EventType {
            static let portrait = LocalizedText(
                en: "Portrait",
                sk: "Portrét",
                cs: "Portrét"
            )
            
            static let wedding = LocalizedText(
                en: "Wedding",
                sk: "Svadba",
                cs: "Svatba"
            )
            
            static let product = LocalizedText(
                en: "Product",
                sk: "Produkt",
                cs: "Produkt"
            )
            
            static let family = LocalizedText(
                en: "Family",
                sk: "Rodina",
                cs: "Rodina"
            )
            
            static let fashion = LocalizedText(
                en: "Fashion",
                sk: "Móda",
                cs: "Móda"
            )
            
            static let other = LocalizedText(
                en: "Other",
                sk: "Iné",
                cs: "Jiné"
            )
        }
        
        enum EventStatus {
            static let scheduled = LocalizedText(
                en: "Scheduled",
                sk: "Naplánované",
                cs: "Naplánováno"
            )
            
            static let confirmed = LocalizedText(
                en: "Confirmed",
                sk: "Potvrdené",
                cs: "Potvrzeno"
            )
            
            static let completed = LocalizedText(
                en: "Completed",
                sk: "Dokončené",
                cs: "Dokončeno"
            )
            
            static let cancelled = LocalizedText(
                en: "Cancelled",
                sk: "Zrušené",
                cs: "Zrušeno"
            )
        }
        
        enum WeekDays {
            static let monday = LocalizedText(
                en: "Mo",
                sk: "Po",
                cs: "Po"
            )
            
            static let tuesday = LocalizedText(
                en: "Tu",
                sk: "Ut",
                cs: "Út"
            )
            
            static let wednesday = LocalizedText(
                en: "We",
                sk: "St",
                cs: "St"
            )
            
            static let thursday = LocalizedText(
                en: "Th",
                sk: "Št",
                cs: "Čt"
            )
            
            static let friday = LocalizedText(
                en: "Fr",
                sk: "Pi",
                cs: "Pá"
            )
            
            static let saturday = LocalizedText(
                en: "Sa",
                sk: "So",
                cs: "So"
            )
            
            static let sunday = LocalizedText(
                en: "Su",
                sk: "Ne",
                cs: "Ne"
            )
        }
    }
}

struct LocalizedText {
    let en: String
    let sk: String
    let cs: String
    
    func localized() -> String {
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        switch language {
        case "sk": return sk
        case "cs": return cs
        default: return en
        }
    }
} 