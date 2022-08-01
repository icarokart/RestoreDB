/*
-----------------------------------------------------------------------
Data de Criação: 19/07/2022
Nome do Objeto: sp_Cria_Registro_Backup
Autor: Ícaro
----------------------------------------------------------------------
*/

Use [Master]
Go

If Exists (Select 1 From Sysobjects Where Id = Object_Id('Dbo.[sp_Cria_Registro_Backup]'))
     Drop Procedure Dbo.sp_Cria_Registro_Backup
Go

Create Procedure Dbo.sp_Cria_Registro_Backup(
	@Tipo_Banco Char,
	@Dt_Midia_Bkp Varchar(30),
	@Sigla_Cliente Varchar(10),
	@Observacoes Varchar(500)
)
As
	Begin

		Declare
			@Dt_Restauracao Datetime,
			@Tp_Bd Varchar(10),
			@Sql Nvarchar(500),
			@Instancia Nvarchar(50),
			@Versao_Desktop Varchar(12),
			@Versao_Bd Varchar(12),
			@Bd_Cliente Varchar(50)

		Set @Dt_Restauracao = (Select Getdate())
		Set @Tp_Bd = (Select Case Upper(@Tipo_Banco) 
								When 'D' Then 'Dados' 
								When 'L' Then 'Log' 
								When 'B' Then 'Binários'
							 End
					 )
		
		Set @Sigla_Cliente = Upper(@Sigla_Cliente)
		Set @Instancia = Convert(Nvarchar(50), Serverproperty('Servername'))
		Set @Bd_Cliente = (select NOME_BANCO from PARAMETROS_RESTORE where CLIENTE = @Sigla_Cliente)
		Set @Bd_Cliente = Upper(@Bd_Cliente)


		--se ainda nao houver nenhum registro do cliente, cria um novo
		If Not Exists(Select 1 From Suporte_Registro_Backup Where Cliente = @Sigla_Cliente)
			Begin
				Insert [Dbo].[Suporte_Registro_Backup]
					 ([Cliente]
					, [Data_Restauracao]
					, [Data_Midia_Backup]
					, [Tipo_Banco]
					, [Instancia_Atual]
					, [Nome_Banco]
					, [Observacoes]
					, [Versao_Desktop]
					, [Versao_Bd])

				Values(@Sigla_Cliente
					, @Dt_Restauracao
					, @Dt_Midia_Bkp
					, @Tp_Bd
					, @Instancia
					, @Bd_Cliente
					, @Observacoes
					, Null
					, Null)
			End

		--cria um novo registro para o mesmo cliente caso já tenha algum banco de tipo diferente
		If Exists(Select 1 From Suporte_Registro_Backup Where Cliente = @Sigla_Cliente and Tipo_Banco <> @Tp_Bd)
			Begin
				Insert[Dbo].[Suporte_Registro_Backup]
					 ([Cliente]
					, [Data_Restauracao]
					, [Data_Midia_Backup]
					, [Tipo_Banco]
					, [Instancia_Atual]
					, [Nome_Banco]
					, [Observacoes]
					, [Versao_Desktop]
					, [Versao_Bd])

			    Values(@Sigla_Cliente
					, @Dt_Restauracao
					, @Dt_Midia_Bkp
					, @Tp_Bd
					, @Instancia
					, @Bd_Cliente
					, @Observacoes
					, Null
					, Null)
			End

		--atualiza as informações caso já haja um registro do mesmo cliente e do mesmo tipo de banco
		If Exists(Select 1 From Suporte_Registro_Backup Where Cliente = @Sigla_Cliente and Tipo_Banco = @Tp_Bd)
			Begin
				Update Suporte_Registro_Backup
				Set [Cliente] = @Sigla_Cliente
				, [Data_Restauracao] = @Dt_Restauracao
				, [Data_Midia_Backup] = @Dt_Midia_Bkp
				, [Tipo_Banco] = @Tp_Bd
				, [Instancia_Atual] = @Instancia
				, [Nome_Banco] = @Bd_Cliente
				, [Observacoes] = @Observacoes
				, [Versao_Desktop] = Null
				, [Versao_Bd] = Null
				From [Master].Dbo.Suporte_Registro_Backup Srb
				Where Srb.Cliente = @Sigla_Cliente
					And Srb.Tipo_Banco = @Tp_Bd
			End

	End
Go







