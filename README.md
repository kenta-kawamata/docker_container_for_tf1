# Docker container for Tensorflow1

## 環境

## 使用方法（ローカル環境or通信環境が良くない環境を想定）

1. 以下のリンクから依存関係にあるcudnnファイルをDockerfile配下にダウンロードする。

[developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804](https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/)
[個人用バックアップ先](https://drive.google.com/drive/folders/1zbMdOlB4cEUiF27gfYc5dFcMZKoCskfm?usp=sharing)

依存関係にあるcudnnファイル
```
cudnn-10.0-linux-x64-v7.4.2.24.tgz
libcudnn7_7.4.2.24-1+cuda10.0_amd64.deb
libcudnn7-dev_7.4.2.24-1+cuda10.0_amd64.deb
```

2. ビルド

```
$ docker compose up -b --build .
```