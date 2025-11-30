-- function da Q1: fn_canais_patrocinados() (explicar 229)

    CREATE OR REPLACE FUNCTION fn_canais_patrocinados(p_id_empresa INT)
    RETURNS TABLE (
        nome_empresa VARCHAR,
        nome_canal VARCHAR,
        id_plataforma INT,
        total_pago NUMERIC
    )
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        SELECT
            e.nome_empresa,
            p.nome_canal,
            p.id_plataforma,
            SUM(p.valor) AS total_pago
        FROM Patrocinio p
        JOIN Empresa e ON p.id_empresa = e.id_empresa
        WHERE p.id_empresa = p_id_empresa
        GROUP BY e.nome_empresa, p.nome_canal, p.id_plataforma
        ORDER BY e.nome_empresa, p.id_plataforma, p.nome_canal;
    END;
    $$;


-- function da Q2: fn_total_desembolsado_por_usuario()

    CREATE OR REPLACE FUNCTION fn_total_desembolsado_por_usuario(p_id_usuario BIGINT)
    RETURNS TABLE (
        id_usuario BIGINT,
        total_canais_membro BIGINT,
        total_desembolsado_mensal NUMERIC
    )
    AS $$
    BEGIN
        RETURN QUERY
        SELECT
            i.id_usuario,
            COUNT(*) AS total_canais_membro,
            SUM(nc.valor) AS total_desembolsado_mensal
        FROM Inscricao i
        JOIN NivelCanal nc
            ON nc.nome_canal = i.nome_canal
            AND nc.id_plataforma = i.id_plataforma
            AND nc.nivel = i.nivel
        WHERE i.id_usuario = p_id_usuario
        GROUP BY i.id_usuario
        ORDER BY total_desembolsado_mensal DESC;
    END;
    $$ LANGUAGE plpgsql;


-- function da Q3: fn_total_recebido_por_canal()

    CREATE OR REPLACE FUNCTION fn_total_recebido_por_canal(
        p_nome_canal VARCHAR DEFAULT NULL,
        p_id_plataforma INT DEFAULT NULL
    )
    RETURNS TABLE (
        canal VARCHAR(50),
        id_plataforma INT,
        total_recebido NUMERIC(10,2)
    )
    AS $$
    BEGIN
        RETURN QUERY
        SELECT
            c.nome AS canal,
            c.id_plataforma,
            SUM(d.valor) AS total_recebido
        FROM Doacao d
        JOIN Video v
            ON v.id_video = d.id_video
            AND v.id_plataforma = d.id_plataforma
        JOIN Canal c
            ON c.nome = v.nome_canal
            AND c.id_plataforma = v.id_plataforma
        WHERE
            (p_nome_canal IS NULL OR c.nome = p_nome_canal)
            AND (p_id_plataforma IS NULL OR c.id_plataforma = p_id_plataforma)
        GROUP BY c.nome, c.id_plataforma
        HAVING SUM(d.valor) > 0
        ORDER BY total_recebido DESC;
    END;
    $$ LANGUAGE plpgsql;


-- function da Q4: fn_doacoes_filtro()

    CREATE OR REPLACE FUNCTION fn_doacoes_filtro(
        p_id_plataforma INT DEFAULT NULL,
        p_valor_minimo NUMERIC DEFAULT 0
    )
    RETURNS TABLE (
        id_video BIGINT,
        id_plataforma INT,
        total_doacoes NUMERIC(10,2)
    )
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        SELECT
            d.id_video,
            d.id_plataforma,
            SUM(d.valor) AS total
        FROM Doacao d
        WHERE d.status_doacao = 'lido'
            AND (p_id_plataforma IS NULL OR d.id_plataforma = p_id_plataforma)
        GROUP BY
            d.id_video,
            d.id_plataforma
        HAVING SUM(d.valor) >= p_valor_minimo
        ORDER BY
            d.id_video,
            d.id_plataforma;
    END;
    $$;


-- function da Q5: fn_patrocinio()

    CREATE OR REPLACE FUNCTION fn_patrocinio(
        p_id_plataforma INT DEFAULT NULL,
        p_nome_canal VARCHAR(50) DEFAULT NULL,
        p_valor_minimo NUMERIC DEFAULT 0
    )
    RETURNS TABLE (
        nome_canal VARCHAR(50),
        id_plataforma INT,
        total_patrocinio NUMERIC(10,2)
    )
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        SELECT
            p.nome_canal,
            p.id_plataforma,
            SUM(p.valor) AS total_patrocinio
        FROM Patrocinio p
        WHERE
            (p_id_plataforma IS NULL OR p.id_plataforma = p_id_plataforma)
            AND (p_nome_canal IS NULL OR p.nome_canal = p_nome_canal)
        GROUP BY
            p.nome_canal,
            p.id_plataforma
        HAVING SUM(p.valor) >= p_valor_minimo
        ORDER BY total_patrocinio DESC;
    END;
    $$;


-- function da Q6: fn_inscricoes()

    CREATE OR REPLACE FUNCTION fn_inscricoes(
        p_id_plataforma INT DEFAULT NULL,
        p_nome_canal VARCHAR(50) DEFAULT NULL,
        p_valor_minimo NUMERIC DEFAULT 0
    )
    RETURNS TABLE (
        nome_canal VARCHAR(50),
        id_plataforma INT,
        total_aportes NUMERIC(10,2)
    )
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        SELECT
            i.nome_canal,
            i.id_plataforma,
            SUM(nc.valor) AS total_aportes
        FROM Inscricao i
        JOIN NivelCanal nc
            ON nc.nome_canal = i.nome_canal
            AND nc.id_plataforma = i.id_plataforma
            AND nc.nivel = i.nivel
        WHERE
            (p_id_plataforma IS NULL OR i.id_plataforma = p_id_plataforma)
            AND (p_nome_canal IS NULL OR i.nome_canal = p_nome_canal)
        GROUP BY i.nome_canal, i.id_plataforma
        HAVING SUM(nc.valor) >= p_valor_minimo
        ORDER BY total_aportes DESC;
    END;
    $$;


-- function da Q7: fn_total_doacoes_canal()

    CREATE OR REPLACE FUNCTION fn_total_doacoes_canal(
        p_id_plataforma INT DEFAULT NULL,
        p_nome_canal VARCHAR(50) DEFAULT NULL,
        p_valor_minimo NUMERIC DEFAULT 0
    )
    RETURNS TABLE (
        nome_canal VARCHAR(50),
        id_plataforma INT,
        total_doacoes NUMERIC(10,2)
    ) 
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        SELECT
            v.nome_canal,
            v.id_plataforma,
            SUM(d.valor) AS total_doacoes
        FROM Doacao d
        JOIN Video v
            ON v.id_video = d.id_video
            AND v.id_plataforma = d.id_plataforma
        WHERE 
            (p_id_plataforma IS NULL OR v.id_plataforma = p_id_plataforma)
            AND (p_nome_canal IS NULL OR v.nome_canal = p_nome_canal)
        GROUP BY
            v.nome_canal,
            v.id_plataforma
        HAVING SUM(d.valor) > p_valor_minimo
        ORDER BY total_doacoes DESC;
    END;
    $$;


-- function da Q8: fn_faturamento_total()

    CREATE OR REPLACE FUNCTION fn_faturamento_total(
        p_id_plataforma INT DEFAULT NULL,
        p_nome_canal VARCHAR(50) DEFAULT NULL,
        p_valor_minimo NUMERIC DEFAULT 0
    )
    RETURNS TABLE (
        nome_canal VARCHAR(50),
        id_plataforma INT,
        faturamento_total NUMERIC(10,2)
    )
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        SELECT
            resultado.nome_canal,
            resultado.id_plataforma,
            SUM(resultado.faturamento) AS faturamento_total
        FROM (

            SELECT
                p.nome_canal,
                p.id_plataforma,
                SUM(p.valor) AS faturamento
            FROM Patrocinio p
            WHERE 
                (p_id_plataforma IS NULL OR p.id_plataforma = p_id_plataforma)
                AND (p_nome_canal IS NULL OR p.nome_canal = p_nome_canal)
            GROUP BY p.nome_canal, p.id_plataforma

            UNION ALL

            SELECT
                i.nome_canal,
                i.id_plataforma,
                SUM(n.valor) AS faturamento
            FROM Inscricao i
            JOIN NivelCanal n
                ON n.nome_canal = i.nome_canal
                AND n.id_plataforma = i.id_plataforma
                AND n.nivel = i.nivel
            WHERE 
                (p_id_plataforma IS NULL OR i.id_plataforma = p_id_plataforma)
                AND (p_nome_canal IS NULL OR i.nome_canal = p_nome_canal)
            GROUP BY i.nome_canal, i.id_plataforma

            UNION ALL

            SELECT
                v.nome_canal,
                v.id_plataforma,
                SUM(d.valor) AS faturamento
            FROM Doacao d
            JOIN Video v
                ON v.id_video = d.id_video
                AND v.id_plataforma = d.id_plataforma
            WHERE
                d.status_doacao = 'recebido'
                AND (p_id_plataforma IS NULL OR v.id_plataforma = p_id_plataforma)
                AND (p_nome_canal IS NULL OR v.nome_canal = p_nome_canal)
            GROUP BY v.nome_canal, v.id_plataforma

        ) AS resultado
        GROUP BY resultado.nome_canal, resultado.id_plataforma
        HAVING SUM(resultado.faturamento) >= p_valor_minimo
        ORDER BY faturamento_total DESC;
    END;
    $$;