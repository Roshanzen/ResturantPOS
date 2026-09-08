# Restaurant POS — API Contract

## Base URL
`/api/v1`

## Authentication

### POST /auth/login
Request:
```json
{
  "username": "string",
  "password": "string"
}
```

Response 201:
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": 3600
}
```

### POST /auth/refresh
Request:
```json
{
  "refresh_token": "string"
}
```

Response 201:
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": 3600
}
```

### POST /auth/logout
Response 204

### GET /auth/me
Response 200:
```json
{
  "id": "string",
  "username": "string",
  "role": "string",
  "branch_id": "string",
  "terminal_id": "string"
}
```

## Menu

### GET /menu/items
Response 200:
```json
[
  {
    "id": "string",
    "name": "string",
    "sku": "string",
    "description": "string?",
    "category": "string",
    "price_minor": 15000,
    "currency": "NPR",
    "preparation_minutes": 5,
    "available": true,
    "version": 1,
    "updated_at": "2026-01-01T00:00:00Z"
  }
]
```

### POST /menu/items
Request:
```json
{
  "name": "string",
  "sku": "string",
  "description": "string?",
  "category": "string",
  "price_minor": 15000,
  "currency": "NPR",
  "preparation_minutes": 5,
  "available": true
}
```

Response 201: same as GET item

### PATCH /menu/items/{id}
Request (partial):
```json
{
  "name": "string?",
  "available": true?
}
```

Response 200: same as GET item

### DELETE /menu/items/{id}
Response 204

## Tables

### GET /tables
Response 200:
```json
[
  {
    "id": "string",
    "name": "string",
    "floor": "string",
    "capacity": 4,
    "status": "free",
    "active_order_id": "string?",
    "reservation_status": "string?",
    "version": 1,
    "updated_at": "2026-01-01T00:00:00Z"
  }
]
```

### PATCH /tables/{id}
Request:
```json
{
  "status": "active"
}
```

Response 200: same as GET table

## Orders

### POST /orders
Request:
```json
{
  "idempotency_key": "uuid",
  "table_id": "string",
  "customer_id": "string?",
  "order_type": "dine_in",
  "notes": "string?",
  "discount_minor": 0,
  "items": [
    {
      "menu_item_id": "string",
      "quantity": 2,
      "notes": "string?",
      "modifiers": "string?"
    }
  ]
}
```

Response 201:
```json
{
  "id": "string",
  "order_number": "ORD-00001",
  "idempotency_key": "uuid",
  "branch_id": "string",
  "terminal_id": "string",
  "cashier_id": "string",
  "table_id": "string",
  "customer_id": "string?",
  "order_type": "dine_in",
  "status": "submitted",
  "business_date": "2026-01-01",
  "subtotal_minor": 15000,
  "discount_minor": 0,
  "service_charge_minor": 0,
  "tax_minor": 0,
  "grand_total_minor": 15000,
  "paid_amount_minor": 0,
  "balance_minor": 15000,
  "currency": "NPR",
  "notes": "string?",
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-01-01T00:00:00Z",
  "server_version": "1",
  "sync_status": "synced",
  "void_reason": null,
  "audit_metadata": "string?"
}
```

### GET /orders
Query params: `status`, `table_id`
Response 200: array of Order

### GET /orders/{id}
Response 200: Order

### PATCH /orders/{id}
Request:
```json
{
  "status": "accepted",
  "void_reason": "string?"
}
```

Response 200: Order

### POST /orders/{id}/cancel
Request:
```json
{
  "reason": "string"
}
```

Response 200: Order

### POST /orders/{id}/void
Request:
```json
{
  "reason": "string"
}
```

Response 200: Order

## Payments

### POST /payments/intents
Request:
```json
{
  "order_id": "string",
  "payment_method": "cash",
  "amount_minor": 15000,
  "idempotency_key": "uuid"
}
```

Response 201:
```json
{
  "id": "string",
  "order_id": "string",
  "payment_method": "cash",
  "requested_amount_minor": 15000,
  "authorized_amount_minor": 15000,
  "tendered_amount_minor": 0,
  "change_amount_minor": 0,
  "gateway_reference": null,
  "status": "pending",
  "idempotency_key": "uuid",
  "failure_reason": null,
  "refund_amount_minor": 0,
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-01-01T00:00:00Z",
  "user_id": "string",
  "terminal_id": "string"
}
```

### POST /payments/{id}/confirm
Request:
```json
{
  "idempotency_key": "uuid",
  "tendered_amount_minor": 20000
}
```

Response 200: Payment

### POST /payments/{id}/refund
Request:
```json
{
  "amount_minor": 15000,
  "reason": "string",
  "idempotency_key": "uuid"
}
```

Response 200: Payment

### GET /payments/{id}
Response 200: Payment

## Customers

### GET /customers
Response 200: array of Customer

### POST /customers
Request:
```json
{
  "name": "string",
  "phone": "string",
  "address": "string",
  "email": "string?"
}
```

Response 201: Customer

### PATCH /customers/{id}
Request (partial):
```json
{
  "name": "string?",
  "phone": "string?",
  "address": "string?",
  "email": "string?"
}
```

Response 200: Customer

## Sync

### POST /sync/push
Request:
```json
{
  "operations": [
    {
      "operation_type": "create_order",
      "entity_type": "order",
      "entity_id": "string",
      "payload": {},
      "idempotency_key": "uuid"
    }
  ]
}
```

Response 200:
```json
{
  "results": [
    {
      "idempotency_key": "uuid",
      "status": "accepted",
      "server_version": "1"
    }
  ]
}
```

### GET /sync/pull
Query params: `since` (ISO timestamp)
Response 200:
```json
{
  "menu_items": [],
  "tables": [],
  "customers": [],
  "updated_at": "2026-01-01T00:00:00Z"
}
```

## Reports

### GET /reports/sales
Query params: `start_date`, `end_date`, `branch_id`
Response 200: sales report JSON

### GET /reports/closing
Query params: `shift_id`
Response 200: closing report JSON

## Error Responses

All errors follow this format:
```json
{
  "error": {
    "code": "string",
    "message": "string",
    "details": {}
  }
}
```

Common codes:
- `UNAUTHORIZED` — Missing or expired token
- `FORBIDDEN` — Insufficient permissions
- `NOT_FOUND` — Resource not found
- `VALIDATION_ERROR` — Invalid request data
- `CONFLICT` — Idempotency conflict or version mismatch
- `PAYMENT_FAILED` — Payment processing error
- `INTERNAL` — Server error
