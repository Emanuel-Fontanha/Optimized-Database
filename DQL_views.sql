-- Nova consulta 2:

    SELECT
        id_usuario,
        total_canais_membro,
        total_desembolsado_mensal
    FROM vw_inscricoes_usuario
    ORDER BY total_desembolsado_mensal DESC;

-- Nova consulta 3:

    SELECT *
    FROM vw_doacoes_por_canal
    WHERE total_doacoes > 0
    ORDER BY total_doacoes DESC;

-- Nova consulta 5:

    SELECT *
    FROM vw_patrocinio_canal
    ORDER BY total_patrocinio DESC;

-- Nova consulta 7:

    SELECT
        nome_canal,
        id_plataforma,
        total_doacoes AS total_recebido
    FROM vw_doacoes_por_canal
    WHERE total_doacoes > 0
    ORDER BY total_doacoes DESC;

-- Nova consulta 8:

    SELECT
        nome_canal,
        id_plataforma,
        faturamento_total
    FROM vw_faturamento_canal
    ORDER BY faturamento_total DESC
    LIMIT 100;
