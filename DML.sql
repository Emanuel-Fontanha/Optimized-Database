INSERT INTO Conversao (sigla_moeda, nome_moeda, fator_conver_to_dolar)
SELECT 
    'M' || LPAD(i::text, 4, '0') AS sigla_moeda,
    'Moeda_' || i AS nome_moeda,
    ROUND((RANDOM() * 10 + 0.5)::NUMERIC, 4) AS fator_conver_to_dolar
FROM generate_series(1, 1000) AS s(i);


INSERT INTO Empresa (id_empresa, nome_empresa, nome_fantasia)
SELECT 
    i AS id_empresa,
    'Empresa_' || i AS nome_empresa,
    'Fantasia_' || i AS nome_fantasia
FROM generate_series(1, 1000) AS s(i);


INSERT INTO Pais (ddi, nome_pais, sigla_moeda)
SELECT 
    i AS ddi,
    'Pais_' || i AS nome_pais,
    'M' || LPAD((1 + floor(random() * 1000))::text, 4, '0') AS sigla_moeda
FROM generate_series(1, 1000) AS s(i);


INSERT INTO EmpresaPais (id_empresa, ddi_pais_origem, id_nacional)
SELECT
    i AS id_empresa,
    i AS ddi_pais_origem,
    'NAC_' || i AS id_nacional
FROM generate_series(1, 1000) AS s(i);


INSERT INTO Plataforma (id_plataforma, nome_plataforma, id_empresa_fund, id_empresa_respo, data_fundacao, qtd_usuarios)
SELECT
    i AS id_plataforma,
    'Plataforma_' || i AS nome_plataforma,
    (1 + floor(random() * 1000))::int AS id_empresa_fund,
    (1 + floor(random() * 1000))::int AS id_empresa_respo,
    -- data aleatória entre 1980 e 2023
    date '1980-01-01' + (floor(random() * 16000))::int AS data_fundacao,
    (1000 + floor(random() * 10000000))::int AS qtd_usuarios
FROM generate_series(1, 1000) AS s(i);


INSERT INTO Usuario (nick, email, data_nasc, telefone, end_postal, ddi_pais_residencia)
SELECT
    'user_' || i AS nick,
    'user_' || i || '@exemplo.com' AS email,
    -- datas de nascimento entre 1960 e 2010
    date '1960-01-01' + (floor(random() * 18250))::int AS data_nasc,
    '+55-' || LPAD(i::text, 4, '0') AS telefone,
    'Endereco_' || i AS end_postal,
    (1 + floor(random() * 1000))::int AS ddi_pais_residencia
FROM generate_series(1, 1000) AS s(i);


INSERT INTO PlataformaUsuario (id_plataforma, nick_usuario, numero_usuario)
SELECT
    i AS id_plataforma,
    'user_' || i AS nick_usuario,
    i AS numero_usuario
FROM generate_series(1, 1000) AS s(i);


INSERT INTO StreamerPais (nick_streamer, ddi_pais_origem, nro_passaporte)
SELECT
    'user_' || i AS nick_streamer,
    i AS ddi_pais_origem,
    'PASS_' || i AS nro_passaporte
FROM generate_series(1, 1000) AS s(i);


INSERT INTO Canal (nome, id_plataforma, nick_streamer, tipo, data_inicio, descricao, qtd_visualizacoes)
SELECT
    'Canal_' || i AS nome,
    i AS id_plataforma,
    'user_' || i AS nick_streamer,
    (ARRAY['publico','privado','misto'])[1 + floor(random() * 3)] AS tipo,
    date '2000-01-01' + (floor(random() * 9000))::int AS data_inicio,
    'Descricao do canal ' || i AS descricao,
    (floor(random() * 10000000))::int AS qtd_visualizacoes
FROM generate_series(1, 1000) AS s(i);


INSERT INTO NivelCanal (nome_canal, id_plataforma, nivel, nome_nivel, valor, gif)
SELECT
    'Canal_' || i AS nome_canal,
    i AS id_plataforma,
    1 AS nivel,
    'Nivel_1' AS nome_nivel,
    (5 + random() * 45)::numeric(10,2) AS valor,
    'gif_nivel_1_canal_' || i || '.gif' AS gif
FROM generate_series(1, 1000) AS s(i);

-- inserir em Patrocínio
WITH emp AS (
    SELECT id_empresa,
           row_number() OVER (ORDER BY random()) AS ern,
           (SELECT count(*) FROM Empresa) AS total_emp
    FROM Empresa
),
     can AS (
         SELECT nome, id_plataforma,
                row_number() OVER (ORDER BY random()) AS crn
         FROM Canal
     ),
     pair AS (
         SELECT
             can.nome,
             can.id_plataforma,
             emp.id_empresa
         FROM can
                  JOIN emp
                       ON ((can.crn - 1) % emp.total_emp) + 1 = emp.ern
     )
INSERT INTO Patrocinio (id_empresa, nome_canal, id_plataforma, valor)
SELECT
    p.id_empresa,
    p.nome,
    p.id_plataforma,
    ROUND((RANDOM() * 9000 + 1000)::numeric, 2)
FROM pair p
ORDER BY random()
LIMIT 1000;


INSERT INTO Inscricao (nome_canal, id_plataforma, nick_membro, nivel)
SELECT 
    n.nome_canal,
    n.id_plataforma,
    u.nick,
    n.nivel
FROM NivelCanal n
JOIN Usuario u ON TRUE
ORDER BY RANDOM()
LIMIT 1000;


INSERT INTO Video (nome_canal, id_plataforma, titulo, data_hora, tema, duracao, visus_simultaneas, visus_totais)
SELECT
    c.nome,
    c.id_plataforma,
    'Video ' || g,
    make_timestamp(
        2010 + (g % 10),
        1 + ((floor(random() * 1000)::int + g) % 12),
        1 + ((floor(random() * 2000)::int + g) % 28),
        (floor(random() * 24)::int),
        (floor(random() * 60)::int),
        (floor(random() * 60)::int)
    ),
    'Tema ' || (RANDOM()*50)::int,
    (10 + (RANDOM()*590))::int || 'min',
    (RANDOM()*5000)::int,
    (RANDOM()*200000)::int
FROM Canal c
CROSS JOIN generate_series(1, 1000) g
ORDER BY random()
LIMIT 1000;



INSERT INTO Colaboracao (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_streamer)
SELECT 
    v.nome_canal,
    v.id_plataforma,
    v.titulo,
    v.data_hora,
    u.nick
FROM Video v
JOIN Usuario u ON TRUE
ORDER BY RANDOM()
LIMIT 1000;


WITH 
    vids AS (SELECT * FROM Video ORDER BY RANDOM() LIMIT 1000),
    users AS (SELECT nick FROM Usuario ORDER BY RANDOM() LIMIT 1000)
INSERT INTO Comentario (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, texto, data_hora_postagem, is_online)
SELECT 
    v.nome_canal,
    v.id_plataforma,
    v.titulo,
    v.data_hora,
    u.nick,
    row_number() OVER () AS id_comentario,
    'Comentario auto',
    NOW() - (RANDOM()*INTERVAL '60 days'),
    RANDOM() > 0.5
FROM vids v
JOIN users u ON v.id_plataforma = v.id_plataforma
ORDER BY RANDOM()
LIMIT 1000;


INSERT INTO Doacao (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao, valor, status_doacao)
SELECT
    c.nome_canal,
    c.id_plataforma,
    c.titulo_video,
    c.data_hora_vid,
    c.nick_usuario,
    c.id_comentario,
    gs AS id_doacao,
    ROUND(((RANDOM() * 200)::numeric) + 1, 2) AS valor,
    CASE
        WHEN r < 0.33 THEN 'recusado'
        WHEN r < 0.66 THEN 'lido'
        ELSE 'recebido'
    END AS status_doacao
FROM (
    SELECT
        nome_canal, id_plataforma, titulo_video, data_hora_vid,
        nick_usuario, id_comentario,
        (
            ('x' ||
            substr(md5(random()::text), 1, 8)
            )::bit(32)::bigint
            / 4294967295.0     -- normaliza para [0,1)
        ) AS r

    FROM Comentario
    ORDER BY RANDOM()
    LIMIT 1000
) c
JOIN generate_series(1, 1) gs ON true;


INSERT INTO DoacaoBitcoin (
    nome_canal, id_plataforma, titulo_video, data_hora_vid,
    nick_usuario, id_comentario, id_doacao, txid
)
SELECT 
    d.nome_canal, d.id_plataforma, d.titulo_video, d.data_hora_vid,
    d.nick_usuario, d.id_comentario, d.id_doacao,
    md5(random()::text || clock_timestamp()::text)
FROM Doacao d
ORDER BY RANDOM()
LIMIT 400;


INSERT INTO DoacaoPaypal (
    nome_canal, id_plataforma, titulo_video, data_hora_vid,
    nick_usuario, id_comentario, id_doacao, id_paypal
)
SELECT 
    d.nome_canal, d.id_plataforma, d.titulo_video, d.data_hora_vid,
    d.nick_usuario, d.id_comentario, d.id_doacao,
    'PAYPAL-' || md5(random()::text)
FROM Doacao d
ORDER BY RANDOM()
LIMIT 400;


INSERT INTO DoacaoCartao (
    nome_canal, id_plataforma, titulo_video, data_hora_vid,
    nick_usuario, id_comentario, id_doacao,
    numero_cartao, bandeira, data_transacao
)
SELECT 
    d.nome_canal, d.id_plataforma, d.titulo_video, d.data_hora_vid,
    d.nick_usuario, d.id_comentario, d.id_doacao,
    LPAD((RANDOM()*1e16)::bigint::text, 16, '0'),
    (ARRAY['Visa','Mastercard','Elo','Amex'])[floor(random()*4)+1],
    NOW() - RANDOM() * INTERVAL '30 days'
FROM Doacao d
ORDER BY RANDOM()
LIMIT 400;


WITH random_doacoes AS (
    SELECT 
        d.nome_canal,
        d.id_plataforma,
        d.titulo_video,
        d.data_hora_vid,
        d.nick_usuario,
        d.id_comentario,
        d.id_doacao,
        ROW_NUMBER() OVER (
            PARTITION BY d.id_plataforma, d.nick_usuario, d.id_comentario
            ORDER BY random()
        ) AS seq_plataforma
    FROM Doacao d
    ORDER BY random()
    LIMIT 400
)
INSERT INTO DoacaoMecanismoPlat (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao, seq_plataforma)
SELECT
    nome_canal,
    id_plataforma,
    titulo_video,
    data_hora_vid,
    nick_usuario,
    id_comentario,
    id_doacao,
    seq_plataforma
FROM random_doacoes;
