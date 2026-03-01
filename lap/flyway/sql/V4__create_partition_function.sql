-- V4: Функция автоматического создания месячных партиций

CREATE OR REPLACE FUNCTION raw.create_month_partition(p_month date)
RETURNS void AS
$$
DECLARE
    partition_name text;
    start_date date;
    end_date date;
BEGIN
    -- Начало месяца
    start_date := date_trunc('month', p_month)::date;
    -- Следующий месяц
    end_date := (start_date + interval '1 month')::date;

    partition_name := format(
        'shipment_line_%s',
        to_char(start_date, 'YYYY_MM')
    );

    -- Создаём партицию, если её нет
    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS raw.%I PARTITION OF raw.shipment_line
         FOR VALUES FROM (%L) TO (%L);',
        partition_name,
        start_date,
        end_date
    );
END;
$$ LANGUAGE plpgsql;
