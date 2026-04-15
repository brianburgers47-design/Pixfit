const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const dataFile = path.resolve(
  process.cwd(),
  process.env.DATA_FILE || './data/pixfit-store.json',
);

function createEmptyStore() {
  return {
    users: {},
    processedEvents: {},
    fulfilledSessions: {},
  };
}

function ensureDataFile() {
  fs.mkdirSync(path.dirname(dataFile), { recursive: true });

  if (!fs.existsSync(dataFile)) {
    fs.writeFileSync(dataFile, JSON.stringify(createEmptyStore(), null, 2));
  }
}

function readStore() {
  ensureDataFile();
  const raw = fs.readFileSync(dataFile, 'utf8');
  return raw.trim() ? JSON.parse(raw) : createEmptyStore();
}

function writeStore(store) {
  ensureDataFile();
  const tempFile = `${dataFile}.tmp`;
  fs.writeFileSync(tempFile, JSON.stringify(store, null, 2));
  fs.renameSync(tempFile, dataFile);
}

function now() {
  return new Date().toISOString();
}

function normalizeAnonymousUserId(value) {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();

  if (!trimmed || trimmed.length > 120) {
    return null;
  }

  // Keep IDs boring: enough for UUIDs and browser-generated anonymous IDs.
  if (!/^[a-zA-Z0-9_-]+$/.test(trimmed)) {
    return null;
  }

  return trimmed;
}

function createAnonymousUserId() {
  return `anon_${crypto.randomUUID().replaceAll('-', '')}`;
}

function defaultFreeCredits() {
  const parsed = Number.parseInt(process.env.FREE_CREDITS_DEFAULT || '2', 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : 2;
}

function ensureUser(anonymousUserId) {
  const store = readStore();
  const safeId =
    normalizeAnonymousUserId(anonymousUserId) || createAnonymousUserId();

  if (!store.users[safeId]) {
    store.users[safeId] = {
      anonymousUserId: safeId,
      credits: defaultFreeCredits(),
      isPro: false,
      hasStarter: false,
      plan: 'free',
      stripeCustomerId: null,
      stripeSubscriptionId: null,
      subscriptionStatus: null,
      createdAt: now(),
      updatedAt: now(),
    };
    writeStore(store);
  }

  return store.users[safeId];
}

function getUser(anonymousUserId) {
  const safeId = normalizeAnonymousUserId(anonymousUserId);

  if (!safeId) {
    return null;
  }

  const store = readStore();
  return store.users[safeId] || null;
}

function updateUser(anonymousUserId, updater) {
  const safeId = normalizeAnonymousUserId(anonymousUserId);

  if (!safeId) {
    throw new Error('Invalid anonymousUserId');
  }

  const store = readStore();
  const user = store.users[safeId];

  if (!user) {
    throw new Error('Unknown anonymousUserId');
  }

  const nextUser = {
    ...user,
    ...updater(user),
    updatedAt: now(),
  };

  store.users[safeId] = nextUser;
  writeStore(store);
  return nextUser;
}

function addCredits(anonymousUserId, creditsToAdd) {
  return updateUser(anonymousUserId, (user) => ({
    credits: Math.max(0, Number(user.credits || 0) + creditsToAdd),
    hasStarter: true,
    plan: user.isPro ? 'pro' : 'starter',
  }));
}

function setProStatus({
  anonymousUserId,
  isPro,
  stripeCustomerId,
  stripeSubscriptionId,
  subscriptionStatus,
}) {
  return updateUser(anonymousUserId, (user) => ({
    isPro,
    plan: isPro ? 'pro' : user.hasStarter ? 'starter' : 'free',
    stripeCustomerId: stripeCustomerId || null,
    stripeSubscriptionId: stripeSubscriptionId || null,
    subscriptionStatus: subscriptionStatus || null,
  }));
}

function findUserByStripeSubscriptionId(stripeSubscriptionId) {
  if (!stripeSubscriptionId) {
    return null;
  }

  const store = readStore();
  return (
    Object.values(store.users).find(
      (user) => user.stripeSubscriptionId === stripeSubscriptionId,
    ) || null
  );
}

function consumeExport(anonymousUserId) {
  const safeId = normalizeAnonymousUserId(anonymousUserId);

  if (!safeId) {
    throw new Error('Invalid anonymousUserId');
  }

  const store = readStore();
  const user = store.users[safeId];

  if (!user) {
    throw new Error('Unknown anonymousUserId');
  }

  if (user.isPro) {
    return {
      allowed: true,
      reason: 'pro',
      user,
    };
  }

  const credits = Number(user.credits || 0);

  if (credits <= 0) {
    return {
      allowed: false,
      reason: 'no_credits',
      user,
    };
  }

  const nextUser = {
    ...user,
    credits: credits - 1,
    updatedAt: now(),
  };

  store.users[safeId] = nextUser;
  writeStore(store);

  return {
    allowed: true,
    reason: 'credit_used',
    user: nextUser,
  };
}

function hasProcessedEvent(eventId) {
  const store = readStore();
  return Boolean(store.processedEvents[eventId]);
}

function markProcessedEvent(eventId, type) {
  const store = readStore();
  store.processedEvents[eventId] = {
    type,
    processedAt: now(),
  };
  writeStore(store);
}

function hasFulfilledSession(sessionId) {
  const store = readStore();
  return Boolean(store.fulfilledSessions[sessionId]);
}

function markFulfilledSession(sessionId, payload) {
  const store = readStore();
  store.fulfilledSessions[sessionId] = {
    ...payload,
    fulfilledAt: now(),
  };
  writeStore(store);
}

module.exports = {
  addCredits,
  consumeExport,
  ensureUser,
  findUserByStripeSubscriptionId,
  getUser,
  hasFulfilledSession,
  hasProcessedEvent,
  markFulfilledSession,
  markProcessedEvent,
  normalizeAnonymousUserId,
  setProStatus,
};
