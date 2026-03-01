-- V3: Основная таблица raw.shipment_line (партиционированная)

CREATE TABLE raw.shipment_line (
    barcode_id      bigint       NOT NULL,
    shipment_date   date         NOT NULL,
    client_id       bigint       NOT NULL,
    region_id       integer      NOT NULL,
    revenue         numeric(18,2) NOT NULL,
    cost            numeric(18,2) NOT NULL,

    CONSTRAINT shipment_line_barcode_positive CHECK (barcode_id > 0)
)
PARTITION BY RANGE (shipment_date);

CREATE UNIQUE INDEX idx_shipment_line_barcode
ON raw.shipment_line (barcode_id);
