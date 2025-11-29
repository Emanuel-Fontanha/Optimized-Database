-- 1
SELECT
    e.nome_empresa,
    p.nome_canal,
    p.id_plataforma,
    SUM(p.valor) AS total_pago
FROM Patrocinio p
JOIN Empresa e
    ON p.id_empresa = e.id_empresa
GROUP BY
    e.nome_empresa,
    p.nome_canal,
    p.id_plataforma
ORDER BY
    e.nome_empresa,
    p.id_plataforma,
    p.nome_canal;


-- 2
SELECT
    i.id_usuario,
    COUNT(*) AS total_canais_membro,
    SUM(nc.valor) AS total_desembolsado_mensal
FROM Inscricao i
JOIN NivelCanal nc
    ON nc.nome_canal = i.nome_canal
    AND nc.id_plataforma = i.id_plataforma
    AND nc.nivel = i.nivel
GROUP BY i.id_usuario
ORDER BY total_desembolsado_mensal DESC;


-- 3
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
GROUP BY c.nome, c.id_plataforma
HAVING SUM(d.valor) > 0
ORDER BY total_recebido DESC;


-- 4
SELECT
    d.id_video,
    d.id_plataforma,
    SUM(d.valor) AS total_doacoes_lidas
FROM Doacao d
WHERE d.status_doacao = 'lido'
GROUP BY
    d.id_video,
    d.id_plataforma
ORDER BY
    d.id_video,
    d.id_plataforma;


-- 5
SELECT
    p.nome_canal,
    p.id_plataforma,
    SUM(p.valor) AS total_patrocinio
FROM Patrocinio p
GROUP BY p.nome_canal, p.id_plataforma
ORDER BY total_patrocinio DESC;


-- 6
WITH valores AS (
    SELECT
        i.nome_canal,
        i.id_plataforma,
        nc.valor
    FROM Inscricao i
    JOIN NivelCanal nc
        ON nc.nome_canal = i.nome_canal
        AND nc.id_plataforma = i.id_plataforma
        AND nc.nivel = i.nivel
)
SELECT
    nome_canal,
    id_plataforma,
    SUM(valor) AS total_aportes
FROM valores
GROUP BY nome_canal, id_plataforma
ORDER BY total_aportes DESC;


-- 7
SELECT
    v.nome_canal,
    v.id_plataforma,
    SUM(d.valor) AS total_doacoes
FROM Doacao d
JOIN Video v
    ON v.id_video = d.id_video
    AND v.id_plataforma = d.id_plataforma
GROUP BY
    v.nome_canal,
    v.id_plataforma
HAVING SUM(d.valor) > 0
ORDER BY total_doacoes DESC;


-- 8
-- explain (analyse , buffers )
SELECT
    resultado.nome_canal,
    resultado.id_plataforma,
    SUM(resultado.faturamento) AS faturamento_total
FROM (

    -- 1. Receita de patrocínios
    SELECT
        p.nome_canal,
        p.id_plataforma,
        SUM(p.valor) AS faturamento
    FROM Patrocinio p
    GROUP BY p.nome_canal, p.id_plataforma

    UNION ALL

    -- 2. Receita de membros (inscrição)
    SELECT
        i.nome_canal,
        i.id_plataforma,
        SUM(n.valor) AS faturamento
    FROM Inscricao i
    JOIN NivelCanal n
        ON n.nome_canal = i.nome_canal
        AND n.id_plataforma = i.id_plataforma
        AND n.nivel = i.nivel
    GROUP BY i.nome_canal, i.id_plataforma

    UNION ALL

    -- 3. Receita de doações recebidas (precisa JOIN até Canal!)
    SELECT
        c.nome AS nome_canal,
        c.id_plataforma,
        SUM(d.valor) AS faturamento
    FROM Doacao d
    JOIN Comentario cm
        ON cm.id_comentario = d.id_comentario
        AND cm.id_plataforma  = d.id_plataforma
        AND cm.id_video       = d.id_video
        AND cm.nick_usuario   = d.nick_usuario
    JOIN Video v
        ON v.id_video = cm.id_video
        AND v.id_plataforma = cm.id_plataforma
    JOIN Canal c
        ON c.nome = v.nome_canal
        AND c.id_plataforma = v.id_plataforma
    WHERE d.status_doacao = 'recebido'
    GROUP BY c.nome, c.id_plataforma
) AS resultado
GROUP BY resultado.nome_canal, resultado.id_plataforma
ORDER BY faturamento_total DESC
LIMIT 100;
