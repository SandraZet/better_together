// FIX: Ändere diese Zeile in syncSlots():

// VORHER (FALSCH):
const dateStr = Utilities.formatDate(new Date(date), "GMT", "yyyy-MM-dd");

// NACHHER (RICHTIG):
const dateStr = Utilities.formatDate(new Date(date), Session.getScriptTimeZone(), "yyyy-MM-dd");

// Oder wenn das nicht funktioniert, nutze die lokale Timezone:
const dateStr = Utilities.formatDate(new Date(date), "Europe/Vienna", "yyyy-MM-dd");
