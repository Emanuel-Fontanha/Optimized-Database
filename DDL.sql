CREATE TABLE Empresa (
    id_empresa INT PRIMARY KEY,
    nome_empresa VARCHAR(50) NOT NULL,
    nome_fantasia VARCHAR(50)
);

CREATE TABLE Conversao (
    moeda VARCHAR(5) PRIMARY KEY,
    nome_moeda VARCHAR(15) NOT NULL,
    fator_conver_to_dolar NUMERIC(10,4) NOT NULL
);

CREATE TABLE Pais (
    ddi INT PRIMARY KEY,
    nome_pais VARCHAR(50) NOT NULL,
    moeda VARCHAR(10) NOT NULL,

    CONSTRAINT fk_sigla_moeda FOREIGN KEY (moeda)
        REFERENCES Conversao(moeda)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE EmpresaPais (
    id_empresa INT,
    ddi_pais_origem INT,
    id_nacional VARCHAR(50),

    CONSTRAINT fk_empresa_em_pais PRIMARY KEY (id_empresa, ddi_pais_origem),
    FOREIGN KEY (id_empresa) REFERENCES Empresa(id_empresa)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (ddi_pais_origem) REFERENCES Pais(ddi)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Plataforma (
    id_plataforma INT PRIMARY KEY,
    nome_plataforma VARCHAR(50) NOT NULL,
    id_empresa_fund INT,
    id_empresa_respo INT,
    data_fundacao DATE,
    qtd_usuarios INT NOT NULL,

    CONSTRAINT fk_empr_fund_platf FOREIGN KEY (id_empresa_fund)
        REFERENCES Empresa(id_empresa)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT fk_empr_respo_platf FOREIGN KEY (id_empresa_respo)
        REFERENCES Empresa(id_empresa)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE TABLE Usuario (
    nick VARCHAR(50) PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    data_nasc DATE NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    end_postal VARCHAR(150),
    ddi_pais_residencia INT,

    CONSTRAINT fk_pais_usuario FOREIGN KEY (ddi_pais_residencia)
        REFERENCES Pais(ddi)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE TABLE PlataformaUsuario (
    id_plataforma INT,
    nick_usuario VARCHAR(50),
    numero_usuario INT NOT NULL,

    CONSTRAINT pk_usuario_em_plat PRIMARY KEY (id_plataforma, nick_usuario),
    FOREIGN KEY (id_plataforma) REFERENCES Plataforma(id_plataforma)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (nick_usuario) REFERENCES Usuario(nick)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE StreamerPais (
    nick_streamer VARCHAR(50),
    ddi_pais_origem INT,
    nro_passaporte VARCHAR(30) NOT NULL,

    CONSTRAINT pk_streamer_pais PRIMARY KEY (nick_streamer, ddi_pais_origem),
    FOREIGN KEY (nick_streamer) REFERENCES Usuario(nick)
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
    data_inicio DATE,
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
    nick_membro VARCHAR(50),
    nivel INT,

    CHECK (nivel BETWEEN 1 AND 5),
    CONSTRAINT pk_inscricao
        PRIMARY KEY (nome_canal, id_plataforma, nick_membro),
    CONSTRAINT fk_nvl_canal_inscr
        FOREIGN KEY (nome_canal, id_plataforma, nivel)
        REFERENCES NivelCanal(nome_canal, id_plataforma, nivel)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_usuario_inscr FOREIGN KEY (nick_membro)
        REFERENCES Usuario(nick)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Video (
    nome_canal VARCHAR(50),
    id_plataforma INT,
    titulo VARCHAR (50),
    data_hora TIMESTAMP,
    tema VARCHAR(50),
    duracao VARCHAR(10),
    visus_simultaneas INT DEFAULT 0,
    visus_totais INT DEFAULT 0,

    CONSTRAINT pk_video
        PRIMARY KEY (nome_canal, id_plataforma, titulo, data_hora),
    CONSTRAINT fk_canal_video
        FOREIGN KEY (nome_canal, id_plataforma)
        REFERENCES Canal(nome, id_plataforma)
        ON DELETE CASCADE
        ON UPDATE CASCADE
)

CREATE TABLE Colaboracao (
    nome_canal VARCHAR(50),
    id_plataforma INT,
    titulo_video VARCHAR (50),
    data_hora_vid TIMESTAMP,
    nick_streamer VARCHAR(50),

    CONSTRAINT pk_colab
        PRIMARY KEY (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_streamer),
    CONSTRAINT fk_video_colab
        FOREIGN KEY (nome_canal, id_plataforma, titulo_video, data_hora_vid)
        REFERENCES Video(nome_canal, id_plataforma, titulo, data_hora)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_streamer_colab
        FOREIGN KEY (nick_streamer)
        REFERENCES Usuario(nick)
        ON DELETE CASCADE
        ON UPDATE CASCADE
)

CREATE TABLE Comentario (
    nome_canal VARCHAR(50),
    id_plataforma INT,
    titulo_video VARCHAR (50),
    data_hora_vid TIMESTAMP,
    nick_usuario VARCHAR(50),
    id_comentario INT,
    texto VARCHAR(200),
    data_hora_postagem TIMESTAMP,
    is_online BOOLEAN,

    CONSTRAINT pk_comentario
        PRIMARY KEY (nome_canal, id_plataforma, titulo_video, data_hora_vid, id_comentario),
    CONSTRAINT fk_video_comentado
        FOREIGN KEY (nome_canal, id_plataforma, titulo_video, data_hora_vid)
        REFERENCES Video(nome_canal, id_plataforma, titulo, data_hora)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_usuario_coment
        FOREIGN KEY (nick_usuario)
        REFERENCES Usuario(nick)
        ON DELETE CASCADE
        ON UPDATE CASCADE
)

/*
    SOBRE DOAÇÃO: se eu identifico o Comentário, eu já identifico o Vídeo por traceback, não?
    R: sim, identifica. Trazer os dados duplicados de Vídeo e Comentário garante consultas menores e mais simples, porém, requer FKs sólidas para garantir a integridade.
    PERGUNTAR AO BEDO SOBRE NORMALIZAÇÃO - violação da 2FN.
*/

CREATE TABLE Doacao (
    nome_canal VARCHAR(50),
    id_plataforma INT,
    titulo_video VARCHAR (50),
    data_hora_vid TIMESTAMP,
    nick_usuario VARCHAR(50),
    id_comentario INT,
    id_doacao INT,
    valor NUMERIC(10,2) NOT NULL,
    status_doacao VARCHAR(10) NOT NULL,

    CHECK (status_doacao IN ('recusado','recebido','lido')),
    CONSTRAINT pk_doacao
        PRIMARY KEY (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao),
    CONSTRAINT fk_coment_doacao
        FOREIGN KEY (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario)
        REFERENCES Comentario(nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE DoacaoBitcoin (
    nome_canal VARCHAR(50),
    id_plataforma INT,
    titulo_video VARCHAR (50),
    data_hora_vid TIMESTAMP,
    nick_usuario VARCHAR(50),
    id_comentario INT,
    id_doacao INT,
    txid VARCHAR(256) NOT NULL,

    CONSTRAINT pk_doac_bitcoin
        PRIMARY KEY (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao),
    CONSTRAINT fk_doac_bitcoin
        FOREIGN KEY (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao)
        REFERENCES Doacao(nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE DoacaoPaypal (
    nome_canal VARCHAR(50),
    id_plataforma INT,
    titulo_video VARCHAR (50),
    data_hora_vid TIMESTAMP,
    nick_usuario VARCHAR(50),
    id_comentario INT,
    id_doacao INT,
    id_paypal VARCHAR(100) NOT NULL,

    CONSTRAINT pk_doac_paypal
        PRIMARY KEY (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao),
    CONSTRAINT fk_doac_paypal
        FOREIGN KEY (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao)
        REFERENCES Doacao(nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE DoacaoCartao (
    nome_canal VARCHAR(50),
    id_plataforma INT,
    titulo_video VARCHAR (50),
    data_hora_vid TIMESTAMP,
    nick_usuario VARCHAR(50),
    id_comentario INT,
    id_doacao INT,
    numero_cartao VARCHAR(20) NOT NULL,
    bandeira VARCHAR(30) NOT NULL,
    data_transacao TIMESTAMP NOT NULL

    CONSTRAINT pk_doac_cartao
        PRIMARY KEY (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao),
    CONSTRAINT fk_doac_cartao
        FOREIGN KEY (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao)
        REFERENCES Doacao(nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE DoacaoMecanismoPlat (
    nome_canal VARCHAR(50),
    id_plataforma INT,
    titulo_video VARCHAR (50),
    data_hora_vid TIMESTAMP,
    nick_usuario VARCHAR(50),
    id_comentario INT,
    id_doacao INT,
    seq_plataforma INT NOT NULL

    CONSTRAINT pk_doac_mec_plat
        PRIMARY KEY (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao),
    CONSTRAINT fk_doac_mec_plat
        FOREIGN KEY (nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao)
        REFERENCES Doacao(nome_canal, id_plataforma, titulo_video, data_hora_vid, nick_usuario, id_comentario, id_doacao)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
