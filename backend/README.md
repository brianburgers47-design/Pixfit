# Pixfit Stripe backend

Minimal Express backend for Pixfit Checkout payments.

## What it handles

- Anonymous users without login.
- Starter one-time payment: adds 20 credits after Stripe webhook confirmation.
- Pro monthly subscription: sets `isPro = true` when the subscription is active/trialing.
- Idempotent webhooks using processed Stripe event IDs and fulfilled Checkout Session IDs.
- JSON file storage for MVP simplicity.

## Setup

```bash
cd backend
cp .env.example .env
npm install
npm run dev
```

Set these values in `.env`:

```bash
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_STARTER_LOOKUP_KEY=starter_20_credits
STRIPE_PRO_LOOKUP_KEY=pro_monthly
FRONTEND_ORIGIN=http://localhost:7357
SUCCESS_URL=http://localhost:7357/#/payment-success
CANCEL_URL=http://localhost:7357/#/paywall
```

You can use `STRIPE_STARTER_PRICE_ID` and `STRIPE_PRO_PRICE_ID` instead of lookup keys if you prefer fixed price IDs.

## Stripe CLI test webhook

```bash
stripe listen --forward-to localhost:8787/api/stripe/webhook
```

Copy the `whsec_...` secret into `.env`.

## API

### POST `/api/users/bootstrap`

Request:

```json
{
  "anonymousUserId": "anon_existing_id_optional"
}
```

Response:

```json
{
  "anonymousUserId": "anon_...",
  "credits": 2,
  "isPro": false,
  "subscriptionStatus": null
}
```

### GET `/api/me?anonymousUserId=anon_...`

Returns current credits and Pro status.

### POST `/api/checkout/session`

Request:

```json
{
  "anonymousUserId": "anon_...",
  "plan": "starter"
}
```

`plan` can be `starter` or `pro`.

Response:

```json
{
  "checkoutUrl": "https://checkout.stripe.com/..."
}
```

### POST `/api/stripe/webhook`

Stripe calls this endpoint. Do not call it from Flutter.

## Production notes

- Keep `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` on the server only.
- Do not trust success URLs for credits; the webhook is the source of truth.
- JSON storage is fine for local MVP testing. Move to SQLite/Postgres before production traffic.
- Without login, users can lose access if they clear browser storage. A later login system can migrate anonymous credits into an account.
