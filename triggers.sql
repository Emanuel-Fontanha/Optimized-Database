-- trigger function 01: fn_trg_atualizar_qtd_usuarios()

    -- Incrementa ou decrementa a quantia de usuários numa plataforma sempre que PlataformaUsuario for alterada

    CREATE OR REPLACE FUNCTION fn_trg_atualizar_qtd_usuarios()
    RETURNS TRIGGER AS $$
    BEGIN
        UPDATE Plataforma p
        SET qtd_usuarios = (
            SELECT COUNT(*)
            FROM PlataformaUsuario pu
            WHERE pu.id_plataforma = p.id_plataforma
        )
        WHERE p.id_plataforma = COALESCE(NEW.id_plataforma, OLD.id_plataforma);

        RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;


    -- trigger definition 01: trg_atualizar_qtd_usuarios

    CREATE TRIGGER trg_atualizar_qtd_usuarios
    AFTER INSERT OR DELETE ON PlataformaUsuario
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_atualizar_qtd_usuarios();

-- trigger function 02: fn_trg_atualizar_qtd_visualizacoes()

    -- Corrige as quantidades de visualizações dos canais sempre que há alterações em linhas de Video

    CREATE OR REPLACE FUNCTION fn_trg_atualizar_qtd_visualizacoes()
    RETURNS TRIGGER AS $$
    DECLARE
        canal_nome VARCHAR(50);
        plataforma_id INT;
    BEGIN
        IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
            canal_nome := NEW.nome_canal;
            plataforma_id := NEW.id_plataforma;
        ELSIF TG_OP = 'DELETE' THEN
            canal_nome := OLD.nome_canal;
            plataforma_id := OLD.id_plataforma;
        END IF;

        UPDATE Canal c
        SET qtd_visualizacoes = (
            SELECT COALESCE(SUM(v.visus_totais), 0)
            FROM Video v
            WHERE v.nome_canal = c.nome
                AND v.id_plataforma = c.id_plataforma
        )
        WHERE c.nome = canal_nome
            AND c.id_plataforma = plataforma_id;

        RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;


    -- trigger definition 02: trg_atualizar_qtd_visualizacoes

    CREATE TRIGGER trg_atualizar_qtd_visualizacoes
    AFTER INSERT OR UPDATE OR DELETE ON Video
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_atualizar_qtd_visualizacoes();

