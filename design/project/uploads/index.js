/**
* Momentum Cloud Functions – Firestore + Voiceflow + FlutterFlow
* --------------------------------------------------------------
* Keep your secret key safe (use Functions config or env vars in production).
*
* NOTE: This file includes:
*  1) handleVoiceflowEvent
*  2) UpdateMomentumList
*  3) fetchAllMomentumLists
*  4) updateUserPoints
*  5) getUserPoints
*  6) UpdateMomentumListCSV
*  7) getUserProfileForVF
*  8) LinkAnonymousToEmailApi
*  9) ping
* 10) saveCoreListItems (UPDATED — FLATTENED PATH)
* 11) fetchAllCoreListItems (UPDATED — FLATTENED PATH)  ← last function
*/

const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

/**
 * ==============================================================
 * CONFIG
 * ==============================================================
 *
 * IMPORTANT:
 * - Replace this secret with your own, and keep it private.
 * - In production: use Firebase Functions config / env vars.
 */
const API_SECRET = "YOUR_BACKEND_SECRET_HERE"; // scrubbed for public repo

/** Verify secret (works for both GET query and POST body usage when you pass secret explicitly) */
function verifyKey(secretFromRequest) {
    return String(secretFromRequest || "").trim() === API_SECRET;
}

/** Basic helpers */
function asTrimmedString(v) {
    return String(v == null ? "" : v).trim();
}

function getUserDocRef(userId) {
    return db.collection("users").doc(String(userId));
}

/**
 * ==============================================================
 * CORE NORMALIZATION
 * ==============================================================
 */
const CORE_LABELS_BY_ID = {
    mindset_core: "Mindset Core",
    career_finance_core: "Career & Finance Core",
    physical_health_core: "Physical Health Core",
    emotional_mental_core: "Emotional & Mental Health Core",
    relationships_core: "Relationships Core",
};

function coreIdToLabel(coreId) {
    return CORE_LABELS_BY_ID[coreId] || String(coreId || "");
}

/**
 * Accept:
 *  - Full label: "Mindset Core"
 *  - Short id:   "mindset", "relationships", etc
 *  - Full id:    "mindset_core"
 */
function coreNameToId(core) {
    const raw = String(core || "").trim();
    if (!raw) return "";

    const lower = raw.toLowerCase();

    // If caller already passed the final id:
    if (Object.keys(CORE_LABELS_BY_ID).includes(lower)) return lower;

    // short ids → stable ids
    const SHORT_MAP = {
        mindset: "mindset_core",
        career_finance: "career_finance_core",
        career: "career_finance_core",
        finance: "career_finance_core",
        physical_health: "physical_health_core",
        physical: "physical_health_core",
        health: "physical_health_core",
        emotional_mental: "emotional_mental_core",
        emotional: "emotional_mental_core",
        mental: "emotional_mental_core",
        relationships: "relationships_core",
        relationship: "relationships_core",
    };

    if (SHORT_MAP[lower]) return SHORT_MAP[lower];

    // full labels
    const match = Object.entries(CORE_LABELS_BY_ID).find(
        ([, label]) => label.toLowerCase() === lower
    );
    if (match) return match[0];

    return "";
}

/**
 * Category tier:
 * - "Pain Point"   → pain_point
 * - "Golden Habit" → golden_habit
 */
function normalizeCategory(category) {
    const raw = String(category || "").trim().toLowerCase();

    if (!raw) {
        // default if not provided
        return { id: "pain_point", label: "Pain Point" };
    }

    if (raw.includes("pain")) return { id: "pain_point", label: "Pain Point" };
    if (raw.includes("golden")) return { id: "golden_habit", label: "Golden Habit" };

    // allow already-normalized ids
    if (raw === "pain_point") return { id: "pain_point", label: "Pain Point" };
    if (raw === "golden_habit") return { id: "golden_habit", label: "Golden Habit" };

    // fallback: treat as id
    return { id: raw.replace(/\s+/g, "_"), label: category };
}



// Put these helpers near your other helpers (top of file)
function stripWrappingQuotes(s) {
    const t = String(s ?? "").trim();
    if (
        (t.startsWith('"') && t.endsWith('"')) ||
        (t.startsWith("'") && t.endsWith("'"))
    ) {
        return t.slice(1, -1);
    }
    return t;
}
function normalizeItems(itemsRaw) {
    // Already an array → clean and return
    if (Array.isArray(itemsRaw)) {
        return itemsRaw
            .map((x) => stripWrappingQuotes(String(x)).trim())
            .filter(Boolean);
    }

    // Helper: safe JSON.parse
    const tryParse = (s) => {
        try {
            return JSON.parse(s);
        } catch (_) {
            return null;
        }
    };

    // String → handle:
    //  - JSON array: ["a","b"]
    //  - JSON string containing JSON array: "\"[\\\"a\\\",\\\"b\\\"]\""
    //  - CSV: "a,b"
    if (typeof itemsRaw === "string") {
        let s = itemsRaw.trim();
        if (!s) return [];

        // Try parse once (works if s is JSON array OR JSON string)
        let parsed = tryParse(s);

        // If it parsed into a STRING, it may contain the real JSON array text → parse again
        if (typeof parsed === "string") {
            const parsed2 = tryParse(parsed);
            if (Array.isArray(parsed2)) {
                return parsed2
                    .map((x) => stripWrappingQuotes(String(x)).trim())
                    .filter(Boolean);
            }
            // If not an array, treat parsed string as the new s and continue fallback logic
            s = parsed;
            parsed = null;
        }

        // If it parsed into an ARRAY directly
        if (Array.isArray(parsed)) {
            return parsed
                .map((x) => stripWrappingQuotes(String(x)).trim())
                .filter(Boolean);
        }

        // If it LOOKS like an array, try parsing as array text
        if (s.startsWith("[") && s.endsWith("]")) {
            const parsed3 = tryParse(s);
            if (Array.isArray(parsed3)) {
                return parsed3
                    .map((x) => stripWrappingQuotes(String(x)).trim())
                    .filter(Boolean);
            }
        }

        // CSV fallback
        return s
            .split(",")
            .map((x) => stripWrappingQuotes(x).trim())
            .filter(Boolean);
    }

    return [];
}



function parseItemsInput(items) {
    // items can be: array, JSON string '["a","b"]', CSV "a,b", or single value
    if (Array.isArray(items)) {
        return items.map(asTrimmedString).filter((s) => s.length > 0);
    }

    if (typeof items === "string") {
        const t = items.trim();

        // If it's a JSON array string, parse it
        if (t.startsWith("[") && t.endsWith("]")) {
            try {
                const parsed = JSON.parse(t);
                if (Array.isArray(parsed)) {
                    return parsed.map(asTrimmedString).filter((s) => s.length > 0);
                }
            } catch (e) {
                // fall back to CSV below
            }
        }

        // Fallback: treat as CSV
        return t
            .split(",")
            .map(asTrimmedString)
            .filter((s) => s.length > 0);
    }

    if (items != null) {
        const one = asTrimmedString(items);
        return one ? [one] : [];
    }

    return [];
}




/* **********************************************************************
 * 1) handleVoiceflowEvent
 * ********************************************************************** */
exports.handleVoiceflowEvent = onRequest({ cors: true }, async (req, res) => {
    res.set("Cache-Control", "no-store");

    try {
        const { secret, userId, eventName, payload } =
            req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }

        const ff_uid = asTrimmedString(userId);
        if (!ff_uid) {
            return res.status(400).json({ ok: false, error: "Missing userId" });
        }

        const safeEvent = asTrimmedString(eventName) || "unknown_event";
        const safePayload = payload || {};

        const vfDocRef = db.collection("vf_events").doc(ff_uid);

        // This creates a single "event doc" that your app can poll.
        await vfDocRef.set(
            {
                status: "New",
                eventName: safeEvent,
                payload: safePayload,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                eventCount: admin.firestore.FieldValue.increment(1),
            },
            { merge: true }
        );

        return res.json({ ok: true });
    } catch (e) {
        logger.error("handleVoiceflowEvent error:", e);
        return res.status(500).json({ ok: false, error: "Internal server error" });
    }
});

/* **********************************************************************
 * 2) UpdateMomentumList
 * ********************************************************************** */
exports.UpdateMomentumList = onRequest({ cors: true }, async (req, res) => {
    res.set("Cache-Control", "no-store");

    try {
        const { secret, ff_uid, ListName, ItemsCSV } =
            req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }

        const userId = asTrimmedString(ff_uid);
        const listName = asTrimmedString(ListName);
        const itemsCsv = ItemsCSV;

        if (!userId || !listName) {
            return res.status(400).json({
                ok: false,
                error: "Missing ff_uid or ListName",
            });
        }

        // Accept CSV string or array
        let items = [];
        if (Array.isArray(itemsCsv)) {
            items = itemsCsv.map((x) => String(x).trim()).filter(Boolean);
        } else {
            items = String(itemsCsv || "")
                .split(",")
                .map((s) => s.trim())
                .filter(Boolean);
        }

        const listRef = db
            .collection("users")
            .doc(userId)
            .collection("momentum_lists")
            .doc(listName);

        await listRef.set(
            {
                name: listName,
                items,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
        );

        return res.json({ ok: true, userId, listName, count: items.length });
    } catch (e) {
        logger.error("UpdateMomentumList error:", e);
        return res.status(500).json({ ok: false, error: "Internal server error" });
    }
});

/* **********************************************************************
 * 3) fetchAllMomentumLists
 * ********************************************************************** */
exports.fetchAllMomentumLists = onRequest({ cors: true }, async (req, res) => {
    res.set("Cache-Control", "no-store");

    try {
        const { secret, userId } = req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }

        const uid = asTrimmedString(userId);
        if (!uid) {
            return res.status(400).json({ ok: false, error: "Missing userId" });
        }

        const snap = await db
            .collection("users")
            .doc(uid)
            .collection("momentum_lists")
            .get();

        const lists = snap.docs.map((d) => {
            const data = d.data() || {};
            return {
                name: data.name || d.id,
                items: Array.isArray(data.items) ? data.items : [],
            };
        });

        return res.json({ ok: true, userId: uid, lists });
    } catch (e) {
        logger.error("fetchAllMomentumLists error:", e);
        return res.status(500).json({ ok: false, error: "Internal server error" });
    }
});

/* **********************************************************************
 * 4) updateUserPoints
 * ********************************************************************** */
exports.updateUserPoints = onRequest({ cors: true }, async (req, res) => {
    res.set("Cache-Control", "no-store");

    try {
        const { secret, userId, points, type } =
            req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }

        const uid = asTrimmedString(userId);
        if (!uid) {
            return res.status(400).json({ ok: false, error: "Missing userId" });
        }

        const pts = Number(points);
        if (!Number.isFinite(pts)) {
            return res.status(400).json({ ok: false, error: "Invalid points" });
        }

        const typeStr = asTrimmedString(type) || "General";

        const userRef = db.collection("users").doc(uid);
        const summaryRef = userRef.collection("points").doc("summary");
        const historyRef = userRef.collection("points").doc("summary").collection("history").doc();
        // If you prefer: userRef.collection("points").doc("summary") is fine,
        // OR store history at userRef.collection("points_history").doc() (either works).

        let newTotal = 0;

        await db.runTransaction(async (tx) => {
            const summarySnap = await tx.get(summaryRef);
            const currentTotal = summarySnap.exists ? Number(summarySnap.data().total || 0) : 0;

            newTotal = currentTotal + pts;

            // 1) Update summary
            tx.set(
                summaryRef,
                {
                    total: newTotal,
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
                },
                { merge: true }
            );

            // 2) Write history entry
            tx.set(historyRef, {
                type: typeStr,
                points: pts,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });

            // 3) Optional: store total on user doc too (handy for quick reads)
            tx.set(
                userRef,
                {
                    points: newTotal,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
                { merge: true }
            );
        });

        return res.json({
            ok: true,
            userId: uid,
            type: typeStr,
            pointsAdded: pts,
            totalPoints: newTotal,
        });
    } catch (e) {
        logger.error("updateUserPoints error:", e);
        return res.status(500).json({ ok: false, error: "Internal server error" });
    }
});


/* **********************************************************************
 * 5) getUserPoints
 * ********************************************************************** */
exports.getUserPoints = onRequest({ cors: true }, async (req, res) => {
    res.set("Cache-Control", "no-store");

    try {
        const { secret, userId } = req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }

        const uid = asTrimmedString(userId);
        if (!uid) {
            return res.status(400).json({ ok: false, error: "Missing userId" });
        }

        const doc = await db.collection("users").doc(uid).get();
        const data = doc.data() || {};

        return res.json({
            ok: true,
            userId: uid,
            points: Number(data.points || 0),
        });
    } catch (e) {
        logger.error("getUserPoints error:", e);
        return res.status(500).json({ ok: false, error: "Internal server error" });
    }
});

/* **********************************************************************
 * 6) UpdateMomentumListCSV
 * ********************************************************************** */
exports.UpdateMomentumListCSV = onRequest({ cors: true }, async (req, res) => {
    res.set("Cache-Control", "no-store");

    try {
        const { secret, ff_uid, ListName, ItemsCSV } =
            req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }

        const userId = asTrimmedString(ff_uid);
        const listName = asTrimmedString(ListName);
        const itemsCsv = asTrimmedString(ItemsCSV);

        if (!userId || !listName) {
            return res.status(400).json({ ok: false, error: "Missing ff_uid or ListName" });
        }

        const items = itemsCsv
            .split(",")
            .map((s) => s.trim())
            .filter(Boolean);

        const listRef = db
            .collection("users")
            .doc(userId)
            .collection("momentum_lists")
            .doc(listName);

        await listRef.set(
            {
                name: listName,
                items,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
        );

        return res.json({ ok: true, userId, listName, count: items.length });
    } catch (e) {
        logger.error("UpdateMomentumListCSV error:", e);
        return res.status(500).json({ ok: false, error: "Internal server error" });
    }
});

/* **********************************************************************
 * 7) getUserProfileForVF
 * ********************************************************************** */
exports.getUserProfileForVF = onRequest({ cors: true }, async (req, res) => {
    res.set("Cache-Control", "no-store");

    try {
        const { secret, userId } = req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }

        const uid = asTrimmedString(userId);
        if (!uid) {
            return res.status(400).json({ ok: false, error: "Missing userId" });
        }

        const doc = await db.collection("users").doc(uid).get();
        const data = doc.data() || {};

        // Return whatever profile fields you want Voiceflow to consume
        return res.json({
            ok: true,
            userId: uid,
            email: data.email || "",
            points: Number(data.points || 0),
            currentCore: data.currentCore || null,
        });
    } catch (e) {
        logger.error("getUserProfileForVF error:", e);
        return res.status(500).json({ ok: false, error: "Internal server error" });
    }
});

/* **********************************************************************
 * 8) LinkAnonymousToEmailApi - upgrade anon user to email.
 * ********************************************************************** */
exports.LinkAnonymousToEmailApi = onRequest({ cors: true }, async (req, res) => {
    res.set("Cache-Control", "no-store");

    try {
        const { secret, uid, email } = req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }

        // This endpoint is just a placeholder for your flow.
        // You said your anonymous->email linking is now working.
        // Keep this as-is if you already use it for logging / debugging.
        const userId = asTrimmedString(uid);
        const em = asTrimmedString(email);

        if (!userId || !em) {
            return res.status(400).json({ ok: false, error: "Missing uid or email" });
        }

        await db.collection("users").doc(userId).set(
            {
                email: em,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
        );

        return res.json({ ok: true, uid: userId, email: em });
    } catch (e) {
        logger.error("LinkAnonymousToEmailApi error:", e);
        return res.status(500).json({ ok: false, error: "Internal server error" });
    }
});

/**
 * 9) ping
 *    Simple health-check endpoint.
 *    Returns { ok: true, ts: <server timestamp> }
 */
exports.ping = onRequest(async (req, res) => {
    try {
        const { secret } = req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }

        return res.json({ ok: true, ts: Date.now() });
    } catch (err) {
        logger.error("ping error", err);
        return res.status(500).json({ ok: false, error: err.message || "Error" });
    }
});

/* ------------------------------------------------------------------ */
/* UPDATED CORE-LIST FUNCTIONS (CoreListItems-only; separate from MomentumLists) */
/* ------------------------------------------------------------------ */

/**
 * 10) saveCoreListItems (UPDATED)
 *
 * Saves under (FLATTENED — no extra folders):
 *   /users/{uid}/core/{coreId}/{categoryId}/{listName}
 *
 * IMPORTANT:
 * - We *always* set() the core doc so it EXISTS
 *   (fixes your "fetch returns []" problem).
 *
 * Expected query params (GET preferred, POST supported):
 *   secret
 *   userId
 *   core        → "Mindset Core"
 *   category    → "Pain Point" OR "Golden Habit"
 *   listName    → e.g. "Core Pain Point" or "Golden Habit Drafts"
 *   items       → CSV string OR array
 */
exports.saveCoreListItems = onRequest(async (req, res) => {
    try {
        const { secret, userId, core, category, listName, items } =
            req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }

        if (!userId || !core || !listName) {
            return res.status(400).json({
                ok: false,
                error: "Missing required params: userId, core, listName",
            });
        }

        const coreId = coreNameToId(core);
        const coreLabel = coreIdToLabel(coreId);
        if (!coreId) {
            return res.status(400).json({ ok: false, error: "Invalid core" });
        }

        const { id: categoryId, label: categoryLabel } = normalizeCategory(category);

        const safeListName = asTrimmedString(listName);
        if (!safeListName) {
            return res.status(400).json({ ok: false, error: "Invalid listName" });
        }

        // Parse items (CSV string OR array) → array of non-empty strings
        let itemArray = [];
        if (Array.isArray(items)) {
            itemArray = items
                .map((s) => asTrimmedString(s))
                .filter((s) => s.length > 0);
        } else if (typeof items === "string") {
            itemArray = items
                .split(",")
                .map((s) => asTrimmedString(s))
                .filter((s) => s.length > 0);
        } else if (items != null) {
            itemArray = [asTrimmedString(items)].filter((s) => s.length > 0);
        }

        const userRef = getUserDocRef(userId);

        // Core doc MUST exist for fetch to work
        const coreDocRef = userRef.collection("core").doc(coreId);
        await coreDocRef.set(
            {
                id: coreId,
                label: coreLabel,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
        );

        // FLATTENED storage:
        //   /users/{uid}/core/{coreId}/{categoryId}/{listName}
        const listDocRef = coreDocRef.collection(categoryId).doc(safeListName);

        await listDocRef.set(
            {
                name: safeListName,
                items: itemArray,
                coreId,
                coreLabel,
                categoryId,
                categoryLabel,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
        );

        return res.json({
            ok: true,
            userId: String(userId),
            coreId,
            coreLabel,
            categoryId,
            categoryLabel,
            listName: safeListName,
            count: itemArray.length,
            savedPath: `/users/${userId}/core/${coreId}/${categoryId}/${safeListName}`,
        });
    } catch (err) {
        logger.error("saveCoreListItems error", err);
        return res.status(500).json({ ok: false, error: err.message || "Internal error" });
    }
});

/**
 * 11) fetchAllCoreListItems (UPDATED)
 *
 * Reads flattened structure:
 *   /users/{uid}/core/{coreId}/{categoryId}/{listName}
 *
 * Returns:
 * {
 *   ok: true,
 *   userId: "...",
 *   cores: [
 *     {
 *       id: "mindset_core",
 *       label: "Mindset Core",
 *       categories: [
 *         {
 *           id: "pain_point",
 *           label: "Pain Point",
 *           lists: [
 *             { name: "Core Pain Point", items: ["..."] }
 *           ]
 *         },
 *         ...
 *       ]
 *     },
 *     ...
 *   ]
 * }
 *
 * FlutterFlow JSONPaths:
 *   $.cores
 *   $.cores[*].label
 *   $.cores[*].categories
 *   $.cores[*].categories[*].label
 *   $.cores[*].categories[*].lists
 *   $.cores[*].categories[*].lists[*].name
 *   $.cores[*].categories[*].lists[*].items
 */

exports.fetchAllCoreListItems = onRequest(async (req, res) => {
    try {
        const { secret, userId } = req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }

        if (!userId) {
            return res.status(400).json({ ok: false, error: "Missing userId" });
        }

        const userRef = getUserDocRef(userId);

        // Only returns docs that actually exist.
        const coreSnap = await userRef.collection("core").get();

        const cores = [];

        for (const coreDoc of coreSnap.docs) {
            const coreData = coreDoc.data() || {};
            const coreId = coreDoc.id;
            const coreLabel = coreData.label || coreIdToLabel(coreId);

            // Categories are subcollections under core doc
            const categories = [];
            const categoryCollections = await coreDoc.ref.listCollections();

            for (const catCol of categoryCollections) {
                const categoryId = catCol.id;

                const lists = [];
                const listsSnap = await catCol.get();

                for (const listDoc of listsSnap.docs) {
                    const listData = listDoc.data() || {};
                    lists.push({
                        name: listData.name || listDoc.id,
                        items: Array.isArray(listData.items) ? listData.items : [],
                    });
                }

                // Try to find a friendly label from any list doc, otherwise fallback
                const categoryLabel =
                    listsSnap.docs.find((d) => (d.data() || {}).categoryLabel)?.data()
                        ?.categoryLabel ||
                    (categoryId === "pain_point"
                        ? "Pain Point"
                        : categoryId === "golden_habit"
                            ? "Golden Habit"
                            : categoryId);

                categories.push({
                    id: categoryId,
                    label: categoryLabel,
                    lists,
                });
            }

            cores.push({
                id: coreId,
                label: coreLabel,
                categories,
            });
        }

        return res.json({
            ok: true,
            userId: String(userId),
            cores,
        });
    } catch (err) {
        logger.error("fetchAllCoreListItems error", err);
        return res.status(500).json({ ok: false, error: err.message || "Internal error" });
    }
});

/**
* 12) fetchCoreListItemsByCoreName (currently not going to use. but returns all )
*
* Params (GET preferred, POST supported):
*   secret
*   userId
*   coreName   → "mindset_core" OR "mindset" OR "Mindset Core"
*
* Returns:
* {
*   ok: true,
*   userId: "...",
*   core: {
*     id: "mindset_core",
*     label: "Mindset Core",
*     categories: [
*       { id: "pain_point", label: "Pain Point", lists: [{ name, items: [] }] }
*     ]
*   }
* }
*
* FlutterFlow JSONPaths:
*   $.core.label
*   $.core.categories
*   $.core.categories[*].label
*   $.core.categories[*].lists
*   $.core.categories[*].lists[*].name
*   $.core.categories[*].lists[*].items
*/
exports.fetchCoreListItemsByCoreName = onRequest(async (req, res) => {
    try {
        const { secret, userId, coreName } = req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }

        const uid = asTrimmedString(userId);
        if (!uid) {
            return res.status(400).json({ ok: false, error: "Missing userId" });
        }

        const requestedCore = asTrimmedString(coreName);
        if (!requestedCore) {
            return res.status(400).json({ ok: false, error: "Missing coreName" });
        }

        // Normalize coreName -> coreId (supports "Mindset Core", "mindset", "mindset_core", etc.)
        const coreId = coreNameToId(requestedCore);
        if (!coreId) {
            return res.status(400).json({ ok: false, error: "Invalid coreName" });
        }

        const userRef = getUserDocRef(uid);
        const coreDocRef = userRef.collection("core").doc(coreId);
        const coreDoc = await coreDocRef.get();

        // If the core doc doesn't exist yet, return empty core (or you can 404 if you prefer)
        if (!coreDoc.exists) {
            return res.json({
                ok: true,
                userId: String(uid),
                core: {
                    id: coreId,
                    label: coreIdToLabel(coreId),
                    categories: [],
                },
            });
        }

        const coreData = coreDoc.data() || {};
        const coreLabel = coreData.label || coreIdToLabel(coreId);

        // Categories are subcollections under core doc (same approach as fetchAllCoreListItems)
        const categories = [];
        const categoryCollections = await coreDocRef.listCollections();

        for (const catCol of categoryCollections) {
            const categoryId = catCol.id;

            const lists = [];
            const listsSnap = await catCol.get();

            for (const listDoc of listsSnap.docs) {
                const listData = listDoc.data() || {};
                lists.push({
                    name: listData.name || listDoc.id,
                    items: Array.isArray(listData.items) ? listData.items : [],
                });
            }

            // Try to find a friendly label from any list doc, otherwise fallback
            const categoryLabel =
                listsSnap.docs.find((d) => (d.data() || {}).categoryLabel)?.data()?.categoryLabel ||
                (categoryId === "pain_point"
                    ? "Pain Point"
                    : categoryId === "golden_habit"
                        ? "Golden Habit"
                        : categoryId);

            categories.push({
                id: categoryId,
                label: categoryLabel,
                lists,
            });
        }

        return res.json({
            ok: true,
            userId: String(uid),
            core: {
                id: coreId,
                label: coreLabel,
                categories,
            },
        });
    } catch (err) {
        logger.error("fetchCoreListItemsByCoreName error", err);
        return res.status(500).json({ ok: false, error: err.message || "Internal error" });
    }
});

/**
* 13) fetchCoreCategoriesByCoreName
*
* Params:
*  secret, userId, coreName
*
* Returns:
*  { ok, userId, core: { id, label }, categories: [{ id, label }] }
*/
exports.fetchCoreCategoriesByCoreName = onRequest(async (req, res) => {
    try {
        const { secret, userId, coreName } = req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) return res.status(401).json({ ok: false, error: "Invalid secret" });

        const uid = asTrimmedString(userId);
        const requestedCore = asTrimmedString(coreName);
        if (!uid || !requestedCore) {
            return res.status(400).json({ ok: false, error: "Missing userId or coreName" });
        }

        const coreId = coreNameToId(requestedCore);
        if (!coreId) return res.status(400).json({ ok: false, error: "Invalid coreName" });

        const userRef = getUserDocRef(uid);
        const coreDocRef = userRef.collection("core").doc(coreId);
        const coreDoc = await coreDocRef.get();

        // Core doc may not exist yet (return empty)
        if (!coreDoc.exists) {
            return res.json({
                ok: true,
                userId: String(uid),
                core: { id: coreId, label: coreIdToLabel(coreId) },
                categories: [],
            });
        }

        const categoryCollections = await coreDocRef.listCollections();

        const categories = categoryCollections.map((col) => {
            const id = col.id;
            const label =
                id === "pain_point"
                    ? "Pain Point"
                    : id === "golden_habit"
                        ? "Golden Habit"
                        : id;
            return { id, label };
        });

        return res.json({
            ok: true,
            userId: String(uid),
            core: { id: coreId, label: (coreDoc.data() || {}).label || coreIdToLabel(coreId) },
            categories,
        });
    } catch (err) {
        logger.error("fetchCoreCategoriesByCoreName error", err);
        return res.status(500).json({ ok: false, error: err.message || "Internal error" });
    }
});


/**
 * 14) fetchCoreListsByCoreAndCategory
 *
 * Params:
 *  secret, userId, coreName, category   (category can be "Pain Point" or "pain_point" etc.)
 *
 * Returns:
 *  { ok, userId, core:{...}, category:{id,label}, lists:[{ name, itemCount }] }
 */
exports.fetchCoreListsByCoreAndCategory = onRequest(async (req, res) => {
    try {
        const { secret, userId, coreName, category } =
            req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }
        if (!userId) return res.status(400).json({ ok: false, error: "Missing userId" });
        if (!coreName) return res.status(400).json({ ok: false, error: "Missing coreName" });
        if (!category) return res.status(400).json({ ok: false, error: "Missing category" });

        const uid = asTrimmedString(userId);
        const coreId = coreNameToId(coreName);
        if (!coreId) return res.status(400).json({ ok: false, error: "Invalid coreName" });

        const { id: categoryId, label: categoryLabel } = normalizeCategory(category);

        const userRef = getUserDocRef(uid);
        const coreRef = userRef.collection("core").doc(coreId);

        const coreDoc = await coreRef.get();
        if (!coreDoc.exists) {
            return res.status(404).json({ ok: false, error: "Core not found" });
        }

        const coreData = coreDoc.data() || {};
        const coreLabel = coreData.label || coreIdToLabel(coreId);

        const catRef = coreRef.collection(categoryId);
        const snap = await catRef.get();

        const lists = snap.docs.map((d) => {
            const data = d.data() || {};
            return {
                name: data.name || d.id,
                items: normalizeItems(data.items),
            };
        });

        return res.json({
            ok: true,
            userId: uid,
            core: { id: coreId, label: coreLabel },
            category: { id: categoryId, label: categoryLabel },
            lists, // each list includes { name, items }
        });
    } catch (err) {
        logger.error("fetchCoreListsByCoreAndCategory error", err);
        return res.status(500).json({ ok: false, error: err.message || "Internal error" });
    }
});



/**  not used --may dell it
 * 15) fetchCoreListItemsByCoreCategoryAndListName
 *
 * Params:
 *  secret, userId, coreName, category, listName
 *
 * Returns:
 *  { ok, userId, core:{...}, category:{...}, list:{ name, items:[] } }
 */
exports.fetchCoreListItemsByCoreCategoryAndListName = onRequest(async (req, res) => {
    try {
        const { secret, userId, coreName, category, listName } =
            req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) return res.status(401).json({ ok: false, error: "Invalid secret" });

        const uid = asTrimmedString(userId);
        const requestedCore = asTrimmedString(coreName);
        const safeListName = asTrimmedString(listName);

        if (!uid || !requestedCore || !safeListName) {
            return res.status(400).json({ ok: false, error: "Missing userId, coreName, or listName" });
        }

        const coreId = coreNameToId(requestedCore);
        if (!coreId) return res.status(400).json({ ok: false, error: "Invalid coreName" });

        const { id: categoryId, label: categoryLabel } = normalizeCategory(category);

        const userRef = getUserDocRef(uid);
        const coreDocRef = userRef.collection("core").doc(coreId);
        const coreDoc = await coreDocRef.get();

        if (!coreDoc.exists) {
            return res.json({
                ok: true,
                userId: String(uid),
                core: { id: coreId, label: coreIdToLabel(coreId) },
                category: { id: categoryId, label: categoryLabel },
                list: { name: safeListName, items: [] },
            });
        }

        const docRef = coreDocRef.collection(categoryId).doc(safeListName);
        const docSnap = await docRef.get();

        const data = docSnap.data() || {};
        const items = Array.isArray(data.items) ? data.items : [];

        return res.json({
            ok: true,
            userId: String(uid),
            core: { id: coreId, label: (coreDoc.data() || {}).label || coreIdToLabel(coreId) },
            category: { id: categoryId, label: categoryLabel },
            list: { name: data.name || safeListName, items },
        });
    } catch (err) {
        logger.error("fetchCoreListItemsByCoreCategoryAndListName error", err);
        return res.status(500).json({ ok: false, error: err.message || "Internal error" });
    }
});


/* **********************************************************************
*  16) UpdateCoreListItems
*
* Updates Core List Items (same idea as UpdateMomentumList)
*
* Writes to:
*  /users/{uid}/core/{coreId}/{categoryId}/{listName}
*
* Accepts (GET or POST):
*  secret, userId, coreName, category, listName, items
*
* items can be:
*  - array (recommended for POST)
*  - CSV string (works for GET)
*  - single string
* ********************************************************************** */
exports.UpdateCoreListItems = onRequest({ cors: true }, async (req, res) => {
    res.set("Cache-Control", "no-store");

    try {
        const { secret, userId, coreName, category, listName, items } =
            req.method === "POST" ? req.body : req.query;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }

        const uid = asTrimmedString(userId);
        const requestedCore = asTrimmedString(coreName);
        const safeListName = asTrimmedString(listName);

        if (!uid || !requestedCore || !safeListName) {
            return res.status(400).json({
                ok: false,
                error: "Missing required fields (userId, coreName, listName)",
            });
        }

        const coreId = coreNameToId(requestedCore);
        if (!coreId) {
            return res.status(400).json({ ok: false, error: "Invalid coreName" });
        }

        const coreLabel = coreIdToLabel(coreId);
        const { id: categoryId, label: categoryLabel } = normalizeCategory(category);

        // ✅ Handles array, JSON array string, double-encoded JSON array string, or CSV
        const itemsArr = normalizeItems(items);

        const userRef = getUserDocRef(uid);

        // Ensure core doc exists (same pattern as saveCoreListItems)
        const coreDocRef = userRef.collection("core").doc(coreId);
        await coreDocRef.set(
            {
                id: coreId,
                label: coreLabel,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
        );

        // Write list doc
        const listRef = coreDocRef.collection(categoryId).doc(safeListName);

        await listRef.set(
            {
                name: safeListName,
                items: itemsArr,
                coreId,
                coreLabel,
                categoryId,
                categoryLabel,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
        );

        return res.json({
            ok: true,
            userId: uid,
            core: { id: coreId, label: coreLabel },
            category: { id: categoryId, label: categoryLabel },
            list: { name: safeListName, items: itemsArr },
            count: itemsArr.length,
            savedPath: `/users/${uid}/core/${coreId}/${categoryId}/${safeListName}`,
        });
    } catch (e) {
        logger.error("UpdateCoreListItems error:", e);
        return res.status(500).json({ ok: false, error: e.message || "Internal server error" });
    }
});


/**
 * saveGoldenHabit (NEW)
 *
 * Stores a structured Golden Habit object (NOT a list).
 *
 * Path:
 *   /users/{userId}/golden_habits/{habitId}
 *
 * Params (GET or POST):
 *   secret (required)
 *   userId (required)
 *   core (required)                 // ex: "Mindset Core" or "mindset_core"
 *   habitName (required)            // name you want to show in FlutterFlow (ex: "Deep Presence Practice")
 *
 * Optional:
 *   habitId                          // if you want to control the doc id
 *   painPoint
 *   backToFutureIdentity
 *   coreDimension
 *   habitType                        // "routine" | "non_routine"
 *   where
 *   when
 *   what
 *   cueType                          // "emotional" | "physical" | "situational" | etc.
 *   trigger
 *   anchorReminder
 *   obstacleIf
 *   obstacleThen
 *   whyWant
 *   whyCan
 *   whyEffective
 *   startingVersion
 *   displayText                      // full formatted Golden Habit block (optional but nice for UI)
 */
function slugifyId(input) {
    const raw = String(input || "").trim().toLowerCase();
    if (!raw) return "";
    // keep letters/numbers/space/_/-
    const cleaned = raw.replace(/[^a-z0-9 _-]/g, "");
    // spaces -> underscore
    const underscored = cleaned.replace(/\s+/g, "_");
    // collapse multiple underscores
    const compact = underscored.replace(/_+/g, "_").replace(/^_+|_+$/g, "");
    return compact.slice(0, 60); // limit length for safety
}

exports.saveGoldenHabit = onRequest({ cors: true }, async (req, res) => {
    res.set("Cache-Control", "no-store");

    try {
        const body = req.method === "POST" ? (req.body || {}) : (req.query || {});
        const {
            secret,
            userId,
            core,
            habitName,
            habitId,

            painPoint,
            backToFutureIdentity,
            coreDimension,

            habitType,
            where,
            when,
            what,
            cueType,
            trigger,
            anchorReminder,

            obstacleIf,
            obstacleThen,

            whyWant,
            whyCan,
            whyEffective,

            startingVersion,
            displayText,
        } = body;

        if (!verifyKey(secret)) {
            return res.status(401).json({ ok: false, error: "Invalid secret" });
        }

        const uid = asTrimmedString(userId);
        const coreRaw = asTrimmedString(core);
        const nameRaw = asTrimmedString(habitName);

        if (!uid || !coreRaw || !nameRaw) {
            return res.status(400).json({
                ok: false,
                error: "Missing required params: userId, core, habitName",
            });
        }

        const coreId = coreNameToId(coreRaw);
        if (!coreId) {
            return res.status(400).json({ ok: false, error: "Invalid core" });
        }
        const coreLabel = coreIdToLabel(coreId);

        // Choose doc id:
        // - use provided habitId if present
        // - else slugify habitName
        // - if slug becomes empty, fallback to timestamp
        let hid = asTrimmedString(habitId);
        if (!hid) {
            const base = slugifyId(nameRaw);
            hid = base ? `gh_${base}` : `gh_${Date.now()}`;
        }

        const docRef = db
            .collection("users")
            .doc(uid)
            .collection("golden_habits")
            .doc(hid);

        const payload = {
            habitId: hid,

            // display fields
            habitName: nameRaw,               // what you show in FlutterFlow lists
            coreId,
            coreLabel,

            // context
            painPoint: asTrimmedString(painPoint),
            backToFutureIdentity: asTrimmedString(backToFutureIdentity),
            coreDimension: asTrimmedString(coreDimension),

            // habit mechanics
            habitType: asTrimmedString(habitType),     // "routine" or "non_routine"
            where: asTrimmedString(where),
            when: asTrimmedString(when),
            what: asTrimmedString(what),

            cueType: asTrimmedString(cueType),
            trigger: asTrimmedString(trigger),

            anchorReminder: asTrimmedString(anchorReminder),

            // obstacle plan
            obstacleIf: asTrimmedString(obstacleIf),
            obstacleThen: asTrimmedString(obstacleThen),

            // why-this-works
            whyWant: asTrimmedString(whyWant),
            whyCan: asTrimmedString(whyCan),
            whyEffective: asTrimmedString(whyEffective),

            // starting (atomic) version
            startingVersion: asTrimmedString(startingVersion),

            // optional full formatted block for rendering
            displayText: asTrimmedString(displayText),

            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Only set createdAt the first time
        await db.runTransaction(async (tx) => {
            const snap = await tx.get(docRef);
            if (!snap.exists) {
                tx.set(docRef, { ...payload, createdAt: admin.firestore.FieldValue.serverTimestamp() });
            } else {
                tx.set(docRef, payload, { merge: true });
            }
        });

        return res.json({
            ok: true,
            userId: uid,
            habitId: hid,
            habitName: nameRaw,
            savedPath: `/users/${uid}/golden_habits/${hid}`,
        });
    } catch (err) {
        logger.error("saveGoldenHabit error", err);
        return res.status(500).json({ ok: false, error: err.message || "Internal error" });
    }
});
