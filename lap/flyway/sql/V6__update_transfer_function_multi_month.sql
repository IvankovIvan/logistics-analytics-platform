-- V6: Обновление load_snapshot для multi-month загрузки

CREATE OR REPLACE FUNCTION raw.load_snapshot()
RETURNS void AS
$$
DECLARE
    rec record;
    invalid_count integer;
BEGIN

    -- 1. Базовая валидация
    SELECT COUNT(*) INTO invalid_count
    FROM staging.snapshot_import
    WHERE barcode_id IS NULL
       OR shipment_date IS NULL
       OR client_id IS NULL
       OR region_id IS NULL
       OR revenue IS NULL
       OR cost IS NULL;

    IF invalid_count > 0 THEN
        RAISE EXCEPTION 'Обнаружены NULL значения в обязательных полях';
    END IF;

    SELECT COUNT(*) INTO invalid_count
    FROM staging.snapshot_import
    WHERE revenue < 0 OR cost < 0;

    IF invalid_count > 0 THEN
        RAISE EXCEPTION 'Обнаружены отрицательные значения revenue/cost';
    END IF;

    -- 2. Обработка каждого месяца
    FOR rec IN
        SELECT DISTINCT date_trunc('month', shipment_date)::date AS month_start
        FROM staging.snapshot_import
    LOOP

        -- Создаём партицию
        PERFORM raw.create_month_partition(rec.month_start);

        -- Удаляем данные месяца
        DELETE FROM raw.shipment_line
        WHERE shipment_date >= rec.month_start
          AND shipment_date < (rec.month_start + interval '1 month');

    END LOOP;

    -- 3. Вставка
    INSERT INTO raw.shipment_line (
        barcode_id,
        shipment_date,
        client_id,
        region_id,
        revenue,
        cost
    )
    SELECT
        barcode_id,
        shipment_date,
        client_id,
        region_id,
        revenue,
        cost
    FROM staging.snapshot_import;

END;
$$ LANGUAGE plpgsql;
