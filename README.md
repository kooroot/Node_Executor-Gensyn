# Gensyn RL-Swarm Node Setup (Linux & Mac)

이 저장소에는 **리눅스(Ubuntu 계열)와 MacOS** 환경에서 **Gensyn RL-Swarm Node** 설치와 설정을 자동화하는 스크립트(`gensyn.sh`)가 포함되어 있습니다.

아래 스크립트는 다음 과정을 한 번에 처리합니다:

1. **OS 감지** - Ubuntu 또는 MacOS 환경을 자동으로 인식
2. **의존성 패키지** 설치 (Ubuntu에서는 apt, MacOS에서는 brew 사용)
3. **Docker / Docker Compose** 설치 확인 및 자동 설치
4. **설치 방법 선택** - 사용자 선택에 따라:
   - **로컬 설치**: Git 저장소를 클론 후 Python 가상환경에서 실행
   - **Docker 실행**: Docker 컨테이너를 통한 실행 (GPU 지원 여부 자동 감지)
5. **GPU 감지** - NVIDIA GPU 존재 여부 및 지원 모델 확인 (RTX 3090, RTX 4090, A100, H100)

---

## 설치 및 실행 방법

1. 스크립트를 다운로드
   ```bash
   wget https://raw.githubusercontent.com/kooroot/Node_Executor-Gensyn/refs/heads/main/gensyn.sh
   ```

2. 실행 권한을 부여
   ```bash
   chmod +x gensyn.sh
   ```

3. 스크립트를 실행
   ```bash
   ./gensyn.sh
   ```
   - 실행 중 설치 방법(로컬 또는 Docker)을 선택하는 옵션이 표시됩니다.
   - 설치 과정에서 `sudo` 암호 입력이 필요할 수 있습니다.

4. 또는 옵션을 지정하여 실행
   ```bash
   # 로컬 설치 방식으로 바로 실행
   ./gensyn.sh --local
   
   # Docker 방식으로 바로 실행
   ./gensyn.sh --docker
   
   # 도움말 표시
   ./gensyn.sh --help
   ```

5. 노드 작동 확인
   - 로컬 설치의 경우:
     - 일반 실행: `cd rl-swarm && source .venv/bin/activate && ./run_rl_swarm.sh` 명령을 실행하여 로그 확인
     - Screen 세션 실행: `screen -r gensyn-rl-swarm` 명령으로 실행 중인 세션 확인
   - Docker 실행의 경우:
     - 일반 실행: `docker ps` 명령으로 컨테이너가 실행 중인지 확인
     - Screen 세션 실행: `screen -r gensyn-rl-swarm-docker` 명령으로 실행 중인 세션 확인

---

## 지원 환경 및 하드웨어

### 운영 체제
- **Ubuntu** (18.04 LTS 이상 권장)
- **MacOS** (Intel 및 Apple Silicon)

### 지원 GPU (CUDA devices)
Docker 실행 시 다음 GPU 모델을 공식 지원합니다:
- RTX 3090
- RTX 4090
- A100
- H100

다른 NVIDIA GPU도 작동할 수 있으나 성능이 최적화되지 않을 수 있습니다.

---

## 설치 세부 과정

### 로컬 설치 방식
1. 필수 의존성 패키지 설치
2. Git을 통해 RL-Swarm 저장소 클론
3. Python 가상환경 설정
4. 실행 준비 완료 메시지 표시

### Docker 실행 방식
1. 필수 의존성 패키지 설치
2. Docker 및 Docker Compose 설치 확인/설치
3. GPU 지원 여부 감지
4. 적절한 Docker 명령어로 컨테이너 실행

---

## 주요 설정 파일 및 환경 변수

### 로컬 설치 시 주요 설정
- **가상환경**: `.venv` 디렉토리에 생성됨
- **실행 스크립트**: `./run_rl_swarm.sh`
- **Screen 세션**: `gensyn-rl-swarm` 이름으로 생성
- **백업 피어 노드**: 코디네이터 피어에 연결 문제가 발생할 경우 사용할 수 있는 백업 주소
  ```
  DEFAULT_PEER_MULTI_ADDRS="/dns/rl-swarm.gensyn.ai/tcp/38331/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ"
  ```
- **MacOS 메모리 설정** (실험적):
  ```
  export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
  ```

### Docker 실행 시 명령어
- **GPU 모드**:
  ```bash
  docker run --gpus all --pull=always -it --rm europe-docker.pkg.dev/gensyn-public-b7d9/public/rl-swarm:v0.0.2 ./run_hivemind_docker.sh
  ```
- **CPU 모드**:
  ```bash
  docker run --pull=always -it --rm europe-docker.pkg.dev/gensyn-public-b7d9/public/rl-swarm:v0.0.2 ./run_hivemind_docker.sh
  ```

### Screen 세션 관리
- **세션 접속**: `screen -r [세션이름]` (예: `screen -r gensyn-rl-swarm`)
- **세션 분리**: `Ctrl+A, D` (세션을 종료하지 않고 빠져나옴)
- **세션 종료**: `Ctrl+A, K` 또는 `screen -S [세션이름] -X quit`
- **세션 목록 확인**: `screen -ls`

---

## 웹 UI 대시보드 작동 및 노드 동작 확인

웹 UI 대시보드를 실행하기 위해서는 `rl-swarm` 폴더에서
```
cd rl-swarm
docker compose up --build -d
```
명령을 실행합니다.

웹 대시보드는 로컬 환경에서 `0.0.0.0:8080`에 접속하여 확인합니다.
만약 Contabo를 사용중이라면 `https://VPS-IP:8080`에 접속하여 확인합니다.
![image](https://github.com/user-attachments/assets/97a556e3-7f3e-462b-9a71-2cbf18ae921a)

---

## 문제 해결

- **Docker 권한 문제**: Ubuntu에서 Docker 설치 후 사용자 권한 문제가 발생하면 로그아웃 후 다시 로그인하세요.
- **MacOS에서 Docker Desktop**: Docker Desktop이 완전히 시작될 때까지 기다린 후 진행하세요.
- **GPU 감지 실패**: 드라이버 설치 상태를 확인하고 `nvidia-smi` 명령이 작동하는지 확인하세요.
- **코디네이터 피어 연결 문제**: 백업 피어 노드를 설정 파일에 추가하세요.
- **Python 패키지 설치 오류**: 가상환경이 올바르게 활성화되었는지 확인하세요.

---

## 문의 / 이슈
- **Gensyn 노드** 자체 문의: [Gensyn 공식 문서](https://gensyn.ai/docs) 또는 커뮤니티
- **스크립트** 관련 문의나 버그 제보: 본 저장소의 [Issues](../../issues) 탭에 등록해주세요.
- **텔레그램 채널**: [Telegram 공지방](https://t.me/web3_laborer)
