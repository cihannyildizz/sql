--Logları Tutacak Tablo
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(255),
    action_type VARCHAR(10), -- INSERT, UPDATE veya DELETE
    timestamp TIMESTAMP,
    user_name VARCHAR(255), -- Kullanıcı adı bilgisini tutmak için
    row_data JSONB -- Etkilenen satır verileri (eski veya yeni veriler)
);
--
--İnsert, Update ve Delete İşlemleri İçin Trigger(Tetikleyici) Oluşturma
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, action_type, timestamp, user_name, row_data)
        VALUES (TG_TABLE_NAME, 'INSERT', NOW(), current_user, row_to_json(NEW));
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, action_type, timestamp, user_name, row_data)
        VALUES (TG_TABLE_NAME, 'UPDATE', NOW(), current_user, jsonb_build_object('old', OLD, 'new', NEW));
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, action_type, timestamp, user_name, row_data)
        VALUES (TG_TABLE_NAME, 'DELETE', NOW(), current_user, row_to_json(OLD));
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
--
--Son olarak tüm tablolara oluşturduğumuz trigger'ları tanımlıyoruz. Bu işlemi veritabanına her tablo eklediğinde çalıştırmak gerekiyor.
DO $$ 
DECLARE
    table_record record;
BEGIN
    FOR table_record IN (SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'CREATE TRIGGER ' || table_record.tablename || '_audit_trigger '
                || 'AFTER INSERT OR UPDATE OR DELETE ON ' || table_record.tablename || ' '
                || 'FOR EACH ROW EXECUTE FUNCTION audit_trigger()';
    END LOOP;
END $$;