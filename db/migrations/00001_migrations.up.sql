-- migrations/000001_init.up.sql
-- PostgreSQL 16+
BEGIN;

CREATE TABLE
    users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        email TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        phone TEXT,
        status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
        email_verified_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        deleted_at TIMESTAMPTZ
    );

CREATE UNIQUE INDEX users_email_unique ON users (lower(email))
WHERE
    deleted_at IS NULL;

CREATE TABLE
    roles (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now ()
    );

CREATE TABLE
    permissions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        code TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now ()
    );

CREATE TABLE
    user_roles (
        user_id UUID NOT NULL REFERENCES users (id),
        role_id UUID NOT NULL REFERENCES roles (id),
        assigned_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        assigned_by UUID REFERENCES users (id),
        PRIMARY KEY (user_id, role_id)
    );

CREATE TABLE
    role_permissions (
        role_id UUID NOT NULL REFERENCES roles (id),
        permission_id UUID NOT NULL REFERENCES permissions (id),
        PRIMARY KEY (role_id, permission_id)
    );

CREATE TABLE
    auth_sessions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        user_id UUID NOT NULL REFERENCES users (id),
        refresh_token_hash TEXT NOT NULL UNIQUE,
        login_source TEXT NOT NULL CHECK (login_source IN ('web', 'mobile', 'api')),
        expires_at TIMESTAMPTZ NOT NULL,
        revoked_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now ()
    );

CREATE INDEX auth_sessions_user_idx ON auth_sessions (user_id, expires_at);

CREATE TABLE
    categories (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        parent_id UUID REFERENCES categories (id),
        name TEXT NOT NULL,
        slug TEXT NOT NULL UNIQUE,
        description TEXT,
        is_active BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now ()
    );

CREATE TABLE
    products (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        category_id UUID REFERENCES categories (id),
        name TEXT NOT NULL,
        slug TEXT NOT NULL UNIQUE,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'archived')),
        created_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        deleted_at TIMESTAMPTZ
    );

CREATE TABLE
    product_variants (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        product_id UUID NOT NULL REFERENCES products (id),
        sku TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        attributes JSONB NOT NULL DEFAULT '{}',
        price BIGINT NOT NULL CHECK (price >= 0),
        currency CHAR(3) NOT NULL DEFAULT 'IDR',
        is_active BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now ()
    );

CREATE INDEX product_variants_product_idx ON product_variants (product_id);

CREATE TABLE
    inventory_stocks (
        variant_id UUID PRIMARY KEY REFERENCES product_variants (id),
        quantity_on_hand BIGINT NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
        quantity_reserved BIGINT NOT NULL DEFAULT 0 CHECK (
            quantity_reserved >= 0
            AND quantity_reserved <= quantity_on_hand
        ),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now ()
    );

-- -------------------
CREATE TABLE
    product_images (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        product_id UUID NOT NULL REFERENCES products (id) ON DELETE CASCADE,
        variant_id UUID REFERENCES product_variants (id) ON DELETE CASCADE,
        image_url TEXT NOT NULL,
        alt_text TEXT,
        sort_order INT NOT NULL DEFAULT 0,
        is_primary BOOLEAN NOT NULL DEFAULT false,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now ()
    );

CREATE INDEX idx_product_images_product_id ON product_images (product_id);

CREATE INDEX idx_product_images_variant_id ON product_images (variant_id);

CREATE UNIQUE INDEX uq_product_images_primary_product ON product_images (product_id)
WHERE
    is_primary = true
    AND variant_id IS NULL;

CREATE UNIQUE INDEX uq_product_images_primary_variant ON product_images (variant_id)
WHERE
    is_primary = true
    AND variant_id IS NOT NULL;

-- -------------------
CREATE TABLE
    inventory_reservations (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        order_id UUID NOT NULL,
        variant_id UUID NOT NULL REFERENCES product_variants (id),
        quantity BIGINT NOT NULL CHECK (quantity > 0),
        status TEXT NOT NULL DEFAULT 'reserved' CHECK (
            status IN ('reserved', 'committed', 'released', 'expired')
        ),
        expires_at TIMESTAMPTZ NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        UNIQUE (order_id, variant_id)
    );

CREATE INDEX inventory_reservations_expiry_idx ON inventory_reservations (expires_at)
WHERE
    status = 'reserved';

CREATE TABLE
    inventory_movements (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        variant_id UUID NOT NULL REFERENCES product_variants (id),
        movement_type TEXT NOT NULL CHECK (
            movement_type IN (
                'receipt',
                'reservation',
                'sale',
                'release',
                'adjustment',
                'return'
            )
        ),
        quantity_delta BIGINT NOT NULL CHECK (quantity_delta <> 0),
        reference_type TEXT NOT NULL,
        reference_id UUID NOT NULL,
        note TEXT,
        created_by UUID REFERENCES users (id),
        created_at TIMESTAMPTZ NOT NULL DEFAULT now ()
    );

CREATE INDEX inventory_movements_variant_date_idx ON inventory_movements (variant_id, created_at DESC);

CREATE TABLE
    carts (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        user_id UUID NOT NULL REFERENCES users (id),
        status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'converted', 'abandoned')),
        created_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now ()
    );

CREATE UNIQUE INDEX carts_one_active_per_user ON carts (user_id)
WHERE
    status = 'active';

CREATE TABLE
    cart_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        cart_id UUID NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
        variant_id UUID NOT NULL REFERENCES product_variants (id),
        quantity BIGINT NOT NULL CHECK (quantity > 0),
        created_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        UNIQUE (cart_id, variant_id)
    );

CREATE TABLE
    orders (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        order_number TEXT NOT NULL UNIQUE,
        user_id UUID NOT NULL REFERENCES users (id),
        status TEXT NOT NULL DEFAULT 'pending_payment' CHECK (
            status IN (
                'pending_payment',
                'paid',
                'processing',
                'shipped',
                'completed',
                'cancelled',
                'refunded'
            )
        ),
        currency CHAR(3) NOT NULL DEFAULT 'IDR',
        subtotal BIGINT NOT NULL CHECK (subtotal >= 0),
        discount_total BIGINT NOT NULL DEFAULT 0 CHECK (discount_total >= 0),
        shipping_total BIGINT NOT NULL DEFAULT 0 CHECK (shipping_total >= 0),
        tax_total BIGINT NOT NULL DEFAULT 0 CHECK (tax_total >= 0),
        grand_total BIGINT NOT NULL CHECK (grand_total >= 0),
        shipping_address JSONB NOT NULL,
        billing_address JSONB,
        notes TEXT,
        placed_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        paid_at TIMESTAMPTZ,
        cancelled_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now ()
    );

CREATE INDEX orders_user_date_idx ON orders (user_id, created_at DESC);

CREATE INDEX orders_status_date_idx ON orders (status, created_at DESC);

CREATE TABLE
    order_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        order_id UUID NOT NULL REFERENCES orders (id),
        variant_id UUID REFERENCES product_variants (id) ON DELETE SET NULL,
        sku_snapshot TEXT NOT NULL,
        product_name_snapshot TEXT NOT NULL,
        variant_name_snapshot TEXT NOT NULL,
        quantity BIGINT NOT NULL CHECK (quantity > 0),
        unit_price BIGINT NOT NULL CHECK (unit_price >= 0),
        discount_total BIGINT NOT NULL DEFAULT 0 CHECK (discount_total >= 0),
        line_total BIGINT NOT NULL CHECK (line_total >= 0),
        created_at TIMESTAMPTZ NOT NULL DEFAULT now ()
    );

CREATE INDEX order_items_order_idx ON order_items (order_id);

CREATE TABLE
    payments (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        order_id UUID NOT NULL REFERENCES orders (id),
        provider TEXT NOT NULL,
        provider_payment_id TEXT,
        provider_reference TEXT,
        status TEXT NOT NULL DEFAULT 'pending' CHECK (
            status IN (
                'pending',
                'processing',
                'succeeded',
                'failed',
                'cancelled',
                'expired'
            )
        ),
        amount BIGINT NOT NULL CHECK (amount > 0),
        currency CHAR(3) NOT NULL DEFAULT 'IDR',
        payment_method TEXT,
        checkout_url TEXT,
        paid_at TIMESTAMPTZ,
        expires_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        UNIQUE (provider, provider_payment_id)
    );

CREATE INDEX payments_order_idx ON payments (order_id, created_at DESC);

CREATE INDEX payments_status_idx ON payments (status, created_at DESC);

CREATE TABLE
    payment_webhook_events (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        provider TEXT NOT NULL,
        provider_event_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        payment_id UUID REFERENCES payments (id),
        payload JSONB NOT NULL,
        status TEXT NOT NULL DEFAULT 'received' CHECK (
            status IN ('received', 'processing', 'processed', 'failed')
        ),
        attempts INTEGER NOT NULL DEFAULT 0 CHECK (attempts >= 0),
        received_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        processed_at TIMESTAMPTZ,
        last_error TEXT,
        UNIQUE (provider, provider_event_id)
    );

CREATE INDEX payment_webhook_pending_idx ON payment_webhook_events (received_at)
WHERE
    status IN ('received', 'failed');

CREATE TABLE
    idempotency_keys (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        scope TEXT NOT NULL,
        idempotency_key TEXT NOT NULL,
        request_hash TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
        response_status INTEGER,
        response_body JSONB,
        resource_id UUID,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        expires_at TIMESTAMPTZ NOT NULL,
        UNIQUE (scope, idempotency_key)
    );

CREATE INDEX idempotency_expiry_idx ON idempotency_keys (expires_at);

CREATE TABLE
    outbox_events (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        aggregate_type TEXT NOT NULL,
        aggregate_id UUID NOT NULL,
        event_type TEXT NOT NULL,
        payload JSONB NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending' CHECK (
            status IN ('pending', 'processing', 'published', 'failed')
        ),
        attempts INTEGER NOT NULL DEFAULT 0 CHECK (attempts >= 0),
        available_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        created_at TIMESTAMPTZ NOT NULL DEFAULT now (),
        published_at TIMESTAMPTZ,
        last_error TEXT
    );

CREATE INDEX outbox_pending_idx ON outbox_events (available_at, created_at)
WHERE
    status IN ('pending', 'failed');

CREATE TABLE
    audit_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        actor_user_id UUID REFERENCES users (id) ON DELETE SET NULL,
        action TEXT NOT NULL,
        resource_type TEXT NOT NULL,
        resource_id UUID,
        metadata JSONB NOT NULL DEFAULT '{}',
        request_id TEXT,
        ip_address INET,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now ()
    );

CREATE INDEX audit_logs_resource_idx ON audit_logs (resource_type, resource_id, created_at DESC);

CREATE INDEX audit_logs_actor_idx ON audit_logs (actor_user_id, created_at DESC);

COMMIT;