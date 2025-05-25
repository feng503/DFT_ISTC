@echo off
setlocal enabledelayedexpansion

:: 设置默认路径
set src_path=./src/*.v

:: 支持通过参数指定源文件路径
if not "%~1"=="" set src_path=%1

:: 清理旧的 work 文件夹
if exist work (
    rmdir /s /q work > nul
)

:: 获取当前日期和时间
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set year=!datetime:~0,4!
set month=!datetime:~4,2!
set day=!datetime:~6,2!
set hour=!datetime:~8,2!
set minute=!datetime:~10,2!
set second=!datetime:~12,2!
set timestamp=!year!-!month!-!day!_!hour!:!minute!:!second!

:: 创建日志文件并添加时间戳
echo ============================== > log.txt
echo Log generated on: !timestamp! >> log.txt
echo ============================== >> log.txt

:: 创建工作库
vlib work >> log.txt 2>&1 || goto :error
vmap work work >> log.txt 2>&1 || goto :error

:: 编译 Verilog 文件
vlog -sv %src_path% >> log.txt 2>&1 || goto :error
:: 编译完成check
echo Complied process completed successfully. Please wait for running outfile...

:: 运行仿真
set sim_mode=-c
if "%~2"=="interactive" set sim_mode=
vsim %sim_mode% -do "add wave -r *; run -all; delete wave *" test >> log.txt 2>&1 || goto :error

goto :end

:error
echo An error occurred during the process. Please check log.txt for details.
exit /b 1

:end
echo Running process completed successfully. Logs are saved in log.txt.