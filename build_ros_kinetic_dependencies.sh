#!/bin/bash
PYTHON2_MAJOR_VERSION=2
PYTHON2_MINOR_VERSION=7
PYTHON2_PATCH_VERSION=13

PYTHON3_MAJOR_VERSION=3
PYTHON3_MINOR_VERSION=6
PYTHON3_PATCH_VERSION=1

PYTHON2_VERSION=${PYTHON2_MAJOR_VERSION}.${PYTHON2_MINOR_VERSION}.${PYTHON2_PATCH_VERSION}
PYTHON3_VERSION=${PYTHON3_MAJOR_VERSION}.${PYTHON3_MINOR_VERSION}.${PYTHON3_PATCH_VERSION}

INSTALL_ROOT=ros-root

set -euf -o pipefail

if [ -z "$ALDE_CTC_CROSS" ]; then
  echo "Please define the ALDE_CTC_CROSS variable with the path to Aldebaran's Crosscompiler toolchain"
  exit 1
fi

mkdir -p ccache-build/
mkdir -p ${INSTALL_ROOT}/ros/ros_catkin_ws/cmake
mkdir -p ${INSTALL_ROOT}/ros/ros_catkin_ws/src
cp repos/pepper_ros1.repos ${INSTALL_ROOT}/ros/ros_catkin_ws/
cp ctc-cmake-toolchain.cmake ${INSTALL_ROOT}/ros/ros_catkin_ws/
cp cmake/eigen3-config.cmake ${INSTALL_ROOT}/ros/ros_catkin_ws/cmake/

mkdir -p ${INSTALL_ROOT}/ros_dependencies
mkdir -p ros_dependencies_sources/src
cp repos/ros1_dependencies.repos ros_dependencies_sources/

USE_TTY=""
if [ -z "$ROS_PEPPER_CI" ]; then
  USE_TTY="-it"
fi

docker run ${USE_TTY} --rm \
  -u $(id -u) \
  -e HOME=/home/nao \
  -e CCACHE_DIR=/home/nao/.ccache \
  -e PYTHON2_VERSION=${PYTHON2_VERSION} \
  -e ALDE_CTC_CROSS=/home/nao/ctc \
  -e INSTALL_ROOT=${INSTALL_ROOT} \
  -v ${PWD}/ccache-build:/home/nao/.ccache \
  -v ${PWD}/Python-${PYTHON2_VERSION}-host:/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}:ro \
  -v ${PWD}/Python-${PYTHON2_VERSION}-host:/home/nao/Python-${PYTHON2_VERSION}-host:ro \
  -v ${PWD}/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}:/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}-pepper:ro \
  -v ${ALDE_CTC_CROSS}:/home/nao/ctc:ro \
  -v ${PWD}/${INSTALL_ROOT}/ros/ros_catkin_ws:/home/nao/${INSTALL_ROOT}/ros/ros_catkin_ws:ro \
  -v ${PWD}/ros_dependencies_sources:/home/nao/ros_dependencies_sources:rw \
  -v ${PWD}/${INSTALL_ROOT}/ros_dependencies:/home/nao/${INSTALL_ROOT}/ros_dependencies:rw \
  -v ${PWD}/ros_dependencies_build_scripts:/home/nao/ros_dependencies_build_scripts:ro \
  ros1-pepper \
  bash -c "\
    set -eu -o pipefail && \
    export LD_LIBRARY_PATH=/home/nao/ctc/openssl/lib:/home/nao/ctc/zlib/lib:/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}/lib && \
    export PATH=/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}/bin:$PATH && \
    export PKG_CONFIG_PATH=/home/nao/${INSTALL_ROOT}/ros_dependencies/lib/pkgconfig && \
    cd /home/nao/ros_dependencies_sources && \
    vcs import src < ros1_dependencies.repos && \

    for script_file in \$(ls /home/nao/ros_dependencies_build_scripts/|sort); do
      /home/nao/ros_dependencies_build_scripts/\$script_file
    done"
