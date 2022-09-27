/*
-----------------------------------------------------------------------
Data de Criação: 19/07/2022
Nome do Objeto: sp_OBTER_NOME_ARQUIVO_LOGICO_BACKUP
Autor: Ícaro

Alterações:
	[Ícaro - 04/09/2022] => Procedimento movido para um BD próprio

	[Ícaro - 27/09/2022] => Alterado o tipo da tabela criada para uma tabela temporaria, devido à conflitos caso mais de uma pessoa executasse o procedimento ao mesmo tempo.


----------------------------------------------------------------------
*/

If Exists (Select 1 From Sysobjects Where Id = Object_Id('dbo.[sp_OBTER_NOME_ARQUIVO_LOGICO_BACKUP]'))
     Drop Procedure dbo.sp_OBTER_NOME_ARQUIVO_LOGICO_BACKUP
Go

Create Procedure dbo.sp_OBTER_NOME_ARQUIVO_LOGICO_BACKUP
(
     @DIRETORIO_ARQ_BAK NVARCHAR(360),
	 @SIGLA_CLIENTE VARCHAR(20)
) As
Begin
     Set NoCount On;

	 DECLARE
			@NOME_ARQ_LOGICO_DATA VARCHAR(100),
			@NOME_ARQ_LOGICO_LOG VARCHAR(100),
			@TIPO_MIDIA TINYINT = 1, -- 1: DISK // 2: URL
			@SQL_CREATE_TABLE NVARCHAR(MAX)

     
	 SET @SQL_CREATE_TABLE = N' create table #tab_RESTORE_FILELISTONLY (
													  nome_logico varchar(50)
													, nome_fisico varchar(500)
													, tipo_banco char
													, grupo_arquivo varchar(50)
													, tamanho BIGint
													, tamanho_max BIGINT
													, id_arquivo int
													, createLSN int
													, dropLSN int
													, id_unico uniqueidentifier
													, read_only_LSN int
													, read_write_LSN int
													, tamanho_backup BIGINT
													, source_block_size BIGint
													, file_group_id varchar(50)
													, log_group_id varchar(50)
													, differential_base_LSN VARCHAR(100)
													, differential_base_GUID varchar(100)
													, is_read_only int
													, is_present int
													, tde_thumbprint varchar(50)
													, snapshot_url varchar(50)
													   )'

	 EXEC SP_EXECUTESQL @SQL_CREATE_TABLE

	 IF (@TIPO_MIDIA = 1)
	 BEGIN
		 INSERT #tab_RESTORE_FILELISTONLY
		 EXEC [REGISTRO_RESTORE_BD]..SP_PROC_RESTORE_FILELISTONLY  @DIRETORIO_ARQ_BAK
	 END

	 ELSE IF (@TIPO_MIDIA = 2)
	 BEGIN
		INSERT #tab_RESTORE_FILELISTONLY
		EXEC [REGISTRO_RESTORE_BD]..SP_PROC_RESTORE_FILELISTONLY  @DIRETORIO_ARQ_BAK
	 END

	 --GUARDANDO O NOME DO ARQUIVO LÓGICO DE DADOS
	 BEGIN
		SET @NOME_ARQ_LOGICO_DATA = (SELECT TOP 1 NOME_LOGICO
									 FROM #tab_RESTORE_FILELISTONLY
									 WHERE TIPO_BANCO = 'D')

		UPDATE [REGISTRO_RESTORE_BD]..PARAMETROS_RESTORE
		SET NOME_LOGICO_DADOS = @NOME_ARQ_LOGICO_DATA
		WHERE CLIENTE = @SIGLA_CLIENTE
	 END

	 --GUARDANDO O NOME DO ARQUIVO LÓGICO DE LOG
	 BEGIN
		SET @NOME_ARQ_LOGICO_LOG = (SELECT TOP 1 NOME_LOGICO
									 FROM #tab_RESTORE_FILELISTONLY
									 WHERE TIPO_BANCO = 'L')

		UPDATE [REGISTRO_RESTORE_BD]..PARAMETROS_RESTORE
		SET NOME_LOGICO_LOG = @NOME_ARQ_LOGICO_LOG
		WHERE CLIENTE = @SIGLA_CLIENTE
	 END
		
	 BEGIN
		DROP TABLE #tab_RESTORE_FILELISTONLY
	 END
   
     Set NoCount Off;
End
Go
