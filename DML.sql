---------------------------------------------------------------------------------------

--  USAMOS UM GERADOR AUTOMÁTICO PORQUE INSERIR MANUALMENTE AS TUPLAS SERIA INVIÁVEL --

---------------------------------------------------------------------------------------

INSERT INTO Empresa (id_empresa, nome_empresa, nome_fantasia)
SELECT i,
    'Empresa_' || i,
    'Fantasia_' || i
FROM generate_series(1,100) AS s(i);

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO Conversao (sigla_moeda, nome_moeda, fator_conver_to_dolar)
SELECT 'M' || i,
    'Moeda_' || i,
    ROUND((0.5 + random()*5)::numeric,4)
FROM generate_series(1,100) AS s(i);

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO Pais (ddi, nome_pais, sigla_moeda)
SELECT i,
    'Pais_' || i,
    'M' || i
FROM generate_series(1,100) AS s(i);

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO EmpresaPais (id_empresa, ddi_pais_origem, id_nacional)
SELECT e.id_empresa, p.ddi, 'IDNAC_' || e.id_empresa || '_' || p.ddi
FROM Empresa e
JOIN Pais p ON p.ddi = e.id_empresa;

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO Plataforma (id_plataforma, nome_plataforma, id_empresa_fund, id_empresa_respo, data_fundacao, qtd_usuarios)
SELECT i,
    'Plataforma_' || i,
    (i % 100) + 1,
    ((i+50) % 100) + 1,
    date '2015-01-01' + (i || ' days')::interval,
    (random()*10000)::int
FROM generate_series(1,100) AS s(i);

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO Usuario (nick, email, data_nasc, telefone, end_postal, ddi_pais_residencia)
SELECT 'usuario_' || i,
    'usuario_' || i || '@teste.com',
    date '1980-01-01' + ((i*30) || ' days')::interval,
    '55' || (100000000+i),
    'Endereco ' || i,
    (i % 100) + 1
FROM generate_series(1,100) AS s(i);

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

WITH usuarios_num AS (
    SELECT nick, ROW_NUMBER() OVER () AS numero_usuario
    FROM Usuario
)
INSERT INTO PlataformaUsuario (id_plataforma, nick_usuario, numero_usuario)
SELECT p.id_plataforma, u.nick, u.numero_usuario
FROM Plataforma p
JOIN usuarios_num u ON u.numero_usuario = p.id_plataforma;

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO StreamerPais (nick_streamer, ddi_pais_origem, nro_passaporte)
SELECT u.nick, u.ddi_pais_residencia, 'PASS_' || u.nick
FROM Usuario u
LIMIT 100;

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO Canal (nome, id_plataforma, nick_streamer, tipo, data_inicio, descricao, qtd_visualizacoes)
SELECT 'Canal_' || i,
    (i % 100) + 1,
    'usuario_' || ((i % 100) + 1),
    CASE WHEN i%3=0 THEN 'privado' WHEN i%3=1 THEN 'publico' ELSE 'misto' END,
    date '2020-01-01' + (i || ' days')::interval,
    'Descricao do canal ' || i,
    (random()*100000)::int
FROM generate_series(1,100) AS s(i);

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO NivelCanal (nome_canal, id_plataforma, nivel, nome_nivel, valor, gif)
SELECT c.nome, c.id_plataforma, n, 'Nivel_' || n, ROUND((random()*100)::numeric,2), 'http://gif.com/' || n
FROM Canal c
CROSS JOIN generate_series(1,5) AS s(n);


---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO Patrocinio (id_empresa, nome_canal, id_plataforma, valor)
SELECT ((i-1) % 100) + 1, c.nome, c.id_plataforma, ROUND((random()*10000)::numeric,2)
FROM Canal c
CROSS JOIN generate_series(1,1) AS s(i);

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO Inscricao (nome_canal, id_plataforma, nick_membro, nivel)
SELECT c.nome, c.id_plataforma, u.nick, ((i-1)%5 + 1)
FROM Canal c
JOIN Usuario u ON u.nick = 'usuario_' || ((c.id_plataforma % 100) + 1)
CROSS JOIN generate_series(1,1) AS s(i);

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO Video (nome_canal, id_plataforma, titulo, data_hora, tema, duracao, visus_simultaneas, visus_totais)
SELECT c.nome, c.id_plataforma, 'Video_' || i,
    now() - ((i*10) || ' days')::interval,
    'Tema_' || i,
    ((i%60)+1) || 'min',
    (random()*1000)::int,
    (random()*5000)::int
FROM Canal c
CROSS JOIN generate_series(1,1) AS s(i);

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO Colaboracao (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_streamer)
SELECT v.nome_canal, v.id_plataforma, v.titulo, v.data_hora, s.nick_streamer
FROM Video v
JOIN StreamerPais s ON s.ddi_pais_origem = ((v.id_plataforma % 100)+1)
LIMIT 100;

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO Comentario (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, texto, data_hora_postagem, is_online)
SELECT v.nome_canal, v.id_plataforma, v.titulo, v.data_hora, u.nick, i, 'Comentario ' || i,
    now() - ((i*2) || ' days')::interval,
    (i%2=0)
FROM Video v
JOIN Usuario u ON u.nick = 'usuario_' || ((v.id_plataforma % 100)+1)
CROSS JOIN generate_series(1,5) AS s(i);

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO Doacao (nome_canal, id_plataforma, titulo_video, data_hora_vid,
                    nick_usuario, id_comentario, id_doacao, valor, status_doacao)
SELECT c.nome_canal, c.id_plataforma, c.titulo_video,c.data_hora_vid, c.nick_usuario,c.id_comentario,
    ROW_NUMBER() OVER (PARTITION BY c.id_comentario ORDER BY random()) AS id_doacao,
    ROUND((random()*1000)::numeric,2),
    CASE WHEN random() < 0.33 THEN 'recusado'
        WHEN random() < 0.66 THEN 'recebido'
        ELSE 'lido'
    END AS status_doacao
FROM Comentario c
CROSS JOIN generate_series(1,3) AS s(i);


---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO DoacaoBitcoin (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao, txid)
SELECT d.nome_canal, d.id_plataforma, d.titulo_video, d.data_hora_vid, d.nick_usuario, d.id_comentario, d.id_doacao,
    md5(random()::text)
FROM Doacao d
LIMIT 100;

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO DoacaoPaypal (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao, id_paypal)
SELECT d.nome_canal, d.id_plataforma, d.titulo_video, d.data_hora_vid, d.nick_usuario, d.id_comentario, d.id_doacao,
    'paypal_' || d.id_doacao
FROM Doacao d
LIMIT 100;

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO DoacaoCartao (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao, numero_cartao, bandeira, data_transacao)
SELECT d.nome_canal, d.id_plataforma, d.titulo_video, d.data_hora_vid, d.nick_usuario, d.id_comentario, d.id_doacao,
    '400000000000' || (d.id_doacao % 1000), 'Visa', now()
FROM Doacao d
LIMIT 100;

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

INSERT INTO DoacaoMecanismoPlat (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao, seq_plataforma)
SELECT d.nome_canal, d.id_plataforma, d.titulo_video, d.data_hora_vid, d.nick_usuario, d.id_comentario, d.id_doacao,
    d.id_doacao
FROM Doacao d
LIMIT 100;
