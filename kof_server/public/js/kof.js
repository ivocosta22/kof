window.kof = (() => {
  const CART_KEY = "kof_cart_v1";
  const LAST_ORDER_KEY = "kof_last_order_id_v1";
  const MY_ORDERS_KEY = "kof_my_orders_v1";
  const TABLE_SESSION_KEY = "kof_table_session_v1";
  const CUSTOMER_DARK_MODE_KEY = "kof_customer_dark_mode_v1";

  let configCache = null;
  let menuCache = null;
  let menuByIdCache = new Map();

  function translateErrorMessage(message, fallbackKey = "errors.requestFailed") {
    const translator = window.kofI18n && typeof window.kofI18n.translateError === "function"
      ? window.kofI18n.translateError
      : null;

    return translator ? translator(message, fallbackKey) : String(message || "");
  }

// Safely read JSON from localStorage. Returns the provided fallback when the
// stored value is missing or invalid.
  function readJsonStorage(key, fallback) {
    try {
      const raw = localStorage.getItem(key);
      return raw ? JSON.parse(raw) : fallback;
    } catch {
      return fallback;
    }
  }

// Write JSON data to localStorage. Centralizes serialization for cart and
// order-related browser persistence.
  function writeJsonStorage(key, value) {
    localStorage.setItem(key, JSON.stringify(value));
  }

// Safely read JSON from sessionStorage. Returns the provided fallback when the
// stored value is missing or invalid.
  function readJsonSessionStorage(key, fallback) {
    try {
      const raw = sessionStorage.getItem(key);
      return raw ? JSON.parse(raw) : fallback;
    } catch {
      return fallback;
    }
  }

// Write JSON data to sessionStorage. Used for short-lived scanned table state.
  function writeJsonSessionStorage(key, value) {
    sessionStorage.setItem(key, JSON.stringify(value));
  }

// Normalize modifier arrays into a stable string key. This lets cart lines with
// the same item and same modifiers merge correctly.
  function normalizeModifiersKey(modifiers) {
    const list = Array.isArray(modifiers) ? [...modifiers] : [];
    list.sort();
    return JSON.stringify(list);
  }

// Normalize quantity values so cart and order quantities always stay at or
// above one even when input values are malformed.
  function normalizeQty(value) {
    return Math.max(1, Number(value || 1));
  }

// Load frontend runtime config once and cache it in memory. Falls back to an
// empty object if the backend config endpoint is unavailable.
  async function loadConfig() {
    if (configCache) {
      return configCache;
    }

    try {
      const response = await fetch("/api/config");

      if (!response.ok) {
        throw new Error(translateErrorMessage("config not ok", "errors.configLoadFailed"));
      }

      configCache = await response.json();
    } catch {
      configCache = {};
    }

    return configCache;
  }

// Load active menu data from the backend and keep both list and id lookup cache
// in sync for fast frontend access.
  async function loadMenu() {
    const response = await fetch("/api/menu");
    const data = await response.json();

    menuCache = Array.isArray(data.items) ? data.items : [];
    menuByIdCache = new Map(menuCache.map((item) => [item.id, item]));

    return menuCache;
  }

  const api = {
    // Return cached runtime config, loading it once from the backend when needed.
    async getConfig() {
      return await loadConfig();
    },

// Load and return the current customer menu from the backend.
    async loadMenu() {
      return await loadMenu();
    },

// Capture a scanned table QR session from the current page URL when present.
// The session is scoped to the current browser tab via sessionStorage.
    syncTableSessionFromUrl() {
      const params = new URLSearchParams(window.location.search);
      const tableLabel = String(params.get("table") || "").replace(/[^A-Za-z0-9 \-]/g, "").trim().slice(0, 10);
      const tableToken = String(params.get("table_token") || "").trim();

      if (!tableLabel || !tableToken) {
        return api.getTableSession();
      }

      const session = {
        table_label: tableLabel,
        table_token: tableToken
      };

      writeJsonSessionStorage(TABLE_SESSION_KEY, session);
      return session;
    },

// Read the current scanned table QR session from the browser tab.
    getTableSession() {
      const session = readJsonSessionStorage(TABLE_SESSION_KEY, null);

      if (!session?.table_label || !session?.table_token) {
        return null;
      }

      return session;
    },

// Clear the current scanned table QR session from the browser tab.
    clearTableSession() {
      sessionStorage.removeItem(TABLE_SESSION_KEY);
    },

// Read the persisted customer dark mode preference from local storage.
    getCustomerDarkMode() {
      return localStorage.getItem(CUSTOMER_DARK_MODE_KEY) === "1";
    },

// Persist the customer dark mode preference into local storage.
    setCustomerDarkMode(enabled) {
      localStorage.setItem(CUSTOMER_DARK_MODE_KEY, enabled ? "1" : "0");
    },

// Apply the current customer dark mode preference to the active page body.
    applyCustomerDarkMode() {
      document.body.classList.toggle("dark", api.getCustomerDarkMode());
    },

// Expose the in-memory menu cache as a read-only style property for pages that
// already loaded menu data.
    get menu() {
      return menuCache || [];
    },

// Expose the in-memory menu lookup map keyed by menu item id.
    get menuById() {
      return menuByIdCache;
    },

// Read the persisted cart from browser storage. Invalid or missing values fall
// back to an empty cart.
    getCart() {
      return readJsonStorage(CART_KEY, []);
    },

// Persist the entire cart into browser storage.
    setCart(cart) {
      writeJsonStorage(CART_KEY, cart);
    },

// Clear the current cart from browser storage.
    clearCart() {
      localStorage.removeItem(CART_KEY);
    },

// Add a line to the cart. Matching item-plus-modifier combinations merge into
// a single cart line with accumulated quantity.
    cartAdd(line) {
      const cart = api.getCart();

      const incomingKey = `${line.menu_item_id}:${normalizeModifiersKey(line.chosen_modifiers)}`;

      const existingIndex = cart.findIndex((item) => {
        const existingKey = `${item.menu_item_id}:${normalizeModifiersKey(item.chosen_modifiers)}`;
        return existingKey === incomingKey;
      });

      if (existingIndex >= 0) {
        cart[existingIndex].qty =
          normalizeQty(cart[existingIndex].qty) + normalizeQty(line.qty);
      } else {
        cart.push({
          ...line,
          qty: normalizeQty(line.qty),
        });
      }

      api.setCart(cart);
    },

// Update a single cart line quantity while enforcing a minimum quantity of one.
    cartUpdateQty(index, qty) {
      const cart = api.getCart();

      if (!cart[index]) {
        return;
      }

      cart[index].qty = normalizeQty(qty);
      api.setCart(cart);
    },

// Remove a cart line by index.
    cartRemove(index) {
      const cart = api.getCart();
      cart.splice(index, 1);
      api.setCart(cart);
    },

// Calculate cart item count and total price in cents from persisted cart data.
    cartTotals() {
      const cart = api.getCart();

      const count = cart.reduce((sum, item) => {
        return sum + normalizeQty(item.qty);
      }, 0);

      const totalCents = cart.reduce((sum, item) => {
        return sum + Number(item.price_cents || 0) * normalizeQty(item.qty);
      }, 0);

      return { count, totalCents };
    },

// Refresh cart summary UI elements when they exist on the current page.
    updateCartBar() {
      const { count, totalCents } = api.cartTotals();
      const cartCountElement = document.getElementById("cartCount");
      const cartTotalElement = document.getElementById("cartTotal");

      if (cartCountElement) {
        cartCountElement.textContent = String(count);
      }

      if (cartTotalElement) {
        cartTotalElement.textContent = (totalCents / 100).toFixed(2);
      }
    },

// Create a new order from the current cart and persist its id into browser
// storage for customer follow-up pages.
    async placeOrder({
      fulfillment_type = "counter_pickup",
      customer_label = "",
      table_label = "",
      table_token = "",
      note = "",
    } = {}) {
      const cart = api.getCart();

      if (cart.length === 0) {
        throw new Error(translateErrorMessage("Cart empty", "errors.cartEmpty"));
      }

      const items = cart.map((item) => ({
        menu_item_id: item.menu_item_id,
        qty: item.qty,
        chosen_modifiers: item.chosen_modifiers || [],
      }));

      const response = await fetch("/api/orders", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          fulfillment_type,
          customer_label,
          table_label,
          table_token,
          note,
          items,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(translateErrorMessage(data?.error || "Order failed", "errors.orderFailed"));
      }

      localStorage.setItem(LAST_ORDER_KEY, String(data.order.id));
      api.addMyOrder(data.order);
      api.clearCart();

      return data.order;
    },

// Return the last placed order id from browser storage.
    getLastOrderId() {
      const raw = localStorage.getItem(LAST_ORDER_KEY);
      return raw ? Number(raw) : null;
    },

// Fetch a single order by id from the backend.
    async fetchOrder(id) {
      const response = await fetch(`/api/orders/${id}`);
      const data = await response.json();

      if (!response.ok) {
        throw new Error(translateErrorMessage(data?.error || "Not found", "errors.notFound"));
      }

      return data.order;
    },

// Read the user's recent order list from browser storage.
    getMyOrders() {
      return readJsonStorage(MY_ORDERS_KEY, []);
    },

// Add an order to the user's recent order list while avoiding duplicates and
// keeping only the latest 20 entries.
    addMyOrder(order) {
      const currentOrders = api.getMyOrders();

      const entry = {
        id: order.id,
        order_number: order.order_number,
        created_at: order.created_at || null,
      };

      const exists = currentOrders.some((item) => item.id === entry.id);
      const nextOrders = exists ? currentOrders : [entry, ...currentOrders];

      writeJsonStorage(MY_ORDERS_KEY, nextOrders.slice(0, 20));
    },

// Clear the user's recent order list from browser storage.
    clearMyOrders() {
      localStorage.removeItem(MY_ORDERS_KEY);
    },

// Open a realtime websocket connection and pass parsed messages to the caller.
// Malformed message payloads are ignored.
    wsConnect(onMsg) {
      const protocol = location.protocol === "https:" ? "wss" : "ws";
      const ws = new WebSocket(`${protocol}://${location.host}`);

      ws.onmessage = (event) => {
        try {
          onMsg(JSON.parse(event.data));
        } catch {}
      };

      return ws;
    },
  };

  return api;
})();
