
CREATE TABLE inventory.inventory_stock (
                                 id UUID PRIMARY KEY,

                                 sku VARCHAR(80) NOT NULL,

                                 on_hand_quantity INTEGER NOT NULL DEFAULT 0,
                                 reserved_quantity INTEGER NOT NULL DEFAULT 0,

                                 version BIGINT NOT NULL DEFAULT 0,

                                 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

                                 CONSTRAINT uq_inventory_stock_sku
                                     UNIQUE (sku),

                                 CONSTRAINT ck_inventory_stock_on_hand
                                     CHECK (on_hand_quantity >= 0),

                                 CONSTRAINT ck_inventory_stock_reserved
                                     CHECK (reserved_quantity >= 0),

                                 CONSTRAINT ck_inventory_stock_availability
                                     CHECK (reserved_quantity <= on_hand_quantity)
);
