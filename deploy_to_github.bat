@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

:: ============================================================
::  GitHub Pages 자동 배포 스크립트
::  대상: dkunyoon.github.io/Market-Research/
::  파일명 형식: yymmdd_US Treasury Market Daily.html
:: ============================================================

title GitHub Pages 자동 배포

echo.
echo  ┌─────────────────────────────────────────┐
echo  │   GitHub Pages 자동 배포 스크립트        │
echo  │   dkunyoon.github.io/Market-Research/   │
echo  └─────────────────────────────────────────┘
echo.

:: ── 설정 영역 ─────────────────────────────────────────────
set REPO_URL=https://github.com/dkunyoon/Market-Research.git
set REPO_DIR=%USERPROFILE%\Market-Research
set BRANCH=main
set FILE_SUFFIX=_US Treasury Market Daily.html
:: ──────────────────────────────────────────────────────────

:: Git 설치 확인
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo  [오류] Git이 설치되어 있지 않습니다.
    echo         https://git-scm.com 에서 설치 후 재실행하세요.
    pause
    exit /b 1
)

:: ── 날짜 입력 ─────────────────────────────────────────────
echo  배포할 리포트 날짜를 입력하세요.
echo  (예: 2026-03-12  /  20260312  /  260312  모두 가능)
echo.
set /p RAW_DATE=  날짜 입력: 

:: 입력값에서 구분자 제거 (하이픈·슬래시·점·공백)
set CLEAN_DATE=!RAW_DATE:-=!
set CLEAN_DATE=!CLEAN_DATE:/=!
set CLEAN_DATE=!CLEAN_DATE:.=!
set CLEAN_DATE=!CLEAN_DATE: =!

:: 길이 계산
set DATE_LEN=0
for /l %%i in (0,1,11) do (
    if not "!CLEAN_DATE:~%%i,1!"=="" set /a DATE_LEN=%%i+1
)

:: yymmdd 변환
if !DATE_LEN!==8 (
    set YYMMDD=!CLEAN_DATE:~2,6!
) else if !DATE_LEN!==6 (
    set YYMMDD=!CLEAN_DATE!
) else (
    echo.
    echo  [오류] 날짜 형식을 인식할 수 없습니다: !RAW_DATE!
    echo         예시: 2026-03-12 / 20260312 / 260312
    pause
    exit /b 1
)

:: 숫자만 포함되어 있는지 체크
echo !YYMMDD!| findstr /r "[^0-9]" >nul
if %errorlevel%==0 (
    echo.
    echo  [오류] 날짜에 숫자 외 문자가 포함되어 있습니다: !YYMMDD!
    pause
    exit /b 1
)

set TARGET_FILE=!YYMMDD!!FILE_SUFFIX!
set SCRIPT_DIR=%~dp0

echo.
echo  [1/5] 파일 확인 중...
echo        └─ 찾는 파일명: !TARGET_FILE!

if not exist "!SCRIPT_DIR!!TARGET_FILE!" (
    echo.
    echo  [오류] 파일을 찾을 수 없습니다.
    echo         경로: !SCRIPT_DIR!!TARGET_FILE!
    echo.
    echo  같은 폴더 내 HTML 파일 목록:
    dir /b "!SCRIPT_DIR!*.html" 2>nul || echo         (HTML 파일 없음)
    echo.
    pause
    exit /b 1
)

echo        └─ 확인 완료!
echo.

:: 리포지토리 클론 또는 Pull
if exist "%REPO_DIR%\.git" (
    echo  [2/5] 로컬 리포지토리 업데이트 중...
    cd /d "%REPO_DIR%"
    git pull origin %BRANCH%
    if %errorlevel% neq 0 (
        echo  [오류] git pull 실패.
        pause
        exit /b 1
    )
) else (
    echo  [2/5] 리포지토리 최초 클론 중...
    git clone %REPO_URL% "%REPO_DIR%"
    if %errorlevel% neq 0 (
        echo  [오류] git clone 실패. URL 또는 인증을 확인하세요.
        pause
        exit /b 1
    )
    cd /d "%REPO_DIR%"
)

echo.
echo  [3/5] 파일 복사 중...
copy /Y "!SCRIPT_DIR!!TARGET_FILE!" "%REPO_DIR%\" > nul
echo        └─ 복사 완료

:: index.html 항상 최신 리포트로 갱신
echo.
echo  [4/5] index.html 갱신 중...
(
    echo ^<!DOCTYPE html^>
    echo ^<html lang="ko"^>
    echo ^<head^>
    echo ^<meta charset="UTF-8"^>
    echo ^<meta http-equiv="refresh" content="0; url=./!TARGET_FILE!"^>
    echo ^<title^>Market Research^</title^>
    echo ^</head^>
    echo ^<body^>
    echo ^<script^>window.location.href="./!TARGET_FILE!"^</script^>
    echo ^<p^>리다이렉트 중... ^<a href="./!TARGET_FILE!"^>클릭^</a^>^</p^>
    echo ^</body^>
    echo ^</html^>
) > "%REPO_DIR%\index.html"
echo        └─ index.html → !TARGET_FILE! 리다이렉트 설정 완료

echo.
echo  [5/5] Git 커밋 및 푸시 중...
cd /d "%REPO_DIR%"
git add .
git commit -m "Add report: !TARGET_FILE!"
if %errorlevel% equ 0 (
    git push origin %BRANCH%
    if %errorlevel% neq 0 (
        echo.
        echo  [오류] git push 실패. GitHub 인증을 확인하세요.
        echo.
        echo  인증 설정 방법:
        echo   1. github.com → Settings → Developer settings
        echo      → Personal access tokens → Generate new token
        echo   2. push 시 비밀번호 대신 토큰 입력
        pause
        exit /b 1
    )
) else (
    echo  [알림] 변경 사항 없음 — 이미 최신 상태입니다.
)

echo.
echo  ┌──────────────────────────────────────────────────────────────────┐
echo  │  배포 완료!                                                       │
echo  │                                                                   │
echo  │  리포트 직접 URL:                                                 │
echo  │  https://dkunyoon.github.io/Market-Research/!TARGET_FILE!
echo  │                                                                   │
echo  │  인덱스 URL (최신 리포트로 자동 이동):                            │
echo  │  https://dkunyoon.github.io/Market-Research/                     │
echo  │                                                                   │
echo  │  ※ GitHub Pages 반영까지 1~2분 소요될 수 있습니다               │
echo  └──────────────────────────────────────────────────────────────────┘
echo.

set /p OPEN_BROWSER=  지금 브라우저로 열까요? (Y/N): 
if /i "!OPEN_BROWSER!"=="Y" (
    start https://dkunyoon.github.io/Market-Research/
)

echo.
pause
exit /b 0
