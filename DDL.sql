CREATE TABLE Empresa (
    id_empresa INT,
    nome_empresa VARCHAR(50) NOT NULL,
    nome_fantasia VARCHAR(50),

    PRIMARY KEY (id_empresa),
    UNIQUE (nome_empresa)
);

CREATE TABLE Plataforma (
    id_plataforma INT,
    nome_plataforma VARCHAR(50) NOT NULL,
    qtd_usuarios INT NOT NULL,
    id_empresa_fund INT,
    id_empresa_respo INT,
    data_fundacao DATE NOT NULL,

    PRIMARY KEY (id_plataforma),
    UNIQUE (nome_plataforma),
    CONSTRAINT fk_empr_fund_platf FOREIGN KEY (id_empresa_fund)
        REFERENCES Empresa(id_empresa)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT fk_empr_respo_platf FOREIGN KEY (id_empresa_respo)
        REFERENCES Empresa(id_empresa)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE TABLE Conversao (
    id_moeda INT, --NOVO
    sigla_moeda VARCHAR(5),
    nome_moeda VARCHAR(30) NOT NULL,
    fator_conver_to_dolar NUMERIC(10,4) NOT NULL,

    UNIQUE (sigla_moeda),
    CHECK (fator_conver_to_dolar > 0),
    PRIMARY KEY (id_moeda)
);

CREATE TABLE Pais (
    ddi INT,
    nome_pais VARCHAR(50) NOT NULL,
    id_moeda INT NOT NULL, -- removido a sigla, já que temos um ID artificial

    CHECK (ddi > 0),
    PRIMARY KEY (ddi),
    UNIQUE (nome_pais),
    CONSTRAINT fk_pais_moeda FOREIGN KEY (id_moeda)
        REFERENCES Conversao(id_moeda)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Usuario (
    id_usuario BIGINT, --NOVO
    nick VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    data_nasc DATE NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    end_postal VARCHAR(150),
    ddi_pais_residencia INT,

    UNIQUE (email),
    UNIQUE (telefone),
    UNIQUE (nick),
    PRIMARY KEY (id_usuario, nick),
    CONSTRAINT fk_pais_usuario FOREIGN KEY (ddi_pais_residencia)
        REFERENCES Pais(ddi)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE TABLE PlataformaUsuario (
    id_plataforma INT,
    id_usuario BIGINT,
    numero_usuario INT NOT NULL,
    nick_usuario VARCHAR(50) NOT NULL,

    CONSTRAINT pk_usuario_em_plat PRIMARY KEY (id_usuario, id_plataforma),
    FOREIGN KEY (id_plataforma) REFERENCES Plataforma(id_plataforma)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_usuario_em_plat FOREIGN KEY (id_usuario, nick_usuario)
        REFERENCES Usuario(id_usuario, nick)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- trigger function 01: fn_trg_atualizar_qtd_usuarios()

    CREATE OR REPLACE FUNCTION fn_trg_atualizar_qtd_usuarios()
    RETURNS TRIGGER AS $$
    BEGIN
        UPDATE Plataforma p
        SET qtd_usuarios = (
            SELECT COUNT(*)
            FROM PlataformaUsuario pu
            WHERE pu.id_plataforma = p.id_plataforma
        )
        WHERE p.id_plataforma = COALESCE(NEW.id_plataforma, OLD.id_plataforma);

        RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;


-- trigger definition 01: trg_atualizar_qtd_usuarios

    CREATE TRIGGER trg_atualizar_qtd_usuarios
    AFTER INSERT OR DELETE ON PlataformaUsuario
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_atualizar_qtd_usuarios();


CREATE TABLE StreamerPais (
    id_streamer BIGINT,
    ddi_pais_origem INT,
    nick_streamer VARCHAR(50),
    nro_passaporte VARCHAR(30) NOT NULL,

    CONSTRAINT pk_streamer_pais PRIMARY KEY (id_streamer, ddi_pais_origem),
    CONSTRAINT unq_streamer_pais UNIQUE (ddi_pais_origem, nro_passaporte),
    CONSTRAINT fk_streamer_pais FOREIGN KEY (id_streamer, nick_streamer)
        REFERENCES Usuario(id_usuario, nick)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (ddi_pais_origem) REFERENCES Pais(ddi)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE EmpresaPais (
    id_empresa INT,
    ddi_pais_origem INT,
    id_nacional VARCHAR(50),

    PRIMARY KEY (id_empresa, ddi_pais_origem),
    UNIQUE (ddi_pais_origem, id_nacional),
    FOREIGN KEY (id_empresa) REFERENCES Empresa(id_empresa)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (ddi_pais_origem) REFERENCES Pais(ddi)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Canal (
    nome VARCHAR(50),
    id_plataforma INT,
    nick_streamer VARCHAR(50),
    tipo VARCHAR(7),
    data_inicio DATE NOT NULL,
    descricao VARCHAR(200),
    qtd_visualizacoes INT DEFAULT 0,

    CHECK (tipo IN ('privado','publico','misto')),
    CONSTRAINT pk_canal PRIMARY KEY (nome, id_plataforma),
    CONSTRAINT fk_plataforma_canal FOREIGN KEY (id_plataforma)
        REFERENCES Plataforma(id_plataforma)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_streamer_canal FOREIGN KEY (nick_streamer)
        REFERENCES Usuario(nick)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE NivelCanal (
    nome_canal VARCHAR(50),
    id_plataforma INT,
    nivel INT,
    nome_nivel VARCHAR(20) NOT NULL,
    valor NUMERIC(10,2) NOT NULL,
    gif VARCHAR(200) NOT NULL,
    
    CHECK (nivel BETWEEN 1 AND 5),
    CONSTRAINT pk_nivel_canal PRIMARY KEY (nome_canal, id_plataforma, nivel),
    CONSTRAINT unq_nome_nvl_canal UNIQUE (nome_canal, id_plataforma, nome_nivel),
    CONSTRAINT fk_nivel_canal FOREIGN KEY (nome_canal, id_plataforma)
        REFERENCES Canal(nome, id_plataforma)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Patrocinio (
    id_empresa INT,
    nome_canal VARCHAR(50),
    id_plataforma INT,
    valor NUMERIC(10,2) NOT NULL,

    CHECK (valor > 0),
    CONSTRAINT pk_patrocinio PRIMARY KEY (id_empresa, nome_canal, id_plataforma),
    CONSTRAINT fk_empresa_patrocinadora FOREIGN KEY (id_empresa)
        REFERENCES Empresa(id_empresa)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_canal_patrocinado FOREIGN KEY (nome_canal, id_plataforma)
        REFERENCES Canal(nome, id_plataforma)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Inscricao (
    nome_canal VARCHAR(50),
    id_plataforma INT,
    nick_membro VARCHAR(50) NOT NULL,
    id_usuario BIGINT,
    nivel INT NOT NULL,

    CHECK (nivel BETWEEN 1 AND 5),
    CONSTRAINT pk_inscricao
        PRIMARY KEY (nome_canal, id_plataforma, id_usuario),
    CONSTRAINT fk_nvl_canal_inscr
        FOREIGN KEY (nome_canal, id_plataforma, nivel)
        REFERENCES NivelCanal(nome_canal, id_plataforma, nivel)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_usuario_inscr FOREIGN KEY (nick_membro, id_usuario)
        REFERENCES Usuario(nick, id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Video (
    id_video BIGINT, -- NOVO
    nome_canal VARCHAR(50) NOT NULL,
    id_plataforma INT,
    titulo VARCHAR (50),
    data_hora TIMESTAMP,
    tema VARCHAR(50),
    duracao VARCHAR(10),
    visus_simultaneas INT DEFAULT 0,
    visus_totais INT DEFAULT 0,

    CONSTRAINT unq_titulo UNIQUE (nome_canal, id_plataforma, titulo),
    CONSTRAINT pk_video
        PRIMARY KEY (id_plataforma, id_video), -- NOVO
    CONSTRAINT fk_canal_video
        FOREIGN KEY (nome_canal, id_plataforma)
        REFERENCES Canal(nome, id_plataforma)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- trigger function 02: fn_trg_atualizar_qtd_visualizacoes()

    CREATE OR REPLACE FUNCTION fn_trg_atualizar_qtd_visualizacoes()
    RETURNS TRIGGER AS $$
    DECLARE
        canal_nome TEXT;
        plataforma_id INT;
    BEGIN
        IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
            canal_nome := NEW.nome_canal;
            plataforma_id := NEW.id_plataforma;
        ELSIF TG_OP = 'DELETE' THEN
            canal_nome := OLD.nome_canal;
            plataforma_id := OLD.id_plataforma;
        END IF;

        UPDATE Canal c
        SET qtd_visualizacoes = (
            SELECT COALESCE(SUM(v.qtd_visualizacoes),0)
            FROM Video v
            WHERE v.nome_canal = c.nome_canal
                AND v.id_plataforma = c.id_plataforma
        )
        WHERE c.nome_canal = canal_nome 
            AND c.id_plataforma = plataforma_id;

        RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;


-- trigger definition 02: trg_atualizar_qtd_visualizacoes

    CREATE TRIGGER trg_atualizar_qtd_visualizacoes
    AFTER INSERT OR UPDATE OR DELETE ON Video
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_atualizar_qtd_visualizacoes();


CREATE TABLE Colaboracao (
    id_video BIGINT, -- NOVO
    id_plataforma INT,
    nick_streamer VARCHAR(50),

    CONSTRAINT pk_colab
        PRIMARY KEY (id_video, id_plataforma, nick_streamer), -- NOVO
    CONSTRAINT fk_video_colab -- NOVO
        FOREIGN KEY (id_plataforma, id_video)
        REFERENCES Video(id_plataforma, id_video)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_streamer_colab
        FOREIGN KEY (nick_streamer)
        REFERENCES Usuario(nick)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Comentario (
    id_comentario BIGINT,
    id_plataforma INT,
    id_video BIGINT, -- NOVO
    nick_usuario VARCHAR(50),
    texto VARCHAR(200) NOT NULL,
    data_hora_postagem TIMESTAMP NOT NULL,
    is_online BOOLEAN,

    CONSTRAINT pk_comentario
        PRIMARY KEY (id_comentario, id_plataforma, id_video, nick_usuario), -- NOVO
    CONSTRAINT fk_video_comentado -- NOVO
        FOREIGN KEY (id_plataforma, id_video)
        REFERENCES Video(id_plataforma, id_video)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_usuario_coment
        FOREIGN KEY (nick_usuario)
        REFERENCES Usuario(nick)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Doacao (
    id_doacao BIGINT,
    id_comentario BIGINT,
    id_plataforma INT,
    id_video BIGINT, -- NOVO
    nick_usuario VARCHAR(50),
    valor NUMERIC(10,2) NOT NULL,
    status_doacao VARCHAR(10) NOT NULL,

    CHECK (status_doacao IN ('recusado','recebido','lido')),
    CONSTRAINT pk_doacao
        PRIMARY KEY (id_doacao, id_comentario, id_plataforma, id_video, nick_usuario),
    CONSTRAINT fk_coment_doacao
        FOREIGN KEY (id_comentario, id_plataforma, id_video, nick_usuario)
        REFERENCES Comentario(id_comentario, id_plataforma, id_video, nick_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE DoacaoBitcoin (
    id_doacao BIGINT,
    id_comentario BIGINT,
    id_plataforma INT,
    id_video BIGINT, -- NOVO
    nick_usuario VARCHAR(50),
    txid VARCHAR(256) NOT NULL,

    UNIQUE (txid),
    CONSTRAINT pk_doacao_bictoin
        PRIMARY KEY (id_doacao, id_comentario, id_plataforma, id_video, nick_usuario),
    CONSTRAINT fk_doacao_bitcoin
        FOREIGN KEY (id_doacao, id_comentario, id_plataforma, id_video, nick_usuario)
        REFERENCES Doacao(id_doacao, id_comentario, id_plataforma, id_video, nick_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE DoacaoPaypal (
    id_doacao BIGINT,
    id_comentario BIGINT,
    id_plataforma INT,
    id_video BIGINT, -- NOVO
    nick_usuario VARCHAR(50),
    id_paypal VARCHAR(100) NOT NULL,

    UNIQUE (id_paypal),
    CONSTRAINT pk_doacao_paypal
        PRIMARY KEY (id_doacao, id_comentario, id_plataforma, id_video, nick_usuario),
    CONSTRAINT fk_doacao_paypal
        FOREIGN KEY (id_doacao, id_comentario, id_plataforma, id_video, nick_usuario)
        REFERENCES Doacao(id_doacao, id_comentario, id_plataforma, id_video, nick_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE DoacaoCartao (
    id_doacao BIGINT,
    id_comentario BIGINT,
    id_plataforma INT,
    id_video BIGINT, -- NOVO
    nick_usuario VARCHAR(50),
    numero_cartao VARCHAR(20) NOT NULL,
    bandeira VARCHAR(30) NOT NULL,
    data_transacao TIMESTAMP NOT NULL,

    CONSTRAINT pk_doacao_cartao
        PRIMARY KEY (id_doacao, id_comentario, id_plataforma, id_video, nick_usuario),
    CONSTRAINT fk_doacao_cartao
        FOREIGN KEY (id_doacao, id_comentario, id_plataforma, id_video, nick_usuario)
        REFERENCES Doacao(id_doacao, id_comentario, id_plataforma, id_video, nick_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE DoacaoMecanismoPlat (
    id_doacao BIGINT,
    id_comentario BIGINT,
    id_plataforma INT,
    id_video BIGINT, -- NOVO
    nick_usuario VARCHAR(50),
    seq_plataforma INT NOT NULL,

    UNIQUE (seq_plataforma),
    CONSTRAINT pk_doacao_mec_plat
        PRIMARY KEY (id_doacao, id_comentario, id_plataforma, id_video, nick_usuario),
    CONSTRAINT fk_doacao_mec_plat
        FOREIGN KEY (id_doacao, id_comentario, id_plataforma, id_video, nick_usuario)
        REFERENCES Doacao(id_doacao, id_comentario, id_plataforma, id_video, nick_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
