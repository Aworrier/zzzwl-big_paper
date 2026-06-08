$ErrorActionPreference = "Stop"
$root='c:\Users\Dell\Desktop\人生轨迹\硕士\硕士毕业设计\大论文\zzzwl-big_paper'
$files=@(
  'docs/Chapter_01.tex','docs/Chapter_02.tex','docs/Chapter_03.tex','docs/Chapter_04.tex','docs/Chapter_05.tex','docs/Chapter_06.tex',
  'docs/AppendixA.tex','docs/AppendixB.tex','docs/AppendixC.tex','docs/AppendixD.tex'
) | ForEach-Object { Join-Path $root $_ }

$acrFile=Join-Path $root 'docs/Acronym.tex'
$acrContent=Get-Content -Raw -Encoding UTF8 $acrFile
$acrKeys=[System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach($line in ($acrContent -split "`n")){
  if($line -match '^\s*([0-9A-Za-z][0-9A-Za-z/\-]*)\s*&'){
    [void]$acrKeys.Add($matches[1])
  }
}

$pattern='\b(?:[A-Z]{2,}(?:/[A-Z]{2,})?|[A-Z]{1,}\-[A-Z0-9]{1,}|[A-Z]{1,}[0-9][A-Z0-9\-]*|[0-9]GPP|[0-9]G)\b'
$ignore=@('BEGIN','END','CHAPTER','SECTION','SUBSECTION','SUBSUBSECTION','PAR','TEXTBF','LABEL','REF','CITE','CITET','CITEP','ITEM','ITEMIZE','ENUMERATE','FIGURE','TABLE','TABULAR','CENTERING','CAPTION','HLINE','LEFT','RIGHT','TOP','BOTTOM','MATHRM','MATHBB','MATHCAL','BIBITEM','NEWCOMMAND','INCLUDEGRAPHICS','TH','TD','TR')
$ignoreSet=[System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$ignore|%{[void]$ignoreSet.Add($_)}

$candidates=@{}
foreach($f in $files){
  $txt=Get-Content -Raw -Encoding UTF8 $f
  $txt=[regex]::Replace($txt,'(?m)^\s*%.*$','')
  $txt=[regex]::Replace($txt,'(?<!\\)%.*$','', 'Multiline')
  $txt=[regex]::Replace($txt,'\$\$.*?\$\$',' ','Singleline')
  $txt=[regex]::Replace($txt,'\$.*?\$',' ','Singleline')
  $txt=[regex]::Replace($txt,'\\\[.*?\\\]',' ','Singleline')
  $txt=[regex]::Replace($txt,'\\\(.*?\\\)',' ','Singleline')
  $txt=[regex]::Replace($txt,'\\caption\{.*?\}',' ','Singleline')
  $txt=[regex]::Replace($txt,'\\(?:label|ref|eqref|cite|citet|citep|pageref)\s*\{.*?\}',' ','Singleline')
  $txt=[regex]::Replace($txt,'\\[a-zA-Z@]+\*?(\[[^\]]*\])?',' ')
  $txt=$txt -replace '[{}_^~]',' '

  $m=[regex]::Matches($txt,$pattern)
  foreach($x in $m){
    $k=$x.Value.Trim()
    if($k.Length -lt 2){continue}
    if($ignoreSet.Contains($k)){continue}
    if(-not $candidates.ContainsKey($k)){
      $candidates[$k]=[PSCustomObject]@{Count=0;FirstFile=(Split-Path -Leaf $f)}
    }
    $candidates[$k].Count++
  }
}

$outFile=Join-Path $root 'tmp_acronym_diff.txt'
$sb = New-Object System.Text.StringBuilder
$keys=$candidates.Keys | Sort-Object
[void]$sb.AppendLine('===TotalCandidates===')
[void]$sb.AppendLine([string]$keys.Count)
[void]$sb.AppendLine('===MissingInAcronym===')
$missing=$keys | Where-Object { -not $acrKeys.Contains($_) }
foreach($k in $missing){ [void]$sb.AppendLine("$k`t$($candidates[$k].Count)`t$($candidates[$k].FirstFile)") }
[void]$sb.AppendLine('===InAcronymButNotInBody===')
$extra=$acrKeys | Where-Object { -not $candidates.ContainsKey($_) } | Sort-Object
foreach($k in $extra){ [void]$sb.AppendLine($k) }
[void]$sb.AppendLine('===AllCandidates===')
foreach($k in $keys){ [void]$sb.AppendLine("$k`t$($candidates[$k].Count)`t$($candidates[$k].FirstFile)") }
Set-Content -Path $outFile -Value $sb.ToString() -Encoding UTF8
Write-Output "WROTE $outFile"
