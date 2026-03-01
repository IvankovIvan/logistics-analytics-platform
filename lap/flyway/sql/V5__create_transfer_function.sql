-- V5: Функция переноса данных из staging в raw с базовой валидацией

CREATE OR REPLACE FUNCTION raw.load_snapshot(p_window_start date)
RETURNS void AS
$$
DECLARE
    invalid_count integer;
BEGIN

    -- 1. Проверка обязательных полей
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

    -- 2. Проверка отрицательных значений
    SELECT COUNT(*) INTO invalid_count
    FROM staging.snapshot_import
    WHERE revenue < 0 OR cost < 0;

    IF invalid_count > 0 THEN
        RAISE EXCEPTION 'Обнаружены отрицательные значения revenue/cost';
    END IF;

    -- 3. Удаляем данные за окно
    DELETE FROM raw.shipment_line
    WHERE shipment_date >= p_window_start;

    -- 4. Вставляем данные в raw
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
