/******************************************************************
 * OPTIMIZED FIRESTORE SYNC SCRIPT
 * ---------------------------------------------------------------
 * Fixes:
 * 1. Rate limiting (Utilities.sleep)
 * 2. Option: nur aktuelle/zukünftige Slots syncen
 * 3. Completions NICHT mehr aus Firestore lesen
 *    (werden von der App verwaltet)
 ******************************************************************/

// === 1. Service Account Credentials ===
// ⚠️  DO NOT commit real credentials here.
// Paste your service account JSON values below only when running locally in
// the Apps Script editor — never store them in version control.
const FIREBASE_SERVICE_ACCOUNT = {
  "type": "service_account",
  "project_id": "better-together-deed2",
  "private_key_id": "YOUR_PRIVATE_KEY_ID",
  "private_key": "YOUR_PRIVATE_KEY",
  "client_email": "YOUR_CLIENT_EMAIL",
  "client_id": "YOUR_CLIENT_ID",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "YOUR_CLIENT_X509_CERT_URL",
  "universe_domain": "googleapis.com"
};

// === 2. Firestore URL ===
const FIRESTORE_BASE_URL =
  `https://firestore.googleapis.com/v1/projects/better-together-deed2/databases/nowdb/documents`;

// === 3. CONFIG ===
const CONFIG = {
  // Rate limiting: Millisekunden zwischen Requests
  DELAY_BETWEEN_REQUESTS: 200,
  
  // Nur aktuelle/zukünftige Slots syncen (vs. alle historischen)
  SYNC_ONLY_CURRENT_AND_FUTURE: true,
  
  // Ab welchem Datum syncen (falls SYNC_ONLY_CURRENT_AND_FUTURE = true)
  // Automatisch: heute - 2 Tage
  getDaysAgo(days) {
    const date = new Date();
    date.setDate(date.getDate() - days);
    return date;
  }
};

/******************************************************************
 * AUTH TOKEN FROM SERVICE ACCOUNT
 ******************************************************************/
function getAccessToken() {
  const now = Math.floor(Date.now() / 1000);
  
  const header = {
    alg: "RS256",
    typ: "JWT"
  };
  
  const claimSet = {
    iss: FIREBASE_SERVICE_ACCOUNT.client_email,
    scope: "https://www.googleapis.com/auth/datastore",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600
  };

  const headerEncoded = Utilities.base64EncodeWebSafe(JSON.stringify(header)).replace(/=+$/, '');
  const claimSetEncoded = Utilities.base64EncodeWebSafe(JSON.stringify(claimSet)).replace(/=+$/, '');
  const signatureInput = headerEncoded + '.' + claimSetEncoded;
  
  const signature = Utilities.computeRsaSha256Signature(signatureInput, FIREBASE_SERVICE_ACCOUNT.private_key);
  const signatureEncoded = Utilities.base64EncodeWebSafe(signature).replace(/=+$/, '');
  
  const jwt = signatureInput + '.' + signatureEncoded;

  const options = {
    method: "post",
    payload: {
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt
    },
    muteHttpExceptions: true
  };

  const response = UrlFetchApp.fetch("https://oauth2.googleapis.com/token", options);
  const result = JSON.parse(response.getContentText());
  
  if (result.error) {
    Logger.log("Auth Error: " + JSON.stringify(result));
    throw new Error(result.error_description);
  }
  
  return result.access_token;
}

/******************************************************************
 * GENERIC FIRESTORE WRITE mit Rate Limiting
 ******************************************************************/
function writeDocument(collection, docId, data, updateMask = null) {
  let url = `${FIRESTORE_BASE_URL}/${collection}/${docId}`;
  
  if (updateMask && updateMask.length > 0) {
    const maskParams = updateMask.map(field => `updateMask.fieldPaths=${field}`).join('&');
    url += `?${maskParams}`;
  }
  
  const token = getAccessToken();

  const payload = JSON.stringify({
    fields: toFirestoreFormat(data),
  });

  const options = {
    method: "patch",
    contentType: "application/json",
    payload: payload,
    headers: { Authorization: `Bearer ${token}` },
    muteHttpExceptions: true,
  };

  const res = UrlFetchApp.fetch(url, options);
  const responseText = res.getContentText();
  
  if (res.getResponseCode() !== 200) {
    Logger.log("ERROR writing " + docId + ": " + responseText);
    throw new Error("Failed to write " + docId);
  } else {
    Logger.log("✓ Wrote: " + docId);
  }
  
  // WICHTIG: Rate limiting - kurz warten
  Utilities.sleep(CONFIG.DELAY_BETWEEN_REQUESTS);
}

/******************************************************************
 * CONVERT JSON → FIRESTORE FIELDS FORMAT
 ******************************************************************/
function toFirestoreFormat(obj) {
  const out = {};
  for (const key in obj) {
    if (obj[key] === null || obj[key] === "") {
      out[key] = { stringValue: "" };
    } else if (typeof obj[key] === "string") {
      out[key] = { stringValue: obj[key] };
    } else if (typeof obj[key] === "number") {
      out[key] = { integerValue: obj[key] };
    } else if (obj[key] instanceof Date) {
      out[key] = { timestampValue: obj[key].toISOString() };
    } else if (Array.isArray(obj[key])) {
      out[key] = { arrayValue: { values: [] } };
    } else {
      out[key] = { stringValue: String(obj[key]) };
    }
  }
  return out;
}

/******************************************************************
 * SYNC SLOTS - OPTIMIERT
 * - Completions werden NICHT mehr gelesen (App managed diese)
 * - Optional: nur aktuelle/zukünftige Slots
 * - Rate limiting
 ******************************************************************/
function syncSlots() {
  Logger.log("📋 Starting syncSlots (optimized)...");
  
  const sheet = SpreadsheetApp.getActive().getSheetByName("Slots");
  if (!sheet) {
    Logger.log("❌ ERROR: Sheet 'Slots' not found!");
    return;
  }
  
  Logger.log("✓ Found sheet: " + sheet.getName());
  Logger.log("✓ Last row: " + sheet.getLastRow());
  
  if (sheet.getLastRow() < 2) {
    Logger.log("⚠️ No data rows found (only header)");
    return;
  }
  
  const values = sheet.getRange(2, 1, sheet.getLastRow() - 1, 6).getValues();
  Logger.log("✓ Read " + values.length + " rows");

  // Optional: Filter für nur aktuelle/zukünftige Slots
  const cutoffDate = CONFIG.SYNC_ONLY_CURRENT_AND_FUTURE 
    ? CONFIG.getDaysAgo(2) 
    : null;

  let count = 0;
  let skipped = 0;
  
  values.forEach((row, index) => {
    const [date, slot, taskId, sponsoredBy, completions, sponsorUrl] = row;
    
    if (!date || !slot || !taskId) {
      Logger.log(`Row ${index + 2}: ⏭️ Skipping empty row`);
      skipped++;
      return;
    }

    const rowDate = new Date(date);
    const dateStr = Utilities.formatDate(rowDate, Session.getScriptTimeZone(), "yyyy-MM-dd");
    
    // Filter: nur aktuelle/zukünftige
    if (cutoffDate && rowDate < cutoffDate) {
      skipped++;
      return;
    }

    const docId = `${dateStr}_${slot}`;
    Logger.log(`Row ${index + 2}: ${docId}`);

    try {
      // Slot schreiben (OHNE completions - die App managed diese!)
      writeDocument("slots", docId, {
        date: dateStr,
        slot: String(slot),
        taskId: String(taskId),
        sponsoredBy: String(sponsoredBy || ""),
        sponsorUrl: String(sponsorUrl || ""),
      }, ["date", "slot", "taskId", "sponsoredBy", "sponsorUrl"]);
      
      count++;
    } catch (e) {
      Logger.log(`  ❌ ERROR: ${e.message}`);
    }
  });

  Logger.log(`✅ Slots synced! (${count} written, ${skipped} skipped)`);
}

/******************************************************************
 * SYNC TASKS - mit Rate Limiting
 ******************************************************************/
function syncTasks() {
  Logger.log("📋 Starting syncTasks (optimized)...");
  
  const sheet = SpreadsheetApp.getActive().getSheetByName("Tasks");
  if (!sheet) {
    Logger.log("❌ ERROR: Sheet 'Tasks' not found!");
    return;
  }

  Logger.log("✓ Found sheet: " + sheet.getName());
  Logger.log("✓ Last row: " + sheet.getLastRow());
  
  if (sheet.getLastRow() < 2) {
    Logger.log("⚠️ No data rows found (only header)");
    return;
  }

  const values = sheet.getRange(2, 1, sheet.getLastRow() - 1, 8).getValues();
  Logger.log("✓ Read " + values.length + " rows");

  let count = 0;
  
  values.forEach((row, index) => {
    const [taskId, headline, text, subline, submittedBy, location, variant, notes] = row;

    if (!taskId) {
      Logger.log(`Row ${index + 2}: ⏭️ Skipping (no taskId)`);
      return;
    }

    Logger.log(`Row ${index + 2}: ${taskId}`);

    try {
      writeDocument("tasks", String(taskId), {
        taskId: String(taskId),
        headline: String(headline || ""),
        text: String(text || ""),
        subline: String(subline || ""),
        submittedBy: String(submittedBy || ""),
        variant: String(variant || ""),
        notes: String(notes || ""),
        location: String(location || ""),
      }, ["taskId", "headline", "text", "subline", "submittedBy", "variant", "notes", "location"]);
      
      count++;
    } catch (e) {
      Logger.log(`  ❌ ERROR: ${e.message}`);
    }
  });

  Logger.log(`✅ Tasks synced! (${count} documents written)`);
}

/******************************************************************
 * IMPORT IDEAS FROM FIRESTORE TO GOOGLE SHEET
 ******************************************************************/
function importIdeas() {
  Logger.log("📥 Starting importIdeas...");
  
  const ss = SpreadsheetApp.getActive();
  let sheet = ss.getSheetByName("Ideas");
  
  if (!sheet) {
    Logger.log("Creating new 'Ideas' sheet...");
    sheet = ss.insertSheet("Ideas");
    sheet.getRange(1, 1, 1, 6).setValues([
      ["Date", "Timestamp", "Nickname", "Location", "Idea", "ID"]
    ]);
    sheet.getRange(1, 1, 1, 6).setFontWeight("bold");
  }
  
  if (sheet.getLastRow() > 1) {
    sheet.deleteRows(2, sheet.getLastRow() - 1);
  }
  
  const token = getAccessToken();
  const url = `${FIRESTORE_BASE_URL}/ideas`;
  
  const options = {
    method: "get",
    headers: { Authorization: `Bearer ${token}` },
    muteHttpExceptions: true
  };
  
  const response = UrlFetchApp.fetch(url, options);
  const result = JSON.parse(response.getContentText());
  
  if (!result.documents || result.documents.length === 0) {
    Logger.log("⚠️ No ideas found");
    return;
  }
  
  Logger.log(`✓ Found ${result.documents.length} ideas`);
  
  const rows = [];
  result.documents.forEach(doc => {
    const fields = doc.fields;
    const docId = doc.name.split('/').pop();
    
    const date = fields.date?.stringValue || "";
    const timestamp = fields.timestamp?.timestampValue || "";
    const nickname = fields.nickname?.stringValue || "";
    const location = fields.location?.stringValue || "";
    const idea = fields.idea?.stringValue || "";
    
    let formattedTime = timestamp;
    if (timestamp) {
      try {
        const dateObj = new Date(timestamp);
        formattedTime = Utilities.formatDate(
          dateObj, 
          Session.getScriptTimeZone(), 
          "yyyy-MM-dd HH:mm:ss"
        );
      } catch (e) {
        Logger.log("Could not format timestamp: " + timestamp);
      }
    }
    
    rows.push([date, formattedTime, nickname, location, idea, docId]);
  });
  
  rows.sort((a, b) => {
    if (a[1] > b[1]) return -1;
    if (a[1] < b[1]) return 1;
    return 0;
  });
  
  if (rows.length > 0) {
    sheet.getRange(2, 1, rows.length, 6).setValues(rows);
    Logger.log(`✅ Imported ${rows.length} ideas!`);
    sheet.autoResizeColumns(1, 6);
  }
}

/******************************************************************
 * RUN ALL
 ******************************************************************/
function syncAll() {
  Logger.log("🚀 Starting optimized sync...");
  Logger.log(`⚙️ Config: Rate limit=${CONFIG.DELAY_BETWEEN_REQUESTS}ms, OnlyCurrentFuture=${CONFIG.SYNC_ONLY_CURRENT_AND_FUTURE}`);
  
  syncTasks();
  syncSlots();
  importIdeas();
  
  Logger.log("✅ ALL SYNCED!");
}

/******************************************************************
 * DEBUG & TEST FUNCTIONS
 ******************************************************************/
function debugSheets() {
  const ss = SpreadsheetApp.getActive();
  Logger.log("📊 Spreadsheet: " + ss.getName());
  
  const sheets = ss.getSheets();
  Logger.log("📄 Anzahl Tabs: " + sheets.length);
  
  sheets.forEach(sheet => {
    Logger.log("  - Tab: '" + sheet.getName() + "' (Zeilen: " + sheet.getLastRow() + ")");
  });
}

function testConfig() {
  Logger.log("⚙️ Current Config:");
  Logger.log("- Delay: " + CONFIG.DELAY_BETWEEN_REQUESTS + "ms");
  Logger.log("- Sync only current/future: " + CONFIG.SYNC_ONLY_CURRENT_AND_FUTURE);
  
  if (CONFIG.SYNC_ONLY_CURRENT_AND_FUTURE) {
    const cutoff = CONFIG.getDaysAgo(2);
    Logger.log("- Cutoff date: " + Utilities.formatDate(cutoff, Session.getScriptTimeZone(), "yyyy-MM-dd"));
  }
}
