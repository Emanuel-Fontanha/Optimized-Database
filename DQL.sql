------------------------------ primeira consulta ----------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT e.nome_empresa AS empresa, c.nome AS canal, p.valor AS valor_patrocinio
FROM Patrocinio p
    JOIN Empresa e
ON p.id_empresa = e.id_empresa
    JOIN Canal c
ON p.nome_canal = c.nome AND p.id_plataforma = c.id_plataforma
ORDER BY e.nome_empresa, c.nome;


------------------------------ segunda consulta ----------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    U.nick AS usuario,
    COUNT(I.nome_canal) AS qtd_canais_membro,
    SUM(N.valor) AS total_mensal_assinaturas,
    DATE_TRUNC('month', CURRENT_DATE) AS mes_referencia
FROM Usuario U
        JOIN Inscricao I
                    ON U.nick = I.nick_membro
        JOIN NivelCanal N
                    ON I.nome_canal = N.nome_canal
                        AND I.id_plataforma = N.id_plataforma
                        AND I.nivel = N.nivel
GROUP BY U.nick
ORDER BY U.nick;

------------------------------ terceira consulta ----------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT D.nome_canal, D.id_plataforma, SUM(D.valor) AS total_recebido
FROM
    Doacao D
        JOIN Canal C
             ON D.nome_canal = C.nome
                 AND D.id_plataforma = C.id_plataforma
WHERE D.status_doacao = 'recebido'
GROUP BY D.nome_canal, D.id_plataforma
HAVING SUM(D.valor) > 0
ORDER BY total_recebido DESC;

------------------------------ quarta consulta ----------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT V.nome_canal, V.id_plataforma, V.titulo, V.data_hora, SUM(D.valor) AS total_doado_lido
FROM Doacao D
         JOIN Comentario C
              ON D.nome_canal = C.nome_canal
                  AND D.id_plataforma = C.id_plataforma
                  AND D.titulo_video = C.titulo_video
                  AND D.data_hora_vid = C.data_hora_vid
                  AND D.nick_usuario = C.nick_usuario
                  AND D.id_comentario = C.id_comentario
         JOIN Video V
              ON C.nome_canal = V.nome_canal
                  AND C.id_plataforma = V.id_plataforma
                  AND C.titulo_video = V.titulo
                  AND C.data_hora_vid = V.data_hora
WHERE D.status_doacao = 'lido'
GROUP BY V.nome_canal, V.id_plataforma, V.titulo, V.data_hora
ORDER BY V.nome_canal, V.titulo;

------------------------------ quinta consulta ----------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT P.nome_canal, P.id_plataforma, SUM(P.valor) AS total_patrocinio
FROM Patrocinio P
GROUP BY P.nome_canal, P.id_plataforma
ORDER BY total_patrocinio DESC;
--LIMIT :k;

------------------------------ sexta consulta ----------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    I.nome_canal,
    I.id_plataforma,
    SUM(N.valor) AS total_faturado_membros
FROM Inscricao I
         JOIN NivelCanal N
              ON I.nome_canal = N.nome_canal
                  AND I.id_plataforma = N.id_plataforma
                  AND I.nivel = N.nivel
GROUP BY I.nome_canal, I.id_plataforma
ORDER BY total_faturado_membros DESC;
--LIMIT :k;
------------------------------ setima consulta  ----------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT D.nome_canal, D.id_plataforma, SUM(D.valor) AS total_recebido
FROM Doacao D
         JOIN Video V
              ON D.nome_canal = V.nome_canal
                  AND D.id_plataforma = V.id_plataforma
                  AND D.titulo_video = V.titulo
                  AND D.data_hora_vid = V.data_hora
WHERE
    D.status_doacao = 'recebido'
GROUP BY D.nome_canal, D.id_plataforma
ORDER BY total_recebido DESC;
--LIMIT :k;

------------------------------ Oitava consulta  ----------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    resultado.nome_canal,
    resultado.id_plataforma,
    SUM(resultado.faturamento) AS faturamento_total
FROM (

         -- Receita de patrocínios
         SELECT
             p.nome_canal,
             p.id_plataforma,
             SUM(p.valor) AS faturamento
         FROM Patrocinio p
         GROUP BY p.nome_canal, p.id_plataforma

         UNION ALL

         -- Receita de membros (inscrições vigentes)
         SELECT
             i.nome_canal,
             i.id_plataforma,
             SUM(n.valor) AS faturamento
         FROM Inscricao i
                  JOIN NivelCanal n
                       ON i.nome_canal = n.nome_canal
                           AND i.id_plataforma = n.id_plataforma
                           AND i.nivel = n.nivel
         GROUP BY i.nome_canal, i.id_plataforma

         UNION ALL

         -- Receita de doações recebidas
         SELECT
             d.nome_canal,
             d.id_plataforma,
             SUM(d.valor) AS faturamento
         FROM Doacao d
         WHERE d.status_doacao = 'recebido'
         GROUP BY d.nome_canal, d.id_plataforma

     ) AS resultado
GROUP BY
    resultado.nome_canal,
    resultado.id_plataforma
ORDER BY
    faturamento_total DESC
LIMIT 100;

------------------------------- ÍNDICES ------------------------------
CREATE INDEX idx_doacao_canal
    ON Doacao (nome_canal, id_plataforma);

CREATE INDEX idx_patrocinio_empresa
    ON Patrocinio USING hash (id_empresa);

CREATE INDEX idx_inscricao_usuario
    ON Inscricao (nick_membro);

CREATE INDEX idx_doacao_usuario
     ON Doacao USING hash (nick_usuario);
----------------------------- FUNÇÕES -------------------------------
-------------------------------------------------------------------- 1
CREATE OR REPLACE FUNCTION canais_patrocinados(
    p_id_empresa INT DEFAULT NULL
)
    RETURNS TABLE (
                      empresa VARCHAR,
                      canal VARCHAR,
                      valor_patrocinio NUMERIC
                  )
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
        SELECT
            e.nome_empresa,
            c.nome,
            p.valor
        FROM Patrocinio p
                 JOIN Empresa e ON p.id_empresa = e.id_empresa
                 JOIN Canal c   ON p.nome_canal = c.nome
            AND p.id_plataforma = c.id_plataforma
        WHERE (p_id_empresa IS NULL OR p.id_empresa = p_id_empresa)
        ORDER BY e.nome_empresa, c.nome;
END;
$$;
SELECT * FROM canais_patrocinados(129);

--------------------------------------------------------------------- 2
CREATE OR REPLACE FUNCTION resumo_assinaturas_por_usuario(
    p_usuario TEXT DEFAULT NULL
)
    RETURNS TABLE (
                      usuario VARCHAR(50),
                      qtd_canais_membro BIGINT,
                      total_mensal_assinaturas NUMERIC,
                      mes_referencia DATE
                  )
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
        SELECT
            U.nick AS usuario,
            COUNT(I.nome_canal) AS qtd_canais_membro,
            SUM(N.valor) AS total_mensal_assinaturas,
            DATE_TRUNC('month', CURRENT_DATE)::date AS mes_referencia
        FROM Usuario U
                 INNER JOIN Inscricao I
                            ON U.nick = I.nick_membro
                 INNER JOIN NivelCanal N
                            ON I.nome_canal = N.nome_canal
                                AND I.id_plataforma = N.id_plataforma
                                AND I.nivel = N.nivel
        WHERE (p_usuario IS NULL OR U.nick = p_usuario)
        GROUP BY U.nick
        ORDER BY U.nick;
END;
$$;

SELECT * FROM resumo_assinaturas_por_usuario();
------------------------------------------------------------------- 3
CREATE OR REPLACE FUNCTION doacoes_recebidas_por_canal(
    p_nome_canal TEXT DEFAULT NULL
)
    RETURNS TABLE (
                      nome_canal VARCHAR(50),
                      id_plataforma INT,
                      total_recebido NUMERIC
                  )
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
        SELECT
            D.nome_canal,
            D.id_plataforma,
            SUM(D.valor) AS total_recebido
        FROM Doacao D
                 JOIN Canal C
                      ON D.nome_canal = C.nome
                          AND D.id_plataforma = C.id_plataforma
        WHERE D.status_doacao = 'recebido'
          AND (p_nome_canal IS NULL OR D.nome_canal = p_nome_canal)
        GROUP BY D.nome_canal, D.id_plataforma
        HAVING SUM(D.valor) > 0
        ORDER BY total_recebido DESC;
END;
$$;
SELECT * FROM doacoes_recebidas_por_canal();

-------------------------------------------------------------------- 4
CREATE OR REPLACE FUNCTION doacoes_lidas_por_video(
    p_titulo_video TEXT DEFAULT NULL,
    p_data_hora_video TIMESTAMP DEFAULT NULL
)
    RETURNS TABLE (
                      nome_canal VARCHAR(50),
                      id_plataforma INT,
                      titulo VARCHAR(50),
                      data_hora TIMESTAMP,
                      total_doado_lido NUMERIC
                  )
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
        SELECT
            V.nome_canal,
            V.id_plataforma,
            V.titulo,
            V.data_hora,
            SUM(D.valor) AS total_doado_lido
        FROM Doacao D
                 JOIN Comentario C
                      ON D.nome_canal = C.nome_canal
                          AND D.id_plataforma = C.id_plataforma
                          AND D.titulo_video = C.titulo_video
                          AND D.data_hora_vid = C.data_hora_vid
                          AND D.nick_usuario = C.nick_usuario
                          AND D.id_comentario = C.id_comentario
                 JOIN Video V
                      ON C.nome_canal = V.nome_canal
                          AND C.id_plataforma = V.id_plataforma
                          AND C.titulo_video = V.titulo
                          AND C.data_hora_vid = V.data_hora
        WHERE D.status_doacao = 'lido'
          AND (p_titulo_video IS NULL OR V.titulo = p_titulo_video)
          AND (p_data_hora_video IS NULL OR V.data_hora = p_data_hora_video)
        GROUP BY V.nome_canal, V.id_plataforma, V.titulo, V.data_hora
        ORDER BY V.nome_canal, V.titulo;
END;
$$;

SELECT * FROM doacoes_lidas_por_video('Video 489');

-------------------------------------------------------------------- 5
CREATE OR REPLACE FUNCTION top_canais_patrocinio(p_k INTEGER)
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
            P.nome_canal,
            P.id_plataforma,
            SUM(P.valor)::numeric(10,2) AS total_patrocinio
        FROM Patrocinio P
        GROUP BY
            P.nome_canal,
            P.id_plataforma
        ORDER BY
            total_patrocinio DESC
        LIMIT p_k;
END;
$$;

SELECT * FROM top_canais_patrocinio(100);
-------------------------------------------------------------------- 6
CREATE OR REPLACE FUNCTION top_canais_membros(p_k INTEGER)
    RETURNS TABLE (
                      nome_canal VARCHAR(50),
                      id_plataforma INT,
                      total_faturado_membros NUMERIC(10,2)
                  )
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
        SELECT
            I.nome_canal,
            I.id_plataforma,
            SUM(N.valor)::NUMERIC(10,2) AS total_faturado_membros
        FROM Inscricao I
                 JOIN NivelCanal N
                      ON I.nome_canal = N.nome_canal
                          AND I.id_plataforma = N.id_plataforma
                          AND I.nivel = N.nivel
        GROUP BY
            I.nome_canal,
            I.id_plataforma
        ORDER BY
            total_faturado_membros DESC
        LIMIT p_k;
END;
$$;

SELECT * FROM top_canais_membros(100);
-------------------------------------------------------------------- 7
CREATE OR REPLACE FUNCTION top_canais_doacoes(p_k INTEGER)
    RETURNS TABLE (
                      nome_canal VARCHAR(50),
                      id_plataforma INT,
                      total_recebido NUMERIC(10,2)
                  )
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
        SELECT
            D.nome_canal,
            D.id_plataforma,
            SUM(D.valor)::NUMERIC(10,2) AS total_recebido
        FROM Doacao D
                 JOIN Video V
                      ON D.nome_canal = V.nome_canal
                          AND D.id_plataforma = V.id_plataforma
                          AND D.titulo_video = V.titulo
                          AND D.data_hora_vid = V.data_hora
        WHERE D.status_doacao = 'recebido'
        GROUP BY D.nome_canal, D.id_plataforma
        ORDER BY total_recebido DESC
        LIMIT p_k;
END;
$$;

SELECT * FROM top_canais_doacoes(100);
-------------------------------------------------------------------- 8
CREATE OR REPLACE FUNCTION top_k_faturamento_total(
    p_k INTEGER
)
    RETURNS TABLE (
                      nome_canal VARCHAR(50),
                      id_plataforma INT,
                      faturamento_total NUMERIC
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

                 -- Receita de patrocínios
                 SELECT
                     p.nome_canal,
                     p.id_plataforma,
                     SUM(p.valor) AS faturamento
                 FROM Patrocinio p
                 GROUP BY p.nome_canal, p.id_plataforma

                 UNION ALL

                 -- Receita de membros
                 SELECT
                     i.nome_canal,
                     i.id_plataforma,
                     SUM(n.valor) AS faturamento
                 FROM Inscricao i
                          JOIN NivelCanal n
                               ON i.nome_canal = n.nome_canal
                                   AND i.id_plataforma = n.id_plataforma
                                   AND i.nivel = n.nivel
                 GROUP BY i.nome_canal, i.id_plataforma

                 UNION ALL

                 -- Receita de doações recebidas
                 SELECT
                     d.nome_canal,
                     d.id_plataforma,
                     SUM(d.valor) AS faturamento
                 FROM Doacao d
                 WHERE d.status_doacao = 'recebido'
                 GROUP BY d.nome_canal, d.id_plataforma
             ) AS resultado
        GROUP BY resultado.nome_canal, resultado.id_plataforma
        ORDER BY faturamento_total DESC
        LIMIT p_k;
END;
$$;

SELECT * FROM top_k_faturamento_total(100);


