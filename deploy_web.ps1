$SSH_KEY = "E:\C_Project\aws-keys\LightsailDefaultKey-ap-northeast-2.pem"
$VPS = "ubuntu@15.164.189.87"
$WEB_DIR = "/var/www/kmediwell-web"

Write-Host "Flutter Web 빌드 중..."
flutter build web --release
if ($LASTEXITCODE -ne 0) { Write-Error "빌드 실패"; exit 1 }

ssh -i $SSH_KEY $VPS "sudo chown -R ubuntu:ubuntu $WEB_DIR"

Write-Host "VPS 전송 중..."
scp -i $SSH_KEY -r "build/web/*" "${VPS}:${WEB_DIR}/"
if ($LASTEXITCODE -ne 0) { Write-Error "전송 실패"; exit 1 }

ssh -i $SSH_KEY $VPS "sudo chown -R www-data:www-data $WEB_DIR"

Write-Host "배포 완료: https://kmediwell.autotaxsystem.co.kr"
