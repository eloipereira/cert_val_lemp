@echo off
REM cert_val_lemp v1.0
REM Desenvolvido por: 
REM Eloi Pereira
REM Maj/EngEl
REM LEMP, BA5
REM etpereira@emfa.pt

call config.bat

setlocal EnableDelayedExpansion

set sign="%sign0%"

:MENU
	call :header 0
	set /P choice=" * Escolher opcao e premir ENTER: "
	if %choice%==1 goto CIE_MODE
	if %choice%==2 goto BATCH_MODE
	if %choice%==3 goto CONFIG
	if %choice%==s goto EOF


:CIE_MODE
	call :header 1
	set file=''
	set filename=''
	set CIE=''
	echo Assinante: %sign%
	echo.
	pushd %cert_path%
	echo * Lista de certificados por validar: 
	echo.
	set empty=1
	for /f %%a in ('dir /b /a *.pdf 2^>nul') do (
		set empty=0
		echo  - %%a
	)
	if %empty%==1 (
		echo  - Nao existem certificados por validar
		echo.
		popd
		pause
		goto :MENU
	)
	echo.
	set /P CIE=" * Inserir CIE e premir ENTER (s para sair, 1 para primeiro CIE da lista): "
	if %CIE%==1 (
		echo A procurar primeiro certificado...
		for /f "delims=" %%b in ('dir /a /b *.pdf 2^>nul') do (
			set file=%%~dpnxb
			set filename=%%~nb
			goto start_val
		)
	)
	if %CIE%==s goto MENU 
	for /f "delims=" %%c in ('dir /a /b %CIE%*.pdf 2^>nul') do (
		set file=%%~dpnxc
		set filename=%%~nc
		goto start_val
	)
	popd
	if NOT DEFINED file goto NOTFOUND
	goto CIE_MODE
	:start_val
		pushd %cert_path%
		call :open_pdf !file!
		if %errorlevel% gtr 0 (
			echo ERROR: Nao foi possivel abrir ficheiro !filename!
			popd
			pause
			goto CIE_MODE
			)
		popd
		call :header 1
		echo * Certificado: !filename!
		echo  1 - Validar 
		echo  2 - Stand-by 
		echo  3 - Sair
		echo.
		set choice0=''
		set /P choice0=" * Escolher opcao: "
		if %choice0%==1 goto VALIDAR
		if %choice0%==2 goto STDBY
		if %choice0%==3 goto VAL_UNSUCC
		goto CIE_MODE

:VALIDAR
	echo.
	echo * Insira o CC no leitor
	pause
	pushd %cert_path%
	call :jsign !file!
	popd
	if %errorlevel%==0 goto VAL_SUCC
	if %errorlevel%==1 goto VAL_UNSUCC
	if %errorlevel%==2 goto VAL_UNSUCC
	if %errorlevel%==3 goto VAL_UNSUCC
	if %errorlevel%==4 goto VAL_UNSUCC

:VAL_SUCC
	pushd %output_path%
	for /f "delims=" %%d in ('dir /b !file! 2^>nul') do set output_file=%%~fd
	if NOT DEFINED output_file goto VAL_UNSUCC
	popd
	echo * Feche a janela do certificado e prima ENTER
	pause
	pushd %cert_path%
	move !file! %bin_path%
	if %errorlevel%==0 (
		echo INFO: !filename! VALIDADO COM SUCESSO
	) else (
		echo ERROR: Erro ao eliminar !filename!. Certifique-se que o pdf esta fechado.
		goto VAL_SUCC
	)
	popd
	pause
	goto CIE_MODE
	
:VAL_UNSUCC
	echo ERROR: !filename! NAO VALIDADO e mantido na pasta %cert_path%
	pause
	goto CIE_MODE
 
:STDBY
	echo * Feche a janela do certificado e prima ENTER
	pause
	pushd %cert_path%
	move !file! %standby_path%
	if %errorlevel%==0 (
		echo INFO: !filename! movido para a pasta de stand-by
	) else (
		echo ERROR: Erro ao mover !filename!. Certifique-se que o pdf esta fechado.
		goto STDBY
	)
	popd
	pause
	goto CIE_MODE

:NOTFOUND
	echo ERROR: Certificado do %CIE% NAO FOI ENCONTRADO
	pause
	goto CIE_MODE

:BATCH_MODE
	call :header 2
	echo Assinante: %sign%
	echo.
	echo * Mover certificados para %batch_sign_path%
	echo.
	pause
	cls
	call :header 2
	echo * Lista de certificados por validar em batch: 
	echo.
	pushd %batch_sign_path%
	set empty=1
	for /f %%e in ('dir /b *.pdf 2^>nul') do (
		echo %%e
		set empty=0
	)
	if %empty%==1 (
		echo  - Nao existem certificados por validar em batch
		echo.
		popd
		pause
		goto :MENU
	)
	pause
	for /f %%f in ('dir /b *.pdf 2^>nul') do (
		call :jsign %%f
		if %errorlevel%==0 (
			cls
			pushd %output_path%
			if EXIST %%f ( 
				for /f %%g in ('dir /b %%f') do if %%~zg equ 0 (
					echo ERROR: Ficheiro %%g gerado esta CORRUMPIDO. Remover...
					pause
					del %%g	
				) else (
					:REMOVE_FROM_BATCH
						pushd %batch_sign_path%
						move %%f %bin_path%
						if %errorlevel%==0 (
							echo INFO: Certificado %%~nf VALIDADO COM SUCESSO
							pause
						) else (
							echo ERROR: Erro ao eliminar certificado %%~nf. Certifique-se que o pdf esta fechado.
							goto REMOVE_FROM_BATCH
						)
						popd
				)
			) else (
				cls
				echo ERROR: Certificado %%~nf NAO FOI ASSINADO
				pause
				)
			popd
		) else (
				cls
				echo ERROR: Certificado %%~nf NAO FOI ASSINADO
				pause
				)
		)
	)
	popd
	pause
	goto MENU
	
:CONFIG	
	call :header 3
	echo 1 - Responsavel Tecnico: %sign0%
	echo 2 - Responsavel Qualidade: %sign1% 
	echo 3 - Responsavel Producao:  %sign2%
	echo.
	echo * Assinante actual: %sign%
	echo.
	set /P choice1=" * Alterar: (1 - RT, 2 - RQ, 3 - RP, s - sair)"
		if %choice1%==1 (
			set sign="%sign0%"
			goto CONFIG
		) 
		if %choice1%==2 (
			set sign="p/ %sign1%"
			goto CONFIG
		) 
		if %choice1%==3 (
			set sign="p/ %sign2%"
			goto CONFIG
		) 
		if %choice1%==s goto MENU
	goto MENU
	
:jsign
	echo.
	echo **************************** JSIGN PDF **************************** 
	java -jar "%jsign_path%\JSignPdf.jar" -l %location% -c %contact% -q -kst WINDOWS-MY -llx %llx% -lly %lly% -urx %urx% -ury %ury% -V -pg %page% --l2-text %sign% --render-mode SIGNAME_AND_DESCRIPTION -os "" --disable-modify-content -d %output_path% %~1
	set out=%errorlevel%
	echo *******************************************************************
	echo.
	exit /B %out%

:open_pdf
	echo Opening pdf %~1 
	%pdfReader% %~1
	set out=%errorlevel%
	exit /B %out%
	
:header
	cls
	echo.
	echo ------------------------------------------------------------------
	echo CERT_VAL_LEMP - Software de Validacao de Certificados do LEMP v1.0
	echo ------------------------------------------------------------------
	echo.
	if %~1==0 (
		echo 1 - Validar certificado por CIE
		echo 2 - Validar certificados em batch
		echo 3 - Configuracao
		echo s - Sair
	)
	if %~1==1 (
		echo 1 - Validar certificado por CIE
		echo.
		echo.
		echo.
	)
	if %~1==2 (
		echo.
		echo 2 - Validar certificados em batch
		echo.
		echo.
	)
	if %~1==3 (
		echo.
		echo.
		echo 3 - Configuracao
		echo.
	)
	echo.
	exit /B %errorlevel%

:EOF
