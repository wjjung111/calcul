# 계산 노트 기록 도우미 — calc.html을 띄우고, 계산 기록을 앱 폴더의 계산노트기록.json 파일로 저장한다.
# 계산노트 실행.bat이 이 파일을 숨김 창으로 실행. 앱 창을 닫으면 2분 안에 스스로 종료된다.
$ErrorActionPreference = 'Stop'
$root     = Split-Path -Parent $MyInvocation.MyCommand.Path
$appFile  = Join-Path $root 'calc.html'
$dataFile = Join-Path $root '계산노트기록.json'
$bakFile  = Join-Path $root '계산노트기록.이전본.json'
$logFile  = Join-Path $root 'server-error.log'

function Open-AppWindow([string]$target) {
  $browsers = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LocalAppData\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
  )
  $exe = $browsers | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($exe) { Start-Process -FilePath $exe -ArgumentList "--app=$target" }
  else { Start-Process $target }
}

try {
  # 48750~48759 중 빈 포트에 서버를 연다. 전부 사용 중이면 = 이미 계산노트가 떠 있는 것 → 창만 하나 더 연다.
  $listener = $null; $port = 0
  foreach ($p in 48750..48759) {
    try {
      $l = New-Object System.Net.HttpListener
      $l.Prefixes.Add("http://localhost:$p/")
      $l.Start(); $listener = $l; $port = $p; break
    } catch { }  # 포트 사용 중 — 다음 포트 시도
  }
  if ($null -eq $listener) { Open-AppWindow "http://localhost:48750/"; exit }

  Open-AppWindow "http://localhost:$port/"

  $utf8 = New-Object System.Text.UTF8Encoding($false)
  $lastSeen = Get-Date
  while ($true) {
    $ctxTask = $listener.GetContextAsync()
    while (-not $ctxTask.Wait(1000)) {
      # 앱이 10초마다 ping — 120초간 아무 요청 없으면 창이 닫힌 것으로 보고 종료
      if (((Get-Date) - $lastSeen).TotalSeconds -gt 120) { $listener.Stop(); exit }
    }
    $ctx = $ctxTask.Result
    $lastSeen = Get-Date
    $req = $ctx.Request; $res = $ctx.Response
    try {
      $path = $req.Url.AbsolutePath
      if ($req.HttpMethod -eq 'GET' -and ($path -eq '/' -or $path -eq '/calc.html')) {
        $bytes = [System.IO.File]::ReadAllBytes($appFile)
        $res.ContentType = 'text/html; charset=utf-8'
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
      }
      elseif ($req.HttpMethod -eq 'GET' -and $path -eq '/load') {
        if (Test-Path $dataFile) { $bytes = [System.IO.File]::ReadAllBytes($dataFile) }
        else { $bytes = $utf8.GetBytes('{}') }
        $res.ContentType = 'application/json; charset=utf-8'
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
      }
      elseif ($req.HttpMethod -eq 'POST' -and $path -eq '/save') {
        $ms = New-Object System.IO.MemoryStream
        $req.InputStream.CopyTo($ms)
        $tmp = "$dataFile.tmp"
        [System.IO.File]::WriteAllBytes($tmp, $ms.ToArray())
        if (Test-Path $dataFile) { Copy-Item $dataFile $bakFile -Force }   # 직전 상태 1개 보관
        Move-Item $tmp $dataFile -Force
        $bytes = $utf8.GetBytes('{"ok":true}')
        $res.ContentType = 'application/json'
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
      }
      elseif ($path -eq '/ping') {
        $bytes = $utf8.GetBytes('pong')
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
      }
      else { $res.StatusCode = 404 }
    } catch {
      $res.StatusCode = 500
      try { Add-Content -Path $logFile -Value ("[{0}] 요청 처리 오류: {1}" -f (Get-Date), $_) } catch { }
    } finally { $res.Close() }
  }
} catch {
  try { Add-Content -Path $logFile -Value ("[{0}] 도우미 시작 실패: {1}" -f (Get-Date), $_) } catch { }
  # 도우미가 못 떠도 앱은 열어준다 (이때는 브라우저 저장으로만 동작)
  Open-AppWindow $appFile
}
