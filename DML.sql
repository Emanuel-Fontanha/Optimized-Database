-- INSERTS

INSERT INTO Empresa (id_empresa, nome_empresa, nome_fantasia)
SELECT
    gs AS id_empresa,
    'Empresa_' || gs AS nome_empresa,
    'Fantasia_' || gs AS nome_fantasia
FROM generate_series(1, 1000) gs;

INSERT INTO Conversao (id_moeda, sigla_moeda, nome_moeda, fator_conver_to_dolar)
SELECT
    gs AS id_moeda,
    'M' || gs AS sigla_moeda,
    'Moeda_' || gs AS nome_moeda,
    (gs % 10 + 1) * 0.5  -- valores entre 0.5 e 5.0
FROM generate_series(1, 100) gs;

INSERT INTO Pais (ddi, nome_pais, id_moeda)
SELECT
    gs AS ddi,
    'Pais_' || gs AS nome_pais,
    (gs % 100) + 1  -- referencia moedas existentes
FROM generate_series(1, 500) gs;

INSERT INTO Plataforma (id_plataforma, nome_plataforma, qtd_usuarios, id_empresa_fund, id_empresa_respo, data_fundacao)
SELECT
    gs AS id_plataforma,
    'Plataforma_' || gs AS nome_plataforma,
    (gs * 1500) % 500000 + 10000 AS qtd_usuarios,
    (gs % 1000) + 1 AS id_empresa_fund,
    ((gs + 77) % 1000) + 1 AS id_empresa_respo,
    DATE '2000-01-01' + (gs % 7000) * INTERVAL '1 day'
FROM generate_series(1, 200) gs;

INSERT INTO Usuario (id_usuario, nick, email, data_nasc, telefone, end_postal, ddi_pais_residencia)
SELECT
    gs                                                          AS id_usuario,
    'user_' || gs                                                AS nick,
    'user' || gs || '@example.com'                               AS email,
    DATE '1970-01-01' + (floor(random()*13000)::int) * INTERVAL '1 day' AS data_nasc,
    '55' || LPAD((10000000 + gs % 9000000)::text, 8, '0')        AS telefone,
    'Endereco ' || gs                                            AS end_postal,
    ((gs - 1) % 200) + 1                                         AS ddi_pais_residencia
FROM generate_series(1,8000) gs;

INSERT INTO PlataformaUsuario (id_plataforma, id_usuario, numero_usuario, nick_usuario)
SELECT
    p.id_plataforma,
    u.id_usuario,
    u.id_usuario AS numero_usuario, -- <== gera pelo próprio id
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

INSERT INTO StreamerPais (id_streamer, ddi_pais_origem, nick_streamer, nro_passaporte)
SELECT
    gs                                                     AS id_streamer,
    ((gs - 1) % 200) + 1                                   AS ddi_pais_origem,
    'user_' || gs                                           AS nick_streamer,
    'P' || LPAD(gs::text, 8, '0')                           AS nro_passaporte
FROM generate_series(1,2000) gs;

INSERT INTO EmpresaPais (id_empresa, ddi_pais_origem, id_nacional)
SELECT
    e.id_empresa,
    p.ddi,
    'IDN_' || row_number() OVER () AS id_nacional
FROM Empresa e
         CROSS JOIN Pais p
ORDER BY random()
LIMIT 5000;


INSERT INTO Canal (nome, id_plataforma, nick_streamer, tipo, data_inicio, descricao, qtd_visualizacoes)
SELECT
    'Canal_' || gs AS nome,
    ((gs - 1) % 200) + 1 AS id_plataforma,
    u.nick AS nick_streamer,
    (ARRAY['publico','privado','misto'])[(gs % 3) + 1] AS tipo,
    DATE '2015-01-01' + ((gs * 11) % 3000) * INTERVAL '1 day' AS data_inicio,
    'Descricao canal ' || gs AS descricao,
    ((gs * 1237) % 1000000) AS qtd_visualizacoes

FROM generate_series(1, 5000) gs
         CROSS JOIN LATERAL (
    SELECT nick
    FROM Usuario
    ORDER BY random()
    LIMIT 1
    ) u;

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

WITH canais AS (
    SELECT nome, id_plataforma FROM Canal
),
     empresas AS (
         SELECT id_empresa FROM Empresa
     )
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

WITH canais AS (
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
         JOIN usuarios u
              ON random() < 0.002   -- ~0.2% dos usuários se inscrevem no canal
LIMIT 20000;
