window.kofI18n = (() => {
  const LANG_KEY = "kof_lang_v1";
  const DEFAULT_LANG = "en";

  function getRegistry() {
    const upper = window.KOF_TRANSLATIONS;
    const lower = window.kofTranslations;
    const upperHasEntries = upper && typeof upper === "object" && Object.keys(upper).length > 0;
    const lowerHasEntries = lower && typeof lower === "object" && Object.keys(lower).length > 0;
    const registry = upperHasEntries ? upper : (lowerHasEntries ? lower : {});

    if ((!window.KOF_TRANSLATIONS || !upperHasEntries) && registry && Object.keys(registry).length) {
      window.KOF_TRANSLATIONS = registry;
    }

    if ((!window.kofTranslations || !lowerHasEntries) && registry && Object.keys(registry).length) {
      window.kofTranslations = registry;
    }

    return registry || {};
  }

  function getLanguage() {
    const registry = getRegistry();
    const stored = String(localStorage.getItem(LANG_KEY) || "").trim();
    if (stored && registry[stored]) return stored;
    return DEFAULT_LANG;
  }

  function setLanguage(lang) {
    const registry = getRegistry();
    const normalized = String(lang || "").trim();
    if (normalized && registry[normalized]) {
      localStorage.setItem(LANG_KEY, normalized);
      return normalized;
    }

    localStorage.setItem(LANG_KEY, DEFAULT_LANG);
    return DEFAULT_LANG;
  }

  function getByPath(obj, key) {
    return String(key || "")
      .split(".")
      .reduce((acc, part) => (acc && typeof acc === "object") ? acc[part] : undefined, obj);
  }

  function interpolate(template, params = {}) {
    return String(template).replace(/\{(\w+)\}/g, (_, name) => {
      const value = params[name];
      return value === undefined || value === null ? "" : String(value);
    });
  }

  function t(key, params = {}, langOverride = null) {
    const registry = getRegistry();
    const lang = langOverride || getLanguage();

    const fromLang = getByPath(registry[lang], key);
    if (typeof fromLang === "string") {
      return interpolate(fromLang, params);
    }

    const fromDefault = getByPath(registry[DEFAULT_LANG], key);
    if (typeof fromDefault === "string") {
      return interpolate(fromDefault, params);
    }

    return String(key);
  }

  function applyPageTranslations(root = document) {
    const nodes = root.querySelectorAll("[data-i18n]");

    for (const node of nodes) {
      const key = node.getAttribute("data-i18n");
      const attr = node.getAttribute("data-i18n-attr");
      const paramsRaw = node.getAttribute("data-i18n-params");

      let params = {};
      if (paramsRaw) {
        try {
          params = JSON.parse(paramsRaw);
        } catch {}
      }

      const value = t(key, params);

      if (attr) {
        node.setAttribute(attr, value);
      } else {
        node.textContent = value;
      }
    }
  }

  function translateError(input, fallbackKey = "errors.requestFailed") {
    const raw = typeof input === "string"
      ? input
      : (input && typeof input.message === "string" ? input.message : "");

    if (!raw) {
      const fallback = t(fallbackKey);
      return fallback === fallbackKey ? "Request failed" : fallback;
    }

    const exactMap = {
      unauthorized: "errors.unauthorized",
      "no fields to update": "errors.noFieldsToUpdate",
      "old_pin and new_pin required": "errors.oldAndNewPinRequired",
      "PIN too short (min 4)": "errors.pinTooShort",
      "not found": "errors.notFound",
      "wrong PIN": "errors.wrongPin",
      "username and pin required": "errors.usernameAndPinRequired",
      "invalid credentials": "errors.invalidCredentials",
      "invalid role": "errors.invalidRole",
      "username already exists": "errors.usernameAlreadyExists",
      "invalid id": "errors.invalidId",
      "is_active required": "errors.isActiveRequired",
      "cannot disable yourself": "errors.cannotDisableYourself",
      "cannot disable root admin user": "errors.cannotDisableRootAdmin",
      "cannot disable the last active manager": "errors.cannotDisableLastManager",
      "name and price_cents required": "errors.nameAndPriceRequired",
      "name required": "errors.nameRequired",
      "unit required": "errors.unitRequired",
      "stock_qty and low_stock_threshold must be numbers": "errors.stockAndLowMustBeNumbers",
      "ingredient already exists": "errors.ingredientAlreadyExists",
      "name cannot be empty": "errors.nameCannotBeEmpty",
      "unit cannot be empty": "errors.unitCannotBeEmpty",
      "invalid stock_qty": "errors.invalidStockQty",
      "invalid low_stock_threshold": "errors.invalidLowStockThreshold",
      "ingredient update failed": "errors.ingredientUpdateFailed",
      "delta_qty must be a non-zero number": "errors.deltaQtyNonZero",
      "invalid reason": "errors.invalidReason",
      "recipe array required": "errors.recipeArrayRequired",
      "menu item not found": "errors.menuItemNotFound",
      "invalid ingredient_id in recipe": "errors.invalidIngredientIdInRecipe",
      "qty_per_item must be greater than 0": "errors.qtyPerItemPositive",
      "duplicate ingredient in recipe": "errors.duplicateIngredientInRecipe",
      "Receipt available only for paid orders": "errors.receiptPaidOnly",
      "receipt load failed": "errors.receiptLoadFailed",
      "invalid order context": "errors.invalidOrderContext",
      "items required": "errors.itemsRequired",
      "Cart empty": "errors.cartEmpty",
      "Order failed": "errors.orderFailed",
      "config not ok": "errors.configLoadFailed",
      "Valid table QR is required for table orders": "errors.tableQrRequired",
      "Table QR does not match selected table": "errors.tableQrMismatch",
      "Request failed": "errors.requestFailed"
    };

    if (exactMap[raw]) {
      const translated = t(exactMap[raw]);
      return translated === exactMap[raw] ? raw : translated;
    }

    let match = raw.match(/^Request failed \((\d+)\)$/);
    if (match) {
      const translated = t("errors.requestFailedStatus", { status: match[1] });
      return translated === "errors.requestFailedStatus" ? raw : translated;
    }

    match = raw.match(/^ingredient not found: (.+)$/);
    if (match) {
      const translated = t("errors.ingredientNotFoundId", { id: match[1] });
      return translated === "errors.ingredientNotFoundId" ? raw : translated;
    }

    match = raw.match(/^invalid menu_item_id: (.+)$/);
    if (match) {
      const translated = t("errors.invalidMenuItemId", { id: match[1] });
      return translated === "errors.invalidMenuItemId" ? raw : translated;
    }

    match = raw.match(/^requested quantity unavailable for: (.+)$/);
    if (match) {
      const translated = t("errors.requestedQuantityUnavailable", { name: match[1] });
      return translated === "errors.requestedQuantityUnavailable" ? raw : translated;
    }

    return raw;
  }

  function getAvailableLanguages() {
    return Object.keys(getRegistry());
  }

  return {
    LANG_KEY,
    DEFAULT_LANG,
    getLanguage,
    setLanguage,
    getAvailableLanguages,
    t,
    applyPageTranslations,
    translateError,
  };
})();
