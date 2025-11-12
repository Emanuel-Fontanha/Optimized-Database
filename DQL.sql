-- Primeira Consulta
SELECT 
    e.nome_empresa AS empresa,
    c.nome AS canal,
    c.id_plataforma AS plataforma,
    p.valor AS valor_patrocinio
FROM Patrocinio p
JOIN Empresa e 
    ON p.id_empresa = e.id_empresa
JOIN Canal c 
    ON p.nome_canal = c.nome 
   AND p.id_plataforma = c.id_plataforma
ORDER BY e.nome_empresa, c.nome;

-- Segunda Consulta
SELECT 
    U.nick AS usuario,
    COUNT(DISTINCT I.nome_canal) AS qtd_canais_membro,
    DATE_TRUNC('month', V.data_hora) AS mes_referencia,
    SUM(D.valor) AS total_desembolsado
FROM 
    Usuario U
    LEFT JOIN Inscricao I 
        ON U.nick = I.nick_membro
    LEFT JOIN Doacao D 
        ON U.nick = D.nick_usuario
    LEFT JOIN Video V 
        ON D.nome_canal = V.nome_canal
        AND D.id_plataforma = V.id_plataforma
        AND D.titulo_video = V.titulo
        AND D.data_hora_vid = V.data_hora
WHERE 
    D.status_doacao = 'recebido'
GROUP BY 
    U.nick,
    DATE_TRUNC('month', V.data_hora)
ORDER BY 
    U.nick,
    mes_referencia;


-- Terceira Consulta
SELECT 
    D.nome_canal,
    D.id_plataforma,
    C.tipo,
    C.nick_streamer,
    SUM(D.valor) AS total_recebido
FROM 
    Doacao D
    JOIN Canal C 
        ON D.nome_canal = C.nome
        AND D.id_plataforma = C.id_plataforma
WHERE 
    D.status_doacao = 'recebido'
GROUP BY 
    D.nome_canal, D.id_plataforma, C.tipo, C.nick_streamer
HAVING 
    SUM(D.valor) > 0
ORDER BY 
    total_recebido DESC;

