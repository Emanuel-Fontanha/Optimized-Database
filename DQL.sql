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
