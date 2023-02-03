#!/bin/bash
echo "sudoはパッケージインストールのapt, brewコマンド, コンテナ作成のdockerコマンドに利用します"
echo "コンテナイメージのビルドが終わるまでしばらく時間がかかりますが、この画面を閉じないでください"
OS=''

#config 存在確認
if [ ! -f ./config ]; then
	echo config not found.
	touch config
fi

#
generate_config() {
	echo IPWB_DATA_DIR=$(pwd)/ipwb-master/warc > ./config
	
	TARGET_DIR=''
	if [ -d "$HOME/Downloads" ]; then
		TARGET_DIR="$HOME/Downloads"
		echo "log: watch dir -> ${TARGET_DIR}" 
	else
		TARGET_DIR=$(pwd)/target
		echo log: ダウンロードフォルダーが見つかりません。手動でwarcfileをtargetフォルダーに移してください。
		if [ ! -d "${TARGET_DIR}" ]; then
			mkdir $(pwd)/target
		fi
	fi
	echo WATCH_TARGET_DIR="${TARGET_DIR}" >> ./config
}

system_check(){
	# kernel check 
	if [ "$(uname)" = 'Darwin' ]; then
		OS='Mac'
	elif [ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]; then
		OS='Linux'
	fi
	echo OS="${OS}" >> ./config 
	DOCKER_PATH=$(which docker)
	if [ -z "${DOCKER_PATH}" ]; then
		echo error: docker is not installed
		exit 1
	fi
}

generate_config
system_check
if [ -z "${OS}" ];then
	echo error: OS
	exit 1
elif [ "${OS}" = 'Linux' ]; then
	echo ""
	sudo apt -qq update
	sudo apt -qq install inotify-tools
	./linuxTask.sh&
elif [ "$OS" = 'Mac' ]; then
	brew install fswatch
	./macTask.sh&
fi

get_arch() {
  local arch
  arch=$(uname -m | tr '[:upper:]' '[:lower:]')
  case ${arch} in
  x86_64)
    arch='amd64'
    ;;
  esac

  echo "${arch}"
}

get_platform() {
  plat=$(uname | tr '[:upper:]' '[:lower:]')

  echo "${plat}"
}

arch="$(get_arch)"
platform="$(get_platform)"
sudo docker build -t beru/ipwb_local ./ipwb-master --build-arg ARCH=$arch --build-arg PLATFORM=$platform

sudo docker run -d --name ipwb_local \
	-v $(pwd)/ipwb-master/warc:/data/warc	-v $(pwd)/ipwb-master/cdxj:/data/cdxj \
	-p 4001:4001   -p 8080:8080   -p 5001:5001 -p 2016:2016 \
	beru/ipwb_local
