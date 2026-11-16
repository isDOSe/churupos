/* Churupos web · conversor limitado dentro de la landing.
   Sin USDT, historial ni modo offline: eso vive en la app. */

(() => {
  "use strict";

  const API = "https://ve.dolarapi.com/v1/cotizaciones";

  const CURRENCIES = {
    ves: { code: "VES", label: "Bolívar", source: "Base", base: true },
    usd: { code: "USD", label: "Dólar BCV", source: "BCV" },
    eur: { code: "EUR", label: "Euro BCV", source: "BCV" },
  };

  const ORDER = ["usd", "eur", "ves"];
  const KEYS = {
    pair: "churupos.webapp.pair.v1",
    rates: "churupos.webapp.rates.v1",
  };
  const REFRESH_EVERY = 5 * 60 * 1000;
  const MANUAL_COOLDOWN = 5 * 1000;

  const money = new Intl.NumberFormat("es-VE", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  const money4 = new Intl.NumberFormat("es-VE", {
    minimumFractionDigits: 4,
    maximumFractionDigits: 4,
  });

  const $ = (id) => document.getElementById(id);

  const el = {
    modal: $("waModal"),
    sheet: $("waSheet"),
    sheetList: $("waSheetList"),
    sheetTitle: $("waSheetTitle"),
    from: $("waFrom"),
    to: $("waTo"),
    fromCode: $("waFromCode"),
    fromLabel: $("waFromLabel"),
    toCode: $("waToCode"),
    toLabel: $("waToLabel"),
    swap: $("waSwap"),
    amount: $("waAmount"),
    amountCode: $("waAmountCode"),
    amountRule: $("waAmountRule"),
    result: $("waResult"),
    resultCurrency: $("waResultCurrency"),
    dot: $("waDot"),
    rate: $("waRate"),
    time: $("waTime"),
    offline: $("waOffline"),
    error: $("waError"),
    retry: $("waRetry"),
    reset: $("waReset"),
    refresh: $("waRefresh"),
    progress: $("waProgress"),
    close: document.querySelector("[data-wa-close]"),
    sheetClose: document.querySelector("[data-wa-sheet-close]"),
    triggers: document.querySelectorAll("[data-open-webapp]"),
    download: document.querySelector("[data-wa-download]"),
    sources: document.querySelector("[data-wa-sources]"),
  };

  const state = {
    pair: { from: "usd", to: "ves", amount: "1" },
    rates: {},
    fetchedAt: null,
    errors: {},
    offline: false,
    refreshing: false,
    lastAttempt: 0,
    open: false,
  };

  let lastFocused = null;
  let sheetRole = null;
  let sheetTrigger = null;
  let timer = null;

  /* ---------- almacenamiento ---------- */

  function storageGet(key) {
    try {
      return localStorage.getItem(key);
    } catch {
      return null;
    }
  }

  function storageSet(key, value) {
    try {
      localStorage.setItem(key, value);
    } catch {
      /* modo privado o cuota llena */
    }
  }

  function loadPair() {
    const raw = storageGet(KEYS.pair);
    if (!raw) return;
    try {
      const data = JSON.parse(raw);
      const from = CURRENCIES[data?.from] ? data.from : null;
      const to = CURRENCIES[data?.to] ? data.to : null;
      if (from && to && from !== to) {
        state.pair = {
          from,
          to,
          amount: typeof data.amount === "string" ? data.amount : "1",
        };
      }
    } catch {
      /* configuración corrupta */
    }
  }

  function persistPair() {
    storageSet(KEYS.pair, JSON.stringify(state.pair));
  }

  function loadRates() {
    const raw = storageGet(KEYS.rates);
    if (!raw) return;
    try {
      const data = JSON.parse(raw);
      for (const key of ["usd", "eur"]) {
        const quote = data?.rates?.[key];
        if (quote && Number(quote.ves) > 0) {
          state.rates[key] = {
            ves: Number(quote.ves),
            updatedAt: quote.updatedAt ? new Date(quote.updatedAt) : null,
            stale: false,
          };
        }
      }
      state.fetchedAt = data?.fetchedAt ? new Date(data.fetchedAt) : null;
    } catch {
      /* caché corrupta */
    }
  }

  function persistRates() {
    storageSet(
      KEYS.rates,
      JSON.stringify({
        fetchedAt: state.fetchedAt,
        rates: state.rates,
      }),
    );
  }

  /* ---------- formato ---------- */

  function parseAmount(raw) {
    const text = String(raw ?? "").trim();
    if (!text) return 0;
    const normalized = text.includes(",")
      ? text.replace(/\./g, "").replace(",", ".")
      : text;
    const value = Number(normalized);
    return Number.isFinite(value) ? value : 0;
  }

  function sanitizeAmount(raw) {
    let out = "";
    let separator = false;
    for (const char of String(raw ?? "")) {
      if (char >= "0" && char <= "9") {
        out += char;
      } else if ((char === "," || char === ".") && !separator) {
        out += char;
        separator = true;
      }
      if (out.length >= 18) break;
    }
    return out;
  }

  function moneyText(value) {
    return money.format(Math.abs(value) < 5e-10 ? 0 : value);
  }

  function symbolMoney(currency, number) {
    switch (currency) {
      case "usd":
        return `$ ${number}`;
      case "eur":
        return `€ ${number}`;
      default:
        return `Bs. ${number}`;
    }
  }

  function formatMoney(currency, value) {
    return symbolMoney(currency, moneyText(value));
  }

  function formatRate(currency, value) {
    const clean = Math.abs(value) < 5e-10 ? 0 : value;
    const number = Math.abs(clean) < 1 ? money4.format(clean) : money.format(clean);
    return symbolMoney(currency, number);
  }

  function clockTime(input) {
    if (!input) return "";
    const when = input instanceof Date ? input : new Date(input);
    if (Number.isNaN(when.getTime())) return "";
    const now = new Date();
    const hour = when.getHours() % 12 === 0 ? 12 : when.getHours() % 12;
    const minutes = String(when.getMinutes()).padStart(2, "0");
    const suffix = when.getHours() >= 12 ? "p. m." : "a. m.";
    const time = `${hour}:${minutes} ${suffix}`;

    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const day = new Date(when.getFullYear(), when.getMonth(), when.getDate());
    const diff = Math.round((today - day) / 86400000);
    if (diff === 0) return time;
    if (diff === 1) return `ayer ${time}`;
    return `${String(when.getDate()).padStart(2, "0")}/${String(
      when.getMonth() + 1,
    ).padStart(2, "0")} ${time}`;
  }

  /* ---------- conversión ---------- */

  function quoteFor(currency) {
    if (CURRENCIES[currency].base) {
      return { ves: 1, updatedAt: state.fetchedAt, stale: false };
    }
    return state.rates[currency] ?? null;
  }

  function currentView() {
    const from = state.pair.from;
    const to = state.pair.to;
    const amount = parseAmount(state.pair.amount);
    const fromQuote = quoteFor(from);
    const toQuote = quoteFor(to);
    const available = Boolean(fromQuote && toQuote);

    let result = null;
    let unitRate = null;
    let effectiveAt = null;
    let stale = false;

    if (available) {
      unitRate = fromQuote.ves / toQuote.ves;
      result = (amount * fromQuote.ves) / toQuote.ves;

      const age = state.fetchedAt
        ? Date.now() - new Date(state.fetchedAt).getTime()
        : Infinity;
      stale =
        state.offline ||
        fromQuote.stale ||
        toQuote.stale ||
        age > REFRESH_EVERY;

      effectiveAt = state.fetchedAt;
      if (!effectiveAt) {
        const times = [
          !CURRENCIES[from].base ? fromQuote.updatedAt : null,
          !CURRENCIES[to].base ? toQuote.updatedAt : null,
        ].filter(Boolean);
        effectiveAt = times.length
          ? new Date(Math.min(...times.map((time) => new Date(time).getTime())))
          : null;
      }
    }

    return {
      from,
      to,
      amount,
      available,
      result,
      unitRate,
      effectiveAt,
      stale,
      empty: !state.pair.amount || amount === 0,
    };
  }

  function render() {
    const from = CURRENCIES[state.pair.from];
    const to = CURRENCIES[state.pair.to];

    el.fromCode.textContent = from.code;
    el.fromLabel.textContent = from.label;
    el.toCode.textContent = to.code;
    el.toLabel.textContent = to.label;
    el.amountCode.textContent = from.code;
    el.resultCurrency.textContent = to.label;

    if (document.activeElement !== el.amount) {
      el.amount.value = state.pair.amount;
    }

    const view = currentView();
    el.result.textContent = view.available
      ? formatMoney(view.to, view.result)
      : "—";

    el.dot.className = "wa-dot";
    if (!view.available) {
      el.dot.classList.add("wa-dot--rose");
      el.rate.textContent = state.refreshing
        ? "Cargando tasas…"
        : "Sin tasa disponible";
      el.time.textContent = "";
    } else {
      el.dot.classList.add(view.stale ? "wa-dot--amber" : "wa-dot--mint");
      el.rate.textContent = `1 ${from.code} = ${formatRate(
        to.code.toLowerCase(),
        view.unitRate,
      )}`;
      el.time.textContent = clockTime(view.effectiveAt);
    }

    el.offline.hidden = !(state.offline && view.available);

    let error = "";
    if (!view.available && !state.refreshing && state.lastAttempt) {
      error = state.errors.dolar
        ? "No pudimos cargar la tasa del BCV. Revisa tu conexión e intenta de nuevo."
        : "No hay tasa disponible para este par.";
    }
    el.error.textContent = error;
    el.error.hidden = !error;
    el.retry.hidden = !error;

    el.refresh.disabled = state.refreshing;
    el.refresh.classList.toggle("is-busy", state.refreshing);
    el.progress.hidden = !state.refreshing;
  }

  /* ---------- red ---------- */

  async function fetchRates() {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);
    try {
      const response = await fetch(API, {
        cache: "no-store",
        signal: controller.signal,
      });
      if (!response.ok) throw new Error(`dolarapi ${response.status}`);
      const data = await response.json();
      if (!Array.isArray(data)) throw new Error("respuesta inesperada");

      const quotes = {};
      for (const item of data) {
        const key = String(item?.moneda ?? "").toUpperCase();
        if (key !== "USD" && key !== "EUR") continue;
        const price = Number(item?.promedio);
        if (!(price > 0) || !Number.isFinite(price)) continue;
        quotes[key.toLowerCase()] = {
          ves: price,
          updatedAt: item?.fechaActualizacion
            ? new Date(item.fechaActualizacion)
            : new Date(),
          stale: false,
        };
      }
      if (!Object.keys(quotes).length) throw new Error("sin cotizaciones");
      return quotes;
    } finally {
      clearTimeout(timeout);
    }
  }

  async function refresh({ manual = false } = {}) {
    if (state.refreshing) return;

    const now = Date.now();
    if (manual && now - state.lastAttempt < MANUAL_COOLDOWN) return;
    state.lastAttempt = now;
    state.refreshing = true;
    render();

    try {
      const quotes = await fetchRates();
      const next = { ...state.rates };
      for (const key of ["usd", "eur"]) {
        if (quotes[key]) {
          next[key] = quotes[key];
        } else if (next[key]) {
          next[key] = { ...next[key], stale: true };
        }
      }
      state.rates = next;
      state.errors = {};
      state.offline = false;
      state.fetchedAt = new Date();
      persistRates();
    } catch {
      state.errors = { dolar: true };
      state.offline = true;
      for (const key of ["usd", "eur"]) {
        if (state.rates[key]) {
          state.rates[key] = { ...state.rates[key], stale: true };
        }
      }
    } finally {
      state.refreshing = false;
      render();
    }
  }

  function refreshIfStale() {
    const last = state.fetchedAt ? new Date(state.fetchedAt).getTime() : 0;
    if (!last || Date.now() - last > REFRESH_EVERY) {
      refresh();
    }
  }

  /* ---------- modal ---------- */

  function setPageInert(inert) {
    document
      .querySelectorAll(".site-header, main, .site-footer")
      .forEach((node) => {
        node.toggleAttribute("inert", inert);
      });
  }

  function lockScroll() {
    const gap = window.innerWidth - document.documentElement.clientWidth;
    document.body.style.paddingRight = gap > 0 ? `${gap}px` : "";
    document.body.classList.add("wa-locked");
  }

  function unlockScroll() {
    document.body.classList.remove("wa-locked");
    document.body.style.paddingRight = "";
  }

  function openModal() {
    if (state.open) return;
    lastFocused = document.activeElement;
    state.open = true;

    el.modal.hidden = false;
    lockScroll();
    setPageInert(true);
    render();
    el.modal.focus();

    clearInterval(timer);
    timer = setInterval(() => {
      if (state.open && document.visibilityState === "visible") refresh();
    }, REFRESH_EVERY);

    refreshIfStale();
  }

  function closeModal({ restoreFocus = true } = {}) {
    if (!state.open) return;
    if (!el.sheet.hidden) closeSheet();
    state.open = false;
    el.modal.hidden = true;
    clearInterval(timer);
    timer = null;
    unlockScroll();
    setPageInert(false);
    if (restoreFocus) lastFocused?.focus?.();
  }

  /* ---------- hoja de monedas ---------- */

  function openSheet(role) {
    if (!state.open) return;
    sheetRole = role;
    sheetTrigger = document.activeElement;
    el.sheetTitle.textContent =
      role === "from" ? "Elegir origen" : "Elegir destino";
    el.sheetList.innerHTML = "";

    for (const key of ORDER) {
      const currency = CURRENCIES[key];
      const selected = state.pair[role] === key;
      const quote = quoteFor(key);
      const rate = quote
        ? key === "ves"
          ? "base"
          : formatRate("ves", quote.ves)
        : "sin datos";

      const option = document.createElement("button");
      option.type = "button";
      option.className = "wa-option";
      option.setAttribute("role", "option");
      option.setAttribute("aria-selected", String(selected));
      option.innerHTML = `
        <span class="wa-option__code">${currency.code}</span>
        <span class="wa-option__label">${currency.label} · ${currency.source}</span>
        <span class="wa-option__rate">${rate}<small>por 1 ${currency.code}</small></span>
      `;
      option.addEventListener("click", () => chooseCurrency(role, key));
      el.sheetList.appendChild(option);
    }

    el.sheet.hidden = false;
    el.modal.inert = true;
    sheetTrigger?.setAttribute("aria-expanded", "true");
    el.sheetList.querySelector(".wa-option")?.focus();
  }

  function closeSheet() {
    if (el.sheet.hidden) return;
    el.sheet.hidden = true;
    el.modal.inert = false;
    sheetTrigger?.setAttribute("aria-expanded", "false");
    sheetTrigger?.focus?.();
    sheetTrigger = null;
  }

  function chooseCurrency(role, key) {
    const pair = { ...state.pair };
    if (pair[role] === key) {
      closeSheet();
      return;
    }

    if (role === "from") {
      if (key === pair.to) {
        pair.from = pair.to;
        pair.to = state.pair.from;
      } else {
        pair.from = key;
      }
    } else if (key === pair.from) {
      pair.from = pair.to;
      pair.to = state.pair.from;
    } else {
      pair.to = key;
    }

    state.pair = pair;
    persistPair();
    render();
    closeSheet();
  }

  /* ---------- acciones ---------- */

  function swapPair() {
    state.pair = {
      from: state.pair.to,
      to: state.pair.from,
      amount: state.pair.amount,
    };
    persistPair();
    render();
    navigator.vibrate?.(8);
  }

  function resetPair() {
    state.pair = { from: "usd", to: "ves", amount: "1" };
    el.amount.value = "1";
    persistPair();
    render();
    el.amount.blur();
    navigator.vibrate?.(10);
  }

  /* ---------- eventos ---------- */

  el.triggers.forEach((trigger) => {
    trigger.addEventListener("click", (event) => {
      event.preventDefault();
      openModal();
    });
  });

  el.close?.addEventListener("click", closeModal);
  el.sheetClose?.addEventListener("click", closeSheet);
  el.from.addEventListener("click", () => openSheet("from"));
  el.to.addEventListener("click", () => openSheet("to"));
  el.swap.addEventListener("click", swapPair);
  el.reset.addEventListener("click", resetPair);
  el.refresh.addEventListener("click", () => refresh({ manual: true }));
  el.retry.addEventListener("click", () => refresh({ manual: true }));

  el.download?.addEventListener("click", () =>
    closeModal({ restoreFocus: false }),
  );
  el.sources?.addEventListener("click", () =>
    closeModal({ restoreFocus: false }),
  );

  el.amount.addEventListener("input", () => {
    const clean = sanitizeAmount(el.amount.value);
    if (clean !== el.amount.value) el.amount.value = clean;
    state.pair.amount = clean;
    persistPair();
    render();
  });

  el.amount.addEventListener("blur", () => {
    state.pair.amount = sanitizeAmount(el.amount.value);
    persistPair();
    render();
  });

  el.sheet.addEventListener("click", (event) => {
    if (event.target === el.sheet) closeSheet();
  });

  el.modal.addEventListener("click", (event) => {
    if (event.target === el.modal) closeModal();
  });

  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    if (!el.sheet.hidden) closeSheet();
    else if (state.open) closeModal();
  });

  document.addEventListener("visibilitychange", () => {
    if (state.open && document.visibilityState === "visible") {
      refreshIfStale();
    }
  });

  /* ---------- arranque ---------- */

  loadPair();
  loadRates();
  el.amount.value = state.pair.amount;
  render();
})();
