require('dotenv').config();

const cors = require('cors');
const express = require('express');
const path = require('path');
const Stripe = require('stripe');
const {
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
} = require('./store');

const app = express();
const port = Number.parseInt(process.env.PORT || '8787', 10);
const host = '0.0.0.0';
const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
const stripe = stripeSecretKey ? new Stripe(stripeSecretKey) : null;
const flutterBuildPath = path.resolve(__dirname, '..', '..', 'build', 'web');

const allowedOrigins = (process.env.FRONTEND_ORIGIN || 'http://localhost:7357')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

function isAllowedOrigin(origin) {
  if (!origin) {
    return true;
  }

  if (allowedOrigins.includes(origin)) {
    return true;
  }

  try {
    const { hostname, protocol } = new URL(origin);
    const isLocalhost =
      hostname === 'localhost' ||
      hostname === '127.0.0.1' ||
      hostname === '0.0.0.0';
    const isNgrok = protocol === 'https:' && hostname.endsWith('.ngrok-free.dev');

    return isLocalhost || isNgrok;
  } catch {
    return false;
  }
}

function requireStripe() {
  if (!stripe) {
    const error = new Error('Missing STRIPE_SECRET_KEY');
    error.code = 'missing_stripe_secret_key';
    throw error;
  }

  return stripe;
}

function logEvent(name, data = {}) {
  console.log('[event]', name, JSON.stringify(data));
}

function jsonUser(user) {
  return {
    anonymousUserId: user.anonymousUserId,
    credits: Number(user.credits || 0),
    isPro: Boolean(user.isPro),
    plan: user.plan || (user.isPro ? 'pro' : 'free'),
    subscriptionStatus: user.subscriptionStatus || null,
  };
}

function configStatus() {
  return {
    hasStripeSecretKey: Boolean(stripeSecretKey),
    hasWebhookSecret: Boolean(webhookSecret),
    hasStarterPrice:
      Boolean(process.env.STRIPE_STARTER_PRICE_ID) ||
      Boolean(process.env.STRIPE_STARTER_LOOKUP_KEY || 'starter_20_credits'),
    hasProPrice:
      Boolean(process.env.STRIPE_PRO_PRICE_ID) ||
      Boolean(process.env.STRIPE_PRO_LOOKUP_KEY || 'pro_monthly'),
  };
}

function logConfigStatus() {
  const status = configStatus();
  console.log('[config] FRONTEND_ORIGIN:', allowedOrigins.join(', '));
  console.log('[config] SUCCESS_URL:', successUrl());
  console.log('[config] CANCEL_URL:', cancelUrl());
  console.log('[config] Flutter web build:', flutterBuildPath);

  if (!status.hasStripeSecretKey) {
    console.warn('[config] Missing STRIPE_SECRET_KEY. Checkout is disabled.');
  }

  if (!status.hasWebhookSecret) {
    console.warn('[config] Missing STRIPE_WEBHOOK_SECRET. Webhook verification is disabled.');
  }

  if (!status.hasStarterPrice) {
    console.warn('[config] Missing Starter price ID or lookup key.');
  }

  if (!status.hasProPrice) {
    console.warn('[config] Missing Pro price ID or lookup key.');
  }
}

function appUrl() {
  return process.env.APP_URL || process.env.PUBLIC_URL || 'http://localhost:8787';
}

function successUrl() {
  return process.env.SUCCESS_URL || `${appUrl()}/#/payment-success`;
}

function cancelUrl() {
  return process.env.CANCEL_URL || `${appUrl()}/#/paywall`;
}

function isActiveSubscriptionStatus(status) {
  return status === 'active' || status === 'trialing';
}

async function resolvePriceId(plan) {
  const stripeClient = requireStripe();

  if (plan === 'starter' && process.env.STRIPE_STARTER_PRICE_ID) {
    return process.env.STRIPE_STARTER_PRICE_ID;
  }

  if (plan === 'pro' && process.env.STRIPE_PRO_PRICE_ID) {
    return process.env.STRIPE_PRO_PRICE_ID;
  }

  const lookupKey = plan === 'starter'
    ? process.env.STRIPE_STARTER_LOOKUP_KEY || 'starter_20_credits'
    : process.env.STRIPE_PRO_LOOKUP_KEY || 'pro_monthly';

  const prices = await stripeClient.prices.list({
    active: true,
    lookup_keys: [lookupKey],
    limit: 1,
  });

  const price = prices.data[0];

  if (!price) {
    const error = new Error(
      `No active Stripe price found for lookup key: ${lookupKey}`,
    );
    error.code = 'stripe_price_lookup_not_found';
    error.lookupKey = lookupKey;
    error.plan = plan;
    throw error;
  }

  return price.id;
}

app.use(
  cors({
    credentials: true,
    origin(origin, callback) {
      if (isAllowedOrigin(origin)) {
        callback(null, true);
        return;
      }

      callback(new Error(`Origin not allowed: ${origin}`));
    },
  }),
);

app.use((request, _response, next) => {
  console.log(`[request] ${request.method} ${request.originalUrl}`);
  next();
});

// Stripe requires the raw request body for signature verification.
app.post('/api/stripe/webhook', express.raw({ type: 'application/json' }), async (request, response) => {
  if (!webhookSecret) {
    response.status(500).send('Missing STRIPE_WEBHOOK_SECRET');
    return;
  }

  const stripeClient = requireStripe();
  const signature = request.headers['stripe-signature'];
  let event;

  try {
    event = stripeClient.webhooks.constructEvent(request.body, signature, webhookSecret);
  } catch (error) {
    console.error('Webhook signature verification failed:', error.message);
    response.status(400).send(`Webhook Error: ${error.message}`);
    return;
  }

  try {
    if (hasProcessedEvent(event.id)) {
      response.json({ received: true, duplicate: true });
      return;
    }

    if (event.type === 'checkout.session.completed') {
      await handleCheckoutCompleted(event.data.object);
    }

    if (event.type === 'customer.subscription.updated' || event.type === 'customer.subscription.deleted') {
      handleSubscriptionChange(event.data.object);
    }

    markProcessedEvent(event.id, event.type);
    response.json({ received: true });
  } catch (error) {
    console.error('Webhook handling failed:', error);
    response.status(500).send('Webhook handling failed');
  }
});

app.use(express.json({ limit: '32kb' }));

app.get('/api/health', (_request, response) => {
  response.json({ ok: true, config: configStatus() });
});

app.post('/api/users/bootstrap', (request, response) => {
  const user = ensureUser(request.body?.anonymousUserId);
  logEvent('user_bootstrap', { anonymousUserId: user.anonymousUserId });
  response.json(jsonUser(user));
});

app.get('/api/me', (request, response) => {
  const anonymousUserId = normalizeAnonymousUserId(request.query.anonymousUserId);

  if (!anonymousUserId) {
    response.status(400).json({ error: 'Missing or invalid anonymousUserId' });
    return;
  }

  const user = getUser(anonymousUserId);

  if (!user) {
    response.status(404).json({ error: 'Unknown anonymousUserId' });
    return;
  }

  response.json(jsonUser(user));
});

app.post('/api/exports/consume', (request, response) => {
  try {
    const anonymousUserId = normalizeAnonymousUserId(request.body?.anonymousUserId);

    if (!anonymousUserId) {
      response.status(400).json({
        allowed: false,
        credits: 0,
        isPro: false,
        plan: 'free',
        subscriptionStatus: null,
        reason: 'missing_or_invalid_anonymous_user_id',
      });
      return;
    }

    const user = getUser(anonymousUserId);

    if (!user) {
      response.status(404).json({
        allowed: false,
        credits: 0,
        isPro: false,
        plan: 'free',
        subscriptionStatus: null,
        reason: 'unknown_user',
      });
      return;
    }

    logEvent('export_attempt', { anonymousUserId });

    const result = consumeExport(anonymousUserId);
    const updatedUser = result.user;

    logEvent('export_result', {
      anonymousUserId,
      allowed: result.allowed,
      credits: updatedUser.credits,
      isPro: updatedUser.isPro,
    });

    response.status(result.allowed ? 200 : 402).json({
      allowed: result.allowed,
      credits: Number(updatedUser.credits || 0),
      isPro: Boolean(updatedUser.isPro),
      plan: updatedUser.plan || (updatedUser.isPro ? 'pro' : 'free'),
      subscriptionStatus: updatedUser.subscriptionStatus || null,
      reason: result.reason,
    });
  } catch (error) {
    console.error('Consume export failed:', error);
    response.status(500).json({
      allowed: false,
      credits: 0,
      isPro: false,
      plan: 'free',
      subscriptionStatus: null,
      reason: 'consume_export_failed',
    });
  }
});

app.post('/api/checkout/session', async (request, response) => {
  try {
    console.log('[checkout] route hit');
    console.log('[checkout] body:', request.body);

    const plan = request.body?.plan;
    const anonymousUserId = normalizeAnonymousUserId(request.body?.anonymousUserId);

    console.log('[checkout] anonymousUserId:', anonymousUserId);
    console.log('[checkout] plan:', plan);

    if (!anonymousUserId) {
      response.status(400).json({ error: 'Missing or invalid anonymousUserId' });
      return;
    }

    if (plan !== 'starter' && plan !== 'pro') {
      response.status(400).json({ error: 'Plan must be starter or pro' });
      return;
    }

    ensureUser(anonymousUserId);

    logEvent('checkout_started', { anonymousUserId, plan });

    console.log('[checkout] resolving price for plan:', plan);
    const priceId = await resolvePriceId(plan);
    console.log('[checkout] resolved priceId:', priceId);

    const mode = plan === 'starter' ? 'payment' : 'subscription';
    const metadata = {
      anonymousUserId,
      plan,
      credits: plan === 'starter' ? '20' : '0',
    };

    console.log('[checkout] creating Stripe Checkout Session');
    const session = await requireStripe().checkout.sessions.create({
      mode,
      line_items: [{ price: priceId, quantity: 1 }],
      client_reference_id: anonymousUserId,
      metadata,
      success_url: `${successUrl()}?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: cancelUrl(),
      ...(plan === 'pro'
        ? {
            subscription_data: {
              metadata,
            },
          }
        : {}),
    });

    console.log('[checkout] session created:', {
      id: session.id,
      url: session.url,
    });

    response.json({ checkoutUrl: session.url });
  } catch (err) {
    console.error('[checkout] failed:', {
      message: err.message,
      code: err.code,
      type: err.type,
      raw: err.raw,
    });

    response.status(500).json({
      error: 'Checkout failed',
    });
  }
});

async function handleCheckoutCompleted(session) {
  const anonymousUserId = normalizeAnonymousUserId(
    session.metadata?.anonymousUserId || session.client_reference_id,
  );
  const plan = session.metadata?.plan;

  if (!anonymousUserId) {
    throw new Error(`Checkout Session ${session.id} is missing anonymousUserId`);
  }

  if (hasFulfilledSession(session.id)) {
    return;
  }

  ensureUser(anonymousUserId);

  logEvent('checkout_completed', {
    anonymousUserId,
    plan,
  });

  if (plan === 'starter') {
    if (session.payment_status !== 'paid') {
      throw new Error(`Starter Checkout Session ${session.id} is not paid`);
    }

    addCredits(anonymousUserId, 20);
    markFulfilledSession(session.id, {
      anonymousUserId,
      plan,
      creditsAdded: 20,
    });
    return;
  }

  if (plan === 'pro') {
    const subscriptionId = typeof session.subscription === 'string'
      ? session.subscription
      : session.subscription?.id;

    let subscriptionStatus = 'active';

    if (subscriptionId) {
      const subscription = await requireStripe().subscriptions.retrieve(subscriptionId);
      subscriptionStatus = subscription.status;
    }

    setProStatus({
      anonymousUserId,
      isPro: isActiveSubscriptionStatus(subscriptionStatus),
      stripeCustomerId: typeof session.customer === 'string' ? session.customer : session.customer?.id,
      stripeSubscriptionId: subscriptionId,
      subscriptionStatus,
    });

    markFulfilledSession(session.id, {
      anonymousUserId,
      plan,
      subscriptionId,
      subscriptionStatus,
    });
  }
}

function handleSubscriptionChange(subscription) {
  const userFromSubscription = findUserByStripeSubscriptionId(subscription.id);
  const anonymousUserId = normalizeAnonymousUserId(
    subscription.metadata?.anonymousUserId || userFromSubscription?.anonymousUserId,
  );

  if (!anonymousUserId) {
    console.warn(
      `Subscription ${subscription.id} has no anonymousUserId metadata and no local user mapping.`,
    );
    return;
  }

  setProStatus({
    anonymousUserId,
    isPro: isActiveSubscriptionStatus(subscription.status),
    stripeCustomerId: typeof subscription.customer === 'string'
      ? subscription.customer
      : subscription.customer?.id,
    stripeSubscriptionId: subscription.id,
    subscriptionStatus: subscription.status,
  });
}

app.use(express.static(flutterBuildPath));

app.get(/^\/(?!api(?:\/|$)).*/, (_request, response) => {
  response.sendFile(path.join(flutterBuildPath, 'index.html'));
});

app.listen(port, host, () => {
  console.log(`Pixfit Stripe backend running on http://${host}:${port}`);
  logConfigStatus();
});
