-- V2: Таблица временного импорта snapshot из CSV

CREATE TABLE staging.snapshot_import (
    barcode_id      bigint,
    shipment_date   date,
    client_id       bigint,
    region_id       integer,
    revenue         numeric(18,2),
    cost            numeric(18,2)
);
