#!/bin/bash
PYTHON2_MAJOR_VERSION=2
PYTHON2_MINOR_VERSION=7
PYTHON2_PATCH_VERSION=13

PYTHON2_VERSION=${PYTHON2_MAJOR_VERSION}.${PYTHON2_MINOR_VERSION}.${PYTHON2_PATCH_VERSION}

INSTALL_ROOT=ros-root

set -euf -o pipefail

if [ -z "$ALDE_CTC_CROSS" ]; then
  echo "Please define the ALDE_CTC_CROSS variable with the path to Aldebaran's Crosscompiler toolchain"
  exit 1
fi

mkdir -p ccache-build/
mkdir -p ${INSTALL_ROOT}/ros/ros_catkin_ws/cmake
mkdir -p ${INSTALL_ROOT}/ros/ros_catkin_ws/src
mkdir -p ${INSTALL_ROOT}/ros/kinetic

cp repos/pepper_ros1.repos ${INSTALL_ROOT}/ros/ros_catkin_ws/
cp ctc-cmake-toolchain.cmake ${INSTALL_ROOT}/ros/ros_catkin_ws/
cp cmake/eigen3-config.cmake ${INSTALL_ROOT}/ros/ros_catkin_ws/cmake/

USE_TTY=""
if [ -z "$ROS_PEPPER_CI" ]; then
  USE_TTY="-it"
fi

docker run ${USE_TTY} --rm \
  -u $(id -u) \
  -e HOME=/home/nao \
  -e CCACHE_DIR=/home/nao/.ccache \
  -e INSTALL_ROOT=${INSTALL_ROOT} \
  -e PYTHON2_VERSION=${PYTHON2_VERSION} \
  -e PYTHON2_MAJOR_VERSION=${PYTHON2_MAJOR_VERSION} \
  -e PYTHON2_MINOR_VERSION=${PYTHON2_MINOR_VERSION} \
  -e ALDE_CTC_CROSS=/home/nao/ctc \
  -v ${PWD}/ccache-build:/home/nao/.ccache \
  -v ${PWD}/Python-${PYTHON2_VERSION}-host:/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}:ro \
  -v ${PWD}/Python-${PYTHON2_VERSION}-host:/home/nao/Python-${PYTHON2_VERSION}-host:ro \
  -v ${PWD}/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}:/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}-pepper:ro \
  -v ${ALDE_CTC_CROSS}:/home/nao/ctc:ro \
  -v ${PWD}/${INSTALL_ROOT}/ros_dependencies:/home/nao/${INSTALL_ROOT}/ros_dependencies:ro \
  -v ${PWD}/${INSTALL_ROOT}/ros/kinetic:/home/nao/${INSTALL_ROOT}/ros/kinetic:rw \
  -v ${PWD}/${INSTALL_ROOT}/ros/ros_catkin_ws:/home/nao/${INSTALL_ROOT}/ros/ros_catkin_ws \
  ros1-pepper \
  bash -c "\
    set -euf -o pipefail && \
    export LD_LIBRARY_PATH=/home/nao/ctc/openssl/lib:/home/nao/ctc/zlib/lib:/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}/lib && \
    export PATH=/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}/bin:$PATH && \
    export PKG_CONFIG_PATH=/home/nao/${INSTALL_ROOT}/ros_dependencies/lib/pkgconfig && \
    cd ${INSTALL_ROOT}/ros/ros_catkin_ws && \
    vcs import src < pepper_ros1.repos && \
    touch src/orocos_kinematics_dynamics/python_orocos_kdl/CATKIN_IGNORE && \
    ./src/catkin/bin/catkin_make_isolated --install --install-space /home/nao/${INSTALL_ROOT}/ros/kinetic -DCMAKE_BUILD_TYPE=Release \
    --cmake-args \
      -DOPENSSL_ROOT_DIR=/home/nao/ctc/openssl \
      -DWITH_QT=OFF \
      -DSETUPTOOLS_DEB_LAYOUT=OFF \
      -DCATKIN_ENABLE_TESTING=OFF \
      -DENABLE_TESTING=OFF \
      -DPYTHON_EXECUTABLE=/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}/bin/python \
      -DPYTHON_LIBRARY=/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}-pepper/lib/libpython${PYTHON2_MAJOR_VERSION}.${PYTHON2_MINOR_VERSION}.so \
      -DTHIRDPARTY=ON \
      -DCMAKE_TOOLCHAIN_FILE=/home/nao/${INSTALL_ROOT}/ros/ros_catkin_ws/ctc-cmake-toolchain.cmake \
      -DALDE_CTC_CROSS=/home/nao/ctc \
      -DCMAKE_PREFIX_PATH=\"/home/nao/${INSTALL_ROOT}/ros/kinetic\" \
      -DCMAKE_FIND_ROOT_PATH=\"/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}-pepper;/home/nao/${INSTALL_ROOT}/ros_dependencies;/home/nao/${INSTALL_ROOT}/ros/kinetic;/home/nao/ctc\" \
    "
cp ${PWD}/setup_ros1_pepper.bash ${PWD}/${INSTALL_ROOT}/setup_ros1_pepper.bash
