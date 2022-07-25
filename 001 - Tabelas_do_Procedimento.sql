USE [master]
GO

CREATE TABLE [dbo].[PARAMETROS_RESTORE](
	[COD_CLIENTE] [int] IDENTITY(1,1) NOT NULL,
	[TIPO_BANCO] [varchar](15) NULL,
	[CLIENTE] [varchar](50) NOT NULL,
	[DIRETORIO_MIDIA] [nvarchar](500) NULL,
	[DIRETORIO_BANCO] [nvarchar](500) NULL,
	[NOME_ARQ_DADOS] [varchar](50) NULL,
	[NOME_ARQ_LOG] [varchar](50) NULL,
	[NOME_BANCO] [varchar](50) NULL
)
GO

CREATE TABLE [dbo].[SUPORTE_REGISTRO_BACKUP](
	[CLIENTE] [varchar](10) NOT NULL,
	[DATA_RESTAURACAO] [datetime] NOT NULL,
	[DATA_MIDIA_BACKUP] [datetime] NOT NULL,
	[TIPO_BANCO] [varchar](10) NOT NULL,
	[INSTANCIA_ATUAL] [varchar](50) NOT NULL,
	[NOME_BANCO] [varchar](50) NULL,
	[OBSERVACOES] [varchar](255) NULL,
	[VERSAO_DESKTOP] [varchar](15) NULL,
	[VERSAO_BD] [varchar](15) NULL
)
GO
