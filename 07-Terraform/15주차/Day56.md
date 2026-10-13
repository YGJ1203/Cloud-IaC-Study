# 2026-10-13 AWS 실습 종합 정리

> **주제:** CloudFront/CDN · S3 · Route 53 · ACM · Docker/ECR · EKS/Kubernetes · LoadBalancer  
> **목적:** 당일 실습 복기 + 실무 설계 포인트 + 면접/자격증 대비  
> **기록 원칙:** `[실습 확인]`은 제공된 메모/로그에서 직접 확인된 내용, `[추가 학습]`은 개념 설명 및 권장 사항, `[미확인]`은 로그만으로 입증되지 않은 부분을 뜻한다.  
> **보안:** 원본 로그에 포함된 AWS 액세스 키와 시크릿 키는 의도적으로 제외했다. **기존 키는 노출된 것으로 간주해 IAM에서 즉시 비활성화·삭제하고 필요한 경우 교체할 것.**

---

## 1. 오늘의 학습 로드맵

| 분야 | 실습/관찰 | 핵심 개념 |
|---|---|---|
| CloudFront | EC2 오리진 및 S3 오리진 기반 배포 | CDN, Edge, Origin, 캐싱 |
| Route 53 | `www`, `cdn`, `book` 서브도메인 및 NS 기록 | DNS, Alias, CNAME |
| ACM | CloudFront 인증서 리전 관련 실습 | `us-east-1` 인증서 |
| ECR | Nginx 이미지 빌드·태그·Push·Pull·Run | Registry, Image Digest |
| EKS | Windows CLI로 kubeconfig 갱신 및 Pod 조회 | Control Plane, Node, kubeconfig |
| Kubernetes | Nginx 4 replicas + LoadBalancer Service | Deployment, Selector, EndpointSlice |
| 운영 | Service/Deployment 삭제, 로그 확인 | 리소스 정리, 비용, 보안 |

### 큰 그림

```text
[사용자 PC]
    |
    +----> [Route 53 DNS] ---> [CloudFront Edge] ---> [EC2 HTTP Origin]
    |                                  |
    |                                  +-----------> [S3 Origin]
    |
    +----> [Route 53 DNS] ---> [ALB] ---> [EC2 Web Servers]
    |
    +----> [EKS Service: LoadBalancer] ---> [AWS ELB]
                                              |
                                        [Worker Nodes]
                                              |
                                       [Nginx Pods x4]

[Docker Host] -- build/tag/push --> [Amazon ECR]
       ^                                |
       +------------- pull -------------+
```

> 서로 다른 실습 환경을 이해하기 위해 하나의 개념도로 묶었다. 위 모든 연결이 **하나의 운영 시스템으로 통합 구축되었다는 뜻은 아니다.**

---

## 2. CloudFront와 CDN

### 2.1 기본 개념 [추가 학습]

- **CDN(Content Delivery Network):** 전 세계에 분산된 엣지 네트워크를 이용해 사용자에게 콘텐츠를 전달하는 방식.
- **Origin(오리진):** 원본 콘텐츠를 제공하는 서버/스토리지. EC2의 HTTP 서버, ALB, S3 등이 가능.
- **Edge Location:** 사용자의 요청을 처리하고 캐시된 콘텐츠를 제공하는 위치.
- **Cache Hit:** 엣지 캐시에 유효한 객체가 있어 오리진 요청 없이 제공.
- **Cache Miss:** 캐시에 유효한 객체가 없어 오리진에서 가져오는 등의 처리가 필요한 상태.
- **TTL(Time To Live):** 객체의 캐시 신선도에 영향을 주는 시간 설정.
- **Invalidation:** 특정 경로의 캐시 객체를 만료 처리하도록 요청하는 기능.

```text
첫 요청:  Client --> CloudFront Edge -- MISS --> Origin
                         |<----- 응답 -----|
           Client <------|  (캐시 정책에 따라 저장)

다음 요청: Client --> CloudFront Edge -- HIT --> Client
```

**주의:** 모든 요청이 반드시 캐싱되는 것은 아니다. 캐시 정책, HTTP 메서드, 헤더, 쿠키, 쿼리 문자열, 오리진 응답의 캐시 제어 등에 따라 결과가 달라진다.

### 2.2 EC2 오리진 실습 [실습 확인]

- 서울 리전 EC2 공인 IP: `54.180.92.228`
- EC2 퍼블릭 DNS: `ec2-54-180-92-228.ap-northeast-2.compute.amazonaws.com`
- CloudFront 배포 도메인: `dfxc892irzmgq.cloudfront.net`
- 실습 PC의 IP는 기록에 존재하지만 공개 학습 문서에서는 생략.

```bash
sudo -s
yum -y install httpd
echo '<h1>MyWeb1 Test Page</h1>' > /var/www/html/index.html
systemctl enable --now httpd
tail -f /var/log/httpd/access_log
```

- `yum -y install httpd`: Apache HTTP Server 설치.
- `echo ... > index.html`: 기본 페이지 생성/덮어쓰기. 원본 로그에는 닫는 `</h1>` 대신 `<h1>`이 반복되었으므로 위는 **교정된 HTML**이다.
- `systemctl enable --now httpd`: 부팅 자동 시작 설정 + 즉시 시작.
- `tail -f`: 액세스 로그 실시간 추적.

**로그 관찰:** EC2 직접 요청은 실습 PC의 IP로 `GET /`가 기록되고, CloudFront 도메인 경유 시에는 다른 출발지 IP로 `GET /` 요청이 기록되었다. `200`은 요청 성공, `/favicon.ico`의 `404`는 파비콘 파일 부재를 의미한다. 로그에 CloudFront 경유 오리진 요청이 나타났다고 해서 그 이후 모든 요청의 캐시 적중 여부가 입증되지는 않는다.

### 2.3 페이지 변경과 캐시 검증 [추가 학습]

원본 로그에서는 페이지를 `MyWeb1 Test Page`에서 `MyWeb1 Test Web Page`로 변경했다.

```bash
# 원본 서버에서 페이지 수정
echo '<h1>MyWeb1 Test Web Page</h1>' > /var/www/html/index.html

# 클라이언트에서 응답 헤더 비교
curl -I https://dfxc892irzmgq.cloudfront.net/
curl -I https://dfxc892irzmgq.cloudfront.net/
```

- `x-cache: Hit from cloudfront` / `Miss from cloudfront` 등의 헤더를 참고하되, 응답 경로와 정책에 따라 달라질 수 있다.
- 필요할 경우 CloudFront Invalidation에 `/*` 또는 특정 객체 경로를 지정한다. 대량의 `/*` 무효화보다는 버전이 붙은 정적 파일 이름을 쓰는 전략도 유용하다.
- HTTPS 사용 시 오리진과 CloudFront 사이의 연결 정책도 별도로 점검한다.

### 2.4 S3 오리진 실습 [실습 메모]

- 메모: 미국 리전의 S3, 약 10GB 콘텐츠.
- CloudFront 도메인: `d2hw42rkoz10tz.cloudfront.net`
- 요청 예시:

```text
http://d2hw42rkoz10tz.cloudfront.net/page1.html
http://d2hw42rkoz10tz.cloudfront.net/page2.html
```

**[미확인]** 두 URL의 실제 HTTP 응답 코드, S3 버킷 정책, OAC 설정, 캐시 적중률은 제공된 로그에 없다.

**[추가 학습] S3 권장 설계:** S3 REST 오리진에는 **Origin Access Control(OAC)** 을 사용하고 버킷의 직접 공개 접근을 제한한다. S3 정적 웹사이트 엔드포인트는 일반적으로 Custom Origin으로 취급되므로 OAC 적용 방식과 다르다.

### 2.5 상파울루 EC2 + CloudFront [실습 확인]

- EC2 리전: `sa-east-1`(상파울루). **상파울루는 리전이고, 가용 영역(AZ)과는 다른 개념이다.**
- EC2 IP: `15.228.190.239`
- CloudFront 도메인: `d1g1dttxpk6g4g.cloudfront.net`
- 사용자 지정 도메인: `cdn.example7777.shop`
- PuTTY 원격 입력이 서울 리전 EC2보다 느리게 느껴졌다는 관찰이 기록됨.
- 웹 액세스 로그에 `/city_image.jpg` 요청과 HTTP `200`이 나타남. 이미지 크기 로그 값은 `8175685`바이트.
- 직접 접속 로그와 CloudFront 경유로 보이는 로그에서 출발지 IP가 달랐음.

**중요:** SSH 입력 반응 속도는 네트워크 RTT와 관련이 있지만, CloudFront의 HTTP 캐시 성능과 같은 지표가 아니다. CDN의 성능 개선은 `curl -w` 측정, 브라우저 개발자 도구, `x-cache`, CloudFront 지표로 비교해야 한다.

```bash
curl -sS -o /dev/null -w 'HTTP=%{http_code} TTFB=%{time_starttransfer}s TOTAL=%{time_total}s\n' \
  http://15.228.190.239/city_image.jpg
curl -sS -o /dev/null -w 'HTTP=%{http_code} TTFB=%{time_starttransfer}s TOTAL=%{time_total}s\n' \
  http://cdn.example7777.shop/city_image.jpg
```

> 위는 **추가 검증용 예시 명령어**이며, 측정 결과를 새로 확인한 것은 아니다. HTTPS가 설정됐다면 HTTPS URL로 비교한다.

---

## 3. Route 53, DNS, ALB, ACM

### 3.1 Route 53 메모 [실습 메모]

기록된 도메인 및 연결 대상:

| 도메인 | 메모/조회 결과 |
|---|---|
| `www.example7777.shop` | `nslookup`에서 `15.228.190.239` 확인 |
| `cdn.example7777.shop` | `nslookup`에서 여러 CloudFront 관련 IP 응답 확인 |
| `book.example7777.shop` | 이름이 메모에 기록됨. 실제 DNS 응답/대상은 미확인 |
| `MyALB-1972209831.ap-northeast-2.elb.amazonaws.com` | ALB DNS 메모 |

추가 EC2 메모: `MyWeb1=3.34.104.12`, `MyWeb2=3.34.104.207`.

기록된 NS 서버:

```text
ns-1855.awsdns-39.co.uk.
ns-1526.awsdns-62.org.
ns-387.awsdns-48.com.
ns-1003.awsdns-61.net.
```

**[추가 학습] DNS 기본:**

- **A:** 호스트 이름 → IPv4 주소.
- **AAAA:** 호스트 이름 → IPv6 주소.
- **CNAME:** 호스트 이름 → 다른 DNS 이름. 일반적인 DNS zone apex에는 사용할 수 없다.
- **Alias:** Route 53에서 CloudFront, ALB 등 AWS 리소스를 가리킬 때 활용하는 확장 기능. Zone apex에서도 사용할 수 있다.
- **NS:** 해당 도메인의 권한 있는 네임서버 정보.

```powershell
nslookup www.example7777.shop
nslookup cdn.example7777.shop
```

`cdn`에 여러 IP가 반환된 것은 정상적으로 가능한 동작이며, 그 IP들을 고정 IP로 취급하면 안 된다. DNS 조회 결과만으로 어떤 엣지 위치에서 응답했는지 단정할 수도 없다.

### 3.2 ACM 인증서 리전 [추가 학습 + 실습 메모]

**CloudFront 배포에 연결하는 ACM 공개 인증서는 미국 동부(버지니아 북부) `us-east-1` 리전에 있어야 한다.** CloudFront가 전역 서비스이기 때문이다.

- CloudFront용 ACM 인증서: `us-east-1`.
- 리전별 ALB에 직접 연결할 ACM 인증서: 해당 **ALB와 동일한 리전**.
- DNS 별칭 레코드 자체가 반드시 버지니아 리전에서 만들어지는 것은 아니다. 메모에 적힌 콘솔의 ‘전역적 별칭’ 문구는 CloudFront 리소스 선택/표시와 관련된 설명으로 이해해야 한다.
- 인증서 발급은 DNS 검증 CNAME을 활용할 수 있다.

**면접 한 문장:** “CloudFront에 사용하는 ACM 인증서는 `us-east-1`에서 발급/관리하지만, 리전 ALB용 인증서는 ALB 리전에 둡니다.”

---

## 4. Docker와 Amazon ECR

### 4.1 개념 [추가 학습]

- **Docker Image:** 컨테이너 실행에 필요한 파일 시스템과 메타데이터.
- **Dockerfile:** 이미지를 생성하기 위한 빌드 지시문.
- **ECR(Elastic Container Registry):** AWS 관리형 컨테이너 이미지 레지스트리.
- **Repository:** 이미지 및 태그를 관리하는 논리 단위.
- **Tag:** 사람이 읽기 쉬운 이미지 버전 참조(`latest`, `v1` 등).
- **Digest:** 콘텐츠 기반의 이미지 식별자(`sha256:...`). 태그와 달리 불변 콘텐츠를 식별하는 데 유용.

### 4.2 실습 Dockerfile [실습 확인]

```dockerfile
FROM nginx
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

`index.html` 내용:

```html
<h1>### Nginx Test Web Page ###</h1>
```

**[추가 학습]** 재현성을 위해 `FROM nginx:버전` 또는 Digest 고정을 고려한다. `EXPOSE 80`은 포트 사용 의도를 문서화하는 지시문이며, 실제 호스트 포트 공개는 `docker run -p`가 수행한다.

### 4.3 빌드 → 로그인 → Push → Pull → Run [실습 확인]

리포지토리: `ray589-repo`, 리전: `ap-northeast-2`.

```bash
# 1. 로컬 이미지 생성
docker image build -t mynginx .

# 2. ECR 인증 (수정 권장 명령)
aws ecr get-login-password --region ap-northeast-2 | \
  docker login --username AWS --password-stdin \
  275060989875.dkr.ecr.ap-northeast-2.amazonaws.com

# 3. ECR 리포지토리 경로로 태그
docker image tag mynginx:latest \
  275060989875.dkr.ecr.ap-northeast-2.amazonaws.com/ray589-repo:latest

# 4. Push
docker image push \
  275060989875.dkr.ecr.ap-northeast-2.amazonaws.com/ray589-repo:latest

# 5. ECR 이미지 목록 조회
aws ecr list-images --repository-name ray589-repo --region ap-northeast-2

# 6. Pull
docker image pull \
  275060989875.dkr.ecr.ap-northeast-2.amazonaws.com/ray589-repo:latest

# 7. 컨테이너 실행
docker container run -itd --name myweb -p 8080:80 \
  275060989875.dkr.ecr.ap-northeast-2.amazonaws.com/ray589-repo:latest
```

**확인된 결과:** 빌드 완료, `Login Succeeded`, 각 레이어 `Pushed`, `latest` 이미지 Digest 출력, `list-images`의 `imageIds` 확인, Pull 성공, `docker run`의 컨테이너 ID 출력. **[미확인]** 브라우저나 `curl`로 `8080` 서비스 응답을 검증한 로그는 없다.

### 4.4 실제 오류와 교정

| 원본 입력/상황 | 원인 | 권장 조치 |
|---|---|---|
| `aws ecr list-image` | AWS CLI 서브명 오타 | `aws ecr list-images` |
| ECR `docker login` 대상에 `/ray589-repo` 포함 | 로그인 대상은 레지스트리 호스트 | 경로를 제외한 호스트만 사용 |
| `docker image rm -f $(docker image ls -qa)` 후 중복 이미지 오류 | 동일 Image ID가 여러 태그에 중복 나열될 수 있음 | 삭제 전 ID/태그 확인; `docker image prune` 등 목적별 명령 사용 |
| `WARNING! Your password will be stored unencrypted` | Docker 자격 증명 저장 방식 경고 | Credential Helper 검토, 실습 후 로그아웃 |

**중요:** 원본 로그의 로컬 이미지 전체 삭제는 실습용 정리였고, 운영 환경에서 무분별하게 실행하면 안 된다. ECR 리포지토리의 원격 이미지는 로컬 이미지 삭제로 사라지지 않는다.

---

## 5. EKS 및 Windows kubectl 실습

### 5.1 EKS 개념 [추가 학습]

- **EKS:** AWS가 Kubernetes Control Plane을 관리하는 서비스.
- **Control Plane:** Kubernetes API와 클러스터 상태를 관리.
- **Worker Node:** 실제 Pod를 실행하는 컴퓨팅 자원.
- **kubeconfig:** kubectl이 사용할 클러스터, 사용자, 컨텍스트 정보를 저장.
- **AWS CLI:** AWS 인증/권한에 따라 EKS 클러스터 정보 조회 및 kubeconfig 갱신에 사용.
- **EKS Pod Identity Agent:** Pod가 IAM 역할 자격 증명을 사용할 수 있도록 지원하는 구성 요소.

### 5.2 Windows 환경 준비 [실습 확인]

원본 메모의 다운로드:

```cmd
curl.exe -LO "https://dl.k8s.io/release/v1.37.0/bin/windows/amd64/kubectl.exe"
curl.exe -LO "https://awscli.amazonaws.com/AWSCLIV2.msi"
AWSCLIV2.msi
```

- 로그에서 `kubectl.exe`와 AWS CLI MSI 다운로드가 완료됨.
- `aws configure` 수행 후 사용자 홈의 `.aws/config`, `.aws/credentials` 존재 확인.
- **원본 로그의 Access Key ID 및 Secret Access Key는 보안상 이 문서에서 제외.**
- `kubectl` 클라이언트와 EKS 서버의 지원 버전 차이를 확인하는 것이 좋다: `kubectl version --client`, `kubectl version`.

```cmd
set CLUSTER_NAME=MyEKSCluster
set VPCID=vpc-017771a9c5809cb5e
echo %CLUSTER_NAME% %VPCID%
aws eks update-kubeconfig --region ap-northeast-2 --name %CLUSTER_NAME%
kubectl get pod -A
```

**확인된 결과:** kubeconfig에 `MyEKSCluster` 컨텍스트 추가 메시지가 출력되었고, `external-dns`, `aws-node`, `coredns`, `eks-node-monitoring-agent`, `eks-pod-identity-agent`, `kube-proxy`, `metrics-server` 등의 Pod가 `Running`으로 조회되었다.

> `set` 구문은 Windows **CMD** 문법이다. PowerShell에서는 `$env:CLUSTER_NAME = 'MyEKSCluster'` 같은 문법을 사용한다.

### 5.3 EKS 배포 YAML [실습 확인]

파일명: `nginx-deploy-clb.yml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
spec:
  replicas: 4
  selector:
    matchLabels:
      app: webui
  template:
    metadata:
      name: nginx-pod
      labels:
        app: webui
    spec:
      containers:
        - name: nginx-container
          image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: webui
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30000
```

**필드 해설:**

| 필드 | 역할 |
|---|---|
| `replicas: 4` | Pod 4개를 유지하도록 Deployment에 선언 |
| `selector.matchLabels` | Deployment가 관리할 Pod 레이블 선택 |
| `template.metadata.labels` | 새 Pod에 `app: webui` 부여 |
| `Service.selector` | `app: webui` Pod를 서비스 백엔드로 선택 |
| `type: LoadBalancer` | 클라우드 연동을 통해 외부 로드밸런서 프로비저닝 요청 |
| `port: 80` | Service 포트 |
| `targetPort: 80` | Pod 내부 애플리케이션 목적지 포트 |
| `nodePort: 30000` | 노드의 서비스 접근 포트(할당 범위와 구성 조건 필요) |

**[추가 학습]** `nodePort`를 직접 고정하지 않으면 일반적인 설정에서는 자동 할당할 수 있다. 실제 생성되는 AWS 로드밸런서의 종류는 EKS 버전, 컨트롤러, Service annotation 및 클러스터 구성에 따라 달라진다. 파일명에 `clb`가 있다고 해서 **실제 Classic Load Balancer 생성이 입증되지는 않는다.**

### 5.4 배포 및 상태 확인 [실습 확인]

```cmd
kubectl create -f nginx-deploy-clb.yml
kubectl get deploy
kubectl get svc,pod,ep -o wide
```

결과 핵심:

```text
NAME           READY   UP-TO-DATE   AVAILABLE
nginx-deploy   4/4     4            4

service/nginx-loadbalancer   LoadBalancer   172.20.87.239
EXTERNAL-IP: a9b796f13b0c04c7b8f60b9b1349ccf2-1526447905.ap-northeast-2.elb.amazonaws.com
PORT(S): 80:30000/TCP
```

Pod 네 개가 모두 `1/1 Running`이었고, IP는 `10.0.1.178`, `10.0.2.100`, `10.0.1.32`, `10.0.2.129`로 확인되었다. 두 서브넷의 워커 노드에 분산된 상태가 로그에 나타난다. Service Endpoints도 Pod IP를 가리켰다.

**[미확인]** 외부 브라우저/`curl`을 통한 로드밸런서 HTTP 응답 성공은 제공된 출력에 없다. `EXTERNAL-IP` 할당은 프로비저닝 진행의 중요한 증거지만 실제 외부 접속 테스트와 동일하지 않다.

### 5.5 Endpoints 폐기 경고 [실습 확인 + 추가 학습]

로그의 경고:

```text
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
```

권장 확인:

```bash
kubectl get endpointslices -l kubernetes.io/service-name=nginx-loadbalancer
kubectl describe svc nginx-loadbalancer
kubectl get pods -o wide
```

**EndpointSlice**는 서비스의 네트워크 엔드포인트를 관리하는 현대적인 Kubernetes API이다. 레거시 Endpoints에만 의존하는 운영 스크립트는 점검해야 한다.

### 5.6 리소스 삭제 [실습 확인]

```cmd
kubectl delete -f nginx-deploy-clb.yml
kubectl get deploy,svc
```

삭제 출력에서 `nginx-deploy`와 `nginx-loadbalancer`가 삭제되었고, 이후 기본 `kubernetes` ClusterIP Service만 표시되었다.

**주의:** Kubernetes 객체 삭제와 AWS 리소스 정리 완료는 동일하지 않다. AWS 콘솔/CLI에서 실제 ELB 삭제, EKS 클러스터, 노드 그룹, NAT Gateway, EIP, CloudWatch 로그 등을 확인한다.

---

## 6. 실무 보안 및 비용 점검

### 6.1 자격 증명 유출 대응 — 반드시 수행

원본 기록에 **실제 AWS Access Key ID와 Secret Access Key가 평문 노출**되었다. 해당 키는 이 문서에서 마스킹하는 것만으로 안전해지지 않는다.

1. IAM에서 해당 Access Key를 즉시 비활성화한다.
2. 사용 내역(CloudTrail 등)과 이상 징후를 확인한다.
3. 기존 키를 삭제하고 필요한 경우 새 자격 증명을 발급한다.
4. 이미 업로드·공유·커밋한 로그가 있다면 비밀정보가 포함된 복사본도 정리한다.
5. EC2에는 가능하면 IAM Instance Profile, EKS 워크로드에는 EKS Pod Identity 또는 IRSA를 사용한다.
6. GitHub에는 `.aws/credentials`, 환경변수 비밀값, SSH 개인 키를 올리지 않는다.

**권장:** 로컬 개발 환경에서도 장기 액세스 키보다 IAM Identity Center 등의 임시 자격 증명 방식을 검토한다.

### 6.2 비용 발생 가능 리소스 [추가 학습]

| 리소스 | 비용 점검 포인트 |
|---|---|
| EKS | 클러스터 제어 플레인 사용료 및 지원 버전 관련 요금 |
| EC2 | 인스턴스 실행, EBS 볼륨, 공인 IPv4 등 |
| ELB | 로드밸런서 운영 시간 및 처리량 관련 요금 |
| NAT Gateway | 시간 및 처리 데이터 비용 |
| CloudFront | 전송량, 요청, 부가 기능 및 요금제 조건 |
| S3 | 저장 용량, 요청, 데이터 전송 등 |
| ECR | 저장 이미지 용량, 전송, 스캔 옵션 등 |
| Route 53 | Hosted Zone, 쿼리, 등록 도메인 등 |
| CloudWatch | 로그 수집/보관 및 모니터링 비용 |

**정리 체크리스트:**

- [ ] EKS 클러스터 및 관리형 노드 그룹 필요 여부 확인
- [ ] Kubernetes LoadBalancer 삭제 후 AWS ELB 실물 삭제 확인
- [ ] NAT Gateway 및 불필요한 EIP/공인 IPv4 확인
- [ ] EC2 인스턴스 및 EBS 볼륨 확인
- [ ] CloudFront 배포 및 S3 저장 객체 확인
- [ ] ECR 불필요 이미지 정리
- [ ] Route 53 Hosted Zone 및 도메인 유지 비용 확인
- [ ] Billing / Cost Explorer에서 과금 확인

---

## 7. 실무 트러블슈팅 치트시트

| 증상 | 점검 순서 |
|---|---|
| CloudFront에 이전 페이지 표시 | `x-cache`, TTL, Cache Policy, Invalidation, 오리진 최신 파일 |
| CloudFront 403 | S3 OAC/버킷 정책, 오리진 권한, WAF, 경로 |
| CloudFront 502/504 | 오리진 연결, TLS 인증서, 포트, 보안 그룹, 타임아웃 |
| 사용자 지정 도메인 HTTPS 오류 | ACM `us-east-1`, SAN, Alternate Domain Name, DNS 레코드 |
| ECR 로그인 실패 | IAM 권한, 리전, 레지스트리 주소, 자격 증명 유효성 |
| ECR Push 실패 | 리포지토리 존재, 태그, Push 권한, 이미지 크기/네트워크 |
| `kubectl` 인증 실패 | AWS CLI 자격 증명, EKS 접근 권한, kubeconfig/context |
| Pod `ImagePullBackOff` | 이미지 URI/태그, 노드 IAM 권한, 네트워크, 레지스트리 접근 |
| Service 외부 접속 실패 | ELB 상태, Target 상태, SG/NACL, 서브넷, Pod readiness, Service selector |
| Pod가 예상보다 적음 | `kubectl describe deploy`, `kubectl describe pod`, Events, 리소스 부족 |

### 추천 진단 명령어

```bash
# Kubernetes
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl describe deployment nginx-deploy
kubectl describe svc nginx-loadbalancer
kubectl get endpointslices -l kubernetes.io/service-name=nginx-loadbalancer
kubectl get events --sort-by=.metadata.creationTimestamp

# ECR
aws ecr describe-repositories --region ap-northeast-2
aws ecr describe-images --repository-name ray589-repo --region ap-northeast-2

# CloudFront HTTP 헤더
curl -I https://dfxc892irzmgq.cloudfront.net/
```

> 위 진단 명령은 **추가 학습용**이며 당일 모두 실행한 기록은 아니다.

---

## 8. 면접 예상 Q&A 15선

**Q1. CDN을 사용하는 이유는?**  
A. 사용자가 가까운 엣지에서 콘텐츠를 받도록 하여 지연을 줄이고, 오리진 부하를 줄이며 전역 콘텐츠 전달을 효율화하기 위해서다.

**Q2. CloudFront의 Origin과 Edge의 차이는?**  
A. Origin은 원본 데이터 공급원, Edge는 사용자 요청 처리와 캐싱을 담당하는 전달 지점이다.

**Q3. Cache Hit와 Miss의 차이는?**  
A. Hit는 캐시된 유효 객체를 제공하는 경우, Miss는 캐시에서 바로 제공할 수 없어 추가 조회가 필요한 경우다.

**Q4. 오리진 파일을 수정했는데 내용이 안 바뀌는 이유는?**  
A. 기존 캐시가 TTL 동안 유효할 수 있다. 캐시 정책 확인, Invalidation, 버전 파일명 적용 등을 검토한다.

**Q5. CloudFront용 ACM 인증서가 `us-east-1`에 필요한 이유는?**  
A. CloudFront의 사용자 지정 HTTPS 인증서가 해당 리전의 ACM 인증서를 사용하도록 설계됐기 때문이다.

**Q6. Route 53 Alias와 CNAME의 차이는?**  
A. Alias는 AWS 대상 리소스를 가리키는 Route 53 확장 기능으로 zone apex에도 쓸 수 있다. CNAME은 표준 DNS 별칭이며 apex에는 일반적으로 사용하지 않는다.

**Q7. CloudFront에서 S3를 안전하게 공개하는 방법은?**  
A. S3 REST 오리진과 OAC를 이용하고 버킷의 직접 공개 접근을 제한한다.

**Q8. ECR과 ECS/EKS의 차이는?**  
A. ECR은 이미지 저장소, ECS/EKS는 컨테이너 워크로드를 실행·오케스트레이션하는 서비스다.

**Q9. Docker Image와 Container의 차이는?**  
A. Image는 실행 템플릿, Container는 이미지를 바탕으로 생성된 실행 인스턴스다.

**Q10. 이미지 Tag와 Digest의 차이는?**  
A. Tag는 이동 가능한 이름이고 Digest는 특정 콘텐츠를 가리키는 해시 식별자다.

**Q11. EKS에서 AWS가 관리하는 부분은?**  
A. EKS는 Kubernetes Control Plane을 관리한다. 노드/Pod 운영 책임은 선택한 컴퓨팅 방식과 관리 기능에 따라 나뉜다.

**Q12. Deployment `replicas: 4`의 의미는?**  
A. 컨트롤러가 선언한 Pod 수 4개를 유지하려 한다는 뜻이다. 실제 가용성은 상태와 배치 제약에 따라 달라진다.

**Q13. Kubernetes Service `LoadBalancer`란?**  
A. 클라우드 로드밸런서와 연동해 Service를 외부에 노출하도록 요청하는 타입이다.

**Q14. `port`, `targetPort`, `nodePort`의 차이는?**  
A. Service의 포트, Pod의 목적지 포트, 노드에서 서비스에 접근하는 포트다.

**Q15. Endpoints 대신 EndpointSlice가 중요한 이유는?**  
A. 서비스 백엔드를 확장성 있게 표현하는 API이며, 구형 Endpoints API는 최신 Kubernetes에서 deprecated 상태이기 때문이다.

---

## 9. 복습용 미니 퀴즈

1. 서울 사용자가 상파울루 EC2의 정적 이미지를 반복 요청할 때 CloudFront가 유리할 수 있는 이유는?
2. `x-cache`가 Miss일 때 반드시 장애인가?
3. CloudFront용 ACM 인증서와 서울 ALB용 ACM 인증서의 리전은 각각?
4. `docker login`에는 ECR 리포지토리 경로까지 넣는 것이 표준인가?
5. ECR Push 후 로컬 이미지를 삭제하면 원격 ECR 이미지도 삭제되는가?
6. `kubectl get deploy`가 `4/4`여도 외부 접속을 추가 확인해야 하는 이유는?
7. `type: LoadBalancer`라는 YAML만으로 CLB 생성이 확정되는가?
8. `kubectl get ep` 경고를 줄이려면 어떤 리소스를 조회하는가?
9. `kubectl delete -f` 후에도 남을 수 있는 AWS 과금 리소스 두 가지는?
10. AWS 액세스 키가 로그에 노출되면 최우선 조치는?

<details>
<summary>정답 확인</summary>

1. 엣지 캐시를 활용하면 원거리 오리진 왕복 요청과 지연을 줄일 수 있기 때문.
2. 아니다. 캐시가 비었거나 만료되었을 수 있다.
3. CloudFront: `us-east-1`; 서울 ALB: `ap-northeast-2`.
4. 아니다. 일반적으로 레지스트리 호스트까지만 지정한다.
5. 아니다. 로컬과 원격 저장소는 별개다.
6. Pod Ready와 외부 ELB/보안 그룹/대상 상태/네트워크 경로는 별개이기 때문.
7. 아니다. 컨트롤러와 annotation 등 환경을 확인해야 한다.
8. `EndpointSlice`.
9. 예: EKS 클러스터, 노드 EC2, NAT Gateway, EBS 등.
10. 키 비활성화/삭제, 사용 내역 조사, 교체.

</details>

---

## 10. 오늘 실습 성과 및 다음 학습 방향

### 실제 확인된 성과

- [x] Apache 설치 및 EC2 HTTP `200` 응답 로그 확인
- [x] CloudFront 경유로 보이는 오리진 요청 로그 확인
- [x] 상파울루 EC2의 이미지 요청 및 `200` 로그 확인
- [x] `www`/`cdn` 도메인 DNS 조회 결과 기록
- [x] Nginx Docker 이미지 빌드
- [x] ECR 로그인·Push·Digest 조회·Pull
- [x] ECR에서 가져온 이미지로 Docker 컨테이너 실행 명령 성공
- [x] Windows에서 EKS kubeconfig 설정 및 Pod 목록 조회
- [x] Nginx Deployment 4/4 Ready
- [x] LoadBalancer Service 외부 DNS 할당
- [x] Deployment/Service Kubernetes 객체 삭제

### 추가 검증하면 좋은 것

1. CloudFront `x-cache` 헤더로 Hit/Miss 반복 확인 및 TTL 테스트.
2. S3 OAC + Block Public Access 구성 확인.
3. CloudFront의 HTTPS 사용자 지정 도메인 인증서 점검.
4. EKS LoadBalancer 외부 `curl` 응답 및 실제 AWS 로드밸런서 유형 확인.
5. AWS ECR 이미지 스캔, immutable tag, 최소 권한 IAM 적용.
6. EKS와 부속 AWS 리소스의 완전한 삭제/과금 확인.

---

## 최종 암기 포인트

> **CloudFront는 콘텐츠 전달/캐싱, Route 53은 DNS, ACM은 TLS 인증서, ECR은 컨테이너 이미지 저장, EKS는 Kubernetes 운영, LoadBalancer Service는 외부 트래픽 진입점이다.**

> **`Pod Running` ≠ 외부 접속 성공 / `Service 삭제` ≠ 모든 AWS 과금 종료 / `Origin 수정` ≠ CloudFront 캐시 즉시 갱신.**

**보안 최우선:** 실습 로그에 노출된 장기 AWS 자격 증명은 반드시 폐기하고, 향후 문서에는 비밀값을 남기지 않는다.


