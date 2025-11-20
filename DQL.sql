------------------------------ primeira consulta ----------------------------
SELECT e.nome_empresa AS empresa, c.nome AS canal, p.valor AS valor_patrocinio
FROM Patrocinio p
    JOIN Empresa e
ON p.id_empresa = e.id_empresa
    JOIN Canal c
ON p.nome_canal = c.nome AND p.id_plataforma = c.id_plataforma
ORDER BY e.nome_empresa, c.nome;


------------------------------ segunda consulta ----------------------------
SELECT
    U.nick AS usuario,
    COUNT(DISTINCT I.nome_canal) AS qtd_canais_membro,
    DATE_TRUNC('month', V.data_hora) AS mes_referencia,
    SUM(D.valor) AS total_desembolsado
FROM Usuario U
        INNER JOIN Inscricao I
                   ON U.nick = I.nick_membro
        LEFT JOIN Doacao D
                  ON U.nick = D.nick_usuario
        LEFT JOIN Video V
                  ON D.nome_canal = V.nome_canal
                      AND D.id_plataforma = V.id_plataforma
                      AND D.titulo_video = V.titulo
                      AND D.data_hora_vid = V.data_hora
WHERE D.status_doacao = 'recebido'
GROUP BY U.nick, DATE_TRUNC('month', V.data_hora)
ORDER BY U.nick, mes_referencia;

------------------------------ terceira consulta ----------------------------
SELECT D.nome_canal, D.id_plataforma, SUM(D.valor) AS total_recebido
FROM Doacao D
        JOIN Canal C
             ON D.nome_canal = C.nome
                 AND D.id_plataforma = C.id_plataforma
WHERE D.status_doacao = 'recebido'
GROUP BY D.nome_canal, D.id_plataforma
HAVING SUM(D.valor) > 0
ORDER BY total_recebido DESC;

------------------------------ quarta consulta ----------------------------
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
SELECT P.nome_canal, P.id_plataforma, SUM(P.valor) AS total_patrocinio
FROM Patrocinio P
GROUP BY P.nome_canal, P.id_plataforma
ORDER BY total_patrocinio DESC
LIMIT :k;

------------------------------ sexta consulta ----------------------------
SELECT D.nome_canal, D.id_plataforma, SUM(D.valor) AS total_recebido
FROM Doacao D
         JOIN Video V
              ON D.nome_canal = V.nome_canal
                  AND D.id_plataforma = V.id_plataforma
                  AND D.titulo_video = V.titulo
                  AND D.data_hora_vid = V.data_hora
WHERE D.status_doacao = 'recebido'
GROUP BY D.nome_canal, D.id_plataforma
ORDER BY total_recebido DESC
LIMIT :k;

------------------------------ setima consulta  ----------------------------
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
ORDER BY total_recebido DESC
LIMIT :k;

------------------------------ Oitava consulta  ----------------------------
SELECT resultado.nome_canal, resultado.id_plataforma, SUM(resultado.faturamento) AS faturamento_total
FROM (

         -- Receita de patrocínios
         SELECT p.nome_canal, p.id_plataforma, SUM(p.valor) AS faturamento
         FROM Patrocinio p
         GROUP BY p.nome_canal, p.id_plataforma

         UNION ALL

         -- Receita de membros (inscrições vigentes)
         SELECT i.nome_canal, i.id_plataforma, SUM(n.valor) AS faturamento
         FROM Inscricao i
                  JOIN NivelCanal n
                       ON i.nome_canal = n.nome_canal
                           AND i.id_plataforma = n.id_plataforma
                           AND i.nivel = n.nivel
         GROUP BY i.nome_canal, i.id_plataforma

         UNION ALL

         -- Receita de doações recebidas
         SELECT d.nome_canal, d.id_plataforma, SUM(d.valor) AS faturamento
         FROM Doacao d
         WHERE d.status_doacao = 'recebido'
         GROUP BY d.nome_canal, d.id_plataforma

     ) AS resultado
GROUP BY resultado.nome_canal, resultado.id_plataforma
ORDER BY faturamento_total DESC
LIMIT 100;

