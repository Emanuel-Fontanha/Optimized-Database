---------------------
-- EMPRESA ----------------------------------------------------------------------------------
---------------------

INSERT INTO Empresa (id_empresa, nome_empresa, nome_fantasia)
SELECT
    aux AS id_empresa,
    'Empresa_' || aux AS nome_empresa,
    'Fantasia_' || aux AS nome_fantasia
FROM generate_series(1, 1000) aux;

---------------------
-- CONVERSÃO ---------------------------------------------------------------------------------
---------------------

INSERT INTO Conversao (id_moeda, sigla_moeda, nome_moeda, fator_conver_to_dolar)
SELECT
    aux AS id_moeda,
    'M' || aux AS sigla_moeda,
    'Moeda_' || aux AS nome_moeda,
    (aux % 10 + 1) * 0.5 AS fator_conver
FROM generate_series(1, 100) aux;

---------------------
-- PAÍS ---------------------------------------------------------------------------------------
---------------------

INSERT INTO Pais (ddi, nome_pais, id_moeda)
SELECT
    aux AS ddi,
    'Pais_' || aux AS nome_pais,
    (aux % 100) + 1 AS id_moeda
FROM generate_series(1, 500) aux;

---------------------
-- PLATAFORMA ---------------------------------------------------------------------------------
---------------------

INSERT INTO Plataforma (id_plataforma, nome_plataforma, qtd_usuarios, id_empresa_fund, id_empresa_respo, data_fundacao)
SELECT
    aux AS id_plataforma,
    'Plataforma_' || aux AS nome_plataforma,
    (aux * 1500) % 500000 + 10000 AS qtd_usuarios,
    (aux % 1000) + 1 AS id_empresa_fund,
    ((aux + 77) % 1000) + 1 AS id_empresa_respo,
    DATE '2000-01-01' + (aux % 7000) * INTERVAL '1 day'
FROM generate_series(1, 200) aux;

---------------------
-- USUÁRIO -------------------------------------------------------------------------------------
---------------------

INSERT INTO Usuario (id_usuario, nick, email, data_nasc, telefone, end_postal, ddi_pais_residencia)
SELECT
    aux AS id_usuario,
    'user_' || aux AS nick,
    'user' || aux || '@example.com' AS email,
    DATE '1970-01-01' + (floor(random()*13000)::int) * INTERVAL '1 day' AS data_nasc,
    '55' || LPAD((10000000 + aux % 9000000)::text, 8, '0') AS telefone,
    'Endereco ' || aux AS end_postal,
    ((aux - 1) % 200) + 1 AS ddi_pais_residencia
FROM generate_series(1,8000) aux;

--------------------------
-- PLATAFORMA USUÁRIO --------------------------------------------------------------------------
--------------------------

INSERT INTO PlataformaUsuario (id_plataforma, id_usuario, numero_usuario, nick_usuario)
SELECT
    p.id_plataforma,
    u.id_usuario,
    u.id_usuario AS numero_usuario,
    'user_' || u.id_usuario AS nick_usuario
FROM (
        SELECT id_usuario,
            floor(random() * 3 + 1) AS qtd
        FROM Usuario
    ) u
CROSS JOIN LATERAL (
    SELECT id_plataforma
    FROM Plataforma
    ORDER BY random()
    LIMIT u.qtd
) p;

---------------------
-- STREAMER PAÍS -------------------------------------------------------------------------------
---------------------

INSERT INTO StreamerPais (id_streamer, ddi_pais_origem, nick_streamer, nro_passaporte)
SELECT
    aux AS id_streamer,
    ((aux - 1) % 200) + 1 AS ddi_pais_origem,
    'user_' || aux AS nick_streamer,
    'P' || LPAD(aux::text, 8, '0') AS nro_passaporte
FROM generate_series(1,2000) aux;

---------------------
-- EMPRESA PAÍS --------------------------------------------------------------------------------
---------------------

INSERT INTO EmpresaPais (id_empresa, ddi_pais_origem, id_nacional)
SELECT
    e.id_empresa,
    p.ddi,
    'IDN_' || row_number() OVER () AS id_nacional
FROM Empresa e
CROSS JOIN Pais p
ORDER BY random()
LIMIT 5000;

---------------------
-- CANAL --------------------------------------------------------------------------------------
---------------------

INSERT INTO Canal (nome, id_plataforma, nick_streamer, tipo, data_inicio, descricao, qtd_visualizacoes)
SELECT
    'Canal_' || aux AS nome,
    ((aux - 1) % 200) + 1 AS id_plataforma,
    u.nick AS nick_streamer,
    (ARRAY['publico','privado','misto'])[(aux % 3) + 1] AS tipo,
    DATE '2015-01-01' + ((aux * 11) % 3000) * INTERVAL '1 day' AS data_inicio,
    'Descricao canal ' || aux AS descricao,
    ((aux * 1237) % 1000000) AS qtd_visualizacoes
FROM generate_series(1, 5000) aux
CROSS JOIN LATERAL (
    SELECT nick
    FROM Usuario
    ORDER BY random()
    LIMIT 1
) u;

---------------------
-- NÍVEL CANAL --------------------------------------------------------------------------------
---------------------

INSERT INTO NivelCanal (nome_canal, id_plataforma, nivel, nome_nivel, valor, gif)
SELECT
    c.nome,
    c.id_plataforma,
    lvl AS nivel,
    'Nivel_' || lvl AS nome_nivel,
    (lvl * 10)::NUMERIC(10,2) AS valor,
    'gif_' || c.nome || '_' || lvl AS gif
FROM Canal c
CROSS JOIN generate_series(1, 5) AS lvl;

---------------------
-- PATROCINIO ---------------------------------------------------------------------------------
---------------------

WITH
    canais AS (SELECT nome, id_plataforma FROM Canal),
    empresas AS (SELECT id_empresa FROM Empresa)
INSERT INTO Patrocinio (id_empresa, nome_canal, id_plataforma, valor)
SELECT
    e.id_empresa,
    c.nome AS nome_canal,
    c.id_plataforma,
    (random() * 500 + 50)::NUMERIC(10,2) AS valor
FROM canais c
JOIN LATERAL (
    SELECT id_empresa
    FROM empresas
    ORDER BY random()
    LIMIT (1 + (random()*3)::int)
) e ON true
WHERE random() < 0.7; -- somente 70% dos canais terão patrocínio

---------------------
-- INSCRIÇÃO -----------------------------------------------------------------------------------
---------------------

WITH 
    canais AS (
        SELECT ROW_NUMBER() OVER () AS rn, nome, id_plataforma
        FROM Canal
    ),
    usuarios AS (
        SELECT ROW_NUMBER() OVER () AS rn, nick AS nick_usuario, id_usuario
        FROM Usuario
    )
INSERT INTO Inscricao (nome_canal, id_plataforma, nick_membro, id_usuario, nivel)
SELECT
    c.nome,
    c.id_plataforma,
    u.nick_usuario,
    u.id_usuario,
    (FLOOR(random() * 5) + 1)::INT AS nivel
FROM canais c
JOIN usuarios u ON random() < 0.002   -- ~0.2% dos usuários se inscrevem no canal
LIMIT 20000;

---------------------
-- VÍDEO ---------------------------------------------------------------------------------------
---------------------

WITH
    canal_list AS (
        SELECT
        ROW_NUMBER() OVER () AS rn, nome, id_plataforma
        FROM Canal
    )
INSERT INTO Video (id_video, nome_canal, id_plataforma, titulo, data_hora, tema, duracao, visus_simultaneas, visus_totais)
SELECT
    aux AS id_video,
    c.nome AS nome_canal,
    c.id_plataforma AS id_plataforma,
    'Video_' || aux || '_' || c.rn AS titulo,
    (TIMESTAMP '2020-01-01' + (aux % 2000) * INTERVAL '1 hour') AS data_hora,
    (ARRAY['Esporte','Música','Tecnologia','Educação','Entretenimento'])[1 + (aux % 5)] AS tema,
    (FLOOR(random() * 120) + 1)::text || ' min' AS duracao,
    (FLOOR(random() * 5000))::int AS visus_simultaneas,
    (FLOOR(random() * 1000000))::int AS visus_totais
FROM generate_series(1, 100000) aux
JOIN canal_list c ON c.rn = ((aux - 1) % (SELECT COUNT(*) FROM Canal)) + 1;

---------------------
-- COLABORAÇÃO --------------------------------------------------------------------------------
---------------------

WITH 
    vid AS (
        SELECT
            id_video,
            id_plataforma,
            ROW_NUMBER() OVER () AS rn
        FROM Video
    ),
    stre AS (
        SELECT
            nick,
            ROW_NUMBER() OVER () AS rn
        FROM Usuario
    ),
    selected_videos AS (
        SELECT *
        FROM vid
        WHERE rn % 5 = 0
    )
INSERT INTO Colaboracao (id_video, id_plataforma, nick_streamer)
SELECT
    v.id_video,
    v.id_plataforma,
    s.nick
FROM selected_videos v
JOIN LATERAL (
    SELECT nick
    FROM stre
    WHERE rn BETWEEN 1 AND (SELECT COUNT(*) FROM stre)
    ORDER BY random()
    LIMIT ((v.rn % 3) + 1)
) s ON TRUE;

---------------------
-- COMENTÁRIO --------------------------------------------------------------------------------
---------------------

WITH
    videos AS (
        SELECT
            ROW_NUMBER() OVER () AS rn,
            id_plataforma,
            id_video
        FROM Video
    ),
    usuarios AS (
        SELECT
            ROW_NUMBER() OVER () AS rn,
            nick
        FROM Usuario
    ),
    tot AS (
        SELECT
            (SELECT COUNT(*) FROM videos) AS total_videos,
            (SELECT COUNT(*) FROM usuarios) AS total_users
    )
INSERT INTO Comentario (id_comentario, id_plataforma, id_video, nick_usuario, texto, data_hora_postagem, is_online)
SELECT
    aux AS id_comentario,
    v.id_plataforma,
    v.id_video,
    u.nick,
    'Comentário #' || aux AS texto,
    NOW() - (aux || ' seconds')::interval AS data_hora_postagem,
    (aux % 2 = 0) AS is_online
FROM generate_series(1, 500000) aux
CROSS JOIN tot t
JOIN videos v ON v.rn = ((aux - 1) % t.total_videos) + 1
JOIN usuarios u ON u.rn = ((aux - 1) % t.total_users) + 1;

---------------------
-- DOAÇÃO --------------------------------------------------------------------------------------
---------------------

WITH 
    comentarios AS (
        SELECT
            ROW_NUMBER() OVER () AS rn,
            id_comentario,
            id_plataforma,
            id_video,
            nick_usuario
        FROM Comentario
    ),
    selecionados AS (
        SELECT *
        FROM comentarios
        WHERE rn % 2 = 0 -- 50% dos comentários
    )
INSERT INTO Doacao (id_doacao, id_comentario, id_plataforma, id_video, nick_usuario, valor, status_doacao)
SELECT
    rn AS id_doacao,
    id_comentario,
    id_plataforma,
    id_video,
    nick_usuario,
    ROUND( (1 + random()*499)::numeric, 2 ) AS valor,
    CASE (rn % 3)
        WHEN 0 THEN 'recebido'
        WHEN 1 THEN 'lido'
        ELSE 'recusado'
        END AS status_doacao
FROM selecionados;

------------------------
-- DOAÇÃO BITCOIN -------------------------------------------------------------------------------
------------------------

WITH 
    d AS (
        SELECT
            ROW_NUMBER() OVER () AS rn,
            id_doacao, id_comentario, id_plataforma, id_video, nick_usuario
        FROM Doacao
    )
INSERT INTO DoacaoBitcoin (id_doacao, id_comentario, id_plataforma, id_video, nick_usuario, txid)
SELECT
    id_doacao, id_comentario, id_plataforma, id_video, nick_usuario,
    md5(random()::text || now()::text) AS txid
FROM d
WHERE rn BETWEEN 1 AND 25000;

------------------------
-- DOAÇÃO PAYPAL --------------------------------------------------------------------------------
------------------------

WITH 
    d AS (
        SELECT
            ROW_NUMBER() OVER () AS rn,
            id_doacao, id_comentario, id_plataforma, id_video, nick_usuario
        FROM Doacao
    )
INSERT INTO DoacaoPaypal (id_doacao, id_comentario, id_plataforma, id_video, nick_usuario, id_paypal)
SELECT
    id_doacao, id_comentario, id_plataforma, id_video, nick_usuario,
    'PAYPAL_' || md5(random()::text)
FROM d
WHERE rn BETWEEN 25001 AND 100000;

------------------------
-- DOAÇÃO CARTÃO --------------------------------------------------------------------------------
------------------------

WITH 
    d AS (
        SELECT
            ROW_NUMBER() OVER () AS rn,
            id_doacao, id_comentario, id_plataforma, id_video, nick_usuario
        FROM Doacao
    )
INSERT INTO DoacaoCartao (id_doacao, id_comentario, id_plataforma, id_video, nick_usuario, numero_cartao, bandeira, data_transacao)
SELECT
    id_doacao, id_comentario, id_plataforma, id_video, nick_usuario,
    LPAD((floor(random()*9999999999999999))::text, 16, '0') AS numero_cartao,
    (ARRAY['Visa','Mastercard','Amex','Elo','Discover'])[(rn % 5)+1] AS bandeira,
    NOW() - (rn || ' seconds')::interval AS data_transacao
FROM d
WHERE rn BETWEEN 100001 AND 225000;

------------------------------------
-- DOAÇÃO MECANISMO PLATAFORMA ------------------------------------------------------------------
------------------------------------

WITH 
    d AS (
        SELECT
            ROW_NUMBER() OVER () AS rn,
            id_doacao, id_comentario, id_plataforma, id_video, nick_usuario
        FROM Doacao
    )
INSERT INTO DoacaoMecanismoPlat (id_doacao, id_comentario, id_plataforma, id_video, nick_usuario, seq_plataforma)
SELECT
    id_doacao, id_comentario, id_plataforma, id_video, nick_usuario, rn
FROM d
WHERE rn BETWEEN 225001 AND 250000;
