#!/bin/bash

# Gensyn RL-Swarm 노드 설치 자동화 스크립트
# 지원 OS: Ubuntu, MacOS

# 텍스트 색상 및 포맷 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# 로고 출력
print_logo() {
  echo -e "${BLUE}${BOLD}"
  echo "  ____ _____ _   _ _______   ______   _"
  echo " / ___| ____| \ | / ____\ \ / /  _ \ | |"
  echo "| |  _|  _| |  \| \___ \\\ V /| | | | | |"
  echo "| |_| | |___| |\  |___) || | | |_| | |_|"
  echo " \____|_____|_| \_|____/ |_| |____/  (_)"
  echo -e "${NC}"
  echo -e "${BOLD}RL-Swarm 노드 설치 자동화 스크립트${NC}\n"
}

# OS 체크 함수
check_os() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Ubuntu인지 확인
    if [[ -f /etc/lsb-release ]] && grep -q "Ubuntu" /etc/lsb-release; then
      OS="ubuntu"
      echo -e "${GREEN}[✓] Ubuntu 시스템 감지됨${NC}"
    else
      echo -e "${YELLOW}[!] Ubuntu가 아닌 Linux 시스템 감지됨. 일부 기능이 작동하지 않을 수 있습니다.${NC}"
      OS="linux"
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    echo -e "${GREEN}[✓] MacOS 시스템 감지됨${NC}"
  else
    echo -e "${RED}[✗] 지원되지 않는 운영체제입니다. Ubuntu 또는 MacOS에서만 실행 가능합니다.${NC}"
    exit 1
  fi
}

# 의존성 설치 함수
install_dependencies() {
  echo -e "\n${BLUE}${BOLD}[1/5] 의존성 패키지 설치 중...${NC}"
  
  if [[ "$OS" == "ubuntu" ]]; then
    echo -e "${YELLOW}시스템 패키지 업데이트 중... (sudo 권한 필요)${NC}"
    sudo apt-get update && sudo apt-get upgrade -y
    
    echo -e "${YELLOW}필수 패키지 설치 중...${NC}"
    sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano \
    automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev \
    libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev \
    python3 python3-pip python3-venv screen -y
    
  elif [[ "$OS" == "macos" ]]; then
    # Homebrew 설치 확인
    if ! command -v brew &> /dev/null; then
      echo -e "${YELLOW}Homebrew가 설치되어 있지 않습니다. 설치를 진행합니다...${NC}"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      echo -e "${GREEN}[✓] Homebrew 이미 설치됨${NC}"
      brew update
    fi
    
    echo -e "${YELLOW}필수 패키지 설치 중...${NC}"
    brew install wget jq curl git python3 tmux htop make gcc openssl leveldb
    
    # 스크린은 MacOS에서 기본적으로 사용 가능
  fi
  
  echo -e "${GREEN}[✓] 기본 의존성 패키지 설치 완료${NC}"
}

# Docker 설치 함수
install_docker() {
  echo -e "\n${BLUE}${BOLD}[2/5] Docker 설치 확인 중...${NC}"
  
  if command -v docker &> /dev/null; then
    echo -e "${GREEN}[✓] Docker 이미 설치됨${NC}"
  else
    echo -e "${YELLOW}Docker 설치 중...${NC}"
    
    if [[ "$OS" == "ubuntu" ]]; then
      sudo apt install -y docker docker-compose
      sudo systemctl enable docker
      sudo systemctl start docker
      # 일반 사용자도 도커 명령어를 사용할 수 있도록 권한 설정
      sudo usermod -aG docker $USER
      echo -e "${YELLOW}Docker 사용자 그룹 권한이 추가되었습니다. 스크립트 실행 후 로그아웃했다가 다시 로그인하세요.${NC}"
    
    elif [[ "$OS" == "macos" ]]; then
      echo -e "${YELLOW}Docker Desktop for Mac을 설치합니다...${NC}"
      brew install --cask docker
      echo -e "${YELLOW}Docker Desktop 앱을 실행해주세요.${NC}"
      open -a Docker
      # 사용자에게 Docker Desktop이 실행될 때까지 대기하도록 안내
      echo -e "${YELLOW}Docker Desktop이 완전히 시작될 때까지 기다려주세요...${NC}"
      sleep 10
    fi
  fi
  
  # Docker Compose 설치
  echo -e "\n${BLUE}[3/5] Docker Compose 설치 확인 중...${NC}"
  
  if docker compose version &> /dev/null || command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}[✓] Docker Compose 이미 설치됨${NC}"
  else
    echo -e "${YELLOW}Docker Compose 설치 중...${NC}"
    
    if [[ "$OS" == "ubuntu" ]]; then
      # Docker Compose 설치
      sudo curl -L "https://github.com/docker/compose/releases/download/v2.34.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
      
      # Docker Compose 플러그인 설치
      DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
      mkdir -p "$DOCKER_CONFIG/cli-plugins"
      curl -SL "https://github.com/docker/compose/releases/download/v2.34.0/docker-compose-linux-x86_64" -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
      chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
    
    elif [[ "$OS" == "macos" ]]; then
      echo -e "${GREEN}[✓] Docker Desktop for Mac에는 Docker Compose가 포함되어 있습니다${NC}"
    fi
  fi
  
  echo -e "${GREEN}[✓] Docker 설치 완료${NC}"
  echo -e "${YELLOW}Docker 버전:${NC}"
  docker --version
  echo -e "${YELLOW}Docker Compose 버전:${NC}"
  docker compose version 2>/dev/null || docker-compose --version
}

# 로컬 설치 함수
install_local() {
  echo -e "\n${BLUE}${BOLD}[4/5] Gensyn RL-Swarm 로컬 설치 중...${NC}"
  
  # 폴더 생성 및 이동
  echo -e "${YELLOW}Gensyn RL-Swarm 저장소 클론 중...${NC}"
  git clone https://github.com/gensyn-ai/rl-swarm.git
  cd rl-swarm
  
  # Python 가상환경 설정
  echo -e "${YELLOW}Python 가상환경 설정 중...${NC}"
  python3 -m venv .venv
  
  if [[ "$OS" == "ubuntu" ]]; then
    source .venv/bin/activate
  elif [[ "$OS" == "macos" ]]; then
    source .venv/bin/activate
    # MacOS에서 메모리 설정 (실험적)
    export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
  fi
  
  echo -e "${GREEN}[✓] 로컬 설치 준비 완료${NC}"
  
  # Screen 세션 생성 및 실행
  echo -e "\n${YELLOW}노드를 screen 세션에서 실행 준비 중...${NC}"
  
  # Screen 설치 확인
  if ! command -v screen &> /dev/null; then
    echo -e "${YELLOW}Screen이 설치되어 있지 않습니다. 설치를 진행합니다...${NC}"
    if [[ "$OS" == "ubuntu" ]]; then
      sudo apt-get install -y screen
    elif [[ "$OS" == "macos" ]]; then
      brew install screen
    fi
  fi
  
  # 백업 피어 노드 설정 (기본적으로 사용)
  echo -e "${YELLOW}백업 코디네이터 피어 설정을 적용합니다.${NC}"
  
  # Screen 세션에서 실행할 명령 작성
  SESSION_NAME="gensyn-rl-swarm"
  CURRENT_DIR=$(pwd)
  
  # 실행 커맨드 생성 (백업 피어 사용)
  COMMAND="cd $CURRENT_DIR && source .venv/bin/activate && ./run_rl_swarm.sh"
  #COMMAND="cd $CURRENT_DIR && source .venv/bin/activate && export DEFAULT_PEER_MULTI_ADDRS=\"/dns/rl-swarm.gensyn.ai/tcp/38331/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ\" && ./run_rl_swarm.sh"
  
  # MacOS인 경우 메모리 설정 추가
  if [[ "$OS" == "macos" ]]; then
    COMMAND="cd $CURRENT_DIR && source .venv/bin/activate && export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0 && ./run_rl_swarm.sh"
  fi
  
  # 기존 세션이 있는지 확인하고 종료
  screen -wipe &>/dev/null
  screen -S "$SESSION_NAME" -X quit &>/dev/null
  
  # 새 screen 세션 시작
  screen -dmS "$SESSION_NAME" bash -c "$COMMAND"
  
  echo -e "${GREEN}[✓] RL-Swarm 노드가 '${SESSION_NAME}' Screen 세션에서 실행 중입니다.${NC}"
  echo -e "${YELLOW}세션에 접속하려면: ${BOLD}screen -r $SESSION_NAME${NC}"
  echo -e "${YELLOW}세션에서 빠져나오려면: ${BOLD}Ctrl+A, D${NC}"
  echo -e "${YELLOW}세션 종료하려면: ${BOLD}Ctrl+A, K${NC} 또는 ${BOLD}screen -S $SESSION_NAME -X quit${NC}"
  
  # 코디네이터 피어 백업 정보 제공
  #echo -e "\n${YELLOW}[정보] 백업 피어가 자동으로 설정되었습니다:${NC}"
  #echo 'DEFAULT_PEER_MULTI_ADDRS="/dns/rl-swarm.gensyn.ai/tcp/38331/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ"'
}

# Docker 실행 함수
run_docker() {
  echo -e "\n${BLUE}${BOLD}[4/5] Gensyn RL-Swarm Docker 설정 중...${NC}"
  
  # GPU 감지
  if [[ "$OS" == "ubuntu" ]]; then
    if command -v nvidia-smi &> /dev/null; then
      echo -e "${GREEN}[✓] NVIDIA GPU 감지됨${NC}"
      HAS_GPU=true
      
      # GPU 모델 확인
      GPU_MODEL=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n 1)
      echo -e "${YELLOW}감지된 GPU: $GPU_MODEL${NC}"
      
      # 지원되는 GPU 모델 확인
      if [[ "$GPU_MODEL" == *"RTX 3090"* ]] || [[ "$GPU_MODEL" == *"RTX 4090"* ]] || 
         [[ "$GPU_MODEL" == *"A100"* ]] || [[ "$GPU_MODEL" == *"H100"* ]]; then
        echo -e "${GREEN}[✓] 지원되는 CUDA GPU 모델 감지됨${NC}"
      else
        echo -e "${YELLOW}[!] 공식적으로 지원되지 않는 GPU 모델입니다. 성능이 저하될 수 있습니다.${NC}"
        echo -e "${YELLOW}지원되는 GPU 모델: RTX 3090, RTX 4090, A100, H100${NC}"
      fi
    else
      echo -e "${YELLOW}[!] NVIDIA GPU가 감지되지 않았습니다. CPU 모드로 실행됩니다.${NC}"
      HAS_GPU=false
    fi
  elif [[ "$OS" == "macos" ]]; then
    echo -e "${YELLOW}[!] MacOS에서는 NVIDIA GPU를 지원하지 않습니다. CPU 모드로 실행됩니다.${NC}"
    HAS_GPU=false
  fi
  
  echo -e "\n${BLUE}${BOLD}[5/5] Gensyn RL-Swarm Docker 실행 중...${NC}"
  
  # Screen 설치 확인 및 설치
  echo -e "${YELLOW}Docker 컨테이너를 screen 세션에서 실행합니다...${NC}"
  
  if ! command -v screen &> /dev/null; then
    echo -e "${YELLOW}Screen이 설치되어 있지 않습니다. 설치를 진행합니다...${NC}"
    if [[ "$OS" == "ubuntu" ]]; then
      sudo apt-get install -y screen
    elif [[ "$OS" == "macos" ]]; then
      brew install screen
    fi
  fi
  
  # 실행할 Docker 명령어 준비
  SESSION_NAME="gensyn-rl-swarm-docker"
  
  if [[ "$HAS_GPU" == true ]]; then
    DOCKER_CMD="docker run --gpus all --pull=always -it --rm europe-docker.pkg.dev/gensyn-public-b7d9/public/rl-swarm:v0.0.2 ./run_hivemind_docker.sh"
    echo -e "${YELLOW}GPU 모드로 Docker 컨테이너 준비 중...${NC}"
  else
    DOCKER_CMD="docker run --pull=always -it --rm europe-docker.pkg.dev/gensyn-public-b7d9/public/rl-swarm:v0.0.2 ./run_hivemind_docker.sh"
    echo -e "${YELLOW}CPU 모드로 Docker 컨테이너 준비 중...${NC}"
  fi
  
  # 기존 세션이 있는지 확인하고 종료
  screen -wipe &>/dev/null
  screen -S "$SESSION_NAME" -X quit &>/dev/null
  
  # 새 screen 세션 시작
  screen -dmS "$SESSION_NAME" bash -c "$DOCKER_CMD"
  
  echo -e "${GREEN}[✓] Docker 컨테이너가 '${SESSION_NAME}' Screen 세션에서 실행 중입니다.${NC}"
  echo -e "${YELLOW}세션에 접속하려면: ${BOLD}screen -r $SESSION_NAME${NC}"
  echo -e "${YELLOW}세션에서 빠져나오려면: ${BOLD}Ctrl+A, D${NC}"
  echo -e "${YELLOW}세션 종료하려면: ${BOLD}Ctrl+A, K${NC} 또는 ${BOLD}screen -S $SESSION_NAME -X quit${NC}"
}

# 도움말 표시
show_help() {
  echo -e "${BLUE}${BOLD}Gensyn RL-Swarm 노드 설치 자동화 스크립트 도움말${NC}"
  echo -e "이 스크립트는 Gensyn RL-Swarm 노드를 Ubuntu와 MacOS 환경에서 설치합니다."
  echo -e "\n${BOLD}사용법:${NC}"
  echo -e "  ./gensyn.sh [옵션]"
  echo -e "\n${BOLD}옵션:${NC}"
  echo -e "  -h, --help     도움말 표시"
  echo -e "  -l, --local    로컬 설치 방식 선택 (Git 클론 후 실행)"
  echo -e "  -d, --docker   Docker 방식 선택 (Docker 컨테이너 실행)"
  echo -e "\n${BOLD}예시:${NC}"
  echo -e "  ./gensyn.sh         # 대화형 모드로 실행"
  echo -e "  ./gensyn.sh --local # 로컬 설치 방식으로 바로 실행"
  echo -e "  ./gensyn.sh --docker # Docker 방식으로 바로 실행"
}

# 메인 함수
main() {
  print_logo
  check_os
  install_dependencies
  install_docker
  
  # 커맨드 라인 인자가 있을 경우 처리
  if [[ "$1" == "-l" ]] || [[ "$1" == "--local" ]]; then
    INSTALL_METHOD="local"
  elif [[ "$1" == "-d" ]] || [[ "$1" == "--docker" ]]; then
    INSTALL_METHOD="docker"
  elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
  elif [[ -n "$1" ]]; then
    echo -e "${RED}[✗] 알 수 없는 옵션: $1${NC}"
    show_help
    exit 1
  else
    # 설치 방법 선택
    echo -e "\n${BLUE}${BOLD}Gensyn RL-Swarm 설치 방법 선택:${NC}"
    echo -e "${BOLD}1)${NC} 로컬 설치 (Git 클론 후 실행)"
    echo -e "${BOLD}2)${NC} Docker 실행 (컨테이너 이미지 사용)"
    echo -e "${YELLOW}선택하세요 (1 또는 2):${NC} "
    read -r CHOICE
    
    if [[ "$CHOICE" == "1" ]]; then
      INSTALL_METHOD="local"
    elif [[ "$CHOICE" == "2" ]]; then
      INSTALL_METHOD="docker"
    else
      echo -e "${RED}[✗] 잘못된 선택입니다. 1 또는 2를 입력하세요.${NC}"
      exit 1
    fi
  fi
  
  # 선택한 방법으로 설치 진행
  if [[ "$INSTALL_METHOD" == "local" ]]; then
    install_local
  elif [[ "$INSTALL_METHOD" == "docker" ]]; then
    run_docker
  fi
  
  echo -e "\n${GREEN}${BOLD}Gensyn RL-Swarm 설치 완료!${NC}"
  echo -e "${YELLOW}추가 도움이 필요하시면 공식 Gensyn Github을 참조하세요: https://github.com/gensyn-ai/rl-swarm${NC}"
}

# 스크립트 실행
main "$@"
