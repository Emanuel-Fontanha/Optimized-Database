-- View 01: inscricoes_usuario, favorece Q2

    CREATE VIEW vw_inscricoes_usuario AS
    SELECT
        i.id_usuario,
        COUNT(*) AS total_canais_membro,
        SUM(nc.valor) AS total_desembolsado_mensal
    FROM Inscricao i
    JOIN NivelCanal nc USING (nome_canal, id_plataforma, nivel)
    GROUP BY i.id_usuario;


-- View 02: faturamento_canal, favorece Q8

    CREATE MATERIALIZED VIEW vw_faturamento_canal AS
    SELECT
        resultado.nome_canal,
        resultado.id_plataforma,
        SUM(resultado.faturamento) AS faturamento_total
    FROM (
        SELECT p.nome_canal, p.id_plataforma, SUM(p.valor) AS faturamento
        FROM Patrocinio p
        GROUP BY p.nome_canal, p.id_plataforma

        UNION ALL

        SELECT i.nome_canal, i.id_plataforma, SUM(n.valor) AS faturamento
        FROM Inscricao i
        JOIN NivelCanal n USING (nome_canal, id_plataforma, nivel)
        GROUP BY i.nome_canal, i.id_plataforma

        UNION ALL

        SELECT c.nome, c.id_plataforma, SUM(d.valor)
        FROM Doacao d
        JOIN Comentario cm USING (id_comentario, id_plataforma, id_video, nick_usuario)
        JOIN Video v USING (id_video, id_plataforma)
        JOIN Canal c ON c.nome = v.nome_canal AND c.id_plataforma = v.id_plataforma
        WHERE d.status_doacao = 'recebido'
        GROUP BY c.nome, c.id_plataforma
    ) AS resultado
    GROUP BY resultado.nome_canal, resultado.id_plataforma;

-- View 03: doacoes_por_canal, favorece Q3 e Q7

    CREATE MATERIALIZED VIEW vw_doacoes_por_canal AS
    SELECT
        c.nome AS nome_canal,
        c.id_plataforma,
        SUM(d.valor) AS total_doacoes
    FROM Doacao d
    JOIN Video v USING (id_video, id_plataforma)
    JOIN Canal c ON c.nome = v.nome_canal AND c.id_plataforma = v.id_plataforma
    GROUP BY c.nome, c.id_plataforma;

-- View 04: aportes_por_canal, favorece Q6

    CREATE VIEW vw_aportes_por_canal AS
    SELECT
        i.nome_canal,
        i.id_plataforma,
        SUM(nc.valor) AS total_aportes
    FROM Inscricao i
    JOIN NivelCanal nc
        ON nc.nome_canal = i.nome_canal
        AND nc.id_plataforma = i.id_plataforma
        AND nc.nivel = i.nivel
    GROUP BY
        i.nome_canal,
        i.id_plataforma;
